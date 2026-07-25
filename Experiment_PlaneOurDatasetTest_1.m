%% Real Data (Our Dataset) Plane Comparision
clc; clear; close all;
%% Initialization
folderPath = 'Data/Our';
load(fullfile(folderPath, 'data.mat'));
K = data.cameraParams.Intrinsics.IntrinsicMatrix;
polarImageRGB = imageDataToPolarImageRGB(folderPath, data);
polarImageGray = polarImageRGBToPolarImageGray(polarImageRGB);
imageMask = getPolarImagemask(polarImageGray); 
%% 
Mask = ones(size(polarImageGray(1).I0)) == 1;
V = getViewingDirection(K, Mask); 
Beta = getPerspectiveDistortionAngle(V, Mask);
eta = 1.5;
a = 1;
row = 1024; col = 1224;
V_orth = zeros(row, col, 3); V_orth(:,:,3) = -1;
Beta_orth = zeros(row, col);
%% Calculate normal vector
fig = figure;
for num = 1 : length(polarImageGray)
    plotPolarImage(polarImageGray, imageMask, num, fig);
    Mask = imageMask(num).mask;
    polarImage = polarImageGray(num);
    %% Methods
    % Perspective 
    N = getSurfaceNormalFromSpecularReflection(polarImage, Beta, V, eta, a, Mask);
    % Orthographic 
    N_orth = getSurfaceNormalFromSpecularReflection(polarImage, Beta_orth, V_orth, eta, a, Mask);
    % IJCV 
    N_IJCV = getSurfaceNormalFromSpecularReflection_IJCV(polarImage, V, eta, a, Mask);
    

end













%% Calculate polar image mask
function imageMask = getPolarImagemask(polarImageGray)
    num_imgs = length(polarImageGray);
    imageMask = repmat(struct('mask', []), num_imgs, 1);
    for i = 1 : num_imgs
        img_mean = (polarImageGray(i).I0 + polarImageGray(i).I45 + ...
                    polarImageGray(i).I90 + polarImageGray(i).I135) / 4.0;
        img_normalized = img_mean / 255.0;
        imageMask(i).mask = ~imbinarize(img_normalized, 0.04);        
    end
end
%% Plot polar image
function plotPolarImage(polarImageGray, imageMask, num, fig)
    figure(fig);
    subplot(2,3,1); imshow(polarImageGray(num).I0, []); title('I_{0} (Gray)');
    subplot(2,3,2); imshow(polarImageGray(num).I45, []); title('I_{45} (Gray)');
    subplot(2,3,4); imshow(polarImageGray(num).I90, []); title('I_{90} (Gray)');
    subplot(2,3,5); imshow(polarImageGray(num).I135, []); title('I_{135} (Gray)');
    subplot(2,3,3); imshow(imageMask(num).mask); title('Mask');
end