%% Real Data (IJCV Dataset) Plane Comparision
clc; clear; close all;
%% Initialization
[location, name] = get_name_IJCV();
row = 1024; col = 1224;
V_orth = zeros(row, col, 3); V_orth(:,:,3) = -1;
Beta_orth = zeros(row, col);
num_A = 25;
num_ETA = 12;
a_list = linspace(0.05, 0.7, num_A);
eta_list = linspace(1.3, 1.7, num_ETA);
[A, ETA] = meshgrid(a_list, eta_list);
%% Calculate
error_all_N_angle = NaN(num_ETA, num_A);
error_all_N_angle_orth = NaN(num_ETA, num_A);
error_all_N_angle_IJCV = NaN(num_ETA, num_A);
sumMask = zeros(row, col);
for a_cnt = 1 : length(a_list)
    a = a_list(a_cnt);
    for eta_cnt = 1 : length(eta_list)
        eta = eta_list(eta_cnt);
        err_plot = zeros(row, col);
        err_plot_orth = zeros(row, col);
        err_plot_IJCV = zeros(row, col);
        for i = 1 : length(name)
            fprintf('Processing Image a_cnt = %i, k = %i, eta_cnt =  %i/%i...\n', a_cnt, eta_cnt, i, length(name));
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
            err_N_angle = getErrorNormalAngle(N, N_desired, Mask);
            error_N_angle_orth = getErrorNormalAngle(N_orth, N_desired, Mask);
            error_N_angle_IJCV = getErrorNormalAngle(N_IJCV, N_desired, Mask);
            %% Statistics
            err_plot(Mask) = err_plot(Mask) + err_N_angle(Mask);
            err_plot_orth(Mask) = err_plot_orth(Mask) + error_N_angle_orth(Mask);
            err_plot_IJCV(Mask) = err_plot_IJCV(Mask) + error_N_angle_IJCV(Mask);
            sumMask(Mask) = sumMask(Mask) + 1;
       end
        id = sumMask > 0;
        err_mean = err_plot(id) ./ sumMask(id);
        err_orth_mean = err_plot_orth(id) ./ sumMask(id);
        err_IJCV_mean = err_plot_IJCV(id) ./ sumMask(id);
        error_all_N_angle(eta_cnt, a_cnt) = mean(err_mean(:));
        error_all_N_angle_orth(eta_cnt, a_cnt) = mean(err_orth_mean(:));
        error_all_N_angle_IJCV(eta_cnt, a_cnt) = mean(err_IJCV_mean(:));
        %% Plot
        fprintf('IJCV dataset MAE perspective/orthographic/IJCV: %.3f / %.3f / %.3f\n', error_all_N_angle(eta_cnt, a_cnt), error_all_N_angle_orth(eta_cnt, a_cnt), error_all_N_angle_IJCV(eta_cnt, a_cnt));
    end
end
%%
figure; 
hold on; grid on;
surf(A, ETA, rad2deg(error_all_N_angle), 'FaceAlpha', 0.8, 'EdgeColor', 'none'); 
mesh(A, ETA, rad2deg(error_all_N_angle_orth), 'EdgeColor', 'g'); 
mesh(A, ETA, rad2deg(error_all_N_angle_IJCV), 'EdgeColor', 'r'); 
view([30,10]);
legend('Ours', 'Orthographic', 'IJCV');
xlabel('a'); ylabel('\eta'); zlabel('Mean Error');
%%
% save('./Data/Data_IJCV_dataset_test_A_ETA.mat', 'A', 'ETA', ...
%     'error_all_N_angle', 'error_all_N_angle_orth', 'error_all_N_angle_IJCV');

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



%%
%     fig_N_sp = figure; ax = subplot(1, 3, 1); h = imagesc(error_N_angle); set(h, 'AlphaData', Mask); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Perspective Specular Reflection N Angle');
%     figure(fig_N_sp); ax = subplot(1, 3, 2); h = imagesc(error_N_angle_orth); set(h, 'AlphaData', Mask); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Orthographic Specular Reflection N Angle');
%     figure(fig_N_sp); ax = subplot(1, 3, 3); h = imagesc(error_N_angle_IJCV); set(h, 'AlphaData', Mask); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('IJCV Specular Reflection N Angle');

%    Phi_sp = getAzimuthAngleSpecularReflection(polarImage, Mask);
%     Rho_sp = getDoLP(polarImage, Mask);
%     Theta_sp = getZenithAngleSpecularReflection(Rho_sp ./ a, Mask, Beta, eta);
%     [Phi_d, Theta_d] = getPhiTheta(N_desired, V, Mask);
% 
% 
% 
% 
%     N.sp1 = getSurfaceNormal(V, Theta_sp.sp1, Phi_d, Mask);
%     N.sp2 = getSurfaceNormal(V, Theta_sp.sp2, Phi_d, Mask);
%     N.sp3 = getSurfaceNormal(V, Theta_sp.sp1, Phi_d, Mask);
%     N.sp4 = getSurfaceNormal(V, Theta_sp.sp2, Phi_d, Mask);
%     error_N_angle_d = getErrorNormalAngle(N, N_desired, Mask);
%     fig_N_sp = figure; ax = subplot(1, 3, 1); h = imagesc(error_N_angle_d); set(h, 'AlphaData', Mask); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Perspective Specular Reflection N Angle');
% 
%     
%     err_phi = min(abs(Phi_d - Phi_sp.sp1), abs(Phi_d - Phi_sp.sp2));
%     err_theta = min(abs(Theta_d - Theta_sp.sp1), abs(Phi_d - Theta_sp.sp2));
%     figure; subplot(1,2,1); imagesc(err_phi); colormap(parula); colorbar;
%     subplot(1,2,2);  imagesc(err_theta); colormap(parula); colorbar;
    %%
%     figure;
%     subplot(2,2,1); imshow(polarImage.I0, [0, 255]); title("I_{0}", 'font','FontName', 'Times New Roman', 'FontSize', 14);
%     subplot(2,2,2); imshow(polarImage.I45, [0, 255]); title("I_{45}", 'font','FontName', 'Times New Roman', 'FontSize', 14);
%     subplot(2,2,3); imshow(polarImage.I90, [0, 255]); title("I_{90}", 'font','FontName', 'Times New Roman', 'FontSize', 14);
%     subplot(2,2,4); imshow(polarImage.I135, [0, 255]); title("I_{135}", 'font','FontName', 'Times New Roman', 'FontSize', 14);
%     figure; imshow(Mask);