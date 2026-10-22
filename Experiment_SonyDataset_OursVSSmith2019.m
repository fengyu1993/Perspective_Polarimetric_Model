%% Sony Dataset: Surface Normals and Light Directions from Shading and Polarization
clc; 
clear; 
close all;
%%
% dataset = reatdSonyDataset('Data\SONY\');
dataset = load('./Data/Data_SonyDataset.mat');
eta = 1.5;
%% parameters
[rows, cols] = size(dataset.bear1(1).polarImage.I0);
f = 12.5; pixelPitch = 2.5e-3; 
effectivePitch = 1 * pixelPitch;
fxy = f / effectivePitch;  
K = [fxy,  0,  cols/2; 0, -fxy, rows/2; 0,  0,  1];
%% prepare
nameList = dataset.nameList; % "bear1"    "bear2"    "cat"    "cup1"    "cup3"    "doll"    "squirrel"
for numName = 1 : length(nameList) 
    objName = char(nameList(numName));
    objData = dataset.(objName); 
    Smith_SonyDataset = NaN(rows, cols, 3, length(objData));
    SmithPers_SonyDataset = NaN(rows, cols, 3, length(objData));
    Mask_SonyDataset = ones(rows, cols);
    %% calculate
    Mask = ones(rows, cols);
    for i = 1 : length(objData)
        Mask = Mask & objData(i).mask;
    end
    V = getViewingDirection(K, Mask);  
    Beta = getPerspectiveDistortionAngle(V, Mask);
    Psi = getPsiAngle(V, Mask);
    for i = 1 : length(objData)
        %% parameters
        polarImage = objData(i).polarImage;  
        E = double(objData(i).intensity);
        fields = {'I0', 'I45', 'I90', 'I135'};
        for k = 1:4
            polarImage.(fields{k}) = polarImage.(fields{k}) ./ E;
        end
        N_desired = objData(i).normal;
        lightDirection = objData(i).lightDirection;
        %% methods
        % 两种方法使用相同的输入掩膜
        [N_Smith, Mask_Smith] = getSurfaceNormal_Smith2019(polarImage, eta, Mask, lightDirection');  
        [N_SmithPers, Mask_Pers] = getSurfaceNormal_Smith2019Pers(polarImage, eta, Mask, lightDirection', Psi, Beta);   
        Smith_SonyDataset(:,:,:, i) = N_Smith;
        SmithPers_SonyDataset(:,:,:, i) = N_SmithPers;    
        % 共同评估区域
        gtLength = sqrt(sum(N_desired.^2, 3));
        Mask_valid = Mask & Mask_Smith & Mask_Pers & all(isfinite(N_desired), 3) & isfinite(gtLength) & gtLength > 0;
        Mask_SonyDataset = Mask_SonyDataset & Mask_valid;
        %% Error
        error_Smith = getErrorNormalAngle(N_Smith, N_desired, Mask_valid);
        error_SmithPers = getErrorNormalAngle(N_SmithPers, N_desired, Mask_valid);  
        %% plot
        error_Smith_deg = rad2deg(error_Smith);
        error_SmithPers_deg = rad2deg(error_SmithPers);
        fprintf('Sony %s: %i Smith MAE old / pers: %.3f / %.3f deg\n', objName, i, mean(error_Smith_deg(Mask_valid)), mean(error_SmithPers_deg(Mask_valid)));
%         figure;
%         subplot(1, 2, 1); h = imagesc(error_Smith_deg); set(h, 'AlphaData', Mask_valid); set(gca, 'Color', 'k'); axis image off; colormap(parula); cb = colorbar; ylabel(cb, 'Angular error (deg)'); title('Smith');
%         subplot(1, 2, 2); h = imagesc(error_SmithPers_deg); set(h, 'AlphaData', Mask_valid); set(gca, 'Color', 'k'); axis image off; colormap(parula); cb = colorbar; ylabel(cb, 'Angular error (deg)'); title('SmithPers');
    end
    %% statistics
    err_plot_Smith = zeros(rows, cols);
    err_plot_SmithPers = zeros(rows, cols);
    sumMask = zeros(rows, cols);
    Mask = logical(Mask_SonyDataset);
    for i = 1 : length(objData)
        N_Smith = Smith_SonyDataset(:,:,:,i);
        N_SmithPers = SmithPers_SonyDataset(:,:,:,i);
        error_Smith = getErrorNormalAngle(N_Smith, N_desired, Mask);
        error_SmithPers = getErrorNormalAngle(N_SmithPers, N_desired, Mask);  
        err_plot_Smith(Mask) = err_plot_Smith(Mask) + error_Smith(Mask);
        err_plot_SmithPers(Mask) = err_plot_SmithPers(Mask) + error_SmithPers(Mask);
        sumMask(Mask) = sumMask(Mask) + 1;
    end   
    err_plot_Smith_mean = NaN(rows, cols);
    err_plot_SmithPers_mean = NaN(rows, cols);
    id = sumMask > 0;
    err_plot_Smith_mean(id) = err_plot_Smith(id) ./ sumMask(id);
    err_plot_SmithPers_mean(id) = err_plot_SmithPers(id) ./ sumMask(id);
    figure;
    ax = subplot(1, 2, 1); h = imagesc(err_plot_SmithPers_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('SmithPers');
    ax = subplot(1, 2, 2); h = imagesc(err_plot_Smith_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Smith');
    fprintf('Sony dataset MAE (deg) Smith / SmithPers: %.3f / %.3f\n', rad2deg(mean(err_plot_Smith_mean(id))), rad2deg(mean(err_plot_SmithPers_mean(id))));
    fprintf('Sony dataset SD (deg) Smith / SmithPers: %.3f / %.3f\n', rad2deg(std(err_plot_Smith_mean(id))), rad2deg(std(err_plot_SmithPers_mean(id))));
    fprintf('Sony dataset MED (deg) Smith / SmithPers: %.3f / %.3f\n', rad2deg(median(err_plot_Smith_mean(id))), rad2deg(median(err_plot_SmithPers_mean(id))));
    fprintf('Sony dataset Max (deg) Smith / SmithPers: %.3f / %.3f\n', rad2deg(max(err_plot_Smith_mean(id))), rad2deg(max(err_plot_SmithPers_mean(id))));
    %% save
    nameSave = ['./Data/Data_ExperimentSonyDataset_OursVsSmith_', objName, '.mat'];
    OtherN_est = Smith_SonyDataset;
    OursN_est = SmithPers_SonyDataset;
    save(nameSave,'OtherN_est', 'OursN_est', 'Mask_SonyDataset', 'N_desired');
end





%%
function [N_Smith, Mask_eval]  = getSurfaceNormal_Smith2019(polarImage, eta, Mask, s0)
    images = double(cat(3, polarImage.I0, polarImage.I45, polarImage.I90, polarImage.I135));
    angles = [0, pi/4, pi/2, 3*pi/4];
    [rho_est, phi_ours, Iun_est] = PolarisationImage(images, angles, Mask, 'linear');
    rho_est(~Mask) = 0;
    phi_est = mod(pi/2 - phi_ours, pi);
    theta_est = rho_diffuse(rho_est, eta);
    phi_est(~Mask) = 0;
    theta_est(~Mask) = 0;
    Iun_est(~Mask) = 0;
    %% Height reconstruction ECCV 2016
%     [s, ~, ~] = findLight(theta_est, phi_est, Iun_est, Mask, 3, s0);
%     spec = false(size(Mask));
%     [azi, Bdist] = boundaryPrior(Mask);
%     Bdist(~Mask) = 0;
%     height = HfPol(theta_est, Iun_est, phi_est, s, Mask, false, spec, azi, Bdist);
    %% Height reconstruction TPAMI 2019
    N_init = Propagation(rho_est, phi_est, Mask, eta);
    lambda = 0;%1e-4;
    [albedo, info] = estimateAlbedoTPAMI(theta_est, phi_est, Iun_est, s0, Mask, N_init, lambda);
    I_corrected = zeros(size(Iun_est));
    I_corrected(Mask) = Iun_est(Mask) ./ albedo(Mask);
    spec = false(size(Mask));
    [azi, Bdist] = boundaryPrior(Mask);
    height = HfPol(theta_est, I_corrected, phi_est, s0, Mask, false, spec, azi, Bdist);
    %% MATLAB: first output differentiates across columns;
    [dZdu, dZdr] = gradient(height);
    N_Smith = cat(3, -dZdu, dZdr, ones(size(height)));
    N_Smith = N_Smith ./ sqrt(sum(N_Smith.^2, 3));
    Mask_eval = Mask & isfinite(height) & ...
        all(isfinite(N_Smith), 3);
    N_Smith(repmat(~Mask_eval, [1, 1, 3])) = NaN;
end

function [ height ] = HfPol( theta,diffuse,phi,l,mask,verbose,spec,azi,weight )
%HFPS Height from polarisation
% Inputs:
%   theta   - zenith angle from polarisation
%   diffuse - diffuse image (i.e. unpolarised appearance)
%   phi     - phase angle
%   (the above are all matrices size rows*cols)
%   l       - 3D column vector containing point light source
%   mask    - rows*cols binary foreground mask
%   verbose - if true, it will print out some details on the LS system
%   spec    - a binary spec mask (subset of mask)
%   azi     - priors on the azimuth, e.g. from a convexity prior
%   weight  - per-pixel weight for the azimuth prior
%
% Ouputs:
%   height  - rows*cols estimated height map
%
% William Smith 2016

% Todo: tidy up parameters so just pass an options parameter containing all
% optional params, with sensible defaults

% Note: this is a parameter - need to move this to options later
% Smoothing weight. lambda=0 => no smoothing.
lambda=0.1;

if nargin<6
    verbose=true;
end

rows = size(mask,1);
cols = size(mask,2);

f = cos(theta);

% Pad to avoid boundary problems
f = pad(f);
diffuse = pad(diffuse);
mask = pad(mask);
phi = pad(phi);
theta = pad(theta);
if nargin>=7
    spec = pad(spec);
else
    spec = zeros(size(mask));
end

if nargin==9
    weight = pad(weight);
    azi = pad(azi);
end

rows = rows+2;
cols = cols+2;

% Compute halfway vector
H = (l+[0 0 1]')./norm(l+[0 0 1]');
Hp = -H(1)./H(3);
Hq = -H(2)./H(3);

% Build lookup table relating x,y coordinate of valid pixels to index
% position in vectorised representation
count = 0;
indices = zeros(size(mask));
for row=1:rows
    for col=1:cols
        if mask(row,col)
            count=count+1;
            indices(row,col)=count;
        end
    end
end

% Create mask for 4-neighbours for Laplacian smoothing
h = [0 1 0; 1 0 1; 0 1 0];
mask4n = imfilter(1.*mask,h,'conv')==4;

% The number of usable pixels
npix = sum(mask(:));

if verbose
    disp(['Using ' num2str(npix) ' pixels']);
end

% Preallocate maximum required space
% This would be if all valid pixels had equations for all 8 neighbours for
% all possible pairs of images - it will be less in practice
i = zeros(npix*8*2+sum(mask4n(:))*4,1);
j = zeros(npix*8*2+sum(mask4n(:))*4,1);
s = zeros(npix*8*2+sum(mask4n(:))*4,1);

% Right hand side of linear system:
d = zeros(npix*2+sum(mask4n(:)),1);

NumEq = 0; % number of rows in matrix
k=0; % total number of non-zero entries in matrix

for row=1:rows
    for col=1:cols
        if mask(row,col)
            if mask4n(row,col) && lambda~=0
                % Add Laplacian smoothing term
                NumEq=NumEq+1;
                d(NumEq)=0;
                k=k+1;
                i(k)=NumEq; j(k)=indices(row,col); s(k)=-4*lambda;
                % Edge neighbours
                k=k+1;
                i(k)=NumEq; j(k)=indices(row,col-1); s(k)=1*lambda;
                k=k+1;
                i(k)=NumEq; j(k)=indices(row,col+1); s(k)=1*lambda;
                k=k+1;
                i(k)=NumEq; j(k)=indices(row-1,col); s(k)=1*lambda;
                k=k+1;
                i(k)=NumEq; j(k)=indices(row+1,col); s(k)=1*lambda;
            end
            if nargin==9
                if spec(row,col)
                    maxeq = 5;
                else
                    maxeq = 4;
                end
            else
                if spec(row,col)
                    maxeq = 3;
                else
                    maxeq = 2;
                end
            end
            for eq=1:maxeq
                
                % Start by computing p and q weights and RHSs of eqs
                if spec(row,col)
                    if eq==1 % Half vector constraint
                        RHS = Hp;
                        xval = 1;
                        yval = 0;
                    elseif eq==2 % Half vector constraint
                        RHS = Hq;
                        xval = 0;
                        yval = 1;
                    elseif eq==3 % Phase angle constraint
                        RHS = 0;
                        xval = cos(phi(row,col));
                        yval = -sin(phi(row,col));
                    elseif eq==4 % Azimuth prior from boundary (weighted)
                        RHS = -weight(row,col)*(sin(azi(row,col))*sin(theta(row,col)));
                        xval = weight(row,col)*cos(theta(row,col));
                        yval = 0;
                    elseif eq==5 % Azimuth prior from boundary (weighted)
                        RHS = -weight(row,col)*(cos(azi(row,col))*sin(theta(row,col)));
                        xval = 0;
                        yval = weight(row,col)*cos(theta(row,col));
                    end
                else
                    if eq==1 % Phase angle constraint
                        RHS = 0;
                        xval = cos(phi(row,col));
                        yval = -sin(phi(row,col));
                    elseif eq==2 % Ratio between DOP and Lambertian constraint
                        RHS = diffuse(row,col)/f(row,col) - l(3);
                        xval = -l(1);
                        yval = -l(2);
                    elseif eq==3 % Azimuth prior from boundary (weighted)
                        RHS = -weight(row,col)*(sin(azi(row,col))*sin(theta(row,col)));
                        xval = weight(row,col)*cos(theta(row,col));
                        yval = 0;
                    elseif eq==4 % Azimuth prior from boundary (weighted)
                        RHS = -weight(row,col)*(cos(azi(row,col))*sin(theta(row,col)));
                        xval = 0;
                        yval = weight(row,col)*cos(theta(row,col));
                    end
                end
                
                
                % Now decide which combination of neighbours are present
                % This determines which version of the numerical
                % approximation to the surface gradients will be used
                
                if mask(row,col-1) && mask(row,col+1)
                    % Both X neighbours present
                    if mask(row-1,col)
                        if mask(row+1,col)
                            if mask(row-1,col-1) && mask(row-1,col+1) && mask(row+1,col-1) && mask(row+1,col+1)
                                % All 8 neighbours present
                                NumEq=NumEq+1;
                                d(NumEq)=RHS;
                                % Edge neighbours
                                k=k+1;
                                i(k)=NumEq; j(k)=indices(row,col-1); s(k)=-(4/12)*xval;
                                k=k+1;
                                i(k)=NumEq; j(k)=indices(row,col+1); s(k)=(4/12)*xval;
                                k=k+1;
                                i(k)=NumEq; j(k)=indices(row-1,col); s(k)=(4/12)*yval;
                                k=k+1;
                                i(k)=NumEq; j(k)=indices(row+1,col); s(k)=-(4/12)*yval;
                                % Corner neighbours
                                k=k+1;
                                i(k)=NumEq; j(k)=indices(row-1,col-1); s(k)=-(1/12)*xval+(1/12)*yval;
                                k=k+1;
                                i(k)=NumEq; j(k)=indices(row-1,col+1); s(k)=(1/12)*xval+(1/12)*yval;
                                k=k+1;
                                i(k)=NumEq; j(k)=indices(row+1,col-1); s(k)=-(1/12)*xval-(1/12)*yval;
                                k=k+1;
                                i(k)=NumEq; j(k)=indices(row+1,col+1); s(k)=(1/12)*xval-(1/12)*yval;
                            else
                                % All 4 neighbours present
                                NumEq=NumEq+1;
                                d(NumEq)=RHS;
                                k=k+1;
                                i(k)=NumEq; j(k)=indices(row,col-1); s(k)=-xval/2;
                                k=k+1;
                                i(k)=NumEq; j(k)=indices(row,col+1); s(k)=xval/2;
                                k=k+1;
                                i(k)=NumEq; j(k)=indices(row-1,col); s(k)=yval/2;
                                k=k+1;
                                i(k)=NumEq; j(k)=indices(row+1,col); s(k)=-yval/2;
                            end
                        else
                            % Both X, only forward in Y
                            NumEq=NumEq+1;
                            d(NumEq)=RHS;
                            k=k+1;
                            i(k)=NumEq; j(k)=indices(row,col-1); s(k)=-xval/2;
                            k=k+1;
                            i(k)=NumEq; j(k)=indices(row,col+1); s(k)=xval/2;
                            k=k+1;
                            i(k)=NumEq; j(k)=indices(row-1,col); s(k)=yval;
                            k=k+1;
                            i(k)=NumEq; j(k)=indices(row,col); s(k)=-yval;
                        end
                    elseif mask(row+1,col)
                        % Both X, only backward in Y
                        NumEq=NumEq+1;
                        d(NumEq)=RHS;
                        k=k+1;
                        i(k)=NumEq; j(k)=indices(row,col-1); s(k)=-xval/2;
                        k=k+1;
                        i(k)=NumEq; j(k)=indices(row,col+1); s(k)=xval/2;
                        k=k+1;
                        i(k)=NumEq; j(k)=indices(row+1,col); s(k)=-yval;
                        k=k+1;
                        i(k)=NumEq; j(k)=indices(row,col); s(k)=yval;
                    end
                elseif mask(row,col-1)
                    % Only backward in X
                    if mask(row-1,col)
                        if mask(row+1,col)
                            % Backward in X, both in Y
                            NumEq=NumEq+1;
                            d(NumEq)=RHS;
                            k=k+1;
                            i(k)=NumEq; j(k)=indices(row,col-1); s(k)=-xval;
                            k=k+1;
                            i(k)=NumEq; j(k)=indices(row,col); s(k)=xval;
                            k=k+1;
                            i(k)=NumEq; j(k)=indices(row-1,col); s(k)=yval/2;
                            k=k+1;
                            i(k)=NumEq; j(k)=indices(row+1,col); s(k)=-yval/2;
                        else
                            % Backward in X, only forward in Y
                            NumEq=NumEq+1;
                            d(NumEq)=RHS;
                            k=k+1;
                            i(k)=NumEq; j(k)=indices(row,col-1); s(k)=-xval;
                            k=k+1;
                            i(k)=NumEq; j(k)=indices(row,col); s(k)=xval-yval;
                            k=k+1;
                            i(k)=NumEq; j(k)=indices(row-1,col); s(k)=yval;
                        end
                    elseif mask(row+1,col)
                        % Backward in X, only backward in Y
                        NumEq=NumEq+1;
                        d(NumEq)=RHS;
                        k=k+1;
                        i(k)=NumEq; j(k)=indices(row,col-1); s(k)=-xval;
                        k=k+1;
                        i(k)=NumEq; j(k)=indices(row,col); s(k)=xval+yval;
                        k=k+1;
                        i(k)=NumEq; j(k)=indices(row+1,col); s(k)=-yval;
                    end
                elseif mask(row,col+1)
                    % Only forward in X
                    if mask(row-1,col)
                        if mask(row+1,col)
                            % Forward in X, both in Y
                            NumEq=NumEq+1;
                            d(NumEq)=RHS;
                            k=k+1;
                            i(k)=NumEq; j(k)=indices(row,col+1); s(k)=xval;
                            k=k+1;
                            i(k)=NumEq; j(k)=indices(row,col); s(k)=-xval;
                            k=k+1;
                            i(k)=NumEq; j(k)=indices(row-1,col); s(k)=yval/2;
                            k=k+1;
                            i(k)=NumEq; j(k)=indices(row+1,col); s(k)=-yval/2;
                        else
                            % Forward in X, only forward in Y
                            NumEq=NumEq+1;
                            d(NumEq)=RHS;
                            k=k+1;
                            i(k)=NumEq; j(k)=indices(row,col+1); s(k)=xval;
                            k=k+1;
                            i(k)=NumEq; j(k)=indices(row,col); s(k)=-xval-yval;
                            k=k+1;
                            i(k)=NumEq; j(k)=indices(row-1,col); s(k)=yval;
                        end
                    elseif mask(row+1,col)
                        % Forward in X, only backward in Y
                        NumEq=NumEq+1;
                        d(NumEq)=RHS;
                        k=k+1;
                        i(k)=NumEq; j(k)=indices(row,col+1); s(k)=xval;
                        k=k+1;
                        i(k)=NumEq; j(k)=indices(row,col); s(k)=-xval+yval;
                        k=k+1;
                        i(k)=NumEq; j(k)=indices(row+1,col); s(k)=-yval;
                    end
                end
            end
        end
        % Finished with a pixel
    end
end

if verbose
    disp(['System contains ' num2str(NumEq) ' linear equations with ' num2str(k) ' non-zero entries in C']);
end

i=i(1:k,1);
j=j(1:k,1);
s=s(1:k,1);
d=d(1:NumEq,1);

% Fix one pixel's height to zero to resolve unknown constant of integration
i(k+1)=NumEq+1;
j(k+1)=1;
s(k+1)=1;
d(NumEq+1)=0;

if sum(isnan(d))>0
    warning('d contains NaNs - output will be all NaN');
end

% Build matrix        +1 (for constraint on pixel 1)
C = sparse(i,j,s,NumEq+1,npix);
if verbose
    tic
end
z = C\d;
if verbose
    toc
end

% Copy vector of height values back into appropriate pixel positions
height=zeros(size(mask)).*NaN;
count=0;
for row=1:rows
    for col=1:cols
        if mask(row,col)
            count=count+1;
            height(row,col)=z(count);
        end
    end
end

% Unpad
height = height(2:rows-1,2:cols-1);

end


function [ rho,phi,Iun ] = PolarisationImage( images,angles,mask,method )
%POLARISATIONIMAGE Decompose polarimetric images to polarisation image
%   Inputs:
%      images - rows by cols by nimages matrix of input images
%      angles - vector of polariser angles, length nimages
%      mask   - binary foreground mask (true for foreground)
%      method - either 'linear' or 'nonlinear'
%   Outputs:
%      rho    - rows by cols matrix containing degree of polarisation
%      phi    - rows by cols matrix containing phase angle
%      Iun    - rows by cols matrix containing unpolarised intensity
%
% William Smith 2016

if nargin<4
    % Default to linear method
    method='linear';
end

[rows,cols,nimages] = size(images);

if nargin>2
    % A mask has been provided so select only foreground pixels
    for i=1:nimages
        im = images(:,:,i);
        I(:,i)=im(mask);
    end
else
    % No mask - use all pixels
    I = reshape(images,rows*cols,nimages);
end

if strcmp(method,'nonlinear')
    % For each pixel solve a nonlinear optimisation problem 
    % Warning - slow (displays percentage progress)
    Iun = zeros(size(I,1),1);
    rho = zeros(size(I,1),1);
    phi = zeros(size(I,1),1);
    
    disp('      ');
    for i=1:size(I,1)
        [ Iun(i,1),rho(i,1),phi(i,1) ] = TRSfit( angles,I(i,:) );
        fprintf('\b\b\b\b\b\b%05.2f%%',i/size(I,1)*100);
    end
    phi = mod(phi,pi);
    
elseif strcmp(method,'linear')
    % Fast linear method - this seems to produce almost identical results
    % to the nonlinear method but is much faster
    A = [ones(nimages,1) cos(2.*angles') sin(2.*angles')];
    x = A\(I');
    x = x';
    Imax = x(:,1)+sqrt(x(:,2).^2+x(:,3).^2);
    Imin = x(:,1)-sqrt(x(:,2).^2+x(:,3).^2);
    Iun = (Imin+Imax)./2;
    rho = (Imax-Imin)./(Imax+Imin);
    phi = 0.5*atan2(x(:,3),x(:,2));
    phi = mod(phi,pi);
end

if nargin>2
    % We have a mask so need to reshape the estimated quantities to the
    % masked pixels only
    phi2 = zeros(rows,cols);
    phi2(mask) = phi;
    phi = phi2;
    rho2 = zeros(rows,cols);
    rho2(mask) = rho;
    rho = rho2;
    Iun2 = zeros(rows,cols);
    Iun2(mask) = Iun;
    Iun = Iun2;
else
    phi = reshape(phi,rows,cols);
    rho = reshape(rho,rows,cols);
    Iun = reshape(Iun,rows,cols);
end

end

function [ theta ] = rho_diffuse( rho,n )
%RHO_DIFFUSE Compute zenith angle from DOP for diffuse pixels
%   Uses closed form inversion of DOP expression
%   Inputs:
%      rho - matrix or vector containing degree of polarisation values
%      n   - scalar containing index of refraction
%   Output:
%      theta - zenith angle estimates (same size as rho)
%
% William Smith 2016

temp = ((2.*rho + 2.*n.^2.*rho - 2.*n.^2 + n.^4 + rho.^2 + 4.*n.^2*rho.^2 - n.^4.*rho.^2 - 4.*n.^3.*rho.*(-(rho - 1).*(rho + 1)).^(1/2) + 1)./(n.^4.*rho.^2 + 2.*n.^4.*rho + n.^4 + 6.*n.^2.*rho.^2 + 4.*n.^2.*rho - 2.*n.^2 + rho.^2 + 2.*rho + 1)).^(1/2);
% To avoid complex result in case of numerical issues:
temp = min(real(temp),1);
theta = acos(temp);

end

function [ theta_s ] = rho_spec( rho,n )
%RHO_S Compute zenith angle from degree of polarisation for specular pix
%   There is no closed form inversion for rho_s so this functions uses a
%   look up table and interpolates

theta = 0:0.01:pi/2;

rho_s = (2.*sin(theta).^2.*cos(theta).*sqrt(n.^2-sin(theta).^2))./(n.^2-sin(theta).^2-n.^2.*sin(theta).^2+2.*sin(theta).^4);
%figure; plot(theta,rho_s)
maxpos = find(rho_s==max(rho_s));

theta = theta(1:maxpos);
rho_s = rho_s(1:maxpos);

theta_s = interp1(rho_s,theta,rho);

end

function [ l,T,B ] = findLight( theta,phi,diffuse,mask,ldim,l )
%FINDLIGHT Estimate illumination from polarisation data
% Inputs:
%   theta   - zenith angle estimates from degree of polarisation
%   phi     - phase angle from polarisation image
%   diffuse - unpolarised intensity
%   mask    - binary foreground mask
%   ldim    - Set to 3, 4 or 9 depending on whether solving for point
%             source, order 1 or order 2 spherical harmonic illumination
%   l       - if ldim=3 and the direction of l is known (but not the
%             intensity) then pass in the known direction and only the
%             intensity will be optimised
% Outputs:
%   l       - 3D, 4D or 9D lighting coefficient vector
%   T       - Ambiguous transformation, T*l is also a solution
%   B       - The basis that is consistent with l, B*T is also a possible
%             basis
%
% William Smith 2016

if nargin<5
    ldim = 3;
end

%% Set up some required values

i = diffuse(mask);
theta = theta(mask);
phi = phi(mask);
N(:,1)=sin(phi).*sin(theta);
N(:,2)=cos(phi).*sin(theta);
N(:,3)=cos(theta);

%% Set up appropriate (ambiguous) basis vectors and transformation matrices depending on dimensionality of lighting

if ldim==3
    B = N;
    T = [-1 0 0; 0 -1 0; 0 0 1];
elseif ldim==4
    B = N;
    B(:,4) = 1;
    T = diag([-1 -1 1 1]);
elseif ldim==9
    B = [ones(size(N,1),1) N 3.*N(:,3).^2-1 N(:,1).*N(:,2) N(:,1).*N(:,3) N(:,2).*N(:,3) N(:,1).^2-N(:,2).^2];
    T = diag([1 -1 -1 1 1 1 -1 -1 1]);
end

%% Initialise optimisation

converged = false;
tau = 1e-9;
niter = 0;
maxiter = 100;

if nargin==6
    % In this case, we already know the light source direction and just
    % want to optimise for the intensity
    while ~converged
        idx = (B*l-i).^2>(B*T*l-i).^2;
        P = B;
        P(idx,:)=P(idx,:)*T;
        lnew=l.*((P*l)\i);
        if norm(l-lnew)<tau
                converged=true;
        end
        l=lnew;
        niter = niter+1;
        if niter>maxiter
            break
        end
    end
else
    % Random initialisation
    l = randn(ldim,1);
    if ldim==4
        % This is treating the order 1 model as ambient plus point source
        % and therefore assuming ambient should be positive
        l(4)=abs(l(4));
    end
    
    %% Perform alternating assignment/optimisation
    
    while ~converged
        % indicator function
        idx = (B*l-i).^2>(B*T*l-i).^2;
        P = B;
        P(idx,:)=P(idx,:)*T;
        if ldim==3
            % Unconstrained linear least squares
            lnew = P\i;
        elseif ldim==4
            % Order 0 term is constrained to be positive
            lnew = lsqlin(P,i,[],[],[],[],[-inf -inf -inf 0],[inf inf inf inf]);
        elseif ldim==9
            lnew = P\i;
        end
        if norm(l-lnew)<tau
            converged=true;
        end
        l = lnew;
        niter = niter+1;
        if niter>maxiter
            break
        end
    end
end
B = P;

% disp(['Number of iterations = ' num2str(niter)]);
% disp(['Residual = ' num2str(norm(P*l-i).^2)]);

end

function [ azi,Bdist ] = boundaryPrior( mask,weight )
%BOUNDARYPRIOR Use foreground mask to compute convexity prior
%   Input:
%      mask   - rows by cols binary foreground mask
%      weight - determines how fast the per-pixel weight falls off from the
%               boundary (default: 5)
%   Output:
%      azi    - rows by cols azimuth angle prior
%      Bdist  - weight associated with each azimuth estimate

if nargin<2
    weight=5;
end

% Find boundary of mask
B = bwperim(mask);
[bcol,brow]=find(B);
[row,col]=meshgrid(1:size(mask,2),1:size(mask,1));
% Compute distance to closest point on boundary
[~,D]=knnsearch([brow bcol],[row(mask) col(mask)]);
Bdist = zeros(size(mask)).*NaN;
% Transform to range 0..1
Bdist(mask)=-D;
Bdist(mask) = Bdist(mask)-min(Bdist(mask));
Bdist = Bdist./max(Bdist(mask));
Bdist = Bdist.^weight;
mask2 = mask;
azi = zeros(size(mask));
% Repeatedly erode boundary to propagate into interior
while sum(mask2(:))>0
    % Find boundary of current mask
    B = bwboundaries(mask2,8);
    B{1}(end+1,:)=B{1}(1,:);
    for i=1:size(B{1},1)-1
        azi(B{1}(i,1),B{1}(i,2))=atan2(B{1}(i+1,2)-B{1}(i,2),B{1}(i+1,1)-B{1}(i,1));
    end
    % Remove boundary pixels from mask, i.e. erode mask
    mask2(bwperim(mask2,8))=0;
end
% Transform azimuth angles to vectors
dx = cos(azi);
dy = sin(azi);
dx(~mask)=0;
dy(~mask)=0;
% Smooth vector field
g=fspecial('Gaussian',[9 9],2);
dx = imfilter(dx,g);
dy = imfilter(dy,g);
% Transform back to azimuth angle
azi = atan2(dy,dx);
azi = mod(-azi+pi-pi/2,2*pi);

end

function [ Iun,rho,phi ] = TRSfit( angles,I )
%TRSFIT Nonlinear least squares optimisation to fit sinusoid
%   Inputs:
%      angles - vector of polarising filter angles
%      I      - vector of measured intensities
%   Outputs:
%      Iun, rho, phi - scalar values containing polarisation image params
%
% William Smith 2016

% Initialise
b0(1)=mean(I);
b0(2)=sqrt(mean((I-b0(1)).^2)).*sqrt(2);
b0(3)=0;

options = optimoptions('lsqnonlin', 'Algorithm','trust-region-reflective','Display','off');
b=lsqnonlin(@(b) TRSfitobj(b,angles,I),b0,[0 0 -pi],[inf inf pi],options);

if b(3)<0
    b(3)=b(3)+pi;
end
Iun = b(1);
Imax = Iun+b(2);
Imin = Iun-b(2);
rho = (Imax-Imin)/(Imax+Imin);
phi = b(3);

end

function errs = TRSfitobj(b,angles,I)

I2 = b(1)+b(2).*cos(2.*angles-2*b(3));
errs = I-I2;

end

function [ X2 ] = pad( X )
%PAD Pad a matrix with an additional row/column at each edge

[rows,cols]=size(X);
X2 = zeros(rows+2,cols+2);
X2(2:rows+1,2:cols+1)=X(:,:);
if islogical(X)
    X2 = logical(X2);
end

end
function [ N,height ] = Propagation( rho,phi,mask,n )
%PROPAGATION Shape-from-polarisation by boundary propagation
%   Inputs:
%      rho    - rows by cols matrix of DOP values
%      phi    - rows by cols matrix of phase angles
%      mask   - rows by cols binary foreground mask
%      n      - refractive index
%
%   Outputs:
%      N      - rows by cols by 3 matrix containing surface normals
%      height - height map obtained by integrating N using lsqintegration
%
% This is essentially a re-implementation of the technique used in:
%
% Miyazaki, D., Tan, R.T., Hara, K. and Ikeuchi, K. Polarization-based 
% inverse rendering from a single view. In Proc. ICCV, pp. 982-987, 2003.
%
% and
%
% G. A. Atkinson and E. R. Hancock. Recovery of Surface Orientation from 
% Diffuse Polarization. IEEE Transactions on Image Processing 15:1653-1664,
% June 2006.
%
% It disambiguates polarisation normals beginning at the boundary. Boundary
% normals are disambiguated to minimise angular error to the outward facing
% boundary normal. Normals are then propagated into the interior in
% descending order of zenith angle, with the disambiguation being chosen
% that maximises smoothness with respect to already-disambiguated normals.
%
% William Smith
% 2016

% Invert degree of diffuse polarisation expression to compute zenith angle
temp = ((2.*rho + 2.*n.^2.*rho - 2.*n.^2 + n.^4 + rho.^2 + 4.*n.^2*rho.^2 - n.^4.*rho.^2 - 4.*n.^3.*rho.*(-(rho - 1).*(rho + 1)).^(1/2) + 1)./(n.^4.*rho.^2 + 2.*n.^4.*rho + n.^4 + 6.*n.^2.*rho.^2 + 4.*n.^2.*rho - 2.*n.^2 + rho.^2 + 2.*rho + 1)).^(1/2);
temp = min(real(temp),1);
theta = acos(temp);

% Pad twice to avoid boundary problems (a 7x7 neighbourhood around pixels
% is considered for smoothness)
mask = pad(pad(mask));
theta = pad(pad(theta));
phi = pad(pad(phi));
[rows,cols]=size(mask);

N = zeros(rows,cols,3).*NaN;

B = bwboundaries(mask,8,'noholes');
boundary=mask~=mask;
% This keeps track of which pixels have been disambiguated:
available_estimates=mask~=mask;

% Fill in boundary normals with disambiguation that is closest to outward
% facing normal
B{1}(end+1,:)=B{1}(1,:);
for i=1:size(B{1},1)-1
    r = B{1}(i,1);
    c = B{1}(i,2);
    available_estimates(r,c)=true;
    boundary(r,c)=true;
    azi = atan2(B{1}(i+1,2)-B{1}(i,2),B{1}(i+1,1)-B{1}(i,1));
    n1 = [sin(phi(r,c))*sin(theta(r,c)); cos(phi(r,c))*sin(theta(r,c)); cos(theta(r,c))];
    n2 = [sin(phi(r,c)+pi)*sin(theta(r,c)); cos(phi(r,c)+pi)*sin(theta(r,c)); cos(theta(r,c))];
    nb = [cos(azi)*sin(theta(r,c)); sin(azi)*sin(theta(r,c)); cos(theta(r,c))];
    if dot(n1,nb)>dot(n2,nb)
        N(r,c,:)=n1;
    else
        N(r,c,:)=n2;
    end
end
interior = mask & ~boundary;

% Sort zenith angles of interior pixels into descending order
[~,idx]=sort(theta(interior),1,'descend');
[col,row]=meshgrid(1:cols,1:rows);

% At each iteration, we choose the unprocessed pixel with smallest zenith
% angle that has at least one neighbour
while ~isempty(idx)
    flag = false;
    selected = 1;
    r = row(interior);
    c = col(interior);
    % Consider pixels in ranked-theta order to find first one with at least
    % one neighbour (over 7x7 neighbourhood)
    while flag==false
        neighbourhood = [];
        for i=-3:3
            for j=-3:3
                if (i~=0) || (j~=0)
                    if available_estimates(r(idx(selected))+i,c(idx(selected))+j)
                        neighbourhood = [neighbourhood; r(idx(selected))+i c(idx(selected))+j];
                    end
                end
            end
        end
        if ~isempty(neighbourhood) % We need at least one neighbour to test smoothness
            flag=true;
        else
            selected=selected+1;
        end
    end
    % We now have a pixel with at least one neighbour
    r=r(idx(selected));
    c=c(idx(selected));
    % Select the normals from the neighbourhood
    Ns=[];
    for i=1:size(neighbourhood,1)
        Ns=[Ns; N(neighbourhood(i,1),neighbourhood(i,2),1) N(neighbourhood(i,1),neighbourhood(i,2),2) N(neighbourhood(i,1),neighbourhood(i,2),3)];
    end
    % Compute which local solution has smaller mean angular deviation from
    % its neighbours, our definition of smoothness
    n1 = [sin(phi(r,c))*sin(theta(r,c)); cos(phi(r,c))*sin(theta(r,c)); cos(theta(r,c))];
    n2 = [sin(phi(r,c)+pi)*sin(theta(r,c)); cos(phi(r,c)+pi)*sin(theta(r,c)); cos(theta(r,c))];
    if mean(acos(Ns*n1))<mean(acos(Ns*n2))
        N(r,c,:)=n1;
    else
        N(r,c,:)=n2;
    end
    available_estimates(r,c)=true;
    idx(selected)=[];
end

% Unpad estimated normals and mask
N = N(3:end-2,3:end-2,:);
N = real(N);
mask = mask(3:end-2,3:end-2);
% Integrate normals into height map
% 只有请求第二个输出时，才计算高度
if nargout > 1
    height = lsqintegration(N, mask, false, []);
end

end

function [ N,height ] = LambertianSFP( rho,phi,mask,n,s,albedo,Iun )
%LAMBERTIANSFP Shape-from-polarisation with Lambertian model
%   Inputs:
%      rho    - rows by cols matrix of DOP values
%      phi    - rows by cols matrix of phase angles
%      mask   - rows by cols binary foreground mask
%      n      - refractive index
%      s      - light source direction
%      albedo - diffuse albedo (can be scalar or per-pixel)
%      Iun    - unpolarised intensity
%
%   Outputs:
%      N      - rows by cols by 3 matrix containing surface normals
%      height - height map obtained by integrating N using lsqintegration
%
% This is a re-implementation of the technique used in:
%
% Mahmoud, A.H., El-Melegy, M.T., Farag, A.A.: Direct method for shape 
% recovery from polarization and shading. In: Proc. ICIP. (2012) 1769?1772
%
% William Smith
% 2016

% Invert degree of diffuse polarisation expression to compute zenith angle
temp = ((2.*rho + 2.*n.^2.*rho - 2.*n.^2 + n.^4 + rho.^2 + 4.*n.^2*rho.^2 - n.^4.*rho.^2 - 4.*n.^3.*rho.*(-(rho - 1).*(rho + 1)).^(1/2) + 1)./(n.^4.*rho.^2 + 2.*n.^4.*rho + n.^4 + 6.*n.^2.*rho.^2 + 4.*n.^2.*rho - 2.*n.^2 + rho.^2 + 2.*rho + 1)).^(1/2);
temp = min(real(temp),1);
theta = acos(temp);
Iun((Iun./albedo)>1)=albedo;
Iun = Iun./albedo;

% NOTE: In the paper, they find the intersection of the Lambertian
% constraint and the DOP constraint in terms of angles, I do it in terms of
% unit vectors. Once the two unit vectors have been found, the one that is
% closest to one of the ambiguous polarisation normals is chosen and the
% final result is the average of the chosen one and the closest
% polarisation normal

% Two possible ambiguous polarisation normals:
N1(:,:,1)=sin(phi).*sin(theta);
N1(:,:,2)=cos(phi).*sin(theta);
N1(:,:,3)=cos(theta);
N2(:,:,1)=sin(phi+pi).*sin(theta);
N2(:,:,2)=cos(phi+pi).*sin(theta);
N2(:,:,3)=cos(theta);

N = NaN(size(N1));
for row=1:size(mask,1)
    for col=1:size(mask,2)
        if mask(row,col)
            a = s(1);
            b = s(2);
            c = s(3)*cos(theta(row,col))-Iun(row,col);
            d = -sin(theta(row,col))^2;
            ny1 = -(b*c + a*(- d*a^2 - d*b^2 - c^2)^(1/2))/(a^2 + b^2);
            ny2 = -(b*c - a*(- d*a^2 - d*b^2 - c^2)^(1/2))/(a^2 + b^2);
            %if a~=0
            %    nx1 = -(c - (b*(b*c + a*(- d*a^2 - d*b^2 - c^2)^(1/2)))/(a^2 + b^2))/a;
            %    nx2 = -(c - (b*(b*c - a*(- d*a^2 - d*b^2 - c^2)^(1/2)))/(a^2 + b^2))/a;
            %else
                % Expression for nx1 and nx2 give Inf in this case so
                % compute from known norm of [nx ny]
                nx1 = sqrt(sin(theta(row,col))^2-ny1^2);
                nx2 = -sqrt(sin(theta(row,col))^2-ny1^2);
            %end
            % These are the two possible normals satisfying the Lambertian
            % + polarisation DOP constraint (intersection of two planes and
            % the unit norm constraint):
            n1 = [nx1 ny1 cos(theta(row,col))]';
            n2 = [nx2 ny2 cos(theta(row,col))]';
            n1best = max( dot(n1,squeeze(N1(row,col,:))), ...
                dot(n1,squeeze(N2(row,col,:))) );
            n2best = max( dot(n2,squeeze(N1(row,col,:))), ...
                dot(n2,squeeze(N2(row,col,:))) );
            if n1best>n2best
                na = n1;
            else
                na = n2;
            end
            if dot(na,squeeze(N1(row,col,:)))>dot(na,squeeze(N2(row,col,:)))
                nb = squeeze(N1(row,col,:));
            else
                nb = squeeze(N2(row,col,:));
            end
            n = na+nb;
            n(1:2) = n(1:2)./norm(n(1:2));
            n(1:2) = n(1:2).*sin(theta(row,col));
            n(3) = cos(theta(row,col));
            N(row,col,:)=real(n);
        end
    end
end

% Integrate normals into height map
height = lsqintegration( N,mask,false,[] );

end

function [ height ] = lsqintegration( N,mask,verbose,guidez )
%LSQINTEGRATION Least squares surface integration with optional guide z
%   Input:
%      N      - rows by cols by 3 matrix containing surface normals
%      mask   - rows by cols binary foreground mask
%      guidez - rows by cols guide depth map
%   Output:
%      z      - estimated depth map
%
% William Smith 2016

if nargin<3
    verbose=true;
end

[rows,cols,~]=size(N);

% Pad to avoid boundary problems
N2 = zeros(rows+2,cols+2,3);
N2(2:rows+1,2:cols+1,:)=N;
N = N2;
clear N2

P = -N(:,:,1)./N(:,:,3);
Q = -N(:,:,2)./N(:,:,3);

mask2 = zeros(rows+2,cols+2);
mask2(2:rows+1,2:cols+1)=mask;
mask = mask2;
clear mask2

rows = rows+2;
cols = cols+2;

% Build lookup table relating x,y coordinate of valid pixels to index
% position in vectorised representation
count = 0;
indices = zeros(size(mask));
for row=1:rows
    for col=1:cols
        if mask(row,col)
            count=count+1;
            indices(row,col)=count;
        end
    end
end

% Create mask for smoothed central difference filter
h = [1 0 1; 1 0 1; 1 0 1];
maskSCDx = imfilter(1.*mask,h,'conv')==6;
maskSCDy = imfilter(1.*mask,h','conv')==6;
SCDx = (1/12).*[-1 0 1; -4 0 4; -1 0 1];
SCDy = flipud(SCDx');

% Create mask for SavGol gradient filter
h = ones(5,5);
h(:,3)=0;
maskSGx = imfilter(1.*mask,h,'conv')==20;
maskSGy = imfilter(1.*mask,h','conv')==20;
[~, ~, ~, ~, SG] = SavGol(3,5);
SGx = SG(:,:,2)';
SGy = flipud(SGx');

% Create mask for 4-neighbours for Laplacian smoothing
h = [0 1 0; 1 0 1; 0 1 0];
mask4n = imfilter(1.*mask,h,'conv')==4;
% Smoothing weight. lambda=0 => no smoothing.
lambda=0.2;

% The number of usable pixels
npix = sum(mask(:));

if verbose
    disp(['Using ' num2str(npix) ' pixels']);
end

% Preallocate maximum required space
% This would be if all valid pixels had equations for all 8 neighbours for
% all possible pairs of images - it will be less in practice
i = zeros(npix*20*2,1);
j = zeros(npix*20*2,1);
s = zeros(npix*20*2,1);

% Right hand side of linear system:
d = zeros(npix*2,1);

NumEq = 0; % number of rows in matrix
k=0; % total number of non-zero entries in matrix

for row=1:rows
    for col=1:cols
        if mask(row,col)
            if mask4n(row,col) && lambda~=0
                % Add Laplacian smoothing term
                NumEq=NumEq+1;
                d(NumEq)=0;
                k=k+1;
                i(k)=NumEq; j(k)=indices(row,col); s(k)=-4*lambda;
                % Edge neighbours
                k=k+1;
                i(k)=NumEq; j(k)=indices(row,col-1); s(k)=1*lambda;
                k=k+1;
                i(k)=NumEq; j(k)=indices(row,col+1); s(k)=1*lambda;
                k=k+1;
                i(k)=NumEq; j(k)=indices(row-1,col); s(k)=1*lambda;
                k=k+1;
                i(k)=NumEq; j(k)=indices(row+1,col); s(k)=1*lambda;
            end
            % X equations
%             if maskSGx(row,col) && 1==0
%                 NumEq=NumEq+1;
%                 d(NumEq)=P(row,col);
%                 for a=1:5
%                     for b=1:5
%                         if SGx(a,b)~=0
%                         k=k+1;
%                         i(k)=NumEq; j(k)=indices(row+a-3,col+b-3); s(k)=SGx(a,b);
%                         end
%                     end
%                 end
%             elseif
            if maskSCDx(row,col)
                NumEq=NumEq+1;
                d(NumEq)=P(row,col);
                for a=1:3
                    for b=1:3
                        if SCDx(a,b)~=0
                        k=k+1;
                        i(k)=NumEq; j(k)=indices(row+a-2,col+b-2); s(k)=SCDx(a,b);
                        end
                    end
                end
            elseif mask(row,col-1)
                if mask(row,col+1)
                    % Central difference
                    NumEq=NumEq+1;
                    d(NumEq)=P(row,col);
                    k=k+1;
                    i(k)=NumEq; j(k)=indices(row,col+1); s(k)=0.5;
                    k=k+1;
                    i(k)=NumEq; j(k)=indices(row,col-1); s(k)=-0.5;
                else
                    % Backward difference
                    NumEq=NumEq+1;
                    d(NumEq)=P(row,col);
                    k=k+1;
                    i(k)=NumEq; j(k)=indices(row,col); s(k)=1;
                    k=k+1;
                    i(k)=NumEq; j(k)=indices(row,col-1); s(k)=-1;
                end
            elseif mask(row,col+1)
                % Forward difference
                NumEq=NumEq+1;
                d(NumEq)=P(row,col);
                k=k+1;
                i(k)=NumEq; j(k)=indices(row,col); s(k)=-1;
                k=k+1;
                i(k)=NumEq; j(k)=indices(row,col+1); s(k)=1;
            end
            
            % Y equations
%             if maskSGy(row,col) && 1==0
%                 NumEq=NumEq+1;
%                 d(NumEq)=Q(row,col);
%                 for a=1:5
%                     for b=1:5
%                         if SGy(a,b)~=0
%                         k=k+1;
%                         i(k)=NumEq; j(k)=indices(row+a-3,col+b-3); s(k)=SGy(a,b);
%                         end
%                     end
%                 end
%             elseif 
            if maskSCDy(row,col)
                NumEq=NumEq+1;
                d(NumEq)=Q(row,col);
                for a=1:3
                    for b=1:3
                        if SCDy(a,b)~=0
                        k=k+1;
                        i(k)=NumEq; j(k)=indices(row+a-2,col+b-2); s(k)=SCDy(a,b);
                        end
                    end
                end
            elseif mask(row-1,col)
                if mask(row+1,col)
                    % Central difference
                    NumEq=NumEq+1;
                    d(NumEq)=Q(row,col);
                    k=k+1;
                    i(k)=NumEq; j(k)=indices(row-1,col); s(k)=0.5;
                    k=k+1;
                    i(k)=NumEq; j(k)=indices(row+1,col); s(k)=-0.5;
                else
                    % Backward difference
                    NumEq=NumEq+1;
                    d(NumEq)=Q(row,col);
                    k=k+1;
                    i(k)=NumEq; j(k)=indices(row,col); s(k)=-1;
                    k=k+1;
                    i(k)=NumEq; j(k)=indices(row-1,col); s(k)=1;
                end
            elseif mask(row+1,col)
                % Forward difference
                NumEq=NumEq+1;
                d(NumEq)=Q(row,col);
                k=k+1;
                i(k)=NumEq; j(k)=indices(row,col); s(k)=1;
                k=k+1;
                i(k)=NumEq; j(k)=indices(row+1,col); s(k)=-1;
            end
        end
    end
end

if verbose
    disp(['System contains ' num2str(NumEq) ' linear equations with ' num2str(k) ' non-zero entries in C']);
end

i=i(1:k,1);
j=j(1:k,1);
s=s(1:k,1);
d=d(1:NumEq,1);

i(k+1)=NumEq+1;
j(k+1)=1;
s(k+1)=1;
d(NumEq+1)=0;

% Build matrix        +1 (for constraint on pixel 1)
C = sparse(i,j,s,NumEq+1,npix);
if verbose
    tic
end
%sum(isnan(C(:)))
%sum(isnan(d(:)))
%[c,A] = qr(C,d,0);
%sum(isnan(A(:)))
%sum(isnan(c(:)))

%z = A\c;
z = C\d;
if verbose
    toc
end


% Copy vector of height values back into appropriate pixel positions
height=zeros(size(mask)).*NaN;
count=0;
for row=1:rows
    for col=1:cols
        if mask(row,col)
            count=count+1;
            height(row,col)=z(count);
        end
    end
end

% Unpad
height = height(2:rows-1,2:cols-1);

end
        

function [albedo, info] = estimateAlbedoTPAMI( ...
    theta, phi, Iun, s, Mask, N_init, lambda)
%ESTIMATEALBEDOTPAMI Diffuse albedo estimation, Smith et al., TPAMI 2019.
% New implementation of Sec. 6, Eqs. (39)-(42); NOT the authors' source code.
%
% [albedo,info] = estimateAlbedoTPAMI(theta,phi,Iun,s,Mask,N_init,lambda)
%
% phi: AUTHOR convention, n=[sin(theta)*sin(phi);sin(theta)*cos(phi);cos(theta)].
% s: surface-to-light vector in the same XYZ frame. Its magnitude is retained.
% N_init: normals obtained from convexity/boundary propagation, NOT ground truth.
% lambda: required shading-smoothness weight; no paper-specific default assumed.
% albedo: NaN outside Mask. This is reflectance, NOT a DoLP correction factor.
%
% Objective: sum(min((a-a1).^2,(a-a2).^2)) + lambda*norm(L*(Iun./a))^2.
% Bounds: Iun/norm(s) <= a <= 1. Iun must be positive inside Mask.
% L uses the same 4-neighbour interior stencil as the supplied HfPol code.
% No zero-padding penalty is imposed across the mask boundary.
% Analytic gradient; sparse finite-difference Hessian; trust-region-reflective.
% At a data-term branch tie the first branch's gradient is used. The paper's
% minimum-of-two-squares objective is nonconvex and nonsmooth at such ties.
% This function does not implement Sec. 7 specular constraints/TV inpainting.
% Requires MATLAB Optimization Toolbox (fmincon); designed for R2022b.
% Reference: DOI 10.1109/TPAMI.2018.2868065.

if nargin < 7
    error('estimateAlbedoTPAMI:Inputs', ...
        'Supply theta, phi, Iun, s, Mask, N_init, and lambda.');
end
validateattributes(lambda, {'numeric'}, {'scalar','real','finite','nonnegative'});
Mask = logical(Mask);
[h,w] = size(Mask);
assert(any(Mask(:)), 'Mask must contain valid pixels.');
assert(isequal(size(theta),[h,w]) && isequal(size(phi),[h,w]) && ...
    isequal(size(Iun),[h,w]) && isequal(size(N_init),[h,w,3]), ...
    'Input image and normal dimensions must agree.');
s = double(s(:));
assert(numel(s)==3 && isreal(s) && all(isfinite(s)) && norm(s)>0, ...
    's must be a finite nonzero surface-to-light vector.');
lightNorm = norm(s);                 % Do not silently normalize the light.
t = double(theta(Mask));
p = double(phi(Mask));
I = double(Iun(Mask));
assert(isreal(t) && isreal(p) && isreal(I) && ...
    all(isfinite(t)) && all(isfinite(p)) && all(isfinite(I)) && ...
    all(t>=0 & t<=pi/2) && all(I>0), ...
    'Inside Mask, require finite angles, 0<=theta<=pi/2, and Iun>0.');
lb = I/lightNorm;
if any(lb>1)
    error('estimateAlbedoTPAMI:InfeasibleScale', ...
        ['Eq. (42) requires Iun<=norm(s). Check intensity units and light ', ...
         'scale; inputs are not rescaled automatically.']);
end
n = numel(I);

%% Eq. (39): the two albedo candidates, preserving the printed signed ratios.
n1 = [sin(t).*sin(p), sin(t).*cos(p), cos(t)];
n2 = n1; n2(:,1:2) = -n2(:,1:2);
mu1 = n1*s; mu2 = n2*s;
a1 = I./mu1; a2 = I./mu2;
% An exact zero denominator is undefined; use the remaining finite branch.
bad1 = ~isfinite(a1); bad2 = ~isfinite(a2);
assert(~any(bad1 & bad2), 'Both albedo candidates undefined at some pixels.');
a1(bad1)=Inf; a2(bad2)=Inf;

%% Convexity-based initialization selects a candidate, then enforces bounds.
Nx=double(N_init(:,:,1)); Ny=double(N_init(:,:,2)); Nz=double(N_init(:,:,3));
n0=[Nx(Mask),Ny(Mask),Nz(Mask)];
len=sqrt(sum(n0.^2,2));
assert(isreal(n0) && all(isfinite(n0(:))) && all(isfinite(len) & len>0), ...
    'N_init must contain finite nonzero normals inside Mask.');
n0=n0./len;
pick2=sum(n0.*n2,2)>sum(n0.*n1,2);
pick2(bad1)=true; pick2(bad2)=false;
a0=a1; a0(pick2)=a2(pick2);
a0=min(max(a0,lb),1);

%% Eq. (41): smooth the implied SHADING Iun/albedo, not albedo itself.
L=maskedLaplacian(Mask);
initialCost=albedoObjective(a0,I,a1,a2,L,lambda);
assert(isfinite(initialCost), 'Objective overflow; check grazing denominators.');

%% Eq. (42): optimize jointly over all pixels using sparse derivatives.
% fmincon/TRR does not accept equal bounds. Eliminate exactly fixed a=1
% variables while retaining their contribution to the shading regularizer.
free=(lb<1);
aFixed=a0;
if any(free)
    S=spones(L(:,free));
    HessPattern=spones(S.'*S + speye(nnz(free)));
    options=optimoptions('fmincon', ...
        'Algorithm','trust-region-reflective', ...
        'SpecifyObjectiveGradient',true, ...
        'HessPattern',HessPattern,'Display','off');
    [x,finalCost,exitflag,output]=fmincon(@objectiveFree, ...
        a0(free),[],[],[],[],lb(free),ones(nnz(free),1),[],options);
    a=aFixed; a(free)=x;
else
    a=aFixed; finalCost=initialCost; exitflag=1;
    output=struct('message','All albedos are fixed at 1 by the bounds.', ...
        'iterations',0);
end
albedo=NaN(h,w); albedo(Mask)=a;
info=struct('exitflag',exitflag,'output',output, ...
    'initialCost',initialCost,'finalCost',finalCost,'lambda',lambda, ...
    'numPixels',n,'numSmoothnessTerms',size(L,1), ...
    'numUndefinedCandidates',nnz(bad1)+nnz(bad2), ...
    'lightNorm',lightNorm);
if exitflag<=0
    warning('estimateAlbedoTPAMI:NotConverged', ...
        'Optimization did not converge; inspect info.exitflag and info.output.');
end

    function [f,g] = objectiveFree(x)
        aFull=aFixed; aFull(free)=x;
        [f,gFull]=albedoObjective(aFull,I,a1,a2,L,lambda);
        g=gFull(free);
    end
end

function [f,g] = albedoObjective(a,I,a1,a2,L,lambda)
% Eqs. (40)-(42), with the analytic gradient of the active data branch.
r1=a-a1; r2=a-a2;
r=r1;
pick2=abs(r2)<abs(r1);
r(pick2)=r2(pick2);
d=I./a;
Ld=L*d;
f=sum(r.^2) + lambda*sum(Ld.^2);
if nargout>1
    g=2*r - 2*lambda*(I./a.^2).*(L.'*Ld);
end
end

function L = maskedLaplacian(Mask)
% Only use centres whose four neighbours are all inside Mask.
[h,~]=size(Mask);
n=nnz(Mask);
ids=zeros(size(Mask)); ids(Mask)=(1:n).';
centres=Mask & conv2(double(Mask),[0,1,0;1,0,1;0,1,0],'same')==4;
idx=find(centres); m=numel(idx);
if m==0, L=sparse(0,n); return; end
jj=[ids(idx),ids(idx-1),ids(idx+1),ids(idx-h),ids(idx+h)];
ii=repmat((1:m).',1,5);
vv=repmat([-4,1,1,1,1],m,1);
L=sparse(ii(:),jj(:),vv(:),m,n);
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
            Mask =  dataset.(objName)(1).mask & dataset.(objName)(2).mask & dataset.(objName)(3).mask & dataset.(objName)(4).mask ...
                      & dataset.(objName)(5).mask & dataset.(objName)(6).mask & dataset.(objName)(7).mask & dataset.(objName)(8).mask;
            dataset.(objName)(1).mask = Mask; dataset.(objName)(2).mask = Mask; 
            dataset.(objName)(3).mask = Mask; dataset.(objName)(4).mask = Mask; 
            dataset.(objName)(5).mask = Mask; dataset.(objName)(6).mask = Mask; 
            dataset.(objName)(7).mask = Mask; dataset.(objName)(8).mask = Mask; 

        end
    end
    %% name
    dataset.nameList = ["bear1", "bear2", "cat", "cup1", "cup3", "doll", "squirrel"];
    save('./Data/Data_SonyDataset.mat', '-struct', 'dataset');
end