%% Phase Shift Specular Reflection
clc;
clear;
close all;
%% Load Data
[location, name] = get_name_IJCV();
%%
err_n_list = zeros(1, length(name));
for i = 1 : length(name)
    %% 加载图片与数据
    % 加载图片
    image_name = name(i) + "";
    imageRaw = read_image(location, image_name);
    % 加载mask
    mask_name = name(i) + "_mask.mat";
    mask = load(location + mask_name).data;
%     mask = ones(size(mask));
    Mask = mask == 1;
    % 加载位姿
    pose_name = name(i) + "_pose.txt";
    pose_matrix = readmatrix(location + pose_name);
    R_extrinsic = pose_matrix(:, 1:3);
    % 加载光线
    rays = load(location + "our_rays.mat").data;
    % 计算期望法向量
    normal_w = [0; 0; 1];
    n_desired = R_extrinsic * normal_w;

        K = [120, 0, 612; ...
        0, 112, 512; ...
        0, 0, 1];
eta = 1.5;

    %% 拆分0/45/90/135偏振图像
    
    V = getLightPropagationDirection(K, Mask);
    Beta = getPerspectiveDistortionAngle(V, Mask);
    PolarImage = imageRawToPolarImage(imageRaw);
    Phi = getAzimuthAngleSpecularReflection(PolarImage, Mask);
    Rho = getDoLP(PolarImage, Mask);
    Theta = getZenithAngleSpecularReflection(Rho, Mask, Beta, eta);
    Theta_dp = getZenithAngleDiffuseReflection(Rho, Mask, Beta, eta);
    N = getSurfaceNormal(V, Theta.p, Phi, Mask);

%     [row, col] = find(Mask == 1);
%     k = 90;
%     es = [sin(Phi(row(k), col(k))); -cos(Phi(row(k), col(k))); 0];
%     v = squeeze(V(row(k), col(k), :));
%     theta = Theta.p(row(k), col(k));
%     n = v * cos(theta) - cross(v, es) * sin(theta);
%     squeeze(N(row(k), col(k), :)) - n

    %%
    figure;
    subplot(2,2,1); imshow(PolarImage.I0, [0, 255]); title("I_{0}", 'font','FontName', 'Times New Roman', 'FontSize', 14);
    subplot(2,2,2); imshow(PolarImage.I45, [0, 255]); title("I_{45}", 'font','FontName', 'Times New Roman', 'FontSize', 14);
    subplot(2,2,3); imshow(PolarImage.I90, [0, 255]); title("I_{90}", 'font','FontName', 'Times New Roman', 'FontSize', 14);
    subplot(2,2,4); imshow(PolarImage.I135, [0, 255]); title("I_{135}", 'font','FontName', 'Times New Roman', 'FontSize', 14);
    figure;  
    imagesc(AzimuthAngle); 
    colormap(parula); colorbar;
    figure;
    imagesc(Rho);
    colormap(parula); colorbar;
end




















%% 
function [location, name] = get_name_IJCV()
    location = fullfile('Data', 'IJCV\');
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














