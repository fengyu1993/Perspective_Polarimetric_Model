clc;
clear;
close all;
%% Load data Get polarImageGray 
folderPath = 'Data/CYH';
data = load(fullfile(folderPath, 'data.mat'));
K = data.cameraParams.Intrinsics.IntrinsicMatrix;
polarImageRGB = imageDataToPolarImageRGB(folderPath, data);
polarImageGray = polarImageRGBToPolarImageGray(polarImageRGB);
imageMask = getPolarImagemask(polarImageGray); 
eta = 1.5;
%% Calculate normal vector
fig = figure;
for num = 3 : length(polarImageGray)
    plotPolarImage(polarImageGray, imageMask, num, fig);
    Mask = imageMask(num).mask;
    polarImage = polarImageGray(num);
    V = getViewingDirection(K, Mask); 
    Beta = getPerspectiveDistortionAngle(V, Mask);
    Phi_sp = getAzimuthAngleSpecularReflection(polarImage, Mask);
    Rho_sp = getDoLP(polarImage, Mask);
    Theta_sp = getZenithAngleSpecularReflection(Rho_sp, Mask, Beta, eta);

end




%%
% data = load(fullfile(folderPath, 'data.mat'));
% cameraParams = data.cameraParams;
% nameList = data.nameList;
% nameImagePolar = {'I0', 'I45', 'I90', 'I135'};
% save(fullfile(folderPath, 'data.mat'), 'cameraParams', 'nameList', 'nameImagePolar');


%% Transfer imageData to PolarImage I0 I45 I90 I135
function polarImageRGB = imageDataToPolarImageRGB(folderPath, data)
    num_scenes = length(data.nameList);
    num_polars = length(data.nameImagePolar);
    polarImageRGB = repmat(struct('I0', [], 'I45', [], 'I90', [], 'I135', []), num_scenes, 1);

    for i = 1 : num_scenes
        for j = 1 : num_polars
            polar_name = data.nameImagePolar{j}; 
            name = strcat(data.nameList{i}, polar_name, '.png');
            temp_img = imread(fullfile(folderPath, name));
            temp_img_undistort = undistortImage(temp_img, data.cameraParams.Intrinsics, 'OutputView', 'same');
            polarImageRGB(i).(polar_name) = temp_img_undistort;
        end
    end 

end

%% Transfer PolarImageRGB to PolarImageGray I0 I45 I90 I135
function polarImageGray = polarImageRGBToPolarImageGray(PolarImageRGB)
    num_imgs = length(PolarImageRGB);
    polarImageGray = repmat(struct('I0', [], 'I45', [], 'I90', [], 'I135', []), num_imgs, 1);
    for i = 1 : num_imgs
        polarImageGray(i).I0 = double(rgb2gray(PolarImageRGB(i).I0));
        polarImageGray(i).I45 = double(rgb2gray(PolarImageRGB(i).I45));
        polarImageGray(i).I90 = double(rgb2gray(PolarImageRGB(i).I90));
        polarImageGray(i).I135 = double(rgb2gray(PolarImageRGB(i).I135));
    end  
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