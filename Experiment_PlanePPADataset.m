%% Real Data (PPA Dataset) Plane Comparision
clc; clear; close all;
%% Initialization
[location, name] = get_name_PPA();
a = 0.32;    % 0.320833 0.32
eta = 1.40;  % 1.372727 1.4
row = 1024; col = 1224;
V_orth = zeros(row, col, 3); V_orth(:,:,3) = -1;
Beta_orth = zeros(row, col);
%% Calculate
err_plot = zeros(row, col);
err_plot_orth = zeros(row, col);
err_plot_IJCV = zeros(row, col);
sumMask = zeros(row, col);
for i = 1 : length(name)
    %% Data 
    % polarimetric image
    polarImage = readPolarimetricImage([location, '\images\'], [char(name{i}), '.png']); 
    % mask
    Mask = load([location, '\images\', char(name{i}), '_mask.mat']).data == 1;
    % V
    rays = NaN([size(polarImage.I0), 3]);
    [extrinsic, intrinsic, undistort] = read_data([location, '\cams\'], [char(name{i}), '_cam.txt']);
    [rows, cols] = find(Mask == 1);
    K = intrinsic;
    for cut = 1 : length(rows)
        x = [cols(cut); rows(cut); 1];
        v = K \ x;
        rays(rows(cut), cols(cut), :) = v / norm(v);
    end
    V = -rays;
    % Beta
    Beta = getPerspectiveDistortionAngle(V, Mask);
    % normal
    normal_w = [-0.12410584; -0.31629185; -0.94050901];
    n = extrinsic(1:3, 1:3) * normal_w;
    N_desired = repmat(reshape(n, 1, 1, 3), 1024, 1224);
    %% Methods
    % Perspective 
    N = getSurfaceNormalFromSpecularReflection(polarImage, Beta, V, eta, a, Mask);
    % Orthographic 
    N_orth = getSurfaceNormalFromSpecularReflection(polarImage, Beta_orth, V_orth, eta, a, Mask);
    % IJCV 
    N_IJCV = getSurfaceNormalFromSpecularReflection_IJCV(polarImage, V, eta, a, Mask);
    %% Error
    error_n = getErrorNormalAngle(N, N_desired, Mask);
    error_n_orth = getErrorNormalAngle(N_orth, N_desired, Mask);
    error_n_IJCV = getErrorNormalAngle(N_IJCV, N_desired, Mask);
    %% Statistics
    err_plot(Mask) = err_plot(Mask) + error_n(Mask);
    err_plot_orth(Mask) = err_plot_orth(Mask) + error_n_orth(Mask);
    err_plot_IJCV(Mask) = err_plot_IJCV(Mask) + error_n_IJCV(Mask);
    sumMask(Mask) = sumMask(Mask) + 1;   
end
%% plot
err_plot_mean = NaN(row, col);
err_plot_orth_mean = NaN(row, col);
err_plot_IJCV_mean = NaN(row, col);
id = sumMask > 0;
err_plot_mean(id) = err_plot(id) ./ sumMask(id);
err_plot_orth_mean(id) = err_plot_orth(id) ./ sumMask(id);
err_plot_IJCV_mean(id) = err_plot_IJCV(id) ./ sumMask(id);
figure;
ax = subplot(1, 3, 1); h = imagesc(err_plot_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('ours');
ax = subplot(1, 3, 2); h = imagesc(err_plot_orth_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('orth');
ax = subplot(1, 3, 3); h = imagesc(err_plot_IJCV_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('IJCV');
fprintf('PPA dataset MAE (rad) perspective/orthographic/IJCV: %.3f / %.3f / %.3f\n', (mean(err_plot_mean(id))), (mean(err_plot_orth_mean(id))), (mean(err_plot_IJCV_mean(id))));
fprintf('PPA dataset SD (rad) perspective/orthographic/IJCV: %.3f / %.3f / %.3f\n', (std(err_plot_mean(id))), (std(err_plot_orth_mean(id))), (std(err_plot_IJCV_mean(id))));
fprintf('PPA dataset RMSE (rad) perspective/orthographic/IJCV: %.3f / %.3f / %.3f\n', sqrt(mean(err_plot_mean(id).^2)), sqrt(mean(err_plot_orth_mean(id).^2)), sqrt(mean(err_plot_IJCV_mean(id).^2)));
fprintf('PPA dataset Max (rad) perspective/orthographic/IJCV: %.3f / %.3f / %.3f\n', (max(err_plot_mean(id))), (max(err_plot_orth_mean(id))), (max(err_plot_IJCV_mean(id))));

%% Save
save('./Data/Data_ExperimentPlanePPADataset.mat', 'id',...
    'err_plot_mean', 'err_plot_orth_mean', 'err_plot_IJCV_mean');























%%
function [location, name] = get_name_PPA()
    num = ["000", "024", "048", "072", "096", "120", "144", "168", "192", "216", "240", "264"];
    location = '.\Data\PPA\data\single_normal';
    name = "00000" + num;
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
%     polarImage.I90  = imgRaw(1:2:end, 1:2:end); 
%     polarImage.I45  = imgRaw(1:2:end, 2:2:end); 
%     polarImage.I135 = imgRaw(2:2:end, 1:2:end); 
%     polarImage.I0   = imgRaw(2:2:end, 2:2:end);
     % 
    polarImage.I90  = imgRaw(1:2:end, 1:2:end); 
    polarImage.I135  = imgRaw(1:2:end, 2:2:end); 
    polarImage.I45 = imgRaw(2:2:end, 1:2:end); 
    polarImage.I0   = imgRaw(2:2:end, 2:2:end);   
end
function [extrinsic, intrinsic, last_data] = read_data(location_camera, name_camera)
    fullPath_camera = fullfile(location_camera, name_camera);
    if exist(fullPath_camera, 'file')
        fileID = fopen(fullPath_camera, 'r');
    else
        error('文件不存在，请检查路径。');
    end
    % --- 提取 Extrinsic ---
    fgetl(fileID); % 跳过 "extrinsic"
    extrinsic = cell2mat(textscan(fileID, '%f %f %f %f', 4)); 
    % --- 关键步骤：动态跳过直到看见 "intrinsic" ---
    line = '';
    while ~contains(line, 'intrinsic') && ~feof(fileID)
        line = fgetl(fileID);
    end
    % --- 提取 Intrinsic ---
    % 此时指针已经在 "intrinsic" 这一行之后，直接读取 3x3 矩阵
    intrinsic = cell2mat(textscan(fileID, '%f %f %f', 3));
    fgetl(fileID);
    last_data = cell2mat(textscan(fileID, '%f %f %f %f', 1));
    fclose(fileID);
end


