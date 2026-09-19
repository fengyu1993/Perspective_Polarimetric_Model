%% Formula Verification New Accurate
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
% Beta = Beta_orth;
Psi = getPsiAngle(V, Mask);
flag = 2;
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
    [Phi_desired, Theta_desired, N_desired] = getPhiTheta_New(N_desired, V, Mask);
elseif flag == 3 % plane
    N_valid = randn(1, 3);
    N_valid = N_valid ./ norm(N_valid);
    Nx = zeros(row, col); Nx(Mask) = N_valid(1);
    Ny = zeros(row, col); Ny(Mask) = N_valid(2);
    Nz = zeros(row, col); Nz(Mask) = -abs(N_valid(3));
    N_desired = cat(3, Nx, Ny, Nz);
    [Phi_desired, Theta_desired, N_desired] = getPhiTheta_New(N_desired, V, Mask);
end
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
I_sp_phipol_approx = @(Phi_pol) ...
    cos(Beta).^2 .* I_sp_min .* (((1 + cos(Beta).^2) ./ (2*cos(Beta))).^2) .* cos(Phi_pol - Phi_desired).^2 ./ (cos(Beta).^2 + sin(Beta).^2 .* sin(Phi_desired - Psi).^2) ...
    + cos(Beta).^2 .* I_sp_max .* (sin(Phi_pol - Phi_desired).^2) ./ (cos(Beta).^2 + sin(Beta).^2 .* sin(Phi_desired - Psi).^2);
I_dp_phipol_approx = @(Phi_pol) ...
    cos(Beta).^2 .* I_dp_max .* (((1 + cos(Beta).^2) ./ (2*cos(Beta))).^2) .* cos(Phi_pol - Phi_desired).^2 ./ (cos(Beta).^2 + sin(Beta).^2 .* sin(Phi_desired - Psi).^2) ...
    + cos(Beta).^2 .* I_dp_min .* (sin(Phi_pol - Phi_desired).^2) ./ (cos(Beta).^2 + sin(Beta).^2 .* sin(Phi_desired - Psi).^2);
%% Polar Image 
flag_approx = 0;
if flag_approx == 1
    % specular reflection
    PolarImage_sp.I0 = I_sp_phipol_approx(0);      PolarImage_sp.I45 = I_sp_phipol_approx(pi/4);  
    PolarImage_sp.I90 = I_sp_phipol_approx(pi/2);  PolarImage_sp.I135 = I_sp_phipol_approx(3*pi/4); 
    Rho_sp = getDoLP(PolarImage_sp, Mask);
    % diffuse reflection
    PolarImage_dp.I0 = I_dp_phipol_approx(0);      PolarImage_dp.I45 = I_dp_phipol_approx(pi/4);  
    PolarImage_dp.I90 = I_dp_phipol_approx(pi/2);  PolarImage_dp.I135 = I_dp_phipol_approx(3*pi/4);
    Rho_dp = getDoLP(PolarImage_dp, Mask);
else
    % specular reflection
    PolarImage_sp.I0 = I_sp_phipol(0);      PolarImage_sp.I45 = I_sp_phipol(pi/4);  
    PolarImage_sp.I90 = I_sp_phipol(pi/2);  PolarImage_sp.I135 = I_sp_phipol(3*pi/4); 
    Rho_sp = getDoLP(PolarImage_sp, Mask);
    % diffuse reflection
    PolarImage_dp.I0 = I_dp_phipol(0);      PolarImage_dp.I45 = I_dp_phipol(pi/4);  
    PolarImage_dp.I90 = I_dp_phipol(pi/2);  PolarImage_dp.I135 = I_dp_phipol(3*pi/4);
    Rho_dp = getDoLP(PolarImage_dp, Mask);
end
%% Perspective accurate
    %% Check Phi specular reflection
    Phi_sp = getAzimuthAngleSpecularReflection_Accurate(PolarImage_sp, Mask, Beta, Psi);
    error_phi_sp = getAngleError(Phi_desired, Phi_sp);
    figure('Position', [100, 100, 1050, 450]); subplot(1, 2, 1); imagesc(error_phi_sp); colormap(parula); colorbar; title('Perspective Specular Reflection: err_{\phi}');
    %% Check Phi diffuse reflection
    Phi_dp = getAzimuthAngleDiffuseReflection_Accurate(PolarImage_dp, Mask, Beta, Psi);
    error_phi_dp = getAngleError(Phi_desired, Phi_dp);
    subplot(1, 2, 2); imagesc(error_phi_dp); colormap(parula); colorbar; title('Perspective Diffuse Reflection: err_{\phi}');
    %% Check Theta specular reflection
    Theta_sp = getZenithAngleSpecularReflection_Accurate(PolarImage_sp, Mask, Beta, Psi, eta);
    error_theta_sp = getAngleError(Theta_desired, Theta_sp);
    figure('Position', [100, 100, 1050, 450]); subplot(1, 2, 1); imagesc(error_theta_sp); colormap(parula); colorbar; title('Perspective Specular Reflection: err_{\theta}');
    %% Check Theta diffuse reflection
    Theta_dp = getZenithAngleDiffuseReflection_Accurate(PolarImage_dp, Mask, Beta, Psi, eta);
    error_theta_dp = getAngleError(Theta_desired, Theta_dp);
    subplot(1, 2, 2); imagesc(error_theta_dp); colormap(parula); colorbar; title('Perspective Diffuse Reflection: err_{\theta}');
    %% Check normal vector specular reflection
    N_sp_1 = getSurfaceNormal(V, Theta_sp.sp1, Phi_sp.sp1, Mask);
    N_sp_2 = getSurfaceNormal(V, Theta_sp.sp1, Phi_sp.sp2, Mask);
    N_sp_3 = getSurfaceNormal(V, Theta_sp.sp2, Phi_sp.sp1, Mask);
    N_sp_4 = getSurfaceNormal(V, Theta_sp.sp2, Phi_sp.sp2, Mask);
    error_N_angle_sp_1 = acos(min(max(sum(N_sp_1 .* N_desired, 3), -1), 1));
    error_N_angle_sp_2 = acos(min(max(sum(N_sp_2 .* N_desired, 3), -1), 1));
    error_N_angle_sp_3 = acos(min(max(sum(N_sp_3 .* N_desired, 3), -1), 1));
    error_N_angle_sp_4 = acos(min(max(sum(N_sp_4 .* N_desired, 3), -1), 1)); 
    error_N_angle_sp = min(cat(3, error_N_angle_sp_1, error_N_angle_sp_2, error_N_angle_sp_3, error_N_angle_sp_4), [], 3);
    figure('Position', [100, 100, 1050, 450]); subplot(1, 2, 1); imagesc(error_N_angle_sp); colormap(parula); colorbar; title('Perspective Specular Reflection N Angle');
    %% Check normal vector diffuse reflection
    N_dp_1 = getSurfaceNormal(V, Theta_dp.dp1, Phi_dp.dp1, Mask);
    N_dp_2 = getSurfaceNormal(V, Theta_dp.dp1, Phi_dp.dp2, Mask);
    error_N_angle_dp_1 = acos(min(max(sum(N_dp_1 .* N_desired, 3), -1), 1));
    error_N_angle_dp_2 = acos(min(max(sum(N_dp_2 .* N_desired, 3), -1), 1));
    error_N_angle_dp = min(cat(3, error_N_angle_dp_1, error_N_angle_dp_2), [], 3);
    subplot(1, 2, 2); imagesc(error_N_angle_dp); colormap(parula); colorbar; title('Perspective Diffuse Reflection N Angle');
%% Perspective New
    %% Check Phi specular reflection
    Phi_sp = getAzimuthAngleSpecularReflection_New(PolarImage_sp, Mask);
    error_phi_sp = getAngleError(Phi_desired, Phi_sp);
    figure('Position', [100, 100, 1050, 450]); subplot(1, 2, 1); imagesc(error_phi_sp); colormap(parula); colorbar; title('Perspective Specular Reflection: err_{\phi}');
    %% Check Phi diffuse reflection
    Phi_dp = getAzimuthAngleDiffuseReflection_New(PolarImage_dp, Mask);
    error_phi_dp = getAngleError(Phi_desired, Phi_dp);
    subplot(1, 2, 2); imagesc(error_phi_dp); colormap(parula); colorbar; title('Perspective Diffuse Reflection: err_{\phi}');
    %% Check Theta specular reflection
    Theta_sp = getZenithAngleSpecularReflection_New(Rho_sp, Mask, Beta, eta);
    error_theta_sp = getAngleError(Theta_desired, Theta_sp);
    figure('Position', [100, 100, 1050, 450]); subplot(1, 2, 1); imagesc(error_theta_sp); colormap(parula); colorbar; title('Perspective Specular Reflection: err_{\theta}');
    %% Check Theta diffuse reflection
    Theta_dp = getZenithAngleDiffuseReflection_New(Rho_dp, Mask, Beta, eta);
    error_theta_dp = getAngleError(Theta_desired, Theta_dp);
    subplot(1, 2, 2); imagesc(error_theta_dp); colormap(parula); colorbar; title('Perspective Diffuse Reflection: err_{\theta}');
    %% Check normal vector specular reflection
    N_sp_1 = getSurfaceNormal(V, Theta_sp.pos1, Phi_sp.sp1, Mask);
    N_sp_2 = getSurfaceNormal(V, Theta_sp.pos1, Phi_sp.sp3, Mask);
    N_sp_3 = getSurfaceNormal(V, Theta_sp.pos2, Phi_sp.sp1, Mask);
    N_sp_4 = getSurfaceNormal(V, Theta_sp.pos2, Phi_sp.sp3, Mask);
    N_sp_5 = getSurfaceNormal(V, Theta_sp.neg1, Phi_sp.sp2, Mask);
    N_sp_6 = getSurfaceNormal(V, Theta_sp.neg1, Phi_sp.sp4, Mask);
    N_sp_7 = getSurfaceNormal(V, Theta_sp.neg2, Phi_sp.sp2, Mask);
    N_sp_8 = getSurfaceNormal(V, Theta_sp.neg2, Phi_sp.sp4, Mask);
    error_N_angle_sp_1 = acos(min(max(sum(N_sp_1 .* N_desired, 3), -1), 1));
    error_N_angle_sp_2 = acos(min(max(sum(N_sp_2 .* N_desired, 3), -1), 1));
    error_N_angle_sp_3 = acos(min(max(sum(N_sp_3 .* N_desired, 3), -1), 1));
    error_N_angle_sp_4 = acos(min(max(sum(N_sp_4 .* N_desired, 3), -1), 1));
    error_N_angle_sp_5 = acos(min(max(sum(N_sp_5 .* N_desired, 3), -1), 1));
    error_N_angle_sp_6 = acos(min(max(sum(N_sp_6 .* N_desired, 3), -1), 1));
    error_N_angle_sp_7 = acos(min(max(sum(N_sp_7 .* N_desired, 3), -1), 1));
    error_N_angle_sp_8 = acos(min(max(sum(N_sp_8 .* N_desired, 3), -1), 1));
    error_N_angle_sp = min(cat(3, error_N_angle_sp_1, error_N_angle_sp_2, error_N_angle_sp_3, error_N_angle_sp_4, error_N_angle_sp_5, error_N_angle_sp_6, error_N_angle_sp_7, error_N_angle_sp_8), [], 3);
    figure('Position', [100, 100, 1050, 450]); subplot(1, 2, 1); imagesc(error_N_angle_sp); colormap(parula); colorbar; title('Perspective Specular Reflection N Angle');
    %% Check normal vector diffuse reflection
    N_dp_1 = getSurfaceNormal(V, Theta_dp.dp1, Phi_dp.dp1, Mask);
    N_dp_2 = getSurfaceNormal(V, Theta_dp.dp1, Phi_dp.dp2, Mask);
    error_N_angle_dp_1 = acos(min(max(sum(N_dp_1 .* N_desired, 3), -1), 1));
    error_N_angle_dp_2 = acos(min(max(sum(N_dp_2 .* N_desired, 3), -1), 1));
    error_N_angle_dp = min(cat(3, error_N_angle_dp_1, error_N_angle_dp_2), [], 3);
    subplot(1, 2, 2); imagesc(error_N_angle_dp); colormap(parula); colorbar; title('Perspective Diffuse Reflection N Angle');
%% Perspective Old
    %% Check Phi specular reflection
    Phi_sp_old = getAzimuthAngleSpecularReflection(PolarImage_sp, Mask);
    error_phi_sp_old = getAngleError(Phi_desired, Phi_sp_old);
    figure('Position', [100, 100, 1050, 450]); subplot(1, 2, 1); imagesc(error_phi_sp_old); colormap(parula); colorbar; title('Perspective Specular Reflection Old: err_{\phi}');
    %% Check Phi diffuse reflection
    Phi_dp_old = getAzimuthAngleDiffuseReflection(PolarImage_dp, Mask);
    error_phi_dp_old = getAngleError(Phi_desired, Phi_dp_old);
    subplot(1, 2, 2); imagesc(error_phi_dp_old); colormap(parula); colorbar; title('Perspective Diffuse Reflection Old: err_{\phi}');
    %% Check Theta specular reflection
    Theta_sp_old = getZenithAngleSpecularReflection(Rho_sp, Mask, Beta, eta);
    error_theta_sp_old = getAngleError(Theta_desired, Theta_sp_old);
    figure('Position', [100, 100, 1050, 450]); subplot(1, 2, 1); imagesc(error_theta_sp_old); colormap(parula); colorbar; title('Perspective Specular Reflection Old: err_{\theta}');
    %% Check Theta diffuse reflection
    Theta_dp_old = getZenithAngleDiffuseReflection(Rho_dp, Mask, Beta, eta);
    error_theta_dp_old = getAngleError(Theta_desired, Theta_dp_old);
    subplot(1, 2, 2); imagesc(error_theta_dp_old); colormap(parula); colorbar; title('Perspective Diffuse Reflection Old: err_{\theta}');
    %% Check normal vector specular reflection
    N_sp_1_old = getSurfaceNormal(V, Theta_sp_old.sp1, Phi_sp_old.sp1, Mask);
    N_sp_2_old = getSurfaceNormal(V, Theta_sp_old.sp2, Phi_sp_old.sp1, Mask);
    N_sp_3_old = getSurfaceNormal(V, Theta_sp_old.sp1, Phi_sp_old.sp2, Mask);
    N_sp_4_old = getSurfaceNormal(V, Theta_sp_old.sp2, Phi_sp_old.sp2, Mask);
    % check
    error_N_angle_sp_1_old = acos(min(max(sum(N_sp_1_old .* N_desired, 3), -1), 1));
    error_N_angle_sp_2_old = acos(min(max(sum(N_sp_2_old .* N_desired, 3), -1), 1));
    error_N_angle_sp_3_old = acos(min(max(sum(N_sp_3_old .* N_desired, 3), -1), 1));
    error_N_angle_sp_4_old = acos(min(max(sum(N_sp_4_old .* N_desired, 3), -1), 1));
    error_N_angle_sp_old = min(cat(3, error_N_angle_sp_1, error_N_angle_sp_2, error_N_angle_sp_3, error_N_angle_sp_4), [], 3);
    figure('Position', [100, 100, 1050, 450]); subplot(1, 2, 1); imagesc(error_N_angle_sp_old); colormap(parula); colorbar; title('Perspective Specular Reflection N Angle Old');
    %% Check normal vector diffuse reflection
    N_dp_1_old = getSurfaceNormal(V, Theta_dp_old.dp1, Phi_dp_old.dp1, Mask);
    N_dp_2_old = getSurfaceNormal(V, Theta_dp_old.dp1, Phi_dp_old.dp3, Mask);
    N_dp_3_old = getSurfaceNormal(V, Theta_dp_old.dp2, Phi_dp_old.dp2, Mask);
    N_dp_4_old = getSurfaceNormal(V, Theta_dp_old.dp2, Phi_dp_old.dp4, Mask);
    % check
    error_N_angle_dp_1_old = acos(min(max(sum(N_dp_1_old .* N_desired, 3), -1), 1));
    error_N_angle_dp_2_old = acos(min(max(sum(N_dp_2_old .* N_desired, 3), -1), 1));
    error_N_angle_dp_3_old = acos(min(max(sum(N_dp_3_old .* N_desired, 3), -1), 1));
    error_N_angle_dp_4_old = acos(min(max(sum(N_dp_4_old .* N_desired, 3), -1), 1));
    error_N_angle_dp_old = min(cat(3, error_N_angle_dp_1_old, error_N_angle_dp_2_old, error_N_angle_dp_3_old, error_N_angle_dp_4_old), [], 3);
    subplot(1, 2, 2); imagesc(error_N_angle_dp_old); colormap(parula); colorbar; title('Perspective Diffuse Reflection N Angle Old');
%% Orthographic
    %% Check Theta specular reflection
    Theta_sp_orth = getZenithAngleSpecularReflection_New(Rho_sp, Mask, Beta_orth, eta);
    error_theta_sp_orth = getAngleError(Theta_desired, Theta_sp_orth);
    figure('Position', [100, 100, 1050, 450]); subplot(1, 2, 1); imagesc(error_theta_sp_orth); colormap(parula); colorbar; title('Orthographic Specular Reflection: err_{\theta}');
    %% Check Theta diffuse reflection
    Theta_dp_orth = getZenithAngleDiffuseReflection_New(Rho_dp, Mask, Beta_orth, eta);
    error_theta_dp_orth = getAngleError(Theta_desired, Theta_dp_orth);
    subplot(1, 2, 2); imagesc(error_theta_dp_orth); colormap(parula); colorbar; title('Orthographic Diffuse Reflection: err_{\theta}');
    %% Check normal vector specular reflection
    N_sp_1_orth = getSurfaceNormal(V_orth, Theta_sp_orth.pos1, Phi_sp.sp1, Mask);
    N_sp_2_orth = getSurfaceNormal(V_orth, Theta_sp_orth.pos1, Phi_sp.sp3, Mask);
    N_sp_3_orth = getSurfaceNormal(V_orth, Theta_sp_orth.pos2, Phi_sp.sp1, Mask);
    N_sp_4_orth = getSurfaceNormal(V_orth, Theta_sp_orth.pos2, Phi_sp.sp3, Mask);
    N_sp_5_orth = getSurfaceNormal(V_orth, Theta_sp_orth.neg1, Phi_sp.sp2, Mask);
    N_sp_6_orth = getSurfaceNormal(V_orth, Theta_sp_orth.neg1, Phi_sp.sp4, Mask);
    N_sp_7_orth = getSurfaceNormal(V_orth, Theta_sp_orth.neg2, Phi_sp.sp2, Mask);
    N_sp_8_orth = getSurfaceNormal(V_orth, Theta_sp_orth.neg2, Phi_sp.sp4, Mask);
    error_N_angle_sp_1_orth = acos(min(max(sum(N_sp_1_orth .* N_desired, 3), -1), 1));
    error_N_angle_sp_2_orth = acos(min(max(sum(N_sp_2_orth .* N_desired, 3), -1), 1));
    error_N_angle_sp_3_orth = acos(min(max(sum(N_sp_3_orth .* N_desired, 3), -1), 1));
    error_N_angle_sp_4_orth = acos(min(max(sum(N_sp_4_orth .* N_desired, 3), -1), 1));
    error_N_angle_sp_5_orth = acos(min(max(sum(N_sp_5_orth .* N_desired, 3), -1), 1));
    error_N_angle_sp_6_orth = acos(min(max(sum(N_sp_6_orth .* N_desired, 3), -1), 1));
    error_N_angle_sp_7_orth = acos(min(max(sum(N_sp_7_orth .* N_desired, 3), -1), 1));
    error_N_angle_sp_8_orth = acos(min(max(sum(N_sp_8_orth .* N_desired, 3), -1), 1));
    error_N_angle_sp_orth = min(cat(3, error_N_angle_sp_1_orth, error_N_angle_sp_2_orth, error_N_angle_sp_3_orth, error_N_angle_sp_4_orth, error_N_angle_sp_5_orth, error_N_angle_sp_6_orth, error_N_angle_sp_7_orth, error_N_angle_sp_8_orth), [], 3);
    figure('Position', [100, 100, 1050, 450]); subplot(1, 2, 1); imagesc(error_N_angle_sp_orth); colormap(parula); colorbar; title('Orthographic Specular Reflection N Angle');
    %% Check normal vector diffuse reflection
    N_dp_1_orth = getSurfaceNormal(V_orth, Theta_dp_orth.dp1, Phi_dp.dp1, Mask);
    N_dp_2_orth = getSurfaceNormal(V_orth, Theta_dp_orth.dp1, Phi_dp.dp2, Mask);
    error_N_angle_dp_1_orth = acos(min(max(sum(N_dp_1_orth .* N_desired, 3), -1), 1));
    error_N_angle_dp_2_orth = acos(min(max(sum(N_dp_2_orth .* N_desired, 3), -1), 1));
    error_N_angle_dp_orth = min(cat(3, error_N_angle_dp_1_orth, error_N_angle_dp_2_orth), [], 3);
    subplot(1, 2, 2); imagesc(error_N_angle_dp_orth); colormap(parula); colorbar; title('Orthographic Diffuse Reflection N Angle');
%% Error statistics
error_phi_sp_mean = mean(error_phi_sp(:)) * 180 / pi;
error_phi_dp_mean = mean(error_phi_dp(:)) * 180 / pi;

error_theta_sp_mean = mean(error_theta_sp(:)) * 180 / pi;
error_theta_sp_old_mean = mean(error_theta_sp_old(:)) * 180 / pi;
error_theta_sp_mean_orth = mean(error_theta_sp_orth(:)) * 180 / pi;

error_theta_dp_mean = mean(error_theta_dp(:)) * 180 / pi;
error_theta_dp_old_mean = mean(error_theta_dp_old(:)) * 180 / pi;
error_theta_dp_mean_orth = mean(error_theta_dp_orth(:)) * 180 / pi;

error_N_angle_sp_mean = mean(error_N_angle_sp(:)) * 180 / pi;
error_N_angle_sp_old_mean = mean(error_N_angle_sp_old(:)) * 180 / pi;
error_N_angle_sp_orth_mean = mean(error_N_angle_sp_orth(:)) * 180 / pi;


error_N_angle_dp_mean = mean(error_N_angle_dp(:)) * 180 / pi;
error_N_angle_dp_old_mean = mean(error_N_angle_dp_old(:)) * 180 / pi;
error_N_angle_dp_orth_mean = mean(error_N_angle_dp_orth(:)) * 180 / pi;

fprintf('Specular error phi: %.3f\n', error_phi_sp_mean);
fprintf('Diffuse error phi: %.3f\n', error_phi_dp_mean);
fprintf('Specular mean error theta perspective new/old/orthographic: %.3f / %.3f / %.3f\n', error_theta_sp_mean, error_theta_sp_old_mean, error_theta_sp_mean_orth);
fprintf('Diffuse mean error theta perspective new/old/orthographic: %.3f / %.3f / %.3f\n', error_theta_dp_mean, error_theta_dp_old_mean, error_theta_dp_mean_orth);
fprintf('Specular mean error N angle perspective new/old/orthographic: %.3f / %.3f / %.3f\n', error_N_angle_sp_mean, error_N_angle_sp_old_mean, error_N_angle_sp_orth_mean);
fprintf('Diffuse mean error N angle perspective /new/old/orthographic: %.3f / %.3f / %.3f\n', error_N_angle_dp_mean, error_N_angle_dp_old_mean, error_N_angle_dp_orth_mean);
%%

function error_min = getAngleError(desired, estimate)
    fields = fieldnames(estimate);
    error_min = inf(size(desired));
    for i = 1:numel(fields)
        est_val = estimate.(fields{i});
        err = abs(desired - est_val);
        error_min = min(error_min, err);
    end

end

