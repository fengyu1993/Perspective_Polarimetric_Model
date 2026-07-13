%% Formula Verification
clc; clear; close all;
rng(1);
%% Initialization
Is = 2;
Id = 3;
eta = 1.5;
row = 1024;
col = 1224;
K = [1232, 0, 612; 0, 1232, 512; 0, 0, 1]; 
flag_Proj = 1;
mask = ones(row, col);  Mask = mask == 1;
if flag_Proj == 1
    V = getViewingDirection(K, Mask);       % Perspective Projection
elseif flag_Proj == 2
    V = zeros(row, col, 3); V(:,:,3) = -1;  % Orthographic Projection
end
V_orth = zeros(row, col, 3); V_orth(:,:,3) = -1;
Beta = getPerspectiveDistortionAngle(V, Mask);
Beta_orth = zeros(size(Beta));
Psi = getPsiAngle(V, Mask);
flag = 1;
if flag == 1 % Theta, Phi --> N 
    Theta_desired = rand(row, col) * (pi/2); 
    Phi_desired = rand(row, col) * 2 * pi - pi; 
    N_desired = getSurfaceNormal(V, Theta_desired, Phi_desired, Mask);
elseif flag == 2 % N --> Theta, Phi
    N_valid = randn(length(Beta(Mask)), 3);
    N_valid = N_valid ./ sqrt(sum(N_valid.^2, 2));
    Nx = zeros(row, col); Nx(Mask) = N_valid(:, 1);
    Ny = zeros(row, col); Ny(Mask) = N_valid(:, 2);
    Nz = zeros(row, col); Nz(Mask) = -abs(N_valid(:, 3));
    N_desired = cat(3, Nx, Ny, Nz);
    [Phi_desired, Theta_desired] = getPhiTheta(N_desired, V, Mask);
elseif flag == 3 % plane
    N_valid = randn(1, 3);
    N_valid = N_valid ./ norm(N_valid);
    Nx = zeros(row, col); Nx(Mask) = N_valid(1);
    Ny = zeros(row, col); Ny(Mask) = N_valid(2);
    Nz = zeros(row, col); Nz(Mask) = -abs(N_valid(3));
    N_desired = cat(3, Nx, Ny, Nz);
    [Phi_desired, Theta_desired] = getPhiTheta(N_desired, V, Mask);
end
% Psi = Phi_desired; % Perspective Approximation 
%% Configuration
G = sqrt(eta^2 - sin(Theta_desired).^2);
% specular reflection
R_p = ((G - eta^2 * cos(Theta_desired)) ./ (G + eta^2 * cos(Theta_desired))).^2;
R_s = ((G - cos(Theta_desired)) ./ (G + cos(Theta_desired))).^2;
I_sp_max = R_s ./ (R_s + R_p) * Is;
I_sp_min = R_p ./ (R_s + R_p) * Is;
% diffuse reflection
T_p = 4 * eta^2 * G .* cos(Theta_desired) ./ (G + eta^2 * cos(Theta_desired)).^2;
T_s = 4 * G .* cos(Theta_desired) ./ (G + cos(Theta_desired)).^2;
I_dp_max = T_p ./ (T_s + T_p) * Id;
I_dp_min = T_s ./ (T_s + T_p) * Id;
% function
I_sp_phipol = @(Phi_pol) ...
    I_sp_min .* (cos(Beta).^2 .* cos(Phi_pol - Phi_desired) + sin(Phi_desired - Psi) .* sin(Beta).^2 .* sin(Phi_pol - Psi)).^2 ./ (cos(Beta).^2 + sin(Beta).^2 .* sin(Phi_desired - Psi).^2) ...
    + I_sp_max .* (cos(Beta).^2 .* sin(Phi_pol - Phi_desired).^2) ./ (cos(Beta).^2 + sin(Beta).^2 .* sin(Phi_desired - Psi).^2);
I_dp_phipol = @(Phi_pol) ...
    I_dp_max .* (cos(Beta).^2 .* cos(Phi_pol - Phi_desired) + sin(Phi_desired - Psi) .* sin(Beta).^2 .* sin(Phi_pol - Psi)).^2 ./ (cos(Beta).^2 + sin(Beta).^2 .* sin(Phi_desired - Psi).^2) ...
    + I_dp_min .* (cos(Beta).^2 .* sin(Phi_pol - Phi_desired).^2) ./ (cos(Beta).^2 + sin(Beta).^2 .* sin(Phi_desired - Psi).^2);
%% Polar Image
% specular reflection
PolarImage_sp.I0 = I_sp_phipol(0);      PolarImage_sp.I45 = I_sp_phipol(pi/4);  
PolarImage_sp.I90 = I_sp_phipol(pi/2);  PolarImage_sp.I135 = I_sp_phipol(3*pi/4); 
Rho_sp = getDoLP(PolarImage_sp, Mask);
% diffuse reflection
PolarImage_dp.I0 = I_dp_phipol(0);      PolarImage_dp.I45 = I_dp_phipol(pi/4);  
PolarImage_dp.I90 = I_dp_phipol(pi/2);  PolarImage_dp.I135 = I_dp_phipol(3*pi/4);
Rho_dp = getDoLP(PolarImage_dp, Mask);
%% Perspective projection
    %% Check Phi specular reflection
    Phi_sp = getAzimuthAngleSpecularReflection(PolarImage_sp, Mask);
    % check
    error_phi_sp_1 = abs(Phi_desired - Phi_sp.sp1); error_phi_sp_1 = min(error_phi_sp_1, 2*pi - error_phi_sp_1);
    error_phi_sp_2 = abs(Phi_desired - Phi_sp.sp2); error_phi_sp_2 = min(error_phi_sp_2, 2*pi - error_phi_sp_2);
    error_phi_sp = min(error_phi_sp_1, error_phi_sp_2);
    figure; imagesc(error_phi_sp); colormap(parula); colorbar; title('Perspective Specular Reflection: err_{\phi}');
    %% Check Phi diffuse reflection
    Phi_dp = getAzimuthAngleDiffuseReflection(PolarImage_dp, Mask);
    % check
    error_phi_dp_1 = abs(Phi_desired - Phi_dp.dp1); error_phi_dp_1 = min(error_phi_dp_1, 2*pi - error_phi_dp_1);
    error_phi_dp_2 = abs(Phi_desired - Phi_dp.dp2); error_phi_dp_2 = min(error_phi_dp_2, 2*pi - error_phi_dp_2);
    error_phi_dp_3 = abs(Phi_desired - Phi_dp.dp3); error_phi_dp_3 = min(error_phi_dp_3, 2*pi - error_phi_dp_3);
    error_phi_dp_4 = abs(Phi_desired - Phi_dp.dp4); error_phi_dp_4 = min(error_phi_dp_4, 2*pi - error_phi_dp_4);
    error_phi_dp = min(cat(3, error_phi_dp_1, error_phi_dp_2, error_phi_dp_3, error_phi_dp_4), [], 3);
    figure; imagesc(error_phi_dp); colormap(parula); colorbar; title('Perspective Diffuse Reflection: err_{\phi}');
    %% Check Theta specular reflection
    Theta_sp = getZenithAngleSpecularReflection(Rho_sp, Mask, Beta, eta);
    % check
    error_theta_sp_1 = abs(Theta_desired - Theta_sp.sp1);
    error_theta_sp_2 = abs(Theta_desired - Theta_sp.sp2);
    error_theta_sp = min(error_theta_sp_1, error_theta_sp_2);
    fig_theta_sp = figure; 
    ax_t_theta_sp1 = subplot(1, 2, 1); imagesc(error_theta_sp); colormap(parula); colorbar; title('Perspective Specular Reflection: err_{\theta}');
    %% Check Theta diffuse reflection
    Theta_dp = getZenithAngleDiffuseReflection(Rho_dp, Mask, Beta, eta);
    % check
    error_theta_dp_1 = abs(Theta_dp.dp1 - Theta_desired);
    error_theta_dp_2 = abs(Theta_dp.dp2 - Theta_desired);
    error_theta_dp = min(error_theta_dp_1, error_theta_dp_2);
    fig_theta_dp = figure; 
    ax_t_theta_dp1 = subplot(1, 2, 1); imagesc(error_theta_dp); colormap(parula); colorbar; title('Perspective Diffuse Reflection: err_{\theta}');
    %% Check normal vector specular reflection
    N_sp_1 = getSurfaceNormal(V, Theta_sp.sp1, Phi_sp.sp1, Mask);
    N_sp_2 = getSurfaceNormal(V, Theta_sp.sp2, Phi_sp.sp1, Mask);
    N_sp_3 = getSurfaceNormal(V, Theta_sp.sp1, Phi_sp.sp2, Mask);
    N_sp_4 = getSurfaceNormal(V, Theta_sp.sp2, Phi_sp.sp2, Mask);
    % check
    error_N_angle_sp_1 = acos(min(max(sum(N_sp_1 .* N_desired, 3), -1), 1));
    error_N_angle_sp_2 = acos(min(max(sum(N_sp_2 .* N_desired, 3), -1), 1));
    error_N_angle_sp_3 = acos(min(max(sum(N_sp_3 .* N_desired, 3), -1), 1));
    error_N_angle_sp_4 = acos(min(max(sum(N_sp_4 .* N_desired, 3), -1), 1));
    error_N_angle_sp = min(cat(3, error_N_angle_sp_1, error_N_angle_sp_2, error_N_angle_sp_3, error_N_angle_sp_4), [], 3);
    fig_N_sp = figure;
    ax_t_N_angle_sp1 = subplot(1, 2, 1); imagesc(error_N_angle_sp); colormap(parula); colorbar; title('Perspective Specular Reflection N Angle');
    %% Check normal vector diffuse reflection
    N_dp_1 = getSurfaceNormal(V, Theta_dp.dp1, Phi_dp.dp1, Mask);
    N_dp_2 = getSurfaceNormal(V, Theta_dp.dp1, Phi_dp.dp3, Mask);
    N_dp_3 = getSurfaceNormal(V, Theta_dp.dp2, Phi_dp.dp2, Mask);
    N_dp_4 = getSurfaceNormal(V, Theta_dp.dp2, Phi_dp.dp4, Mask);
    % check
    error_N_angle_dp_1 = acos(min(max(sum(N_dp_1 .* N_desired, 3), -1), 1));
    error_N_angle_dp_2 = acos(min(max(sum(N_dp_2 .* N_desired, 3), -1), 1));
    error_N_angle_dp_3 = acos(min(max(sum(N_dp_3 .* N_desired, 3), -1), 1));
    error_N_angle_dp_4 = acos(min(max(sum(N_dp_4 .* N_desired, 3), -1), 1));
    error_N_angle_dp = min(cat(3, error_N_angle_dp_1, error_N_angle_dp_2, error_N_angle_dp_3, error_N_angle_dp_4), [], 3);
    fig_N_dp = figure;
    ax_t_N_angle_dp1 = subplot(1, 2, 1); imagesc(error_N_angle_dp); colormap(parula); colorbar; title('Perspective Diffuse Reflection N Angle');
%% Orthographic projection
    %% Check Theta specular reflection
    Theta_sp_orth = getZenithAngleSpecularReflection(Rho_sp, Mask, Beta_orth, eta);
    % check
    error_theta_sp_1_orth = abs(Theta_desired - Theta_sp_orth.sp1);
    error_theta_sp_2_orth = abs(Theta_desired - Theta_sp_orth.sp2);
    error_theta_sp_orth = min(error_theta_sp_1_orth, error_theta_sp_2_orth);
    figure(fig_theta_sp); 
    ax_t_theta_sp2 = subplot(1, 2, 2); imagesc(error_theta_sp_orth); colormap(parula); colorbar; title('Orthographic Specular Reflection: err_{\theta}');
    max_val = max([get(ax_t_theta_sp1, 'CLim'), get(ax_t_theta_sp2, 'CLim')]);
    set(ax_t_theta_sp1, 'CLim', [0, max_val]);
    set(ax_t_theta_sp2, 'CLim', [0, max_val]);
    %% Check Theta diffuse reflection
    Theta_dp_orth = getZenithAngleDiffuseReflection(Rho_dp, Mask, Beta_orth, eta);
    % check
    error_theta_dp_1_orth = abs(Theta_dp_orth.dp1 - Theta_desired);
    error_theta_dp_2_orth = abs(Theta_dp_orth.dp2 - Theta_desired);
    error_theta_dp_orth = min(error_theta_dp_1_orth, error_theta_dp_2_orth);
    figure(fig_theta_dp);
    ax_t_theta_dp2 = subplot(1, 2, 2); imagesc(error_theta_dp_orth); colormap(parula); colorbar; title('Orthographic Diffuse Reflection: err_{\theta}');
    max_val = max([get(ax_t_theta_dp1, 'CLim'), get(ax_t_theta_dp2, 'CLim')]);
    set(ax_t_theta_dp1, 'CLim', [0, max_val]);
    set(ax_t_theta_dp2, 'CLim', [0, max_val]);
    %% Check normal vector specular reflection
    N_sp_orth_1 = getSurfaceNormal(V_orth, Theta_sp_orth.sp1, Phi_sp.sp1, Mask);
    N_sp_orth_2 = getSurfaceNormal(V_orth, Theta_sp_orth.sp2, Phi_sp.sp1, Mask);
    N_sp_orth_3 = getSurfaceNormal(V_orth, Theta_sp_orth.sp1, Phi_sp.sp2, Mask);
    N_sp_orth_4 = getSurfaceNormal(V_orth, Theta_sp_orth.sp2, Phi_sp.sp2, Mask);
    % check
    error_N_angle_sp_orth_1 = acos(min(max(sum(N_sp_orth_1 .* N_desired, 3), -1), 1));
    error_N_angle_sp_orth_2 = acos(min(max(sum(N_sp_orth_2 .* N_desired, 3), -1), 1));
    error_N_angle_sp_orth_3 = acos(min(max(sum(N_sp_orth_3 .* N_desired, 3), -1), 1));
    error_N_angle_sp_orth_4 = acos(min(max(sum(N_sp_orth_4 .* N_desired, 3), -1), 1));
    error_N_angle_sp_orth = min(cat(3, error_N_angle_sp_orth_1, error_N_angle_sp_orth_2, error_N_angle_sp_orth_3, error_N_angle_sp_orth_4), [], 3);
    figure(fig_N_sp);
    ax_t_N_angle_sp2 = subplot(1, 2, 2); imagesc(error_N_angle_sp_orth); colormap(parula); colorbar; title('Orthographic Specular Reflection N Angle');
    max_val = max([get(ax_t_N_angle_sp1, 'CLim'), get(ax_t_N_angle_sp2, 'CLim')]);
    set(ax_t_N_angle_sp1, 'CLim', [0, max_val]);
    set(ax_t_N_angle_sp2, 'CLim', [0, max_val]);    
    %% Check normal vector diffuse reflection
    N_dp_orth_1 = getSurfaceNormal(V_orth, Theta_dp_orth.dp1, Phi_dp.dp1, Mask);
    N_dp_orth_2 = getSurfaceNormal(V_orth, Theta_dp_orth.dp1, Phi_dp.dp3, Mask);
    N_dp_orth_3 = getSurfaceNormal(V_orth, Theta_dp_orth.dp2, Phi_dp.dp2, Mask);
    N_dp_orth_4 = getSurfaceNormal(V_orth, Theta_dp_orth.dp2, Phi_dp.dp4, Mask);
    % check
    error_N_angle_dp_orth_1 = acos(min(max(sum(N_dp_orth_1 .* N_desired, 3), -1), 1));
    error_N_angle_dp_orth_2 = acos(min(max(sum(N_dp_orth_2 .* N_desired, 3), -1), 1));
    error_N_angle_dp_orth_3 = acos(min(max(sum(N_dp_orth_3 .* N_desired, 3), -1), 1));
    error_N_angle_dp_orth_4 = acos(min(max(sum(N_dp_orth_4 .* N_desired, 3), -1), 1));
    error_N_angle_dp_orth = min(cat(3, error_N_angle_dp_orth_1, error_N_angle_dp_orth_2, error_N_angle_dp_orth_3, error_N_angle_dp_orth_4), [], 3);
    figure(fig_N_dp);
    ax_t_N_angle_dp2 = subplot(1, 2, 2); imagesc(error_N_angle_dp_orth); colormap(parula); colorbar; title('Orthographic Diffuse Reflection N Angle');
    max_val = max([get(ax_t_N_angle_dp1, 'CLim'), get(ax_t_N_angle_dp2, 'CLim')]);
    set(ax_t_N_angle_dp1, 'CLim', [0, max_val]);
    set(ax_t_N_angle_dp2, 'CLim', [0, max_val]);  
%% Error statistics
error_phi_sp_mean = mean(error_phi_sp(:)) * 180 / pi;
error_phi_dp_mean = mean(error_phi_dp(:)) * 180 / pi;
error_theta_sp_mean = mean(error_theta_sp(:)) * 180 / pi;
error_theta_sp_mean_orth = mean(error_theta_sp_orth(:)) * 180 / pi;
error_theta_dp_mean = mean(error_theta_dp(:)) * 180 / pi;
error_theta_dp_mean_orth = mean(error_theta_dp_orth(:)) * 180 / pi;
error_N_angle_sp_mean = mean(error_N_angle_sp(:)) * 180 / pi;
error_N_angle_sp_orth_mean = mean(error_N_angle_sp_orth(:)) * 180 / pi;
error_N_angle_dp_mean = mean(error_N_angle_dp(:)) * 180 / pi;
error_N_angle_dp_orth_mean = mean(error_N_angle_dp_orth(:)) * 180 / pi;
fprintf('Specular error phi: %.3f\n', error_phi_sp_mean);
fprintf('Diffuse error phi: %.3f\n', error_phi_dp_mean);
fprintf('Specular error theta perspective/orthographic: %.3f / %.3f\n', error_theta_sp_mean, error_theta_sp_mean_orth);
fprintf('Diffuse error theta perspective/orthographic: %.3f / %.3f\n', error_theta_dp_mean, error_theta_dp_mean_orth);
fprintf('Specular error N angle perspective/orthographic: %.3f / %.3f\n', error_N_angle_sp_mean, error_N_angle_sp_orth_mean);
fprintf('Diffuse error N angle perspective/orthographic: %.3f / %.3f\n', error_N_angle_dp_mean, error_N_angle_dp_orth_mean);






