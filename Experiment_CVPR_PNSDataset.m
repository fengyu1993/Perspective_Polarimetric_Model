%% CVPR PNS Dataset: Polarimetric Normal Stereo (CVPR)
clc; 
clear; 
close all;
%% dataset
dataset = reatdPNSDataset('Data\PNS\');
% dataset = load("Data\Data_PNSDataset.mat");

%% parameter
[rows, cols] = size(dataset.book.img_L1_L.polarImage.I0);
V_orth = zeros(rows, cols, 3); V_orth(:,:,3) = 1;
Beta_orth = zeros(rows, cols);
Psi_orth = zeros(rows, cols);
eta = 1.5;
a = 1;
% 所有图像共用的像素坐标
[U, W] = meshgrid(1:cols, 1:rows);
pixels = [U(:)'; W(:)'; ones(1, rows*cols)];
%% calculate
err_plot_Ours = zeros(rows, cols); 
err_plot_Atkinson2006 = zeros(rows, cols);
sumMask = zeros(rows, cols);
nameList = dataset.nameList;
imgNameList = dataset.imgNameList;
for i = 1 : length(nameList)
    objName = char(nameList(i));
    firstImg = char(imgNameList(1));
    % V
    K = dataset.(objName).(firstImg).calib.K;
    rays = K \ pixels;
    rays = rays ./ sqrt(sum(rays.^2, 1));
    rays(1,:) = -rays(1,:);
    V = reshape(rays.', rows, cols, 3);
    for j = 1 : length(imgNameList)
        imgName = char(imgNameList(j));
        data = dataset.(objName).(imgName);
        %% parameters
        polarImage = data.polarImage;
        Mask = data.mask;
        N_desired = data.normal;
        % Beta
        Beta = getPerspectiveDistortionAngle(V, Mask);
        % Psi
        Psi = getPsiAngle(V, Mask);
        %% methods
        % ours
        N_Ours = getSurfaceNormalFromDiffuseReflection_AccurateNew(polarImage, Psi, Beta, V, eta, a, Mask);
        N_Ours.dp1(:,:,2) = -N_Ours.dp1(:,:,2);   N_Ours.dp1(:,:,3) = -N_Ours.dp1(:,:,3);  
        N_Ours.dp2(:,:,2) = -N_Ours.dp2(:,:,2);   N_Ours.dp2(:,:,3) = -N_Ours.dp2(:,:,3);
        % Atkinson2006
        N_Atkinson2006 = getSurfaceNormalFromDiffuseReflection_AccurateNew(polarImage, Psi_orth, Beta_orth, V_orth, eta, a, Mask);
        N_Atkinson2006.dp1(:,:,2) = -N_Atkinson2006.dp1(:,:,2);   N_Atkinson2006.dp1(:,:,3) = -N_Atkinson2006.dp1(:,:,3);  
        N_Atkinson2006.dp2(:,:,2) = -N_Atkinson2006.dp2(:,:,2);   N_Atkinson2006.dp2(:,:,3) = -N_Atkinson2006.dp2(:,:,3);
        %% Error
        error_Ours = getErrorNormalAngle(N_Ours, N_desired, Mask);
        error_Atkinson2006 = getErrorNormalAngle(N_Atkinson2006, N_desired, Mask);       
        %% Statistics
        err_plot_Ours(Mask) = err_plot_Ours(Mask) + error_Ours(Mask);
        err_plot_Atkinson2006(Mask) = err_plot_Atkinson2006(Mask) + error_Atkinson2006(Mask);
        sumMask(Mask) = sumMask(Mask) + 1;
    end
end
%% plot
err_plot_Ours_mean = NaN(rows, cols);
err_plot_Atkinson2006_mean = NaN(rows, cols);
id = sumMask > 0;
err_plot_Ours_mean(id) = err_plot_Ours(id) ./ sumMask(id);
err_plot_Atkinson2006_mean(id) = err_plot_Atkinson2006(id) ./ sumMask(id);
figure;
ax = subplot(1, 2, 1); h = imagesc(err_plot_Ours_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Ours');
ax = subplot(1, 2, 2); h = imagesc(err_plot_Atkinson2006_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Atkinson2006');
fprintf('PNS dataset MAE (deg) Ours/Atkinson2006: %.3f / %.3f\n', rad2deg(mean(err_plot_Ours_mean(id))), rad2deg(mean(err_plot_Atkinson2006_mean(id))));
fprintf('PNS dataset SD (deg) Ours/Atkinson2006: %.3f / %.3f\n', rad2deg(std(err_plot_Ours_mean(id))), rad2deg(std(err_plot_Atkinson2006_mean(id))));
fprintf('PNS dataset MED (deg) Ours/Atkinson2006: %.3f / %.3f\n', rad2deg(median(err_plot_Ours_mean(id))), rad2deg(median(err_plot_Atkinson2006_mean(id))));
fprintf('PNS dataset Max (deg) Ours/Atkinson2006: %.3f / %.3f\n', rad2deg(max(err_plot_Ours_mean(id))), rad2deg(max(err_plot_Atkinson2006_mean(id))));
%%
% save('./Data/Data_ExperimentPNSDataset.mat', 'id', 'sumMask',...
%     'err_plot_Ours_mean', 'err_plot_Atkinson2006_mean');












%%
function dataset = reatdPNSDataset(location)
    subLocation = ["book", "dinosaur", "lemon", "pig", "stone"];
%     imgNames = ["img_L1_L", "img_L1_R", "img_L2_L", "img_L2_R", "img_L3_L", "img_L3_R", "img_L4_L", "img_L4_R", "img_L5_L", "img_L5_R"];
    imgNames = ["img_L1_L", "img_L2_L", "img_L3_L", "img_L4_L", "img_L5_L"];
    dataset = struct(); 
    % data
    for i = 1 : length(subLocation)
        objName = char(subLocation(i));
        folderPath = fullfile(location, subLocation(i));
        calib = load(fullfile(folderPath, 'calib.mat'));
        gt = load(fullfile(folderPath, 'gt.mat'), 'ps_normal_L', 'mask_L');
        normal = double(gt.ps_normal_L);
        normalLength = sqrt(sum(normal.^2, 3));
        Mask = logical(gt.mask_L) & ...
               all(isfinite(normal), 3) & ...
               isfinite(normalLength) & ...
               normalLength > 0;
        normalLength(~Mask) = 1;
        normal = normal ./ normalLength;
        normal(repmat(~Mask, [1, 1, 3])) = NaN;
        for j = 1 : length(imgNames)
            imgName = char(imgNames(j));
            imgRaws = imread(fullfile(folderPath, [imgName, '.png']));
            dataset.(objName).(imgName).polarImage = getPolarImage(imgRaws, 'gray');
            dataset.(objName).(imgName).calib = calib;
            dataset.(objName).(imgName).normal = normal;
            dataset.(objName).(imgName).mask = Mask;
%             figure('Position', [0, 0, 1400, 750], 'Color', 'w', 'Name', objName + imgNames(j)); 
%             subplot(3, 4, 1); imshow(dataset.(objName).(imgName).polarImage.I0, []);
%             subplot(3, 4, 2); imshow(dataset.(objName).(imgName).polarImage.I45, []);
%             subplot(3, 4, 3); imshow(dataset.(objName).(imgName).polarImage.I90, []);
%             subplot(3, 4, 4); imshow(dataset.(objName).(imgName).polarImage.I135, []);
%             subplot(3, 4, 5); imshow(dataset.(objName).(imgName).polarImage.I0 .* dataset.(objName).(imgName).mask, []);
%             subplot(3, 4, 6); imshow(dataset.(objName).(imgName).polarImage.I45 .* dataset.(objName).(imgName).mask, []);
%             subplot(3, 4, 7); imshow(dataset.(objName).(imgName).polarImage.I90 .* dataset.(objName).(imgName).mask, []);
%             subplot(3, 4, 8); imshow(dataset.(objName).(imgName).polarImage.I135 .* dataset.(objName).(imgName).mask, []);
%             subplot(3, 4, 9); imshow( dataset.(objName).(imgName).mask, []);
%             subplot(3, 4, 10); imshow((dataset.(objName).(imgName).normal + 1) / 2);
%             subplot(3, 4, 11); imshow((dataset.(objName).(imgName).normal .* dataset.(objName).(imgName).mask + 1) / 2);      
        end
    end
    %% name
    dataset.nameList = subLocation;
    dataset.imgNameList = imgNames;
    save('./Data/Data_PNSDataset.mat', '-struct', 'dataset');
end

function polarImage = getPolarImage(imgRaw, outputMode)
% Decode PNS Quad-Bayer polarization images.
%
% outputMode:
%   'bayer' : Default. Retain the RGGB mosaic, as in the PNS example.
%   'gray'  : Demosaic each polarization image, then convert to grayscale.
%   'rgb'   : Demosaic each polarization image to RGB.
%
% Outputs are double arrays in [0,1].
% Input must be the unmodified uint8/uint16 image returned by imread.

    if nargin < 2
        outputMode = 'bayer';
    end
    outputMode = validatestring(outputMode, {'bayer', 'gray', 'rgb'});

    validateattributes(imgRaw, {'uint8', 'uint16'}, ...
        {'2d', 'nonempty', 'real'}, mfilename, 'imgRaw');

    [h, w] = size(imgRaw);
    assert(mod(h, 4) == 0 && mod(w, 4) == 0, ...
        'Image dimensions must be multiples of four.');

    % Raw polarization layout: [90, 45; 135, 0].
    names    = {'I0', 'I45', 'I90', 'I135'};
    rowStart = [2, 1, 1, 2];
    colStart = [2, 2, 1, 1];

    polarImage = struct();

    for k = 1:4
        bayer = imgRaw(rowStart(k):2:end, colStart(k):2:end);

        if strcmp(outputMode, 'bayer')
            image = im2double(bayer);
        else
            assert(size(bayer, 1) >= 5 && size(bayer, 2) >= 5, ...
                'Each Bayer image must be at least 5-by-5.');

            image = im2double(demosaic(bayer, 'rggb'));

            if strcmp(outputMode, 'gray')
                image = rgb2gray(image);
            end
        end

        polarImage.(names{k}) = image;
    end
end

