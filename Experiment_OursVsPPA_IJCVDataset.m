%% Real Data (IJCV Dataset) Plane Comparision Ours VS. PPA
clc; clear; close all;
%% Initialization
[location, name] = get_name_IJCV();
row = 1024; col = 1224;
%% Calculate
Num = length(name);
err_plot_Ours = zeros(Num, 1);
err_plot_PPA = zeros(Num, 1);
err_plot_Orth = zeros(Num, 1);
for i = 1 : Num
    fprintf('Processing Image %i/%i...\n', i, length(name));
    %% Data 
    % polarimetric image
    polarImage = readPolarimetricImage(location, name{i}); 
    % mask
    Mask = load([location, name{i}, '_mask.mat']).data == 1;
    % V
    rays = load([location, 'our_rays.mat']).data; 
    V = -rays;
    V(:,:,1) = -V(:,:,1);
    rays_orth = rays;
    rays_orth(:,:,1) = 0; rays_orth(:,:,2) = 0; rays_orth(:,:,3) = 1;
    % Beta Psi
    Beta = getPerspectiveDistortionAngle(V, Mask);
    Psi = getPsiAngle(V, Mask);
    % normal
    poseMatrix = readmatrix([location, name{i}, '_pose.txt']);
    N_desired = poseMatrix(1:3, 1:3) * [0; 0; 1];
    %% Methods
    % PPA
    N_Orth = getSurfaceNormalFromSpecularReflection_PPA(polarImage, Mask, rays_orth);
    % PPA
    N_PPA = getSurfaceNormalFromSpecularReflection_PPA(polarImage, Mask, rays);
    % ours
    Phi_Ours = getAzimuthAngleSpecularReflection_AccurateNew(polarImage, Mask, Beta, Psi);
    rays_reshaped = reshape(rays, [], 3);
    v = rays_reshaped(Mask(:), :)';
    M = [-v(3,:)'.*sin(Phi_Ours.sp1(Mask)), ...
        -v(3,:)'.*cos(Phi_Ours.sp1(Mask)), ...
        v(2,:)' .* cos(Phi_Ours.sp1(Mask)) + v(1,:)' .* sin(Phi_Ours.sp1(Mask))];
    N_ours = getNormalFromEigen(M);
    %% Error
    % Orth
    error_normal_angle = rad2deg(acos(min(max(N_Orth' * N_desired, -1), 1)));
    err_plot_Orth(i) = error_normal_angle;    
    % PPA
    error_normal_angle = rad2deg(acos(min(max(N_PPA' * N_desired, -1), 1)));
    err_plot_PPA(i) = error_normal_angle;
    % ours
    error_normal_angle = rad2deg(acos(min(max(N_ours' * N_desired, -1), 1)));
    err_plot_Ours(i) = error_normal_angle;
end
%% Plot
figure; 
plot(1:Num, err_plot_Orth);
hold on;
plot(1:Num, err_plot_PPA);
plot(1:Num, err_plot_Ours);
set(gca, 'YScale', 'log');
legend("Orth", "PPA", "Ours");
%% Output
fprintf('PPA dataset MAE (deg) Ours/PPA/Orth: %.3f / %.3f / %.3f \n', mean(err_plot_Ours), mean(err_plot_PPA), mean(err_plot_Orth));
fprintf('PPA dataset SD (deg) Ours/PPA/Orth: %.3f / %.3f / %.3f \n', std(err_plot_Ours), std(err_plot_PPA), std(err_plot_Orth));
fprintf('PPA dataset RMSE (deg) Ours/PPA/Orth: %.3f / %.3f / %.3f \n', sqrt(mean(err_plot_Ours.^2)), sqrt(mean(err_plot_PPA.^2)), sqrt(mean(err_plot_Orth.^2)));
fprintf('PPA dataset Max (deg) Ours/PPA/Orth: %.3f / %.3f / %.3f \n', max(err_plot_Ours), max(err_plot_PPA), max(err_plot_Orth));
%% Save
save('./Data/Data_ExperimentPlaneIJCVDataset_OursVsPPA.mat',...
    'err_plot_Orth', 'err_plot_PPA', 'err_plot_Ours');

















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




