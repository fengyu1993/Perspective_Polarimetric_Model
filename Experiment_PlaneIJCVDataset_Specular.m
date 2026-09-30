%% Real Data (IJCV Dataset) Plane Comparision (Specular)
clc; clear; close all;
%% Initialization
[location, name] = get_name_IJCV();
a = 0.73;    % 0.41 0.48 0.5
eta = 1.57;  % 1.70 1.37 1.39
row = 1024; col = 1224;
V_orth = zeros(row, col, 3); V_orth(:,:,3) = -1;
Beta_orth = zeros(row, col);
%% Calculate
err_plot_ours = zeros(row, col);
err_plot_pers = zeros(row, col);
err_plot_orth = zeros(row, col);
err_plot_IJCV = zeros(row, col);
sumMask = zeros(row, col);
for i = 1 : 10%length(name)
    fprintf('Processing Image %i/%i...\n', i, length(name));
    %% Data 
    % polarimetric image
    polarImage = readPolarimetricImage(location, name{i}); 
    % mask
    Mask = load([location, name{i}, '_mask.mat']).data == 1;
    % V
    V = -load([location, 'our_rays.mat']).data; 
    V(:,:,1) = -V(:,:,1);
    % Beta
    Beta = getPerspectiveDistortionAngle(V, Mask);
    % Psi
    Psi = getPsiAngle(V, Mask);
    % normal
    poseMatrix = readmatrix([location, name{i}, '_pose.txt']);
    n = poseMatrix(1:3, 1:3) * [0; 0; 1];
    N_desired = repmat(reshape(n, 1, 1, 3), 1024, 1224);
    %% Methods
    % Perspective accurate
    N_ours = getSurfaceNormalFromSpecularReflection_AccurateNew(polarImage, Psi, Beta, V, eta, a, Mask);
    N_ours.sp1(:,:,1) = -N_ours.sp1(:,:,1);   N_ours.sp2(:,:,1) = -N_ours.sp2(:,:,1);
    N_ours.sp3(:,:,1) = -N_ours.sp3(:,:,1);   N_ours.sp4(:,:,1) = -N_ours.sp4(:,:,1);
    % Perspective 
    N_pers = getSurfaceNormalFromSpecularReflection(polarImage, Beta, V, eta, a, Mask);
    N_pers.sp1(:,:,1) = -N_pers.sp1(:,:,1);   N_pers.sp2(:,:,1) = -N_pers.sp2(:,:,1);
    N_pers.sp3(:,:,1) = -N_pers.sp3(:,:,1);   N_pers.sp4(:,:,1) = -N_pers.sp4(:,:,1);
    % Orthographic 
    N_orth = getSurfaceNormalFromSpecularReflection(polarImage, Beta_orth, V_orth, eta, a, Mask);
    N_orth.sp1(:,:,1) = -N_orth.sp1(:,:,1);   N_orth.sp2(:,:,1) = -N_orth.sp2(:,:,1);
    N_orth.sp3(:,:,1) = -N_orth.sp3(:,:,1);   N_orth.sp4(:,:,1) = -N_orth.sp4(:,:,1);
    % IJCV 
    N_IJCV = getSurfaceNormalFromSpecularReflection_IJCV(polarImage, V, eta, a, Mask);
    N_IJCV.sp1(:,:,1) = -N_IJCV.sp1(:,:,1);   N_IJCV.sp2(:,:,1) = -N_IJCV.sp2(:,:,1);
    N_IJCV.sp3(:,:,1) = -N_IJCV.sp3(:,:,1);   N_IJCV.sp4(:,:,1) = -N_IJCV.sp4(:,:,1);
    %% Error
    error_n_ours = getErrorNormalAngle(N_ours, N_desired, Mask);
    error_n_pers = getErrorNormalAngle(N_pers, N_desired, Mask);
    error_n_orth = getErrorNormalAngle(N_orth, N_desired, Mask);
    error_n_IJCV = getErrorNormalAngle(N_IJCV, N_desired, Mask);
    %% Statistics
    err_plot_ours(Mask) = err_plot_ours(Mask) + error_n_ours(Mask);
    err_plot_pers(Mask) = err_plot_pers(Mask) + error_n_pers(Mask);
    err_plot_orth(Mask) = err_plot_orth(Mask) + error_n_orth(Mask);
    err_plot_IJCV(Mask) = err_plot_IJCV(Mask) + error_n_IJCV(Mask);
    sumMask(Mask) = sumMask(Mask) + 1;
end
%% plot
err_plot_ours_mean = NaN(row, col);
err_plot_pers_mean = NaN(row, col);
err_plot_orth_mean = NaN(row, col);
err_plot_IJCV_mean = NaN(row, col);
id = sumMask > 0;
err_plot_ours_mean(id) = err_plot_ours(id) ./ sumMask(id);
err_plot_pers_mean(id) = err_plot_pers(id) ./ sumMask(id);
err_plot_orth_mean(id) = err_plot_orth(id) ./ sumMask(id);
err_plot_IJCV_mean(id) = err_plot_IJCV(id) ./ sumMask(id);
figure;
ax = subplot(2, 2, 1); h = imagesc(err_plot_ours_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('ours');
ax = subplot(2, 2, 2); h = imagesc(err_plot_pers_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('pers');
ax = subplot(2, 2, 3); h = imagesc(err_plot_orth_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('orth');
ax = subplot(2, 2, 4); h = imagesc(err_plot_IJCV_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('IJCV');
fprintf('IJCV dataset MAE (deg) ours/perspective/orthographic/IJCV: %.3f / %.3f / %.3f / %.3f\n', rad2deg(mean(err_plot_ours_mean(id))), rad2deg(mean(err_plot_pers_mean(id))), rad2deg(mean(err_plot_orth_mean(id))), rad2deg(mean(err_plot_IJCV_mean(id))));
fprintf('IJCV dataset SD (deg) ours/perspective/orthographic/IJCV: %.3f / %.3f / %.3f / %.3f\n', rad2deg(std(err_plot_ours_mean(id))), rad2deg(std(err_plot_pers_mean(id))), rad2deg(std(err_plot_orth_mean(id))), rad2deg(std(err_plot_IJCV_mean(id))));
fprintf('IJCV dataset RMSE (deg) ours/perspective/orthographic/IJCV: %.3f / %.3f / %.3f / %.3f\n', rad2deg(sqrt(mean(err_plot_ours_mean(id).^2))), rad2deg(sqrt(mean(err_plot_pers_mean(id).^2))), rad2deg(sqrt(mean(err_plot_orth_mean(id).^2))), rad2deg(sqrt(mean(err_plot_IJCV_mean(id).^2))));
fprintf('IJCV dataset Max (deg) ours/perspective/orthographic/IJCV: %.3f / %.3f / %.3f / %.3f\n', rad2deg(max(err_plot_ours_mean(id))), rad2deg(max(err_plot_pers_mean(id))), rad2deg(max(err_plot_orth_mean(id))), rad2deg(max(err_plot_IJCV_mean(id))));

%% Save
save('./Data/Data_ExperimentPlaneIJCVDataset.mat', 'id',...
    'err_plot_ours_mean','err_plot_pers_mean', 'err_plot_orth_mean', 'err_plot_IJCV_mean');























%%
function [location, name] = get_name_IJCV()
    location = './Data/IJCV/'; 
    filePattern = fullfile(location, '*.png');
    dirData = dir(filePattern);
    name = {dirData.name};
end
function polarImage = readPolarimetricImage(location_image, name_image)
    fullPath_image = fullfile(location_image, name_image);
    if exist(fullPath_image, 'file')
        imgRaw = imread(fullPath_image);
        if size(imgRaw, 3) == 3
            imgRaw = rgb2gray(imgRaw); 
        end
    else
        error('No image, check location\n');
    end
    imgRaw = double(imgRaw);
    %
    polarImage.I90  = imgRaw(1:2:end, 1:2:end); 
    polarImage.I45  = imgRaw(1:2:end, 2:2:end); 
    polarImage.I135 = imgRaw(2:2:end, 1:2:end); 
    polarImage.I0   = imgRaw(2:2:end, 2:2:end);
end


