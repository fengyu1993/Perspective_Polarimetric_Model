%% 仿真：法向量估计比较
clc; clear; close all;
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
flag = 3;
if flag == 1 % plane
    [Phi_desired, Theta_desired, N_desired, Mask] = getPerspectivePlane(V, row, col, K);
elseif flag == 2 % hemisphere
    [Phi_desired, Theta_desired, N_desired, Mask] = getPerspectiveHemisphere(V, row, col);
elseif flag == 3 % random 
    [Phi_desired, Theta_desired, N_desired] = getPerspectiveRand(V, row, col, Mask);
end
%% Polarimetric Image 
% specular reflection
Parameter_sp.Psi = Psi; Parameter_sp.Beta = Beta; Parameter_sp.eta = eta; Parameter_sp.Is = Is;
PolarImage_sp = getPolarimetricImageSpecularReflection(Phi_desired, Theta_desired, Parameter_sp);
% diffuse reflection
Parameter_dp.Psi = Psi; Parameter_dp.Beta = Beta; Parameter_dp.eta = eta; Parameter_dp.Id = Id;
PolarImage_dp = getPolarimetricImageDiffuseReflection(Phi_desired, Theta_desired, Parameter_dp);
%% Methods Specular Reflection
% Perspective 
N_sp = getSurfaceNormalFromSpecularReflection(PolarImage_sp, Beta, V, eta, Mask);
% Orthographic 
N_sp_orth = getSurfaceNormalFromSpecularReflection(PolarImage_sp, Beta_orth, V_orth, eta, Mask);
% IJCV 
N_sp_IJCV = getSurfaceNormalFromSpecularReflection_IJCV(PolarImage_sp, V, eta, Mask);
%% Methods Diffuse Reflection
% Perspective 
N_dp = getSurfaceNormalFromDiffuseReflection(PolarImage_dp, Beta, V, eta, Mask);
% Orthographic 
N_dp_orth = getSurfaceNormalFromDiffuseReflection(PolarImage_dp, Beta_orth, V_orth, eta, Mask);
% IJCV 
N_dp_IJCV = getSurfaceNormalFromDiffuseReflection_IJCV(PolarImage_dp, V, eta, Mask);
%% Error analysis for specular reflection
% perspective
error_N_angle_sp = getErrorNormalAngle(N_sp, N_desired, Mask);
fig_N_sp = figure; ax = subplot(1, 3, 1); h = imagesc(error_N_angle_sp); set(h, 'AlphaData', Mask); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Perspective Specular Reflection N Angle');
% orthographic
error_N_angle_sp_orth = getErrorNormalAngle(N_sp_orth, N_desired, Mask);
figure(fig_N_sp); ax = subplot(1, 3, 2); h = imagesc(error_N_angle_sp_orth); set(h, 'AlphaData', Mask); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Orthographic Specular Reflection N Angle');
% IJCV
error_N_angle_sp_IJCV = getErrorNormalAngle(N_sp_IJCV, N_desired, Mask);
figure(fig_N_sp); ax = subplot(1, 3, 3); h = imagesc(error_N_angle_sp_IJCV); set(h, 'AlphaData', Mask); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('IJCV Specular Reflection N Angle');
%% Error analysis for diffuse reflection
% perspective
error_N_angle_dp = getErrorNormalAngle(N_dp, N_desired, Mask);
fig_N_dp = figure; ax = subplot(1, 3, 1); h = imagesc(error_N_angle_dp); set(h, 'AlphaData', Mask); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Perspective Diffuse Reflection N Angle');
% orthographic
error_N_angle_dp_orth = getErrorNormalAngle(N_dp_orth, N_desired, Mask);
figure(fig_N_dp); ax = subplot(1, 3, 2); h = imagesc(error_N_angle_dp_orth); set(h, 'AlphaData', Mask); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Orthographic Diffuse Reflection N Angle');
% IJCV
error_N_angle_dp_IJCV = getErrorNormalAngle(N_dp_IJCV, N_desired, Mask);
figure(fig_N_dp); ax = subplot(1, 3, 3); h = imagesc(error_N_angle_dp_IJCV); set(h, 'AlphaData', Mask); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('IJCV Diffuse Reflection N Angle');
%% Plot 3D Shape
fig = figure; 
plot3DShape(fig, N_desired, Mask);
%% Error statistics
error_N_angle_sp_mean = mean(error_N_angle_sp(Mask)) * 180 / pi; 
error_N_angle_sp_orth_mean = mean(error_N_angle_sp_orth(Mask)) * 180 / pi;
error_N_angle_sp_IJCV_mean = mean(error_N_angle_sp_IJCV(Mask)) * 180 / pi;
fprintf('Specular error N angle perspective/orthographic/IJCV: %.3f / %.3f / %.3f\n', error_N_angle_sp_mean, error_N_angle_sp_orth_mean, error_N_angle_sp_IJCV_mean);
error_N_angle_dp_mean = mean(error_N_angle_dp(Mask)) * 180 / pi; 
error_N_angle_dp_orth_mean = mean(error_N_angle_dp_orth(Mask)) * 180 / pi;
error_N_angle_dp_IJCV_mean = mean(error_N_angle_dp_IJCV(Mask)) * 180 / pi;
fprintf('Diffuse error N angle perspective/orthographic/IJCV: %.3f / %.3f / %.3f\n', error_N_angle_dp_mean, error_N_angle_dp_orth_mean, error_N_angle_dp_IJCV_mean);
%% Save data
if flag == 1 % plane
    save('./Data/Data_SimulationPlane.mat', 'Beta', 'N_desired', ...
            'error_N_angle_sp', 'error_N_angle_sp_orth', 'Mask', 'error_N_angle_sp_IJCV', ...
            'error_N_angle_dp', 'error_N_angle_dp_orth', 'error_N_angle_dp_IJCV');

%     save('./Data/Data_SimulationPlane.mat', 'K', 'eta', 'Mask', 'Is', 'Id', 'Psi',...
%             'V', 'Beta', 'Phi_desired', 'Theta_desired', 'N_desired', 'PolarImage_sp', 'PolarImage_dp',...
%             'N_sp', 'N_sp_orth', 'N_sp_IJCV', 'N_dp', 'N_dp_orth', 'N_dp_IJCV', ...
%             'error_N_angle_sp', 'error_N_angle_sp_orth', 'error_N_angle_sp_IJCV', ...
%             'error_N_angle_dp', 'error_N_angle_dp_orth', 'error_N_angle_dp_IJCV');
% 
elseif flag == 2 % hemisphere
     save('./Data/Data_SimulationHemisphere.mat', 'Mask', 'Beta', 'N_desired', ...
            'error_N_angle_sp', 'error_N_angle_sp_orth', 'error_N_angle_sp_IJCV', ...
            'error_N_angle_dp', 'error_N_angle_dp_orth', 'error_N_angle_dp_IJCV');   
    
% %      save('./Data/Data_SimulationHemisphere.mat', 'K', 'eta', 'Mask', 'Is', 'Id', 'Psi',...
% %             'V', 'Beta', 'Phi_desired', 'Theta_desired', 'N_desired', 'PolarImage_sp', 'PolarImage_dp',...
% %             'N_sp', 'N_sp_orth', 'N_sp_IJCV', 'N_dp', 'N_dp_orth', 'N_dp_IJCV', ...
% %             'error_N_angle_sp', 'error_N_angle_sp_orth', 'error_N_angle_sp_IJCV', ...
% %             'error_N_angle_dp', 'error_N_angle_dp_orth', 'error_N_angle_dp_IJCV');  
elseif flag == 3 % random 
    save('./Data/Data_SimulationRandom.mat', 'Mask', 'Beta', 'N_desired', ...
            'error_N_angle_sp', 'error_N_angle_sp_orth', 'error_N_angle_sp_IJCV', ...
            'error_N_angle_dp', 'error_N_angle_dp_orth', 'error_N_angle_dp_IJCV');

% %     save('./Data/Data_SimulationRandom.mat', 'K', 'eta', 'Mask', 'Is', 'Id', 'Psi',...
% %             'V', 'Beta', 'Phi_desired', 'Theta_desired', 'N_desired', 'PolarImage_sp', 'PolarImage_dp',...
% %             'N_sp', 'N_sp_orth', 'N_sp_IJCV', 'N_dp', 'N_dp_orth', 'N_dp_IJCV', ...
% %             'error_N_angle_sp', 'error_N_angle_sp_orth', 'error_N_angle_sp_IJCV', ...
% %             'error_N_angle_dp', 'error_N_angle_dp_orth', 'error_N_angle_dp_IJCV');
end




%%
function [Phi_desired, Theta_desired, N_desired, Mask] = getPerspectivePlane(V, row, col, K)
    N_valid = [-0.619067296067796;   0.587481181114258;  -0.521173238737279];
    N_valid = N_valid ./ norm(N_valid);
    
    Zc = 1100;     
    Pc = [0; 0; Zc];   
    W = 1200;    
    H = 700;     

    temp_up = [0; -1; 0]; 
    U = cross(temp_up, N_valid); 
    U = U / norm(U);
    V_vec = cross(N_valid, U);
    V_vec = V_vec / norm(V_vec);
    
    P1 = Pc + (W/2)*U + (H/2)*V_vec;
    P2 = Pc - (W/2)*U + (H/2)*V_vec;
    P3 = Pc - (W/2)*U - (H/2)*V_vec;
    P4 = Pc + (W/2)*U - (H/2)*V_vec;
    Corners_3D = [P1, P2, P3, P4];
    
    Corners_2D = K * Corners_3D;
    x_pts = Corners_2D(1, :) ./ Corners_2D(3, :);
    y_pts = Corners_2D(2, :) ./ Corners_2D(3, :);

    Mask = poly2mask(x_pts, y_pts, row, col);

    Nx = zeros(row, col); Nx(Mask) = N_valid(1); Nx(~Mask) = NaN;
    Ny = zeros(row, col); Ny(Mask) = N_valid(2); Ny(~Mask) = NaN;
    Nz = zeros(row, col); Nz(Mask) = -abs(N_valid(3)); Nz(~Mask) = NaN;
    N_desired = cat(3, Nx, Ny, Nz);
    [Phi_desired, Theta_desired] = getPhiTheta(N_desired, V, Mask);
end
function [Phi_desired, Theta_desired, N_desired, Mask] = getPerspectiveHemisphere(V, row, col, Mask)

    [X_grid, Y_grid] = meshgrid(1:col, 1:row);
    center_x = col / 2;
    center_y = row / 2;
    radius = min(row, col) / 2 - 20; 
    Mask = ((X_grid - center_x).^2 + (Y_grid - center_y).^2) <= radius^2;

    D = -V; 
    Bw = bwperim(Mask);
    Dx = D(:,:,1); 
    Dy = D(:,:,2); 
    Dz = D(:,:,3);
    D_bnd = [Dx(Bw), Dy(Bw), Dz(Bw)];
    
    Dc = mean(D_bnd, 1);
    Dc = Dc / norm(Dc);
    
    dot_prods = D_bnd * Dc';
    alpha = mean(acos(min(max(dot_prods, -1), 1))); 
    
    Zc_virtual = 1000; 
    C = Zc_virtual * Dc;            
    R = Zc_virtual * sin(alpha);   
    
    D_valid = [Dx(Mask), Dy(Mask), Dz(Mask)];
    
    b = -2 * (D_valid * C');
    c = norm(C)^2 - R^2;
    delta = b.^2 - 4*c;
    
    delta(delta < 0) = 0; 
    
    t = (-b - sqrt(delta)) / 2;
    
    P_valid = D_valid .* t;
    
    N_valid = (P_valid - C) / R;
    N_valid = N_valid ./ vecnorm(N_valid, 2, 2); 
    Nx = zeros(row, col); Ny = zeros(row, col); Nz = zeros(row, col);
    Nx(Mask) = N_valid(:,1); 
    Ny(Mask) = N_valid(:,2); 
    Nz(Mask) = N_valid(:,3);
    N_desired = cat(3, Nx, Ny, Nz);
    
    Vx = V(:,:,1);
    Vy = V(:,:,2);
    Vz = V(:,:,3);
    V_valid = [Vx(Mask), Vy(Mask), Vz(Mask)];
    
    cos_theta = dot(N_valid, V_valid, 2);
    cos_theta = max(min(cos_theta, 1), -1);
    Theta_valid = acos(cos_theta);
    
    Lx = V_valid(:,3).*N_valid(:,1) - N_valid(:,3).*V_valid(:,1);
    Ly = V_valid(:,3).*N_valid(:,2) - N_valid(:,3).*V_valid(:,2);
    Phi_valid = atan2(Ly, Lx);
    
    Theta_desired = NaN(row, col);
    Phi_desired = NaN(row, col);
    Theta_desired(Mask) = Theta_valid;
    Phi_desired(Mask) = Phi_valid;
end
function [Phi_desired, Theta_desired, N_desired] = getPerspectiveRand(V, row, col, Mask)
    rng(2);

    Theta_raw = rand(row, col) * (pi/2); 
    Phi_raw = rand(row, col) * 2 * pi - pi; 
    
    sigma = 0.5; 
    Theta_desired = imgaussfilt(Theta_raw, sigma, 'Padding', 'replicate');
    Phi_desired   = imgaussfilt(Phi_raw, sigma, 'Padding', 'replicate');
    

    Theta_desired = min(max(Theta_desired, 0), pi/2);
    Phi_desired   = min(max(Phi_desired, -pi), pi);

    N_desired = getSurfaceNormal(V, Theta_desired, Phi_desired, Mask);

end

