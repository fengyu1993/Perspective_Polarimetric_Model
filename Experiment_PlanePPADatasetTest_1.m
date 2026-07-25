%% Real Data (PPA Dataset) Plane Comparision 
clc; clear; close all;
%% Initialization
[location, name] = get_name_PPA();
row = 1024; col = 1224;
V_orth = zeros(row, col, 3); V_orth(:,:,3) = -1;
Beta_orth = zeros(row, col);
num_A = 25;
num_ETA = 12;
a_list = linspace(0.05, 0.7, num_A);
eta_list = linspace(1.3, 1.7, num_ETA);
[A, ETA] = meshgrid(a_list, eta_list);
%% Calculate
error_N.angle = NaN(row, col, length(name));
error_N.mask = NaN(row, col, length(name));
error_N_orth.angle = NaN(row, col, length(name));
error_N_orth.mask = NaN(row, col, length(name));
error_N_IJCV.angle = NaN(row, col, length(name));
error_N_IJCV.mask = NaN(row, col, length(name));
error_all_N_angle = NaN(num_ETA, num_A);
error_all_N_angle_orth = NaN(num_ETA, num_A);
error_all_N_angle_IJCV = NaN(num_ETA, num_A);
for a_cnt = 1 : length(a_list)
    a = a_list(a_cnt);
    for eta_cnt = 1 : length(eta_list)
        eta = eta_list(eta_cnt);
        for i = 1 : length(name)
            fprintf('Processing Image j = %i, k = %i, i =  %i/%i...\n', a_cnt, eta_cnt, i, length(name));
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
            error_N.angle(:, :, i) = error_n;
            error_N.mask(:, :, i) = Mask;
            error_N_orth.angle(:, :, i) = error_n_orth;
            error_N_orth.mask(:, :, i) = Mask;
            error_N_IJCV.angle(:, :, i) = error_n_IJCV;
            error_N_IJCV.mask(:, :, i) = Mask; 
        end
        %% Statistics
        err_plot = zeros(row, col);
        err_plot_orth = zeros(row, col);
        err_plot_IJCV = zeros(row, col);
        sumMask = zeros(row, col);
        for i = 1 : length(name)
            mask = error_N.mask(:, :, i) == 1;
        
            curr_err = error_N.angle(:, :, i);
            curr_err_orth = error_N_orth.angle(:, :, i);
            curr_err_IJCV = error_N_IJCV.angle(:, :, i);
        
            err_plot(mask) = err_plot(mask) + curr_err(mask);
            err_plot_orth(mask) = err_plot_orth(mask) + curr_err_orth(mask);
            err_plot_IJCV(mask) = err_plot_IJCV(mask) + curr_err_IJCV(mask);
            
            sumMask(mask) = sumMask(mask) + 1;
        end
        err_plot_mean = NaN(row, col);
        err_plot_orth_mean = NaN(row, col);
        err_plot_IJCV_mean = NaN(row, col);
        id = sumMask > 0;
        err_plot_mean(id) = err_plot(id) ./ sumMask(id);
        err_plot_orth_mean(id) = err_plot_orth(id) ./ sumMask(id);
        err_plot_IJCV_mean(id) = err_plot_IJCV(id) ./ sumMask(id);
        error_all_N_angle(eta_cnt, a_cnt) = mean(err_plot_mean(id));
        error_all_N_angle_orth(eta_cnt, a_cnt) = mean(err_plot_orth_mean(id));
        error_all_N_angle_IJCV(eta_cnt, a_cnt) = mean(err_plot_IJCV_mean(id));
        %% Plot
%         figure;
%         ax = subplot(1, 3, 1); h = imagesc(err_plot_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('ours');
%         ax = subplot(1, 3, 2); h = imagesc(err_plot_orth_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('orth');
%         ax = subplot(1, 3, 3); h = imagesc(err_plot_IJCV_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('IJCV');
        fprintf('PPA dataset MAE perspective/orthographic/IJCV: %.3f / %.3f / %.3f\n', error_all_N_angle(eta_cnt, a_cnt), error_all_N_angle_orth(eta_cnt, a_cnt), error_all_N_angle_IJCV(eta_cnt, a_cnt));
    end
end
%%
save('./Data/Data_PPA_dataset_test_A_ETA.mat', 'A', 'ETA', ...
    'error_all_N_angle', 'error_all_N_angle_orth', 'error_all_N_angle_IJCV');























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



