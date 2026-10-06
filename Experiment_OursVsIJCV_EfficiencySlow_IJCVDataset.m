%% Real Data (IJCV Dataset) Plane Comparision (Specular)
clc; clear; close all;
%% Initialization
[location, name] = get_name_IJCV();
a = 0.70;    % 0.41 0.48 0.5
eta = 1.55;  % 1.70 1.37 1.39
rows = 1024; cols = 1224;
epsilon = 1e-12;
%% Calculate
err_plot_ours = zeros(rows, cols); time_ours = NaN(length(name), 1);
err_plot_IJCV = zeros(rows, cols); time_IJCV = NaN(length(name), 1);
sumMask = zeros(rows, cols);
for i = 1 : length(name)
    fprintf('Processing Image %i/%i...\n', i, length(name));
    %% Data 
    % polarimetric image
    polarImage = readPolarimetricImage(location, name{i}); 
    % mask
    Mask = load([location, name{i}, '_mask.mat']).data == 1;
    [rowMask, colMask] = find(Mask == 1);
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
    %% Configuration
    % Perspective
    N_ours.sp1 = NaN(1024, 1224, 3);
    N_ours.sp2 = NaN(1024, 1224, 3);
    N_ours.sp3 = NaN(1024, 1224, 3);
    N_ours.sp4 = NaN(1024, 1224, 3);
    Vx = V(:,:,1); Vy = V(:,:,2); Vz = V(:,:,3);
    V_mask = [Vx(Mask), Vy(Mask), Vz(Mask)];
    I0_mask   = polarImage.I0(Mask);
    I45_mask  = polarImage.I45(Mask);
    I90_mask  = polarImage.I90(Mask);
    I135_mask = polarImage.I135(Mask);    
    q = @(angle, c, psi) cos(angle - psi).^2 + c.^2 .* sin(angle - psi).^2;
    % IJCV
    N_IJCV.sp1 = NaN(1024, 1224, 3);
    N_IJCV.sp2 = NaN(1024, 1224, 3);
    N_IJCV.sp3 = NaN(1024, 1224, 3);
    N_IJCV.sp4 = NaN(1024, 1224, 3);
    %% Perspective Method
    timer = tic;
    for num = 1 : length(rowMask)
        row = rowMask(num); col = colMask(num);
        I_list = [I0_mask(num); I45_mask(num); I90_mask(num); I135_mask(num)];
        v = V_mask(num, :)';
        % Timing
        beta = acos(abs(v(3)));
        psi = atan2(-v(2), -v(1));
        c = cos(beta);
        q_list = [q(0, c, psi); q(pi/4, c, psi); q(pi/2, c, psi); q(3*pi/4, c, psi)]; 
        cp = cos(2*psi);
        sp = sin(2*psi);
        c2 = c*c;
        F = [1/4, 1/4,  1/4,  1/4;
             1/2,   0, -1/2,    0;
               0, 1/2,    0, -1/2];
        T = [1,      cp,      sp;
             0,   -sp/c,    cp/c;
             1/c2, -cp/c2, -sp/c2];
        W_ours = T * F * diag(q_list);
        H = W_ours * I_list;
        h11 = H(1);
        h12 = H(2);
        h22 = H(3);
        % phi
        gamma_max = 0.5 * atan2(2*h12, h11-h22);
        gamma_parallel = gamma_max + pi/2;
        delta = atan2(c .* sin(gamma_parallel), cos(gamma_parallel));
        phi_sp1 = mod(psi + delta, pi);
        phi_sp2  = phi_sp1 - pi;
        % theta
        rho_0 = sqrt(((h11 - h22).^2 + 4*h12.^2)) ./ (h11 + h22);
        rho_0 = rho_0 / a;
        rho_valid = min(max(rho_0, 0), 1 - epsilon);
        lambda_sp =  (1 - rho_valid) ./ (1 + rho_valid);
        S_sp = [sqrt(lambda_sp); -sqrt(lambda_sp)];
        Xi = (1 - S_sp) ./ (1 + S_sp);
        brewster_cos2 = 1 / (1 + eta^2);
        inner = (2 + Xi.^2 * (eta^2 - 1) - Xi.*sqrt(Xi.^2 * (eta^2 - 1)^2 + 4*eta^2)) ./ (2 * (1 - Xi.^2));
        inner(abs(abs(Xi) - 1) < epsilon) = brewster_cos2; 
        inner = min(max(inner, 0), 1); 
        theta = acos(sqrt(inner));
        % normal
        d_1 = [cos(phi_sp1); sin(phi_sp1); 0];
        d_2 = [cos(phi_sp2); sin(phi_sp2); 0];
        e_s1 = cross(v, d_1); e_s1 = e_s1 ./ norm(e_s1);
        e_s2 = cross(v, d_2); e_s2 = e_s2 ./ norm(e_s2);
        e_p1 = cross(e_s1, v);
        e_p2 = cross(e_s2, v);
        N_ours.sp1(row, col, :) = v * cos(theta(1)) + e_p1 * sin(theta(1));
        N_ours.sp2(row, col, :) = v * cos(theta(1)) + e_p2 * sin(theta(1));
        N_ours.sp3(row, col, :) = v * cos(theta(2)) + e_p1 * sin(theta(2));
        N_ours.sp4(row, col, :) = v * cos(theta(2)) + e_p2 * sin(theta(2));
    end
    time_ours(i) = toc(timer);
    time_ours(i) = time_ours(i) / length(rowMask);
    %% IJCV Method 
    timer = tic;
    for num = 1 : length(rowMask)
        row = rowMask(num); col = colMask(num);
        I_list = [I0_mask(num); I45_mask(num); I90_mask(num); I135_mask(num)];
        v = V_mask(num, :)';
        % Timing
        r_z = -v;
        vx = VecToso3([0; 1; 0]) * r_z; r_x = vx ./ norm(vx);
        r_y = cross(r_z, r_x, 1);
        R = [r_x, r_y, r_z];
        t = pi/2;
        a_0 = [cos(0 + t); sin(0 + t); 0];
        a_45 = [cos(pi/4 + t); sin(pi/4 + t); 0];
        a_90 = [cos(pi/2 + t); sin(pi/2 + t); 0];
        a_135 = [cos(3*pi/4 + t); sin(3*pi/4 + t); 0];
        P_alpha_0 = R' * a_0;   
        P_alpha_45 = R' * a_45;  
        P_alpha_90 = R' * a_90; 
        P_alpha_135 = R' * a_135; 
        t_alpha_0 = VecToso3([0; 0; 1]) * P_alpha_0;     t_alpha_0 = t_alpha_0 / norm(t_alpha_0);
        t_alpha_45 = VecToso3([0; 0; 1]) * P_alpha_45;   t_alpha_45 = t_alpha_45 / norm(t_alpha_45);
        t_alpha_90 = VecToso3([0; 0; 1]) * P_alpha_90;   t_alpha_90 = t_alpha_90 / norm(t_alpha_90);
        t_alpha_135 = VecToso3([0; 0; 1]) * P_alpha_135; t_alpha_135 = t_alpha_135 / norm(t_alpha_135);
        alpha_0_modify = atan2(t_alpha_0(2), t_alpha_0(1));
        alpha_45_modify = atan2(t_alpha_45(2), t_alpha_45(1));
        alpha_90_modify = atan2(t_alpha_90(2), t_alpha_90(1));
        alpha_135_modify = atan2(t_alpha_135(2), t_alpha_135(1));
        c0 = cos(2 * alpha_0_modify);
        s0 = sin(2 * alpha_0_modify);
        c45 = cos(2 * alpha_45_modify);
        s45 = sin(2 * alpha_45_modify);
        c90 = cos(2 * alpha_90_modify);
        s90 = sin(2 * alpha_90_modify);
        c135 = cos(2 * alpha_135_modify);
        s135 = sin(2 * alpha_135_modify);
        M = 0.5 * [1, c0, s0; 1, c45, s45; 1, c90, s90; 1, c135, s135];
        M_inv = pinv(M);
        % phi
        S_hat = M_inv * I_list;
        phi_raw = 0.5 * atan2(S_hat(3,:), S_hat(2,:)) + pi/2;
        phi_sp1 = mod(phi_raw, pi);
        phi_sp2  = phi_sp1 - pi;
        %theta
        rho_0 = sqrt(S_hat(2)^2 + S_hat(3)^2) / S_hat(1);
        rho_0 = rho_0 / a;
        rho_valid = min(max(rho_0, 0), 1 - epsilon);
        lambda_sp =  (1 - rho_valid) ./ (1 + rho_valid);
        S_sp = [sqrt(lambda_sp); -sqrt(lambda_sp)];
        Xi = (1 - S_sp) ./ (1 + S_sp);
        brewster_cos2 = 1 / (1 + eta^2);
        inner = (2 + Xi.^2 * (eta^2 - 1) - Xi.*sqrt(Xi.^2 * (eta^2 - 1)^2 + 4*eta^2)) ./ (2 * (1 - Xi.^2));
        inner(abs(abs(Xi) - 1) < epsilon) = brewster_cos2; 
        inner = min(max(inner, 0), 1); 
        theta = acos(sqrt(inner));
        % normal
        N_orth_sp1 = [sin(theta(1)) * cos(phi_sp1); sin(theta(1)) * sin(phi_sp1); -cos(theta(1))];
        N_orth_sp2 = [sin(theta(2)) * cos(phi_sp1); sin(theta(2)) * sin(phi_sp1); -cos(theta(2))];
        N_orth_sp3 = [sin(theta(1)) * cos(phi_sp2); sin(theta(1)) * sin(phi_sp2); -cos(theta(1))];
        N_orth_sp4 = [sin(theta(2)) * cos(phi_sp2); sin(theta(2)) * sin(phi_sp2); -cos(theta(2))];
        N_IJCV.sp1(row, col, :) = R * N_orth_sp1;
        N_IJCV.sp2(row, col, :) = R * N_orth_sp2;
        N_IJCV.sp3(row, col, :) = R * N_orth_sp3;
        N_IJCV.sp4(row, col, :) = R * N_orth_sp4;
    end
    time_IJCV(i) = toc(timer);
    time_IJCV(i) = time_IJCV(i) / length(rowMask);    
    %% Modify
    N_ours.sp1(:,:,1) = -N_ours.sp1(:,:,1);   N_ours.sp2(:,:,1) = -N_ours.sp2(:,:,1);
    N_ours.sp3(:,:,1) = -N_ours.sp3(:,:,1);   N_ours.sp4(:,:,1) = -N_ours.sp4(:,:,1);
    N_IJCV.sp1(:,:,1) = -N_IJCV.sp1(:,:,1);   N_IJCV.sp2(:,:,1) = -N_IJCV.sp2(:,:,1);
    N_IJCV.sp3(:,:,1) = -N_IJCV.sp3(:,:,1);   N_IJCV.sp4(:,:,1) = -N_IJCV.sp4(:,:,1);  
    %% Error
    error_n_ours = getErrorNormalAngle(N_ours, N_desired, Mask);
    error_n_IJCV = getErrorNormalAngle(N_IJCV, N_desired, Mask);
    %% Statistics
    err_plot_ours(Mask) = err_plot_ours(Mask) + error_n_ours(Mask);
    err_plot_IJCV(Mask) = err_plot_IJCV(Mask) + error_n_IJCV(Mask);
    sumMask(Mask) = sumMask(Mask) + 1;
    %% Time
    fprintf("Timing Ours / IJCV: %.2e x1, %.2e x%.2f\n", time_ours(i), time_IJCV(i), time_IJCV(i)/time_ours(i));
end
%% plot
err_plot_ours_mean = NaN(rows, cols);
err_plot_IJCV_mean = NaN(rows, cols);
id = sumMask > 0;
err_plot_ours_mean(id) = err_plot_ours(id) ./ sumMask(id);
err_plot_IJCV_mean(id) = err_plot_IJCV(id) ./ sumMask(id);
figure;
ax = subplot(1, 2, 1); h = imagesc(err_plot_ours_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('ours');
ax = subplot(1, 2, 2); h = imagesc(err_plot_IJCV_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('IJCV');
fprintf('IJCV dataset MAE (deg) ours/IJCV: %.3f / %.3f\n', rad2deg(mean(err_plot_ours_mean(id))), rad2deg(mean(err_plot_IJCV_mean(id))));
fprintf('IJCV dataset SD (deg) ours/IJCV: %.3f / %.3f\n', rad2deg(std(err_plot_ours_mean(id))), rad2deg(std(err_plot_IJCV_mean(id))));
fprintf('IJCV dataset RMSE (deg) ours/IJCV: %.3f / %.3f\n', rad2deg(sqrt(mean(err_plot_ours_mean(id).^2))), rad2deg(sqrt(mean(err_plot_IJCV_mean(id).^2))));
fprintf('IJCV dataset Max (deg) ours/IJCV: %.3f / %.3f\n', rad2deg(max(err_plot_ours_mean(id))), rad2deg(max(err_plot_IJCV_mean(id))));
 %%
fprintf("All Data Timing Ours / IJCV: %.2e x1, %.2e x%.2f\n", mean(time_ours(:)), mean(time_IJCV(:)), mean(time_IJCV(:))/mean(time_ours(:)));
%% Save
save('./Data/Data_ExperimentPlaneIJCVDataset_EfficiencySlow.mat', 'id',...
    'err_plot_ours_mean', 'err_plot_IJCV_mean', ...
    'time_ours', 'time_IJCV');























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
function so3 = VecToso3(V)
    so3 = [0, -V(3), V(2); V(3), 0, -V(1); -V(2), V(1), 0];
end



%%
%     N_ours_ = getSurfaceNormalFromSpecularReflection_AccurateNew(polarImage, Psi, Beta, V, eta, a, Mask);
%     err.sp1 = abs(N_ours.sp1 - N_ours_.sp1);
%     err.sp2 = abs(N_ours.sp2 - N_ours_.sp2);
%     err.sp3 = abs(N_ours.sp3 - N_ours_.sp3);
%     err.sp4 = abs(N_ours.sp4 - N_ours_.sp4);
%     mean(err.sp1(Mask))
%     mean(err.sp2(Mask))
%     mean(err.sp3(Mask))
%     mean(err.sp4(Mask))
%%
%     N_IJCV_ = getSurfaceNormalFromSpecularReflection_IJCV(polarImage, V, eta, a, Mask);
%     err.sp1 = abs(N_IJCV.sp1 - N_IJCV_.sp1);
%     err.sp2 = abs(N_IJCV.sp2 - N_IJCV_.sp2);
%     err.sp3 = abs(N_IJCV.sp3 - N_IJCV_.sp3);
%     err.sp4 = abs(N_IJCV.sp4 - N_IJCV_.sp4);
%     mean(err.sp1(Mask))
%     mean(err.sp2(Mask))
%     mean(err.sp3(Mask))
%     mean(err.sp4(Mask)) 