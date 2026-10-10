%% Real Data (PPA Dataset) Plane Comparision
clc; clear; close all;
%% Initialization
[location, name] = get_name_PPA();
a = 0.46;    
eta = 1.55;  %1.55
rows = 1024; cols = 1224;
epsilon = 1e-12;
%% Ours pre-processing
% V
rays = NaN(rows, cols, 3);
Mask_temp = ones(rows, cols) == 1;
[extrinsic, intrinsic, undistort] = read_data([location, '\cams\'], [char(name{1}), '_cam.txt']);
[rowsMask, colsMask] = find(Mask_temp == 1);
K = intrinsic;
for cut = 1 : length(rowsMask)
    x = [colsMask(cut); rowsMask(cut); 1];
    v = K \ x;
    rays(rowsMask(cut), colsMask(cut), :) = v / norm(v);
end
V = -rays; V(:,:,2) = -V(:,:,2); V(:,:,3) = -V(:,:,3);
% Beta
Beta = getPerspectiveDistortionAngle(V, Mask_temp);
% Psi
Psi = getPsiAngle(V, Mask_temp);
% q
C = cos(Beta);
q = @(angle) cos(angle - Psi).^2 + C.^2 .* sin(angle - Psi).^2;
%
q_list = NaN(rows, cols, 4);
q_list(:,:,1) = q(0);
q_list(:,:,2) = q(pi/4);
q_list(:,:,3) = q(pi/2);
q_list(:,:,4) = q(3*pi/4);
cp = cos(2*Psi);
sp = sin(2*Psi);
C2 = C .* C;
F = [1/4, 1/4,  1/4,  1/4;
     1/2,   0, -1/2,    0;
       0, 1/2,    0, -1/2];
W_ours_all = NaN(3, 4, rows, cols);
for r = 1 : rows
    for c = 1 : cols
        cv  = C(r,c);
        cv2 = C2(r,c);
        cpv = cp(r,c);
        spv = sp(r,c);
    
        T = [1,        cpv,        spv;
             0,    -spv/cv,     cpv/cv;
             1/cv2, -cpv/cv2, -spv/cv2];
    
        q_pixel = reshape(q_list(r,c,:), 1, 4);
        W_ours_all(:,:,r,c) = (T * F) .* q_pixel;
    end
end
%% IJCV pre-processing
rays = NaN(rows, cols, 3);
Mask_temp = ones(rows, cols) == 1;
[extrinsic, intrinsic, undistort] = read_data([location, '\cams\'], [char(name{1}), '_cam.txt']);
[rowsMask, colsMask] = find(Mask_temp == 1);
K = intrinsic;
for cut = 1 : length(rowsMask)
    x = [colsMask(cut); rowsMask(cut); 1];
    v = K \ x;
    rays(rowsMask(cut), colsMask(cut), :) = v / norm(v);
end
V = -rays; V(:,:,2) = -V(:,:,2); V(:,:,3) = -V(:,:,3);

angles = [0, pi/4, pi/2, 3*pi/4] + pi/2;

A = [cos(angles);
     sin(angles);
     zeros(1,4)];
%
R_list     = NaN(3, 3, rows, cols);
M_inv_list = NaN(3, 4, rows, cols);
for r = 1 : rows
    for c = 1 : cols
        v = reshape(V(r,c,:), 3, 1);
        r_z = v;
        r_x = cross([0;1;0], r_z);
        r_x = r_x / norm(r_x);
        r_y = cross(r_z, r_x);
        R = [r_x, r_y, r_z];
        P = R.' * A;                   % 3×4
        t = VecToso3([0; 0; 1]) * P;
        colNorm = vecnorm(t, 2, 1);
        t = t./ colNorm;
        alpha_modify = atan2(t(2,:), t(1,:));
        M = 0.5 * [ones(4,1), ...
                   cos(2*alpha_modify).', ...
                   sin(2*alpha_modify).'];
    
        R_list(:,:,r,c) = R;
        M_inv_list(:,:,r,c) = pinv(M);
    end
end

%% Calculate
err_plot_ours = zeros(rows, cols); time_ours = NaN(length(name), 1);
err_plot_IJCV = zeros(rows, cols); time_IJCV = NaN(length(name), 1);
sumMask = zeros(rows, cols);
for i = 1 : length(name)
    fprintf('Processing Image %i/%i...\n', i, length(name));
    [extrinsic, intrinsic, undistort] = read_data([location, '\cams\'], [char(name{i}), '_cam.txt']);

    %% Data 
    % polarimetric image
    polarImage = readPolarimetricImage([location, '\images\'], [char(name{i}), '.png']); 
    % mask
    Mask = load([location, '\images\', char(name{i}), '_mask.mat']).data == 1;
    [rowMask, colMask] = find(Mask == 1);
    % normal
    normal_w = [-0.12410584; -0.31629185; -0.94050901];
    n = extrinsic(1:3, 1:3) * normal_w;
    N_desired = repmat(reshape(n, 1, 1, 3), 1024, 1224);
    %% Configuration
    % Perspective
    N_ours.sp1 = NaN(1024, 1224, 3);
    N_ours.sp2 = NaN(1024, 1224, 3);
    N_ours.sp3 = NaN(1024, 1224, 3);
    N_ours.sp4 = NaN(1024, 1224, 3);
    I0_mask   = polarImage.I0(Mask);
    I45_mask  = polarImage.I45(Mask);
    I90_mask  = polarImage.I90(Mask);
    I135_mask = polarImage.I135(Mask);    
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
        psi = Psi(row, col);
        c = C(row, col);
        v = reshape(V(row,col,:), 3, 1);
        % Timing
        W_ours = W_ours_all(:,:,row, col);
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
        d = [cos(phi_sp1); sin(phi_sp1); 0];

        e_s = cross(v, d);
        e_s = e_s / norm(e_s);
        e_p = cross(e_s, v);
        
        ct = cos(theta);
        st = sin(theta);
        
        v1 = v * ct(1);
        p1 = e_p * st(1);
        v2 = v * ct(2);
        p2 = e_p * st(2);
        
        N_ours.sp1(row,col,:) = v1 + p1;
        N_ours.sp2(row,col,:) = v1 - p1;
        N_ours.sp3(row,col,:) = v2 + p2;
        N_ours.sp4(row,col,:) = v2 - p2;

%         d_1 = [cos(phi_sp1); sin(phi_sp1); 0];
%         d_2 = [cos(phi_sp2); sin(phi_sp2); 0];
%         e_s1 = cross(v, d_1); e_s1 = e_s1 ./ norm(e_s1);
%         e_s2 = cross(v, d_2); e_s2 = e_s2 ./ norm(e_s2);
%         e_p1 = cross(e_s1, v);
%         e_p2 = cross(e_s2, v);
%         N_ours.sp1(row, col, :) = v * cos(theta(1)) + e_p1 * sin(theta(1));
%         N_ours.sp2(row, col, :) = v * cos(theta(1)) + e_p2 * sin(theta(1));
%         N_ours.sp3(row, col, :) = v * cos(theta(2)) + e_p1 * sin(theta(2));
%         N_ours.sp4(row, col, :) = v * cos(theta(2)) + e_p2 * sin(theta(2));
    end
    time_ours(i) = toc(timer);
    time_ours(i) = time_ours(i) / length(rowMask); 
    %% IJCV Method 
    timer = tic;
    for num = 1 : length(rowMask)
        row = rowMask(num); col = colMask(num);
        I_list = [I0_mask(num); I45_mask(num); I90_mask(num); I135_mask(num)];
        % Timing
        M_inv = M_inv_list(:,:,row, col);
        R = R_list(:,:,row,col);
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
        N_orth_sp1 = [sin(theta(1)) * cos(phi_sp1); sin(theta(1)) * sin(phi_sp1); cos(theta(1))];
        N_orth_sp2 = [sin(theta(2)) * cos(phi_sp1); sin(theta(2)) * sin(phi_sp1); cos(theta(2))];
        N_orth_sp3 = [sin(theta(1)) * cos(phi_sp2); sin(theta(1)) * sin(phi_sp2); cos(theta(1))];
        N_orth_sp4 = [sin(theta(2)) * cos(phi_sp2); sin(theta(2)) * sin(phi_sp2); cos(theta(2))];
        N_IJCV.sp1(row, col, :) = R * N_orth_sp1;
        N_IJCV.sp2(row, col, :) = R * N_orth_sp2;
        N_IJCV.sp3(row, col, :) = R * N_orth_sp3;
        N_IJCV.sp4(row, col, :) = R * N_orth_sp4;
    end
    time_IJCV(i) = toc(timer);
    time_IJCV(i) = time_IJCV(i) / length(rowMask);  
    %% Modify
    N_ours.sp1(:,:,2) = -N_ours.sp1(:,:,2);   N_ours.sp1(:,:,3) = -N_ours.sp1(:,:,3);  
    N_ours.sp2(:,:,2) = -N_ours.sp2(:,:,2);   N_ours.sp2(:,:,3) = -N_ours.sp2(:,:,3);
    N_ours.sp3(:,:,2) = -N_ours.sp3(:,:,2);   N_ours.sp3(:,:,3) = -N_ours.sp3(:,:,3);
    N_ours.sp4(:,:,2) = -N_ours.sp4(:,:,2);   N_ours.sp4(:,:,3) = -N_ours.sp4(:,:,3);
    N_IJCV.sp1(:,:,2) = -N_IJCV.sp1(:,:,2);   N_IJCV.sp1(:,:,3) = -N_IJCV.sp1(:,:,3);  
    N_IJCV.sp2(:,:,2) = -N_IJCV.sp2(:,:,2);   N_IJCV.sp2(:,:,3) = -N_IJCV.sp2(:,:,3);
    N_IJCV.sp3(:,:,2) = -N_IJCV.sp3(:,:,2);   N_IJCV.sp3(:,:,3) = -N_IJCV.sp3(:,:,3);
    N_IJCV.sp4(:,:,2) = -N_IJCV.sp4(:,:,2);   N_IJCV.sp4(:,:,3) = -N_IJCV.sp4(:,:,3);
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
fprintf('PPA dataset MAE (deg) ours/IJCV: %.3f / %.3f\n', rad2deg(mean(err_plot_ours_mean(id))), rad2deg(mean(err_plot_IJCV_mean(id))));
fprintf('PPA dataset SD (deg) ours/IJCV: %.3f / %.3f\n', rad2deg(std(err_plot_ours_mean(id))), rad2deg(std(err_plot_IJCV_mean(id))));
fprintf('PPA dataset RMSE (deg) ours/IJCV: %.3f / %.3f\n', rad2deg(sqrt(mean(err_plot_ours_mean(id).^2))), rad2deg(sqrt(mean(err_plot_IJCV_mean(id).^2))));
fprintf('PPA dataset Max (deg) ours/IJCV: %.3f / %.3f\n', rad2deg(max(err_plot_ours_mean(id))), rad2deg(max(err_plot_IJCV_mean(id))));
 %%
fprintf("All Data Timing Ours / IJCV: %.2e x1, %.2e x%.2f\n", mean(time_ours(:)), mean(time_IJCV(:)), mean(time_IJCV(:))/mean(time_ours(:)));

%% Save
% save('./Data/Data_ExperimentPlanePPADataset_EfficiencyFast.mat', 'id',...
%     'err_plot_ours_mean', 'err_plot_IJCV_mean',...
%     'time_ours', 'time_IJCV');























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

