function [N_SmithPers, Mask_eval, info] = ...
    getSurfaceNormal_Smith2019Pers(polarImage, eta, Mask, s0, Psi, Beta)
%GETSURFACENORMAL_SMITH2019PERS Perspective adaptation, DIFFUSE setting.
% Coordinates: x right, y up, z toward camera; V is surface-to-camera.
% Psi=atan2(Vy,Vx), Beta=acos(Vz), in radians, at the input image resolution.
% Uses an undistorted pinhole camera. Its normalized pixel map is recovered
% from Psi/Beta, so the requested six-input interface does not require K.
%
% Required existing functions on the MATLAB path:
%   getSurfaceNormalFromDiffuseReflection_AccurateNew (your +z version)
%   getSurfaceNormal (called by your diffuse recovery function)
% Also requires Image Processing Toolbox. Optimization Toolbox is needed
% only if lambdaAlbedo below is set above zero.
%
% This is NEW integration code, NOT the authors' TPAMI implementation.
% Changes: perspective polarization candidates/intensity, boundary normals,
% and linear LOG-DEPTH reconstruction. Boundary-first FIFO propagation and
% first-order masked differences are explicit implementation choices.
% Diffuse-only, known distant lighting, extra DoLP scale a=1; no GT selection.
% Intensities must use one fixed linear radiometric scale (e.g. im2double).
% s0 supplies a direction; its unknown power is absorbed into the albedo.
% Albedo bounds remain Iun0 <= albedo <= 1 after normalizing s0.
%
% Usage:
% N = getSurfaceNormal_Smith2019Pers(I,eta,Mask,s0,Psi,Beta);
% [N,valid,info] = getSurfaceNormal_Smith2019Pers(I,eta,Mask,s0,Psi,Beta);

%% Settings: experiment choices, NOT verified TPAMI default parameters
lambdaAlbedo = 0;       % Matches your current code; removes shading smoothing
smoothWeight = 0.1;     % Residual weight on Laplacian of log depth, not height
boundaryWeight = 1;     % Residual weight on the convex silhouette prior

%% Validate inputs and recover the surface-to-camera rays
validateattributes(eta, {'numeric'}, {'scalar','real','finite','>',1});
Mask_object = logical(Mask);
[h,w] = size(Mask_object);
assert(h>1 && w>1 && isequal(size(Psi),[h,w],size(Beta)), ...
    'Mask, Psi and Beta must have the same image size.');
assert(isreal(Psi) && isreal(Beta), 'Psi and Beta must be real angles.');
images = double(cat(3,polarImage.I0,polarImage.I45, ...
    polarImage.I90,polarImage.I135));
assert(isequal(size(images),[h,w,4]) && isreal(images), ...
    'The four polarization images must be real, grayscale and image-sized.');
polarImage.I0=images(:,:,1); polarImage.I45=images(:,:,2);
polarImage.I90=images(:,:,3); polarImage.I135=images(:,:,4);
s = double(s0(:));
assert(numel(s)==3 && isreal(s) && all(isfinite(s)) && norm(s)>0, ...
    's0 must be a finite nonzero surface-to-light direction.');
s = s/norm(s);
Mask = Mask_object & all(isfinite(images),3) & ...
    isfinite(Psi) & isfinite(Beta) & Beta>=0 & Beta<pi/2;
assert(nnz(Mask)>=4, 'Too few valid pixels.');
V = cat(3,sin(Beta).*cos(Psi),sin(Beta).*sin(Psi),cos(Beta));

%% Your perspective polarization model: candidates and intrinsic intensity
C = getSurfaceNormalFromDiffuseReflection_AccurateNew( ...
    polarImage,Psi,Beta,V,eta,1,Mask);
n1 = reshape(C.dp1,[],3); n1 = n1(Mask(:),:);
n2 = reshape(C.dp2,[],3); n2 = n2(Mask(:),:);
v = reshape(V,[],3); v = v(Mask(:),:);
ps = Psi(Mask); cb = cos(Beta(Mask));
q = @(angle) cos(angle-ps).^2 + cb.^2.*sin(angle-ps).^2;
I0=q(0).*polarImage.I0(Mask); I45=q(pi/4).*polarImage.I45(Mask);
I90=q(pi/2).*polarImage.I90(Mask); I135=q(3*pi/4).*polarImage.I135(Mask);
a0=(I0+I45+I90+I135)/4;
a1=(I0-I90)/2; a2=(I45-I135)/2;
b1=a1.*cos(2*ps)+a2.*sin(2*ps);
Iun0=((a0+b1)+(a0-b1)./cb.^2)/2;  % trace(H)/2, NOT raw-image mean
len1=vecnorm(n1,2,2); len2=vecnorm(n2,2,2);
n1=n1./len1; n2=n2./len2;
ct=sum(n1.*v,2);
good=all(isfinite(n1),2) & all(isfinite(n2),2) & ...
    isfinite(Iun0) & Iun0>0 & ct>1e-8 & len1>0 & len2>0;
idx=find(Mask); Mask(idx(~good))=false;
n1=n1(good,:); n2=n2(good,:); v=v(good,:);
Iun0=Iun0(good); ct=min(ct(good),1);
assert(nnz(Mask)>=4, 'Too few valid perspective normals.');
assert(all(Iun0<=1), ...
    ['Albedo bounds require intrinsic Iun0<=1 for unit light. ', ...
     'Check the common radiometric scale; do not rescale images separately.']);
assert(max(abs(sum(n2.*v,2)-ct))<1e-6, ...
    'Candidate/view conventions disagree. Use your positive-z recovery functions.');

%% Normalized image coordinates and finite differences
x=-v(:,1)./v(:,3); y=-v(:,2)./v(:,3);
[B,fitError]=pixelMetric(Mask,x,y);  % [wx;wy] = B*[w_column;w_row]
[Du,Dr,L,ids]=maskedOperators(Mask);
Dx=B(1,1)*Du+B(1,2)*Dr;
Dy=B(2,1)*Du+B(2,2)*Dr;
n=nnz(Mask); Q=sqrt(1+x.^2+y.^2);

%% Perspective convexity prior and candidate propagation (no ground truth)
[normalPrior,bw]=silhouettePrior(Mask_object,Mask,B,x,y,v,ct);
[nInit,choose2]=propagateCandidates(n1,n2,Mask,normalPrior,ids);

%% TPAMI-style albedo objective, using the TWO PERSPECTIVE candidates
[albedo,albedoInfo]=perspectiveAlbedo(Iun0,n1,n2,s,choose2,L,lambdaAlbedo);
J=Iun0./albedo;

%% Linear perspective phase and shading/DoLP constraints on w=log(depth)
ep=cross(v,n1,2); epLength=vecnorm(ep,2,2);
ep=ep./max(epLength,1e-12);
ep(epLength<1e-8,:)=0;             % Azimuth undefined at zero zenith
diagS=@(a) spdiags(a,0,n,n);
Aphase=diagS(ep(:,1)+x.*ep(:,3))*Dx + ...
       diagS(ep(:,2)+y.*ep(:,3))*Dy;
bphase=-ep(:,3);
Ashade=diagS(s(1)+x*s(3))*Dx + diagS(s(2)+y*s(3))*Dy;
bshade=J./(ct.*Q)-s(3);
A=[Aphase;Ashade;smoothWeight*L];
rhs=[bphase;bshade;zeros(size(L,1),1)];

% Lift the boundary azimuth prior to the local viewing-transverse plane.
if boundaryWeight>0
    wt=boundaryWeight*bw;
    A=[A;diagS(wt.*ct)*Dx;diagS(wt.*ct)*Dy];
    rhs=[rhs;wt.*normalPrior(:,1)./Q;wt.*normalPrior(:,2)./Q];
end

% One exact log-depth anchor per 4-connected component fixes scale only.
cc=bwconncomp(Mask,4);
anchors=cellfun(@(p) ids(p(1)),cc.PixelIdxList);
free=true(n,1); free(anchors)=false;
logDepth=zeros(n,1);
if any(free), logDepth(free)=A(:,free)\rhs; end

%% Normals from the SAME perspective derivatives used by the solver
wx=Dx*logDepth; wy=Dy*logDepth;
nv=[wx,wy,1+x.*wx+y.*wy];
nv=nv./vecnorm(nv,2,2);
hasGradient=full(sum(abs(Du),2)>0 & sum(abs(Dr),2)>0);
valid=hasGradient & isfinite(logDepth) & all(isfinite(nv),2);
idx=find(Mask); Mask_eval=false(h,w); Mask_eval(idx(valid))=true;
out=NaN(h*w,3); out(idx(valid),:)=nv(valid,:);
N_SmithPers=reshape(out,h,w,3);
if nargout>2
    info=struct('lambdaAlbedo',lambdaAlbedo,'smoothWeight',smoothWeight, ...
        'boundaryWeight',boundaryWeight,'geometryFitError',fitError, ...
        'pixelToNormalizedGradient',B,'numComponents',cc.NumObjects, ...
        'numInputPixels',nnz(Mask_object),'numOutputPixels',nnz(Mask_eval), ...
        'albedoOptimization',albedoInfo, ...
        'relativeResidual',norm(A*logDepth-rhs)/max(norm(rhs),eps));
    info.albedo=NaN(h,w); info.albedo(Mask)=albedo;
    info.Iun0=NaN(h,w); info.Iun0(Mask)=Iun0;
    info.logDepth=NaN(h,w); info.logDepth(Mask)=logDepth;
    out=NaN(h*w,3); out(idx,:)=nInit;
    info.initialNormal=reshape(out,h,w,3);
end
end

function [B,fitError]=pixelMetric(Mask,x,y)
% Psi/Beta encode calibration. Recover its affine normalized image mapping.
[r,u]=find(Mask);
G=[ones(numel(u),1),double(u)-mean(u),double(r)-mean(r)];
assert(rank(G)==3, 'Valid pixels must span two image dimensions.');
T=G\[x,y];
fitError=max(vecnorm(G*T-[x,y],2,2));
assert(fitError<1e-6*max(1,max(vecnorm([x,y],2,2))), ...
    ['Psi/Beta do not describe an undistorted pinhole pixel grid. ', ...
     'Check angle conventions, calibration and image resolution.']);
J=[T(2,:).',T(3,:).'];
assert(rcond(J)>1e-10, ...
    'Viewing geometry is degenerate; use the orthographic solver if Beta=0 everywhere.');
B=J.'\eye(2);
end

function [Du,Dr,L,ids]=maskedOperators(Mask)
% Forward differences, backward at the last valid pixel; never cross holes.
[h,w]=size(Mask); n=nnz(Mask);
ids=zeros(h,w); ids(Mask)=1:n;
right=zeros(h,w); right(:,1:end-1)=ids(:,2:end);
left=zeros(h,w); left(:,2:end)=ids(:,1:end-1);
down=zeros(h,w); down(1:end-1,:)=ids(2:end,:);
up=zeros(h,w); up(2:end,:)=ids(1:end-1,:);
Du=oneDerivative(right(Mask),left(Mask),n);
Dr=oneDerivative(down(Mask),up(Mask),n);
centre=Mask & right>0 & left>0 & down>0 & up>0;
j=find(centre); m=numel(j);
ii=repmat((1:m).',1,5);
jj=[ids(j),right(j),left(j),down(j),up(j)];
vv=repmat([-4,1,1,1,1],m,1);
L=sparse(ii(:),jj(:),vv(:),m,n);
end

function D=oneDerivative(next,prev,n)
f=find(next>0); b=find(next==0 & prev>0);
D=sparse([f;f;b;b],[f;next(f);prev(b);b], ...
    [-ones(numel(f),1);ones(numel(f),1); ...
     -ones(numel(b),1);ones(numel(b),1)],n,n);
end

function [normalPrior,weight]=silhouettePrior(objectMask,Mask,B,x,y,v,ct)
% Outward image covectors lifted to 3D tangent-cone normals perpendicular to V.
p=padarray(objectMask,[1,1],false,'both');
F=imgaussfilt(double(bwdist(~p))-double(bwdist(p)),1);
F=F(2:end-1,2:end-1);
[Fu,Fr]=gradient(F);
gx=-(B(1,1)*Fu+B(1,2)*Fr);
gy=-(B(2,1)*Fu+B(2,2)*Fr);
good=objectMask & hypot(gx,gy)>1e-10;
assert(any(good(:)), 'Cannot construct the silhouette prior.');
[~,near]=bwdist(good);
bad=objectMask & ~good; gx(bad)=gx(near(bad)); gy(bad)=gy(near(bad));
gx=gx(Mask); gy=gy(Mask);
e=[gx,gy,x.*gx+y.*gy]; e=e./vecnorm(e,2,2);
normalPrior=v.*ct + e.*sqrt(max(0,1-ct.^2));
dist=double(bwdist(bwperim(objectMask,8))); dist=dist(Mask);
weight=(1-dist/max(max(dist),eps)).^5;
end

function [N,choose2]=propagateCandidates(n1,n2,Mask,prior,ids)
% Boundary-first FIFO traversal of each component; local angular smoothness.
% Unlike the original Propagation, candidate normals are already in camera
% coordinates. No orthographic normal construction or height integration.
[h,w]=size(Mask); n=nnz(Mask);
boundary=bwperim(Mask,8);
pixels=find(Mask); seed=find(boundary(pixels));
choose2=false(n,1); done=false(n,1); queued=false(n,1);
N=NaN(n,3);
choose2(seed)=sum(n2(seed,:).*prior(seed,:),2)> ...
              sum(n1(seed,:).*prior(seed,:),2);
N(seed,:)=n1(seed,:); ss=seed(choose2(seed)); N(ss,:)=n2(ss,:);
done(seed)=true; queued(seed)=true;
queue=zeros(n,1); tail=numel(seed); queue(1:tail)=seed; head=1;
while head<=tail
    k=queue(head); head=head+1;
    [r,c]=ind2sub([h,w],pixels(k));
    neighbours=ids(max(1,r-1):min(h,r+1),max(1,c-1):min(w,c+1));
    neighbours=neighbours(neighbours>0); neighbours=neighbours(:);
    if ~done(k)
        known=neighbours(done(neighbours));
        if isempty(known)
            choose2(k)=dot(n2(k,:),prior(k,:))>dot(n1(k,:),prior(k,:));
        else
            e1=mean(acos(max(-1,min(1,N(known,:)*n1(k,:).'))));
            e2=mean(acos(max(-1,min(1,N(known,:)*n2(k,:).'))));
            choose2(k)=e2<e1;
        end
        N(k,:)=n1(k,:); if choose2(k), N(k,:)=n2(k,:); end
        done(k)=true;
    end
    fresh=neighbours(~queued(neighbours));
    queue(tail+(1:numel(fresh)))=fresh; tail=tail+numel(fresh);
    queued(fresh)=true;
end
assert(all(done), 'Candidate propagation did not reach every valid pixel.');
end

function [a,info]=perspectiveAlbedo(I,n1,n2,s,choose2,L,lambda)
% Smith Eqs. (39)-(42), with perspective candidates and corrected intensity.
a1=I./(n1*s); a2=I./(n2*s);
bad1=~isfinite(a1); bad2=~isfinite(a2);
assert(~any(bad1 & bad2), 'Both albedo candidates are undefined.');
a1(bad1)=Inf; a2(bad2)=Inf;
lo=I;                         % s was normalized; upper bound is one
choose2(bad1)=true; choose2(bad2)=false;
a=a1; a(choose2)=a2(choose2); a=min(max(a,lo),1);
if lambda==0
    % Exact bounded per-pixel minimum, retaining initialization at ties.
    c1=min(max(a1,lo),1); c2=min(max(a2,lo),1);
    E1=(c1-a1).^2; E2=(c2-a2).^2;
    pick2=(E2<E1) | ((E1==E2) & choose2);
    a=c1; a(pick2)=c2(pick2);
    info=struct('exitflag',1,'message', ...
        'lambda=0: exact bounded data-term minimum; ties use propagation.');
    return;
end
free=lo<1; fixed=a;
if ~any(free)
    info=struct('exitflag',1,'message','All albedos fixed by the bounds.');
    return;
end
S=spones(L(:,free));
options=optimoptions('fmincon','Algorithm','trust-region-reflective', ...
    'SpecifyObjectiveGradient',true,'Display','off', ...
    'HessPattern',spones(S.'*S+speye(nnz(free))));
[z,~,flag,output]=fmincon(@objective,a(free),[],[],[],[], ...
    lo(free),ones(nnz(free),1),[],options);
a(free)=z; info=struct('exitflag',flag,'message',output.message);
if flag<=0, warning('Perspective albedo optimization: %s',output.message); end
    function [f,g]=objective(z)
        fullA=fixed; fullA(free)=z;
        r1=fullA-a1; r2=fullA-a2; r=r1;
        pick=abs(r2)<abs(r1); r(pick)=r2(pick);
        d=I./fullA; Ld=L*d;
        f=sum(r.^2)+lambda*sum(Ld.^2);
        gFull=2*r-2*lambda*(I./fullA.^2).*(L.'*Ld);
        g=gFull(free);
    end
end
