function results = IJCV_PerPixel_Comparison(userConfig)
%IJCV_PERPIXEL_COMPARISON Serial, single-pixel Ours versus GMPC benchmark.
% Run from the project folder containing Data/IJCV:
%   results = IJCV_PerPixel_Comparison;
% Optional configuration:
%   cfg.MaxTimingPixelsPerImage = Inf; % time all eligible pixels
%   cfg.FullErrorMaps = true;          % evaluate all eligible pixels
%   results = IJCV_PerPixel_Comparison(cfg);
% Self-test without the dataset:
%   IJCV_PerPixel_Comparison(struct('SelfTestOnly',true));
%
% Each solver call receives exactly FOUR intensities and ONE viewing ray.
% All timers enclose serial pixel loops, with equal output preallocation
% outside timing. I/O, ray normalization, error evaluation and plotting are
% excluded. Loop/indexing/function-call/output-storage costs ARE included.
% Scope 1 includes per-pixel geometry (including GMPC pinv(M)). Scope 2
% caches the complete intensity-to-coefficient maps for BOTH methods.
% The GMPC pseudoinverse is deliberately retained from the supplied code;
% any speed ratio describes this implementation, not a universal lower bound.
% Fixed analyzer axes are written explicitly. Both methods reuse the same
% stable Fresnel inversion and +/- candidate construction; repeated normal
% construction for the azimuth pi-ambiguity is shared for BOTH methods.
%
% Coordinates match the supplied program: v = -our_rays, then flip v_x.
% GMPC uses r_z=-v and local normal z=-cos(theta). Both methods' output x
% components are flipped during untimed ground-truth evaluation.
% Candidate selection uses the ground-truth minimum over FOUR candidates.
%
% Defaults: 10000 timing pixels/image, 5 repeats, FULL error maps. Setting
% FullErrorMaps=false evaluates only the timed sample. Full maps on the
% entire IJCV dataset can take substantial time with serial scalar solvers.
% MATLAB R2019a+ (readmatrix). All helpers are in this file; no project
% getPsiAngle/getErrorNormalAngle/etc. functions are needed.

if nargin<1, userConfig=struct(); end
cfg=defaultConfig();
fields=fieldnames(userConfig);
for j=1:numel(fields)
    assert(isfield(cfg,fields{j}),'Unknown configuration: %s',fields{j});
    cfg.(fields{j})=userConfig.(fields{j});
end
validateConfig(cfg);
C=struct('eta2',cfg.eta^2,'a',cfg.a);
C.B=C.eta2-1; C.K=4*C.eta2;
if cfg.RunSelfTest || cfg.SelfTestOnly, runSelfTest(C); end
if cfg.SelfTestOnly
    results=struct('SelfTestPassed',true); return;
end
files=dir(fullfile(cfg.DataRoot,'*.png'));
assert(~isempty(files),'No PNG images in %s',cfg.DataRoot);
[~,order]=sort({files.name}); files=files(order);
numImages=numel(files);
rayData=load(fullfile(cfg.DataRoot,'our_rays.mat'),'data');
assert(isfield(rayData,'data') && size(rayData.data,3)==3,'Invalid our_rays.mat');
[rows,cols,~]=size(rayData.data);
Vall=-double(rayData.data); Vall(:,:,1)=-Vall(:,:,1);
Vall=reshape(Vall,[],3).';
lengths=sqrt(sum(Vall.^2,1));
Vall=bsxfun(@rdivide,Vall,lengths);
geometryOK=all(isfinite(Vall),1) & abs(Vall(3,:))>1e-10;
clear rayData lengths;
methods={'Ours','GMPC'};
scopes={'Geometry included','Geometry cached'};
seconds=nan(numImages,cfg.NumRepeats,2,2); % image, repeat, method, scope
cacheSeconds=nan(numImages,2);
num_pixels=zeros(numImages,1); eligibleCount=num_pixels; evalCount=num_pixels;
invalidCount=zeros(numImages,2);
sampleIndices=cell(numImages,1);
imageStats=nan(numImages,2,5); % MAE, SD, MED, RMSE, MAX in degrees
sumMask=zeros(rows,cols); errorSum=zeros(rows,cols,2);
pooledN=0; pooledMean=zeros(1,2); pooledM2=zeros(1,2); pooledMax=zeros(1,2);
state=rng; cleanup=onCleanup(@() rng(state)); %#ok<NASGU>
rng(cfg.Seed,'twister');
fprintf('\nIJCV/GMPC dataset: a=%.3f, eta=%.3f, repeats=%d\n',cfg.a,cfg.eta,cfg.NumRepeats);
fprintf('Every solver call processes ONE pixel and returns FOUR candidates.\n');
if cfg.FullErrorMaps
    fprintf('Accuracy/maps: all eligible pixels. Timing: selected pixels.\n');
else
    fprintf('Accuracy/maps: timing sample only.\n');
end
for i=1:numImages
    name=files(i).name;
    fprintf('\n[%d/%d] %s\n',i,numImages,name);
    [Iimage,sz]=readPolarimetricImage(fullfile(cfg.DataRoot,name));
    assert(isequal(sz,[rows,cols]),'Image/ray size mismatch.');
    md=load(sidecar(cfg.DataRoot,name,'_mask.mat'),'data');
    assert(isfield(md,'data') && isequal(size(md.data),[rows,cols]),'Invalid mask.');
    Mask=md.data==1;
    idx=find(Mask(:) & geometryOK.' & all(isfinite(Iimage),1).' & sum(Iimage,1).'>0);
    assert(~isempty(idx),'No eligible pixels in %s',name);
    eligibleCount(i)=numel(idx);
    pose=readmatrix(sidecar(cfg.DataRoot,name,'_pose.txt'));
    nGT=pose(1:3,1:3)*[0;0;1];
    assert(all(isfinite(nGT)) && norm(nGT)>0,'Invalid ground truth.');
    nGT=nGT/norm(nGT);
    P=min(cfg.MaxTimingPixelsPerImage,numel(idx));
    sel=randperm(numel(idx),P); selIdx=idx(sel);
    sampleIndices{i}=selIdx; num_pixels(i)=P;
    It=Iimage(:,selIdx); Vt=Vall(:,selIdx);
    nw=min(P,cfg.WarmupPixels);
    warmCache=buildCache(Vt(:,1:nw));
    for scope=1:2
        for method=1:2
            runScalarPass(method,scope,It(:,1:nw),Vt(:,1:nw),warmCache,C);
        end
    end
    [cache,cacheSeconds(i,:)]=buildCache(Vt);
    latest=cell(1,2);
    for rep=1:cfg.NumRepeats
        % Randomized, reproducible order balances fixed-order effects.
        for task=randperm(4)
            [method,scope]=ind2sub([2,2],task);
            [N,dt]=runScalarPass(method,scope,It,Vt,cache,C);
            seconds(i,rep,method,scope)=dt;
            latest{method}=N;
        end
    end
    for scope=1:2
        us=reshape(median(seconds(i,:,:,scope),2),1,2)*1e6/P;
        fprintf('  %-18s: Ours %.3f, GMPC %.3f us/pixel; GMPC/Ours %.3fx\n', ...
            scopes{scope},us(1),us(2),us(2)/us(1));
    end
    clear cache warmCache N;
    % Separate untimed accuracy pass. Chunking bounds normal/cache memory.
    if cfg.FullErrorMaps
        evalIdx=idx; E=nan(numel(idx),2);
        for first=1:cfg.EvaluationChunkSize:numel(idx)
            jj=first:min(first+cfg.EvaluationChunkSize-1,numel(idx));
            pix=idx(jj); Vi=Vall(:,pix); Ii=Iimage(:,pix);
            localCache=buildCache(Vi);
            for method=1:2
                N=runScalarPass(method,2,Ii,Vi,localCache,C);
                E(jj,method)=normalErrorsDegrees(N,nGT);
            end
        end
        clear localCache N;
    else
        evalIdx=selIdx; E=nan(P,2);
        for method=1:2
            E(:,method)=normalErrorsDegrees(latest{method},nGT);
        end
    end
    invalidCount(i,:)=sum(~isfinite(E),1);
    good=all(isfinite(E),2); Eg=E(good,:); mapIdx=evalIdx(good);
    evalCount(i)=size(Eg,1);
    assert(evalCount(i)>0,'No jointly valid output normals.');
    if any(invalidCount(i,:)>0)
        warning('Invalid output pixels: Ours=%d, GMPC=%d; accuracy uses joint valid set.', ...
            invalidCount(i,1),invalidCount(i,2));
    end
    sumMask(mapIdx)=sumMask(mapIdx)+1;
    for method=1:2
        layer=errorSum(:,:,method);
        layer(mapIdx)=layer(mapIdx)+Eg(:,method);
        errorSum(:,:,method)=layer;
        x=Eg(:,method);
        imageStats(i,method,:)=reshape( ...
            [mean(x),std(x),median(x),sqrt(mean(x.^2)),max(x)],1,1,5);
    end
    % Merge central moments: exact pooled MAE/SD/RMSE without retaining
    % hundreds of millions of individual errors in RAM.
    nBatch=size(Eg,1); bMean=mean(Eg,1);
    bM2=sum(bsxfun(@minus,Eg,bMean).^2,1);
    delta=bMean-pooledMean; total=pooledN+nBatch;
    pooledM2=pooledM2+bM2+delta.^2*(pooledN*nBatch/total);
    pooledMean=pooledMean+delta*(nBatch/total);
    pooledN=total; pooledMax=max(pooledMax,max(Eg,[],1));
    fprintf('  timed %d/%d pixels; evaluated %d joint valid pixels\n',P,numel(idx),nBatch);
end
medianSeconds=reshape(median(seconds,2),numImages,2,2);
usPerImage=bsxfun(@rdivide,medianSeconds,num_pixels)*1e6;
weightedUs=reshape(sum(medianSeconds,1),2,2)*1e6/sum(num_pixels);
Scope=cell(4,1); Method=cell(4,1); Weighted_us_per_pixel=zeros(4,1);
Median_image_us_per_pixel=zeros(4,1); SD_image_us_per_pixel=zeros(4,1);
GMPC_over_method=zeros(4,1);
for scope=1:2
    for method=1:2
        k=(scope-1)*2+method;
        Scope{k}=scopes{scope}; Method{k}=methods{method};
        Weighted_us_per_pixel(k)=weightedUs(method,scope);
        Median_image_us_per_pixel(k)=median(usPerImage(:,method,scope));
        SD_image_us_per_pixel(k)=std(usPerImage(:,method,scope));
        GMPC_over_method(k)=weightedUs(2,scope)/weightedUs(method,scope);
    end
end
Timing=table(Scope,Method,Weighted_us_per_pixel,Median_image_us_per_pixel, ...
    SD_image_us_per_pixel,GMPC_over_method);
Accuracy=table(methods.',pooledMean.',sqrt(pooledM2/max(pooledN-1,1)).', ...
    sqrt(pooledM2/pooledN+pooledMean.^2).',pooledMax.', ...
    'VariableNames',{'Method','MAE_deg','SD_deg','RMSE_deg','MAX_deg'});
id=sumMask>0; mapsDeg=nan(rows,cols,2);
for method=1:2
    x=errorSum(:,:,method); m=nan(rows,cols); m(id)=x(id)./sumMask(id);
    mapsDeg(:,:,method)=m;
end
% MED is reported per image and for the averaged map, NOT approximated by
% averaging image medians and calling it the pooled median.
mapStats=zeros(2,5);
for method=1:2
    x=mapsDeg(:,:,method); x=x(id);
    mapStats(method,:)=[mean(x),std(x),median(x),sqrt(mean(x.^2)),max(x)];
end
MapAccuracy=array2table(mapStats,'VariableNames',{'MAE_deg','SD_deg','MED_deg','RMSE_deg','MAX_deg'}, ...
    'RowNames',methods);
fprintf('\nTiming (median across repeats for each image, then pixel weighted):\n'); disp(Timing);
fprintf('Pooled accuracy over measurement-pixel pairs:\n'); disp(Accuracy);
fprintf('Statistics of the spatially averaged error maps:\n'); disp(MapAccuracy);
results.config=cfg; results.imageNames={files.name}; results.methods=methods;
results.scopes=scopes; results.seconds=seconds; results.num_pixels=num_pixels;
results.medianMicrosecondsPerPixel=usPerImage;
results.cacheBuildSeconds=cacheSeconds; results.sampleIndices=sampleIndices;
results.eligibleCount=eligibleCount; results.evaluationCount=evalCount;
results.invalidCount=invalidCount; results.imageStats=imageStats;
results.imageStatsColumns={'MAE','SD','MED','RMSE','MAX'};
results.timingTable=Timing; results.accuracyTable=Accuracy; results.mapAccuracyTable=MapAccuracy;
results.errorMapsDegrees=mapsDeg; results.id=id; results.sumMask=sumMask;
results.errorMapsAreFull=cfg.FullErrorMaps || all(num_pixels==eligibleCount);
results.environment.MATLAB=version; results.environment.computer=computer;
results.environment.date=datestr(now,30);
results.environment.note='Serial double-precision MATLAB. Record CPU and power settings separately.';
if ~exist(cfg.OutputDir,'dir'), mkdir(cfg.OutputDir); end
[~,tag]=fileparts(tempname(cfg.OutputDir));
prefix=fullfile(cfg.OutputDir,['IJCV_PerPixel_' datestr(now,'yyyymmdd_HHMMSS') '_' tag]);
results.outputPrefix=prefix;
% Compatibility names: image x repeat x scope, in SECONDS for the pixel loop.
% scope 1 = geometry included; scope 2 = geometry cached. These are no longer
% per-location timing maps. Divide by num_pixels to obtain seconds/pixel.
time_ours=reshape(seconds(:,:,1,:),numImages,cfg.NumRepeats,2); %#ok<NASGU>
time_IJCV=reshape(seconds(:,:,2,:),numImages,cfg.NumRepeats,2); %#ok<NASGU>
err_plot_ours_mean=mapsDeg(:,:,1)*pi/180; %#ok<NASGU>
err_plot_IJCV_mean=mapsDeg(:,:,2)*pi/180; %#ok<NASGU>
save([prefix '.mat'],'results','time_ours','time_IJCV','num_pixels', ...
    'id','sumMask','err_plot_ours_mean','err_plot_IJCV_mean','-v7.3');
writetable(Timing,[prefix '_timing.csv']);
writetable(Accuracy,[prefix '_accuracy.csv']);
writetable(MapAccuracy,[prefix '_map_accuracy.csv'],'WriteRowNames',true);
if cfg.MakeFigures, makeFigures(results,prefix); end
fprintf('Saved: %s.mat\n',prefix);
end

function cfg=defaultConfig()
cfg.DataRoot=fullfile('Data','IJCV');
cfg.OutputDir=fullfile('Data','IJCV_PerPixelBenchmark');
cfg.a=0.70; cfg.eta=1.55;
cfg.MaxTimingPixelsPerImage=10000; % Inf to time all eligible pixels
cfg.NumRepeats=5; cfg.WarmupPixels=200; cfg.Seed=42;
cfg.FullErrorMaps=true; cfg.EvaluationChunkSize=10000;
cfg.RunSelfTest=true; cfg.SelfTestOnly=false; cfg.MakeFigures=true;
cfg.FontSize=23; cfg.LineWidth=2; cfg.Scale=1.2; cfg.Resolution=300;
end

function path=sidecar(root,name,suffix)
% Prefer the supplied convention image.png_mask.mat; also accept image_mask.mat.
path=fullfile(root,[name suffix]);
if exist(path,'file')~=2
    [~,stem]=fileparts(name); path=fullfile(root,[stem suffix]);
end
assert(exist(path,'file')==2,'Missing sidecar: %s',path);
end

function [N,elapsed]=runScalarPass(method,scope,I,V,cache,C)
P=size(I,2); N=zeros(3,4,P); % allocation excluded equally
if method==1 && scope==1
    t=tic;
    for p=1:P
        N(:,:,p)=oursPixel(I(:,p),V(:,p),C);
    end
elseif method==1 && scope==2
    t=tic;
    for p=1:P
        N(:,:,p)=oursFromH(cache.Wours(:,:,p)*I(:,p),V(:,p),cache.c(p),cache.psi(p),C);
    end
elseif method==2 && scope==1
    t=tic;
    for p=1:P
        N(:,:,p)=gmpcPixel(I(:,p),V(:,p),C);
    end
else
    t=tic;
    for p=1:P
        N(:,:,p)=gmpcFromS(cache.Wgmpc(:,:,p)*I(:,p),cache.R(:,:,p),C);
    end
end
elapsed=toc(t);
end

function [W,c,psi]=oursGeometry(v)
c=abs(v(3)); % cos(acos(abs(v_z))) simplified for a unit ray
psi=atan2(-v(2),-v(1));
d=[0;pi/4;pi/2;3*pi/4]-psi;
q=cos(d).^2+c*c*sin(d).^2;
cp=cos(2*psi); sp=sin(2*psi); c2=c*c;
F=[1,1,1,1;2,0,-2,0;0,2,0,-2]/4;
T=[1,cp,sp;0,-sp/c,cp/c;1/c2,-cp/c2,-sp/c2];
W=bsxfun(@times,T*F,q.');
end

function N=oursPixel(I,v,C)
[W,c,psi]=oursGeometry(v);
N=oursFromH(W*I,v,c,psi,C);
end

function N=gmpcPixel(I,v,C)
[R,M]=gmpcGeometry(v);
W=pinv(M); % retained from the user's code; counted in geometry-included mode
N=gmpcFromS(W*I,R,C);
end

function N=gmpcFromS(S,R,C)
phi=mod(0.5*atan2(S(3),S(2))+pi/2,pi);
rho=hypot(S(2),S(3))/S(1)/C.a;
[theta1,theta2]=specularZenith(rho,C);
ep=R(:,1)*cos(phi)+R(:,2)*sin(phi);
% R(:,3)=-v and local z=-cos(theta), matching the uploaded implementation.
N=fourCandidates(-R(:,3),ep,theta1,theta2);
end

function [R,M]=gmpcGeometry(v)
rz=-v;
rx=[rz(3);0;-rz(1)]; rx=rx/sqrt(sum(rx.^2));
ry=cross3(rz,rx); R=[rx,ry,rz];
k=sqrt(0.5);
a=[0,-k,-1,-k;1,k,0,-k;0,0,0,0];
P=R.'*a;
% Positive normalization of [-P_y;P_x;0] cancels inside atan2.
alpha=atan2(P(1,:),-P(2,:)).';
M=0.5*[ones(4,1),cos(2*alpha),sin(2*alpha)];
end

function [cache,elapsed]=buildCache(V)
P=size(V,2);
cache.Wours=zeros(3,4,P); cache.c=zeros(1,P); cache.psi=zeros(1,P);
cache.Wgmpc=zeros(3,4,P); cache.R=zeros(3,3,P);
t=tic;
for p=1:P
    [cache.Wours(:,:,p),cache.c(p),cache.psi(p)]=oursGeometry(V(:,p));
end
elapsed(1)=toc(t);
t=tic;
for p=1:P
    [R,M]=gmpcGeometry(V(:,p));
    cache.R(:,:,p)=R; cache.Wgmpc(:,:,p)=pinv(M);
end
elapsed(2)=toc(t);
end

function validateConfig(cfg)
validateattributes(cfg.a, {'numeric'}, {'scalar','real','finite','positive'});
validateattributes(cfg.eta, {'numeric'}, {'scalar','real','finite','>',1});
validateattributes(cfg.NumRepeats, {'numeric'}, {'scalar','integer','>=',3});
validateattributes(cfg.WarmupPixels, {'numeric'}, {'scalar','integer','positive'});
validateattributes(cfg.EvaluationChunkSize, {'numeric'}, {'scalar','integer','positive'});
assert(isscalar(cfg.MaxTimingPixelsPerImage) && cfg.MaxTimingPixelsPerImage > 0 && ...
    (isinf(cfg.MaxTimingPixelsPerImage) || ...
     cfg.MaxTimingPixelsPerImage == floor(cfg.MaxTimingPixelsPerImage)), ...
    'MaxTimingPixelsPerImage must be a positive integer or Inf.');
end


function N = oursFromH(H, v, c, psi, C)
gamma = 0.5*atan2(2*H(2), H(1)-H(3)) + pi/2;
delta = atan2(c*sin(gamma), cos(gamma));
phi = mod(psi+delta, pi);
rho = hypot(H(1)-H(3), 2*H(2))/(H(1)+H(3))/C.a;
[theta1, theta2] = specularZenith(rho, C);
D = [cos(phi); sin(phi); 0];
es = cross3(v, D);
es = es/max(sqrt(sum(es.^2)), 1e-12);
ep = cross3(es, v);
N = fourCandidates(v, ep, theta1, theta2);
end


function N = fourCandidates(v, ep, theta1, theta2)
b1 = v*cos(theta1); w1 = ep*sin(theta1);
b2 = v*cos(theta2); w2 = ep*sin(theta2);
N = [b1+w1, b1-w1, b2+w2, b2-w2];
end


function [theta1, theta2] = specularZenith(rho, C)
% Common inversion for all methods, with identical endpoint handling.
if ~isfinite(rho)
    theta1 = NaN; theta2 = NaN;
    return;
end
rho = min(max(rho,0),1);
s = sqrt((1-rho)/(1+rho));
u = (1-s)/(1+s);
t = u*u;
% Rationalized forms of the supplied Xi=u and Xi=1/u solutions.
% They avoid Xi=Inf at rho=0 and 0/0 at the Brewster point rho=1.
cos2a = 2/(2 + C.B*t + u*sqrt(C.B*C.B*t + C.K));
cos2b = 2*t/(2*t + C.B + sqrt(C.B*C.B + C.K*t));
theta1 = acos(sqrt(min(max(cos2a,0),1)));
theta2 = acos(sqrt(min(max(cos2b,0),1)));
end


function z = cross3(x,y)
z = [x(2)*y(3)-x(3)*y(2); x(3)*y(1)-x(1)*y(3); x(1)*y(2)-x(2)*y(1)];
end


function E = normalErrorsDegrees(N, nGT)
% Oracle ambiguity resolution: best of four candidates using ground truth.
% This evaluates recovery candidates, not an ambiguity-resolution algorithm.
N(1,:,:) = -N(1,:,:); % supplied PPA camera-coordinate convention
L = sqrt(sum(N.^2,1));
N = bsxfun(@rdivide,N,L);
d = sum(bsxfun(@times,N,reshape(nGT,3,1,1)),1);
d = min(max(d,-1),1);
angles = reshape(acos(d)*180/pi,4,[]);
bad = any(~isfinite(reshape(N,12,[])),1);
E = min(angles,[],1).';
E(bad) = NaN;
end


function [I, imageSize] = readPolarimetricImage(path)
assert(exist(path,'file')==2, 'Image not found: %s', path);
raw = imread(path);
if ndims(raw)==3
    % Standard RGB luminance; cast back to preserve integer rounding.
    cls = class(raw);
    raw = cast(0.298936021293776*double(raw(:,:,1)) + ...
        0.587043074451121*double(raw(:,:,2)) + ...
        0.114020904255103*double(raw(:,:,3)), cls);
end
assert(mod(size(raw,1),2)==0 && mod(size(raw,2),2)==0, ...
    'Polarization mosaic dimensions must be even.');
raw = double(raw);
I90 = raw(1:2:end,1:2:end); I45 = raw(1:2:end,2:2:end);
I135 = raw(2:2:end,1:2:end); I0 = raw(2:2:end,2:2:end);
imageSize = size(I0);
I = [I0(:).'; I45(:).'; I90(:).'; I135(:).'];
end


function styleAxes(ax,cfg)
set(ax,'FontName','Times New Roman','FontSize',cfg.FontSize*cfg.Scale, ...
    'LineWidth',cfg.LineWidth,'LabelFontSizeMultiplier',1, ...
    'TitleFontSizeMultiplier',1,'Box','on');
end


function runSelfTest(C)
% Meaningful equivalence checks for the scalar refactoring. These run OUTSIDE
% all benchmark timers and need no images or project helper functions.
rngState = rng;
cleanup = onCleanup(@() rng(rngState)); %#ok<NASGU>
rng(19,'twister');
P = 32;
V = [0.7*(2*rand(2,P)-1); -ones(1,P)];
V = bsxfun(@rdivide,V,sqrt(sum(V.^2,1)));
I = 1+rand(4,P);
cache = buildCache(V);
for p = 1:P
    A = oursPixel(I(:,p),V(:,p),C);
    B = oursFromH(cache.Wours(:,:,p)*I(:,p),V(:,p),cache.c(p),cache.psi(p),C);
    assert(max(abs(A(:)-B(:)))<1e-9,'Ours cache equivalence failed.');
    A = gmpcPixel(I(:,p),V(:,p),C);
    B = gmpcFromS(cache.Wgmpc(:,:,p)*I(:,p),cache.R(:,:,p),C);
    assert(max(abs(A(:)-B(:)))<1e-9,'GMPC cache equivalence failed.');
    [R,G] = gmpcGeometry(V(:,p));
    Sref = G\I(:,p); % QR least squares, independent of cofactor inversion
    S = cache.Wgmpc(:,:,p)*I(:,p);
    assert(max(abs(S-Sref))<1e-10,'GMPC Stokes recovery failed.');
    assert(norm(R.'*R-eye(3),'fro')<1e-12,'GMPC local frame is not orthonormal.');

    vv=V(:,p); ps=cache.psi(p); cc=cache.c(p);
    q=cos([0;pi/4;pi/2;3*pi/4]-ps).^2+cc^2*sin([0;pi/4;pi/2;3*pi/4]-ps).^2;
    J=I(:,p).*q; a0=sum(J)/4; a1=(J(1)-J(3))/2; a2=(J(2)-J(4))/2;
    b1=a1*cos(2*ps)+a2*sin(2*ps); b2=-a1*sin(2*ps)+a2*cos(2*ps);
    Href=[a0+b1;b2/cc;(a0-b1)/cc^2];
    assert(max(abs(Href-cache.Wours(:,:,p)*I(:,p)))<1e-11,'Ours direct-map equivalence failed.');
    phiG=mod(0.5*atan2(Sref(3),Sref(2))+pi/2,pi);
    [tg1,tg2]=specularZenith(hypot(Sref(2),Sref(3))/Sref(1)/C.a,C);
    nr=gmpcFromS(Sref,R,C);
    ang=[tg1,tg1,tg2,tg2]; ph=[phiG,phiG-pi,phiG,phiG-pi];
    for k=1:4
        local=[sin(ang(k))*cos(ph(k));sin(ang(k))*sin(ph(k));-cos(ang(k))];
        assert(max(abs(nr(:,k)-R*local))<1e-11,'GMPC coordinate convention failed.');
    end

    % Compare shared +/- candidate construction with the supplied cross form.
    phi = 0.83; t1=0.31; t2=1.12;
    D = [cos(phi);sin(phi);0];
    es = cross(V(:,p),D); es=es/norm(es);
    ep = cross(es,V(:,p));
    B = fourCandidates(V(:,p),ep,t1,t2);
    theta = [t1,t1,t2,t2]; phis = [phi,phi-pi,phi,phi-pi];
    for k=1:4
        D = [cos(phis(k));sin(phis(k));0];
        es = cross(V(:,p),D); es=es/norm(es);
        n = V(:,p)*cos(theta(k))+cross(es,V(:,p))*sin(theta(k));
        assert(max(abs(n-B(:,k)))<1e-12,'Normal candidate construction failed.');
    end
end
% Check rationalized inversion against the original formula away from its
% removable singularities, and forward Fresnel equations including endpoints.
for eta = [1.2,1.55,2.0]
    T = C; T.eta2=eta^2; T.B=eta^2-1; T.K=4*eta^2;
    for rho = [0,1e-5,0.1,0.4,0.8,0.99,1]
        [t1,t2] = specularZenith(rho,T);
        for theta = [t1,t2]
            ct=cos(theta); st=sin(theta); g=sqrt(eta^2-st^2);
            Rs=((ct-g)/(ct+g))^2;
            Rp=((eta^2*ct-g)/(eta^2*ct+g))^2;
            rhoCheck=(Rs-Rp)/(Rs+Rp);
            assert(abs(rhoCheck-rho)<1e-8,'Forward Fresnel check failed.');
        end
        if rho>0.01 && rho<0.999
            s=sqrt((1-rho)/(1+rho));
            x=[(1-s)/(1+s),(1+s)/(1-s)];
            z=(2+T.B*x.^2-x.*sqrt(T.B^2*x.^2+T.K))./(2*(1-x.^2));
            oldTheta=acos(sqrt(min(max(z,0),1)));
            assert(max(abs(oldTheta-[t1,t2]))<1e-9,'Zenith formula equivalence failed.');
        end
    end
end
fprintf('Scalar self-tests passed (cache, Stokes, normals, Fresnel roots).\n');
end

function makeFigures(results,prefix)
cfg=results.config;
colors=[237,33,35;72,192,170]/255;
for scope=1:2
    medianTimes=reshape(median(results.seconds(:,:,:,scope),2),[],2);
    values=sum(medianTimes,1)*1e6/sum(results.num_pixels);
    f=figure('Color','w','Position',[100,100,780,560]); ax=axes('Parent',f);
    b=bar(ax,1:2,values,'FaceColor','flat'); b.CData=colors;
    set(ax,'XTick',1:2,'XTickLabel',results.methods);
    ylabel(ax,'Time (\mus/pixel)'); title(ax,results.scopes{scope}); styleAxes(ax,cfg);
    print(f,[prefix sprintf('_timing_scope%d.png',scope)],'-dpng',sprintf('-r%d',cfg.Resolution));
end
values=results.errorMapsDegrees(isfinite(results.errorMapsDegrees));
hi=max([values(:);eps]);
if results.errorMapsAreFull, label='Average angular error';
else, label='Sampled average angular error'; end
for method=1:2
    f=figure('Color','w','Position',[100,100,760,640]); ax=axes('Parent',f);
    h=imagesc(ax,results.errorMapsDegrees(:,:,method)); set(h,'AlphaData',results.id);
    set(ax,'Color','w','XTick',[],'YTick',[]); axis(ax,'image');
    colormap(ax,parula(256)); caxis(ax,[0,hi]);
    cb=colorbar(ax,'southoutside'); cb.Label.String='\Delta\gamma (degrees)';
    title(ax,{results.methods{method},label}); styleAxes(ax,cfg);
    print(f,[prefix sprintf('_error_method%d.png',method)],'-dpng',sprintf('-r%d',cfg.Resolution));
end
end
