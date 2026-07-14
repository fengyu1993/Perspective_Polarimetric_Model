%% 仿真：法向量估计比较
clc; clear; close all;
rng(1);
%% Initialization
% configuration
Is = 2; Id = 3;
eta = 1.5; row = 1024; col = 1224;
K = [1232, 0, 612; 0, 1232, 512; 0, 0, 1]; 
mask = ones(row, col);  Mask = mask == 1;
% parameter
V = getViewingDirection(K, Mask);  
V_orth = zeros(row, col, 3); V_orth(:,:,3) = -1;
Beta = getPerspectiveDistortionAngle(V, Mask);
Beta_orth = zeros(size(Beta));
Psi = getPsiAngle(V, Mask);
% normal vector
Theta_desired = rand(row, col) * (pi/2); 
Phi_desired = rand(row, col) * 2 * pi - pi; 
N_desired = getSurfaceNormal(V, Theta_desired, Phi_desired, Mask);
%% Polarimetric Image 
Parameter_sp.Psi = Psi; Parameter_sp.Beta = Beta; Parameter_sp.eta = eta; Parameter_sp.Is = Is;
Parameter_dp.Psi = Psi; Parameter_dp.Beta = Beta; Parameter_dp.eta = eta; Parameter_dp.Id = Id;
% specular reflection
PolarImage_sp.I0 = getPolarimetricImageSpecularReflection(Phi_desired, Theta_desired, Parameter_sp, 0);
PolarImage_sp.I45 = getPolarimetricImageSpecularReflection(Phi_desired, Theta_desired, Parameter_sp, pi/4);
PolarImage_sp.I90 = getPolarimetricImageSpecularReflection(Phi_desired, Theta_desired, Parameter_sp, 2*pi/4);
PolarImage_sp.I135 = getPolarimetricImageSpecularReflection(Phi_desired, Theta_desired, Parameter_sp, 3*pi/4);
% diffuse reflection
PolarImage_dp.I0 = getPolarimetricImageDiffuseReflection(Phi_desired, Theta_desired, Parameter_dp, 0);
PolarImage_dp.I45 = getPolarimetricImageDiffuseReflection(Phi_desired, Theta_desired, Parameter_dp, pi/4);
PolarImage_dp.I90 = getPolarimetricImageDiffuseReflection(Phi_desired, Theta_desired, Parameter_dp, 2*pi/4);
PolarImage_dp.I135 = getPolarimetricImageDiffuseReflection(Phi_desired, Theta_desired, Parameter_dp, 3*pi/4);
%% Methods Specular Reflection
% Perspective 
N_sp = getSurfaceNormalFromSpecularReflection(PolarImage_sp, Beta, V, eta, Mask);
% Orthographic 
N_sp_orth = getSurfaceNormalFromSpecularReflection(PolarImage_sp, Beta_orth, V_orth, eta, Mask);
% IJCV 
N_sp_IJCV = getSurfaceNormalSpecularReflection_IJCV(PolarImage_sp, V, eta, Mask);
%% Methods Diffuse Reflection
% Perspective 
N_dp = getSurfaceNormalFromDiffuseReflection(PolarImage_dp, Beta, V, eta, Mask);
% Orthographic 
N_dp_orth = getSurfaceNormalFromDiffuseReflection(PolarImage_dp, Beta_orth, V_orth, eta, Mask);



%% Error analysis for specular reflection
% perspective
error_N_angle_sp = getErrorNormalAngle(N_sp, N_desired);
fig_N_sp = figure; ax_t_N_angle_sp1 = subplot(1, 3, 1); imagesc(error_N_angle_sp); colormap(parula); colorbar; title('Perspective Specular Reflection N Angle');
% orthographic
error_N_angle_sp_orth = getErrorNormalAngle(N_sp_orth, N_desired);
figure(fig_N_sp); ax_t_N_angle_sp2 = subplot(1, 3, 2); imagesc(error_N_angle_sp_orth); colormap(parula); colorbar; title('Orthographic Specular Reflection N Angle');
% IJCV
error_N_angle_sp_IJCV = getErrorNormalAngle(N_sp_IJCV, N_desired);
figure(fig_N_sp); ax_t_N_angle_sp3 = subplot(1, 3, 3); imagesc(error_N_angle_sp_IJCV); colormap(parula); colorbar; title('IJCV Specular Reflection N Angle');

%% Error analysis for diffuse reflection
% perspective
error_N_angle_dp = getErrorNormalAngle(N_dp, N_desired);
fig_N_dp = figure; ax_t_N_angle_dp1 = subplot(1, 2, 1); imagesc(error_N_angle_dp); colormap(parula); colorbar; title('Perspective Diffuse Reflection N Angle');
% orthographic
error_N_angle_dp_orth = getErrorNormalAngle(N_dp_orth, N_desired);
figure(fig_N_dp); ax_t_N_angle_dp2 = subplot(1, 2, 2); imagesc(error_N_angle_dp_orth); colormap(parula); colorbar; title('Orthographic Diffuse Reflection N Angle');
max_val = max([get(ax_t_N_angle_dp1, 'CLim'), get(ax_t_N_angle_dp2, 'CLim')]); set(ax_t_N_angle_dp1, 'CLim', [0, max_val]); set(ax_t_N_angle_dp2, 'CLim', [0, max_val]); 

%% Error statistics
error_N_angle_sp_mean = mean(error_N_angle_sp(:)) * 180 / pi; 
error_N_angle_sp_orth_mean = mean(error_N_angle_sp_orth(:)) * 180 / pi;
error_N_angle_sp_IJCV_mean = mean(error_N_angle_sp_IJCV(:)) * 180 / pi;
fprintf('Specular error N angle perspective/orthographic/IJCV: %.3f / %.3f / %.3f\n', error_N_angle_sp_mean, error_N_angle_sp_orth_mean, error_N_angle_sp_IJCV_mean);
error_N_angle_dp_mean = mean(error_N_angle_dp(:)) * 180 / pi; 
error_N_angle_dp_orth_mean = mean(error_N_angle_dp_orth(:)) * 180 / pi;
fprintf('Diffuse error N angle perspective/orthographic: %.3f / %.3f\n', error_N_angle_dp_mean, error_N_angle_dp_orth_mean);








