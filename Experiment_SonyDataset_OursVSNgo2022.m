%% Sony Dataset: Surface Normals and Light Directions from Shading and Polarization
clc; 
clear; 
close all;
%%
% dataset = reatdSonyDataset('Data\SONY\');
dataset = load('./Data/Data_SonyDataset.mat');
%% single pixel 
objData = dataset.bear1;
Mask = ones(size(objData(1).polarImage.I0)) == 1;
for num = 1 : length(objData)
    Mask = objData(num).mask & Mask;
end
[rowValid, colValid] = find(Mask == 1);
error = NaN(size(Mask));
for cnt = 1 : length(rowValid)
    row = rowValid(cnt); col = colValid(cnt);
%     row = 578; col = 414;
    polarPixel.I0 = []; polarPixel.I45 = []; polarPixel.I90 = []; polarPixel.I135 = [];
    numLights = numel(objData);
    lightDirection = zeros(numLights, 3);
    for num = 1 : length(objData)
        polarPixel.I0 = [polarPixel.I0; objData(num).polarImage.I0(row, col)];
        polarPixel.I45 = [polarPixel.I45; objData(num).polarImage.I45(row, col)];
        polarPixel.I90 = [polarPixel.I90; objData(num).polarImage.I90(row, col)];
        polarPixel.I135 = [polarPixel.I135; objData(num).polarImage.I135(row, col)];
        lightDirection(num,:) = objData(num).lightDirection(:).';
    end
    lightDirection = lightDirection ./ vecnorm(lightDirection, 2,2);
    %%
    n_Desired = reshape(objData(1).normal(row,col,:), 3, 1);
    [n_Ngo2022, eta_est, info] = get_normal_Ngo2022_pixel(polarPixel, lightDirection);
%     n_Ngo2022(2) = -n_Ngo2022(2);
    error(row, col) = rad2deg(acos(n_Ngo2022' * n_Desired));
    rad2deg(acos(n_Ngo2022' * n_Desired))
end
mean(error(Mask))

% 


function [N_Ngo2022, eta_est, info] = get_normal_Ngo2022_pixel(polarPixel, lightDirection)
%GET_NORMAL_NGO2022 Ngo et al., TPAMI 2022, Algorithm 1 (known lights).
% [N, eta, info] = get_normal_Ngo2022(polarPixel, lightDirection)
%
% INPUT: I0/I45/I90/I135 are L-element vectors of LINEAR intensities;
% lightDirection is L-by-3, surface-to-light, in the normal coordinate frame.
% Orthographic observer: o=[0;0;1]. Polarizer angles: +x toward +y.
% Light intensities must be equal or already radiometrically calibrated.
% OUTPUT: N is a 3-by-1 unit normal; eta is the fitted refractive index.
% Requires MATLAB Optimization Toolbox (lsqnonlin); syntax targets R2022b.
%
% Reference: Ngo, Nagahara, Taniguchi, "Surface Normals and Light Directions
% From Shading and Polarization", TPAMI 44(9), 2022, Sec. 6.1, Eqs. (1)-(25).
% DOI: 10.1109/TPAMI.2021.3072656.
%
% Paper-specified: photometric-stereo initialization, eta0=1, LM, ws=0.5,
% kn=100, pairwise squared ANGULAR errors, and the visibility prior.
% Uses printed Eq. (3): F=rs^2+rp^2, WITHOUT adding a factor of 1/2.
% Uses Snell's law for the incident refracted angle; the paper also writes
% cos(theta_t)=n'*o, which is inconsistent with that law in general.
%
% Unspecified implementation details are explicit below: lambda, darkness
% threshold/statistic, LM tolerances and finite-difference step. This is an
% independent implementation of the published method, NOT the authors' code.
% No ground truth, multistart search, normal flipping, or imposed eta range.
% A mathematically undefined trial receives a fixed large residual; equations
% are unchanged at defined trials. Physical validity is reported separately.

narginchk(2,2);
assert(exist('lsqnonlin','file') == 2, ...
    'get_normal_Ngo2022:Toolbox', 'Requires Optimization Toolbox: lsqnonlin.');

%% Settings: paper values versus explicitly chosen numerical settings
cfg.ws = 0.5;                       % Paper, Sec. 7.1
cfg.kn = 100;                       % Paper, Sec. 6.1
cfg.eta0 = 1.5;                       % Paper, Sec. 6.1 (keep exactly 1)
cfg.lambda = 1;                     % NOT specified numerically in paper
cfg.darkFraction = 0.01;            % NOT specified: threshold on mean I
% darkFraction is relative to this pixel's largest valid observation.
% Set it from the acquisition/noise level, consistently for all test pixels.
cfg.maxIterations = 400;            % Numerical choices, not paper values
cfg.maxFunctionEvaluations = 5000;
cfg.finiteDifferenceStep = 1e-5;
cfg.functionTolerance = 1e-10;
cfg.stepTolerance = 1e-10;
cfg.optimalityTolerance = 1e-10;

%% 1. Read observations and compute the data-dependent visibility alpha
validateattributes(lightDirection, {'numeric'}, ...
    {'real','finite','2d','ncols',3,'nonempty'});
assert(isstruct(polarPixel) && isscalar(polarPixel), ...
    'polarPixel must be a scalar structure.');
L = double(lightDirection);
lengths = sqrt(sum(L.^2,2));
assert(all(lengths > 0), 'Light directions must be nonzero.');
L = L ./ lengths;
fields = {'I0','I45','I90','I135'};
I = zeros(size(L,1),4);
for k = 1:4
    assert(isfield(polarPixel,fields{k}), 'Missing field %s.',fields{k});
    a = polarPixel.(fields{k});
    assert(isnumeric(a) && isreal(a) && numel(a)==size(L,1), ...
        'Each polarization field must have one intensity per light.');
    I(:,k) = double(a(:));
end
N_Ngo2022 = NaN(3,1); eta_est = NaN;
info = struct('valid',false,'converged',false,'exitflag',-1, ...
    'message','','initialNormal',NaN(3,1),'initialEta',cfg.eta0, ...
    'objective',NaN,'settings',cfg,'invalidTrialCount',0);
good = all(isfinite(I) & I>=0,2) & mean(I,2)>0;
if ~any(good)
    info.message = 'No finite, nonnegative, nonzero observations.'; return;
end
intensityScale = max(max(I(good,:)));
alpha = good & mean(I,2)>cfg.darkFraction*intensityScale;
info.visibility = alpha;
info.usedLights = find(alpha);
info.darkThreshold = cfg.darkFraction*intensityScale;
% Removing alpha=0 lights is equivalent to their zero weights in Eq. (21).
I = I(alpha,:)/intensityScale; L = L(alpha,:);
% ONE common scale only: never normalize each light's brightness separately.
if size(L,1)<3 || rank(L)<3
    info.message = 'Need at least three visible, linearly independent lights.';
    return;
end
[~,S,W] = svd(L,0);
info.lightCondition = S(1,1)/S(3,3);
info.leastConstrainedDirection = W(:,3);

%% 2. Conventional photometric-stereo initialization (Sec. 6.1)
g = L \ mean(I,2);
if any(~isfinite(g)) || norm(g)<=eps
    info.message = 'Photometric-stereo initialization is degenerate.'; return;
end
n0 = g/norm(g);
x0 = [acos(max(-1,min(1,n0(3)))); atan2(n0(2),n0(1)); cfg.eta0];
info.initialNormal = n0;
info.initialParameters = x0;
c = build_pairs(I,L);
info.numberOfShadingResiduals = numel(c.li);
info.numberOfPolarizationResiduals = numel(c.ai);
[r0,ok0] = paper_residual(x0,c,cfg);
if ~ok0
    info.message = 'The published model is undefined at the PS initial point.';
    return;
end
info.initialObjective = sum(r0.^2);

%% 3. Single-start Levenberg-Marquardt in [theta; phi; eta]
options = optimoptions('lsqnonlin', ...
    'Algorithm','levenberg-marquardt','Display','off', ...
    'FiniteDifferenceType','forward', ...
    'FiniteDifferenceStepSize',cfg.finiteDifferenceStep, ...
    'MaxIterations',cfg.maxIterations, ...
    'MaxFunctionEvaluations',cfg.maxFunctionEvaluations, ...
    'FunctionTolerance',cfg.functionTolerance, ...
    'StepTolerance',cfg.stepTolerance, ...
    'OptimalityTolerance',cfg.optimalityTolerance);
invalidTrialCount = 0;
[x,~,~,flag,output] = lsqnonlin(@residual_for_lm,x0,[],[],options);
[r,defined,model] = paper_residual(x,c,cfg);
info.exitflag = flag;
info.solverOutput = output;
info.iterations = output.iterations;
info.invalidTrialCount = invalidTrialCount;
info.parameters = x;
info.converged = flag>0 && defined;
if ~defined
    info.message = 'LM ended at an undefined model evaluation.'; return;
end

%% 4. Return the fitted solution without sign correction or GT selection
N_Ngo2022 = model.n;
eta_est = x(3);
info.theta = acos(max(-1,min(1,model.n(3))));
info.phi = atan2(model.n(2),model.n(1));
info.predictedDoLP = model.rho;
info.incidentTransmission = model.t;
ns = numel(c.li); np = numel(c.ai);
info.objective = sum(r.^2);
info.objectiveTerms = [sum(r(1:ns).^2), ...
    sum(r(ns+(1:np)).^2),r(end)^2]; % Weighted shading, polarization, prior
info.shadingResidualRMS = sqrt(mean(r(1:ns).^2)/cfg.ws);
info.polarizationResidualRMS = sqrt(mean(r(ns+(1:np)).^2)/(1-cfg.ws));
info.etaNearUnity = abs(eta_est-1)<1e-4;
info.frontFacing = model.n(3)>0;
info.negativeShading = any(model.t<0);
info.valid = info.frontFacing && eta_est>=1 && all(model.mu>=0) ...
    && ~info.negativeShading && model.rho>=0 && model.rho<=1;
info.message = sprintf('LM exitflag=%d; physical validity=%d. %s', ...
    flag,info.valid,output.message);
if info.etaNearUnity
    info.message = [info.message, ...
        ' eta is near 1: polarization sensitivity can be very weak.'];
end
if info.negativeShading
    info.message = [info.message, ...
        ' The printed Fresnel sum produces negative incident transmission.'];
end

    function r = residual_for_lm(z)
        [r,definedHere] = paper_residual(z,c,cfg);
        if ~definedHere
            invalidTrialCount = invalidTrialCount+1;
        end
    end
end

function c = build_pairs(I,L)
% All UNORDERED pairs: N_L=L(L-1)/2 and N_P=P(P-1)/2, as in paper Sec. 6.
nl = size(I,1);
lp = nchoosek(1:nl,2); ap = nchoosek(1:4,2);
c.L = L; c.angles = [0;pi/4;pi/2;3*pi/4];
c.li = repmat(lp(:,1),4,1); c.lj = repmat(lp(:,2),4,1);
A = I(lp(:,1),:); B = I(lp(:,2),:);
c.s1 = A(:); c.s2 = B(:);
c.ai = repmat(ap(:,1),nl,1); c.aj = repmat(ap(:,2),nl,1);
A = I(:,ap(:,1)).'; B = I(:,ap(:,2)).';
c.p1 = A(:); c.p2 = B(:);
% Eq. (19)/(20) is undefined for a zero measured pair; omit those pairs.
keep = hypot(c.s1,c.s2)>0;
c.li = c.li(keep); c.lj = c.lj(keep);
c.s1 = c.s1(keep); c.s2 = c.s2(keep);
keep = hypot(c.p1,c.p2)>0;
c.ai = c.ai(keep); c.aj = c.aj(keep);
c.p1 = c.p1(keep); c.p2 = c.p2(keep);
end

function [r,defined,m] = paper_residual(x,c,cfg)
% Direct equation-by-equation implementation of the published objective.
% Each row of S1/S2/P1/P2 represents one two-dimensional vector pair.
% E_s and E_p are the SQUARED errors of Eqs. (19)-(20).
% Return their weighted square roots because lsqnonlin squares residuals.
r = 10*ones(numel(c.li)+numel(c.ai)+1,1);
defined = false; m = struct();
if any(~isfinite(x)) || x(3)<=0, return; end

theta = x(1);
phi = x(2);
eta = x(3);

%% Surface normal and light incidence angles
n = [sin(theta)*cos(phi);
     sin(theta)*sin(phi);
     cos(theta)];

cos_theta_i = c.L*n;
cos_theta_i = min(max(cos_theta_i,-1),1); % Roundoff protection
theta_i = acos(cos_theta_i);

% Snell's law stated below Eq. (2):
% sin(theta_i) = eta*sin(theta_t).
% The paper ALSO writes cos(theta_t)=n'*o. That is inconsistent with
% Snell's law in general; here theta_t is the refracted INCIDENT angle.
sin_theta_t = sin(theta_i)/eta;
if any(~isfinite(sin_theta_t)) || any(abs(sin_theta_t)>1)
    return;
end
theta_t = asin(sin_theta_t);
cos_theta_t = cos(theta_t);

%% Eqs. (1)-(2): Fresnel amplitude reflection coefficients
den_perp = cos_theta_i + eta*cos_theta_t;
den_parallel = eta*cos_theta_i + cos_theta_t;
if any(den_perp==0 | den_parallel==0), return; end

r_perp = (cos_theta_i - eta*cos_theta_t) ./ den_perp;
r_parallel = (eta*cos_theta_i - cos_theta_t) ./ den_parallel;

%% Eq. (3): Fresnel reflection ratio AS PRINTED (no factor of 1/2)
F = r_perp.^2 + r_parallel.^2;

%% Eq. (5): incident transmission term
t = (1-F).*cos_theta_i;

%% Eq. (13): diffuse degree of polarization
sin2theta = sin(theta)^2;
radOut = eta^2-sin2theta;
if ~isfinite(radOut) || radOut<0, return; end

den_rho = 2 + 2*eta^2 - (eta+1/eta)^2*sin2theta ...
    + 4*cos(theta)*sqrt(eta^2-sin2theta);
if ~isfinite(den_rho) || den_rho==0, return; end

rho = ((eta-1/eta)^2*sin2theta)/den_rho;

%% Eq. (17): relative polarization intensity
p = 1 + rho*cos(2*c.angles-2*phi);
if any(~isfinite(t)) || any(~isfinite(p)), return; end

%% Eqs. (8)-(9): observed/predicted vectors for shading
S1 = [c.s1, c.s2];
S2 = [t(c.li), t(c.lj)];

normS1 = sqrt(sum(S1.^2,2));
normS2 = sqrt(sum(S2.^2,2));
denS = normS1.*normS2;
if any(denS==0) || any(~isfinite(denS)), return; end

%% Eq. (19): squared angle between S1 and S2
cosAngleS = sum(S1.*S2,2)./denS;
if any(~isfinite(cosAngleS)), return; end
cosAngleS = min(max(cosAngleS,-1),1); % Roundoff protection for acos
E_s = acos(cosAngleS).^2;

%% Eqs. (16)-(17): observed/predicted vectors for polarization
P1 = [c.p1, c.p2];
P2 = [p(c.ai), p(c.aj)];

normP1 = sqrt(sum(P1.^2,2));
normP2 = sqrt(sum(P2.^2,2));
denP = normP1.*normP2;
if any(denP==0) || any(~isfinite(denP)), return; end

%% Eq. (20): squared angle between P1 and P2
cosAngleP = sum(P1.*P2,2)./denP;
if any(~isfinite(cosAngleP)), return; end
cosAngleP = min(max(cosAngleP,-1),1); % Roundoff protection for acos
E_p = acos(cosAngleP).^2;

%% Eqs. (24)-(25): visibility prior, with observer o=[0;0;1]
prior = (1-n(3))/(1+exp(cfg.kn*n(3)));

%% Eq. (21): weighted objective represented as least-squares residuals
% sum(r.^2) = ws*sum(E_s) + (1-ws)*sum(E_p) + lambda*prior.
r = [sqrt(cfg.ws*E_s);
     sqrt((1-cfg.ws)*E_p);
     sqrt(cfg.lambda*prior)];
defined = all(isfinite(r));
if ~defined
    r(:) = 10; return;
end
m = struct('n',n,'rho',rho,'t',t,'mu',cos_theta_i);
end




function dataset = reatdSonyDataset(location)
    subLocation = ["SONY1", "SONY2", "SONY3"];
    subsubLocation = {
        ["bear1", "bear2", "cat"];  
        ["cup1", "cup3"];            
        ["doll",  "squirrel"]         
    };
    subsubsubLocation = ["1", "2", "3", "4", "5", "6", "7", "8"];
    dataset = struct(); 
    % data
    for i = 1 : length(subLocation)
        current_objects = subsubLocation{i}; 
        for j = 1 : length(current_objects)
            objName = char(current_objects(j));
            for k = 1 : length(subsubsubLocation)
                folderPath = fullfile(location, subLocation(i), objName, subsubsubLocation(k));
                dataset.(objName)(k).polarImage.I0 = im2double(imread(fullfile(folderPath, 'A000.tif')));
                dataset.(objName)(k).polarImage.I45 = im2double(imread(fullfile(folderPath, 'A045.tif')));
                dataset.(objName)(k).polarImage.I90 = im2double(imread(fullfile(folderPath, 'A090.tif')));
                dataset.(objName)(k).polarImage.I135 = im2double(imread(fullfile(folderPath, 'A135.tif')));
                dataset.(objName)(k).lightDirection = im2double(load(fullfile(folderPath, 'LightDirection.txt')));
                dataset.(objName)(k).mask = im2double(imread(fullfile(folderPath, 'mask.png'))) > 0.99;
                normal = (im2double(imread(fullfile(folderPath, 'normal.png'))) * 2.0 - 1.0) .* dataset.(objName)(k).mask;
                normalLength = sqrt(sum(normal.^2, 3));
                normalLength(normalLength == 0) = 1;  
                dataset.(objName)(k).normal = normal ./ normalLength;                
%                 figure('Position', [0, 0, 1400, 750], 'Color', 'w', 'Name', objName + "_" + subsubsubLocation(k)); 
%                 subplot(3, 4, 1); imshow(dataset.(objName)(k).polarImage.I0, []);
%                 subplot(3, 4, 2); imshow(dataset.(objName)(k).polarImage.I45, []);
%                 subplot(3, 4, 3); imshow(dataset.(objName)(k).polarImage.I90, []);
%                 subplot(3, 4, 4); imshow(dataset.(objName)(k).polarImage.I135, []);
%                 subplot(3, 4, 5); imshow(dataset.(objName)(k).polarImage.I0 .* dataset.(objName)(k).mask, []);
%                 subplot(3, 4, 6); imshow(dataset.(objName)(k).polarImage.I45 .* dataset.(objName)(k).mask, []);
%                 subplot(3, 4, 7); imshow(dataset.(objName)(k).polarImage.I90 .* dataset.(objName)(k).mask, []);
%                 subplot(3, 4, 8); imshow(dataset.(objName)(k).polarImage.I135 .* dataset.(objName)(k).mask, []);
%                 subplot(3, 4, 9); imshow(dataset.(objName)(k).mask, []);
%                 subplot(3, 4, 10); imshow((dataset.(objName)(k).normal + 1) / 2);
%                 subplot(3, 4, 11); imshow((dataset.(objName)(k).normal .* dataset.(objName)(k).mask + 1) / 2);   
            end
        end
    end
    %% name
    dataset.nameList = ["bear1", "bear2", "cat", "cup1", "cup3", "doll", "squirrel"];
    save('./Data/Data_SonyDataset.mat', '-struct', 'dataset');
end
