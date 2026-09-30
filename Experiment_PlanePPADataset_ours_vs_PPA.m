%% Real Data (PPA Dataset) Plane Comparision Ours VS. PPA
clc; clear; close all;
%% Initialization
[location, name] = get_name_PPA();
row = 1024; col = 1224;
V_orth = zeros(row, col, 3); V_orth(:,:,3) = -1;
Beta_orth = zeros(row, col);
%% Calculate
Num = length(name);
err_plot_ours = zeros(Num, 1);
err_plot_PPA = zeros(Num, 1);
for i = 1 : Num
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
    V(:,:,1) = -V(:,:,1);
    % Beta Psi
    Beta = getPerspectiveDistortionAngle(V, Mask);
    Psi = getPsiAngle(V, Mask);
    % normal
    normal_w = [-0.12410584; -0.31629185; -0.94050901];
    N_desired = extrinsic(1:3, 1:3) * normal_w;
    %% Methods
    % PPA
    N_PPA = getSurfaceNormalFromSpecularReflection_PPA(polarImage, Mask, rays);
    % ours
    Phi_ours = getAzimuthAngleSpecularReflection_Accurate(polarImage, Mask, Beta, Psi);
    rays_reshaped = reshape(rays, [], 3);
    v = rays_reshaped(Mask(:), :)';
    M = [-v(3,:)'.*sin(Phi_ours.sp1(Mask)), ...
        -v(3,:)'.*cos(Phi_ours.sp1(Mask)), ...
        v(2,:)' .* cos(Phi_ours.sp1(Mask)) + v(1,:)' .* sin(Phi_ours.sp1(Mask))];
    N_ours = getNormalFromEigen(M);
    %% Error
    % PPA
    error_normal_angle = rad2deg(acos(min(max(N_PPA' * N_desired, -1), 1)));
    err_plot_PPA(i) = error_normal_angle;
    % ours
    error_normal_angle = rad2deg(acos(min(max(N_ours' * N_desired, -1), 1)));
    err_plot_ours(i) = error_normal_angle;
end
%% Plot
figure; 
plot(1:Num, err_plot_PPA);
hold on;
plot(1:Num, err_plot_ours);


%% Output
fprintf('PPA dataset MAE (deg) Ours/PPA: %.3f / %.3f \n', mean(err_plot_ours), mean(err_plot_PPA));
fprintf('PPA dataset SD (deg) Ours/PPA: %.3f / %.3f \n', std(err_plot_ours), std(err_plot_PPA));
fprintf('PPA dataset RMSE (deg) Ours/PPA: %.3f / %.3f \n', sqrt(mean(err_plot_ours.^2)), sqrt(mean(err_plot_PPA.^2)));
fprintf('PPA dataset Max (deg) Ours/PPA: %.3f / %.3f \n', max(err_plot_ours), max(err_plot_PPA));































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
    polarImage.I90  = imgRaw(1:2:end, 1:2:end); 
    polarImage.I45  = imgRaw(1:2:end, 2:2:end); 
    polarImage.I135 = imgRaw(2:2:end, 1:2:end); 
    polarImage.I0   = imgRaw(2:2:end, 2:2:end);   
end

function [extrinsic, intrinsic, last_data] = read_data(location_camera, name_camera)
    fullPath_camera = fullfile(location_camera, name_camera);
    if exist(fullPath_camera, 'file')
        fileID = fopen(fullPath_camera, 'r');
    else
        error('文件不存在，请检查路径。');
    end
    fgetl(fileID); 
    extrinsic = cell2mat(textscan(fileID, '%f %f %f %f', 4)); 
    line = '';
    while ~contains(line, 'intrinsic') && ~feof(fileID)
        line = fgetl(fileID);
    end
    intrinsic = cell2mat(textscan(fileID, '%f %f %f', 3));
    fgetl(fileID);
    last_data = cell2mat(textscan(fileID, '%f %f %f %f', 1));
    fclose(fileID);
end




