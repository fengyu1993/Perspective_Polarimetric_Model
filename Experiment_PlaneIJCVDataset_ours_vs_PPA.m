%% Real Data (IJCV Dataset) Plane Comparision Ours VS. PPA
clc; clear; close all;
%% Initialization
[location, name] = get_name_IJCV();
row = 1024; col = 1224;
%% Calculate
Num = length(name);
err_plot_ours = zeros(Num, 1);
err_plot_PPA = zeros(Num, 1);
for i = 1 : Num
    %% 加载图片与数据
    % 加载图片
    image_name = name(i) + "";
    img_raw = read_image(location, image_name);
    % 加载mask
    mask_name = name(i) + "_mask.mat";
    mask = load(location + mask_name).data;
    Mask = mask == 1;
    % 加载位姿
    pose_name = name(i) + "_pose.txt";
    pose_matrix = readmatrix(location + pose_name);
    R_extrinsic = pose_matrix(:, 1:3);
    t_extrinsic = pose_matrix(:, 4) ./ 100;
    extrinsic = [R_extrinsic, t_extrinsic; 0, 0, 0. 1];
    % 加载光线
    rays = load(location + "our_rays.mat").data;
    %% 拆分0/45/90/135偏振图像
    % 90  45
    % 135 0
    polarImage.I90  = img_raw(1:2:end, 1:2:end); 
    polarImage.I45  = img_raw(1:2:end, 2:2:end); 
    polarImage.I135 = img_raw(2:2:end, 1:2:end); 
    polarImage.I0   = img_raw(2:2:end, 2:2:end);
    %% V
    V = rays;
    V(:,:,1) = -V(:,:,1);
    % Beta Psi
    Beta = getPerspectiveDistortionAngle(V, Mask);
    Psi = getPsiAngle(V, Mask);
    % normal
    normal_w = [0; 0; 1];
    N_desired = R_extrinsic * normal_w;
    %% Methods
    % PPA
    N_PPA = getSurfaceNormalFromSpecularReflection_PPA(polarImage, Mask, rays);
    % ours
    Phi_ours = getAzimuthAngleSpecularReflection_Accurate(polarImage, Mask, Beta, Psi);
    phi_ous = Phi_ours.sp1;
%     phi_ous = Phi_ours.sp2;
%     Phi_ours = getAzimuthAngleDiffuseReflection_Accurate(polarImage, Mask, Beta, Psi);
%     phi_ous = Phi_ours.dp1;
%     phi_ous = Phi_ours.dp2;
    rays_reshaped = reshape(rays, [], 3);
    v = rays_reshaped(Mask(:), :)';
    M = [-v(3,:)'.*sin(phi_ous(Mask)), ...
        -v(3,:)'.*cos(phi_ous(Mask)), ...
        v(2,:)' .* cos(phi_ous(Mask)) + v(1,:)' .* sin(phi_ous(Mask))];
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









%%
function [location, name] = get_name_IJCV()
    location = 'E:\Publish\Paper\10_Polarimetric visual servoing\Program\23_03_01_aruco_cloudy_300\'; 
    filePattern = fullfile(location, '*.png');
    dirData = dir(filePattern);
    name = {dirData.name};
end

function img_raw = read_image(location_image, name_image)
    fullPath_image = fullfile(location_image, name_image);
    if exist(fullPath_image, 'file')
        img_raw = imread(fullPath_image);
        if size(img_raw, 3) == 3
            img_raw = rgb2gray(img_raw); 
        end
    else
        error('图片不存在，请检查路径。');
    end
    img_raw = double(img_raw);
end





