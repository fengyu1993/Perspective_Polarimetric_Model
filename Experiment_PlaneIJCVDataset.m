%% Real Data (IJCV Dataset) Plane Comparision
clc; clear; close all;
%% Initialization
[location, name] = get_name_IJCV();
a = 0.73; 
eta = 1.57; 
row = 1024; col = 1224;
V_orth = zeros(row, col, 3); V_orth(:,:,3) = -1;
Beta_orth = zeros(row, col);
%% Calculate
for i = 1 : 10%length(name)
    %% Data 
    % polarimetric image
    polarImage = readPolarimetricImage(location, name{i}); 
    % mask
    Mask = load([location, name{i}, '_mask.mat']).data == 1;
    % V
    V = -load([location, 'our_rays.mat']).data; 
    % Beta
    Beta = getPerspectiveDistortionAngle(V, Mask);
    % normal
    poseMatrix = readmatrix([location, name{i}, '_pose.txt']);
    n = poseMatrix(1:3, 1:3) * [0; 0; 1];
    N_desired = repmat(reshape(n, 1, 1, 3), 1024, 1224);
    %% Methods
    % Perspective 
    N = getSurfaceNormalFromSpecularReflection(polarImage, Beta, V, eta, a, Mask);
    % Orthographic 
    N_orth = getSurfaceNormalFromSpecularReflection(polarImage, Beta_orth, V_orth, eta, a, Mask);
    % IJCV 
    N_IJCV = getSurfaceNormalFromSpecularReflection_IJCV(polarImage, V, eta, a, Mask);
    %% Error
    error_N_angle = getErrorNormalAngle(N, N_desired, Mask);
    error_N_angle_orth = getErrorNormalAngle(N_orth, N_desired, Mask);
    error_N_angle_IJCV = getErrorNormalAngle(N_IJCV, N_desired, Mask);
    %%
    n_est_IJCV = get_normal_vector_IJCV(polarImage.I0, polarImage.I45, polarImage.I90, polarImage.I135, Mask, V);
    err_n_IJCV = acos(n' * n_est_IJCV)
    
    %%
    figure;
    subplot(2,2,1); imshow(polarImage.I0, [0, 255]); title("I_{0}", 'font','FontName', 'Times New Roman', 'FontSize', 14);
    subplot(2,2,2); imshow(polarImage.I45, [0, 255]); title("I_{45}", 'font','FontName', 'Times New Roman', 'FontSize', 14);
    subplot(2,2,3); imshow(polarImage.I90, [0, 255]); title("I_{90}", 'font','FontName', 'Times New Roman', 'FontSize', 14);
    subplot(2,2,4); imshow(polarImage.I135, [0, 255]); title("I_{135}", 'font','FontName', 'Times New Roman', 'FontSize', 14);
    figure; imshow(Mask);

    
    fig_N_sp = figure; ax = subplot(1, 3, 1); h = imagesc(error_N_angle); set(h, 'AlphaData', Mask); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Perspective Specular Reflection N Angle');
    figure(fig_N_sp); ax = subplot(1, 3, 2); h = imagesc(error_N_angle_orth); set(h, 'AlphaData', Mask); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Orthographic Specular Reflection N Angle');
    figure(fig_N_sp); ax = subplot(1, 3, 3); h = imagesc(error_N_angle_IJCV); set(h, 'AlphaData', Mask); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('IJCV Specular Reflection N Angle');

    error_N_angle_sp_mean = mean(error_N_angle(Mask)) * 180 / pi; 
    error_N_angle_sp_orth_mean = mean(error_N_angle_orth(Mask)) * 180 / pi;
    error_N_angle_sp_IJCV_mean = mean(error_N_angle_IJCV(Mask)) * 180 / pi;
    error_N_angle_sp_rmse = sqrt(mean(error_N_angle(Mask).^2)) * 180 / pi; 
    error_N_angle_sp_orth_rmse = sqrt(mean(error_N_angle_orth(Mask).^2)) * 180 / pi;
    error_N_angle_sp_IJCV_rmse = sqrt(mean(error_N_angle_IJCV(Mask).^2)) * 180 / pi;
    fprintf('%s\n',name{i});
    fprintf('\t Specular error N angle MAE orthographic/IJCV/perspective: %.3f / %.3f / %.3f\n', error_N_angle_sp_orth_mean, error_N_angle_sp_IJCV_mean, error_N_angle_sp_mean);
    fprintf('\t Specular error N angle RMSE orthographic/IJCV/perspective: %.3f / %.3f / %.3f\n', error_N_angle_sp_orth_rmse, error_N_angle_sp_IJCV_rmse, error_N_angle_sp_rmse);

end
%%





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
    polarImage.I90  = imgRaw(1:2:end, 1:2:end); 
    polarImage.I45  = imgRaw(1:2:end, 2:2:end); 
    polarImage.I135 = imgRaw(2:2:end, 1:2:end); 
    polarImage.I0   = imgRaw(2:2:end, 2:2:end);
end



%%
%     figure;
%     subplot(2,2,1); imshow(polarImage.I0, [0, 255]); title("I_{0}", 'font','FontName', 'Times New Roman', 'FontSize', 14);
%     subplot(2,2,2); imshow(polarImage.I45, [0, 255]); title("I_{45}", 'font','FontName', 'Times New Roman', 'FontSize', 14);
%     subplot(2,2,3); imshow(polarImage.I90, [0, 255]); title("I_{90}", 'font','FontName', 'Times New Roman', 'FontSize', 14);
%     subplot(2,2,4); imshow(polarImage.I135, [0, 255]); title("I_{135}", 'font','FontName', 'Times New Roman', 'FontSize', 14);
%     figure; imshow(Mask);