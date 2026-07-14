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
    [Phi_desired, Theta_desired, N_desired] = getPerspectivePlane(V, row, col, Mask);
elseif flag == 2 % hemisphere
    [Phi_desired, Theta_desired, N_desired] = getPerspectiveHemisphere(V, row, col, Mask);
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
fig_N_dp = figure; ax_t_N_angle_dp1 = subplot(1, 3, 1); imagesc(error_N_angle_dp); colormap(parula); colorbar; title('Perspective Diffuse Reflection N Angle');
% orthographic
error_N_angle_dp_orth = getErrorNormalAngle(N_dp_orth, N_desired);
figure(fig_N_dp); ax_t_N_angle_dp2 = subplot(1, 3, 2); imagesc(error_N_angle_dp_orth); colormap(parula); colorbar; title('Orthographic Diffuse Reflection N Angle');
% IJCV
error_N_angle_dp_IJCV = getErrorNormalAngle(N_dp_IJCV, N_desired);
figure(fig_N_dp); ax_t_N_angle_dp3 = subplot(1, 3, 3); imagesc(error_N_angle_dp_IJCV); colormap(parula); colorbar; title('IJCV Diffuse Reflection N Angle');
%% Error statistics
error_N_angle_sp_mean = mean(error_N_angle_sp(:)) * 180 / pi; 
error_N_angle_sp_orth_mean = mean(error_N_angle_sp_orth(:)) * 180 / pi;
error_N_angle_sp_IJCV_mean = mean(error_N_angle_sp_IJCV(:)) * 180 / pi;
fprintf('Specular error N angle perspective/orthographic/IJCV: %.3f / %.3f / %.3f\n', error_N_angle_sp_mean, error_N_angle_sp_orth_mean, error_N_angle_sp_IJCV_mean);
error_N_angle_dp_mean = mean(error_N_angle_dp(:)) * 180 / pi; 
error_N_angle_dp_orth_mean = mean(error_N_angle_dp_orth(:)) * 180 / pi;
error_N_angle_dp_IJCV_mean = mean(error_N_angle_dp_IJCV(:)) * 180 / pi;
fprintf('Diffuse error N angle perspective/orthographic/IJCV: %.3f / %.3f / %.3f\n', error_N_angle_dp_mean, error_N_angle_dp_orth_mean, error_N_angle_dp_IJCV_mean);
%% Save data
if flag == 1 % plane
    save('./Data/Data_SimulationPlane.mat', 'Beta', ...
            'error_N_angle_sp', 'error_N_angle_sp_orth', 'error_N_angle_sp_IJCV');

%     save('./Data/Data_SimulationPlane.mat', 'K', 'eta', 'Mask', 'Is', 'Id', 'Psi',...
%             'V', 'Beta', 'Phi_desired', 'Theta_desired', 'N_desired', 'PolarImage_sp', 'PolarImage_dp',...
%             'N_sp', 'N_sp_orth', 'N_sp_IJCV', 'N_dp', 'N_dp_orth', 'N_dp_IJCV', ...
%             'error_N_angle_sp', 'error_N_angle_sp_orth', 'error_N_angle_sp_IJCV');
elseif flag == 2 % hemisphere
     save('./Data/Data_SimulationHemisphere.mat', 'Beta', ...
            'error_N_angle_sp', 'error_N_angle_sp_orth', 'error_N_angle_sp_IJCV');   
    
%      save('./Data/Data_SimulationHemisphere.mat', 'K', 'eta', 'Mask', 'Is', 'Id', 'Psi',...
%             'V', 'Beta', 'Phi_desired', 'Theta_desired', 'N_desired', 'PolarImage_sp', 'PolarImage_dp',...
%             'N_sp', 'N_sp_orth', 'N_sp_IJCV', 'N_dp', 'N_dp_orth', 'N_dp_IJCV', ...
%             'error_N_angle_sp', 'error_N_angle_sp_orth', 'error_N_angle_sp_IJCV');   
elseif flag == 3 % random 
    save('./Data/Data_SimulationRandom.mat', 'Beta', ...
            'error_N_angle_sp', 'error_N_angle_sp_orth', 'error_N_angle_sp_IJCV');

%     save('./Data/Data_SimulationRandom.mat', 'K', 'eta', 'Mask', 'Is', 'Id', 'Psi',...
%             'V', 'Beta', 'Phi_desired', 'Theta_desired', 'N_desired', 'PolarImage_sp', 'PolarImage_dp',...
%             'N_sp', 'N_sp_orth', 'N_sp_IJCV', 'N_dp', 'N_dp_orth', 'N_dp_IJCV', ...
%             'error_N_angle_sp', 'error_N_angle_sp_orth', 'error_N_angle_sp_IJCV');
end




%%
function [Phi_desired, Theta_desired, N_desired] = getPerspectivePlane(V, row, col, Mask)
    N_valid = [-0.619067296067796;   0.587481181114258;  -0.521173238737279];
    N_valid = N_valid ./ norm(N_valid);
    Nx = zeros(row, col); Nx(Mask) = N_valid(1);
    Ny = zeros(row, col); Ny(Mask) = N_valid(2);
    Nz = zeros(row, col); Nz(Mask) = -abs(N_valid(3));
    N_desired = cat(3, Nx, Ny, Nz);
    [Phi_desired, Theta_desired] = getPhiTheta(N_desired, V, Mask);
end
function [Phi_desired, Theta_desired, N_desired] = getPerspectiveHemisphere(V, row, col, Mask)
% =========================================================================
    % 根据透视观察向量 V 和掩膜 Mask，生成期望的透视半球法向量和角度
    % =========================================================================
    
    %% 1. 获取从相机指向物体的光线方向 D
    % V 是从物体指向相机的观察向量，因此射线 D = -V
    D = -V; 
    
    %% 2. 利用 Mask 边界估算“视锥” (Viewing Cone) 的几何参数
    % 提取掩膜的边缘像素
    Bw = bwperim(Mask);
    
    % 分离 D 的三个通道 (利用二维 Mask 正确切片)
    Dx = D(:,:,1); 
    Dy = D(:,:,2); 
    Dz = D(:,:,3);
    
    % 获取边缘处的射线集合 (Nx3 矩阵)
    D_bnd = [Dx(Bw), Dy(Bw), Dz(Bw)];
    
    % 估算视锥的中心轴向 (即指向虚拟球心的射线)
    % 对于球体，其边缘射线的平均值极其逼近中心射线
    Dc = mean(D_bnd, 1);
    Dc = Dc / norm(Dc);
    
    % 估算视锥的张角 (Radius Angle) alpha
    dot_prods = D_bnd * Dc';
    alpha = mean(acos(min(max(dot_prods, -1), 1))); % 限制在[-1, 1]防浮点误差
    
    %% 3. 在虚拟空间中构建球体
    % 透视投影下，法向量与绝对尺度无关，我们假设球心在 Z = 1000 处
    Zc_virtual = 1000; 
    C = Zc_virtual * Dc;            % 虚拟球心坐标 (1x3)
    R = Zc_virtual * sin(alpha);    % 虚拟球体半径
    
    %% 4. 光线-球面相交 (Ray-Sphere Intersection) 反解 3D 坐标
    % 提取所有掩膜内的有效射线 (正确的一维切片)
    D_valid = [Dx(Mask), Dy(Mask), Dz(Mask)];
    
    % 解球面一元二次方程: t^2 - 2t(D·C) + |C|^2 - R^2 = 0
    b = -2 * (D_valid * C');
    c = norm(C)^2 - R^2;
    delta = b.^2 - 4*c;
    
    % 处理图像离散化造成的边缘伪影 (防止极少数边缘点 delta < 0 产生复数)
    delta(delta < 0) = 0; 
    
    % 解得光线到达球面的距离 t (取减号代表击中前半球)
    t = (-b - sqrt(delta)) / 2;
    
    % 获得掩膜内像素对应的真实三维交点 P
    P_valid = D_valid .* t;
    
    %% 5. 计算法向量 (N)
    N_valid = (P_valid - C) / R;
    % 强制归一化，确保绝对单位向量
    N_valid = N_valid ./ vecnorm(N_valid, 2, 2); 
    
    % 重建 Nx, Ny, Nz 图像矩阵
    Nx = zeros(row, col); Ny = zeros(row, col); Nz = zeros(row, col);
    Nx(Mask) = N_valid(:,1); 
    Ny(Mask) = N_valid(:,2); 
    Nz(Mask) = N_valid(:,3);
    N_desired = cat(3, Nx, Ny, Nz);
    
    %% 6. 计算透视天顶角 (Theta) 与 透视方位角 (Phi)
    % 修复越界报错: 提取 V 的三个通道，然后再用二维 Mask 进行索引
    Vx = V(:,:,1);
    Vy = V(:,:,2);
    Vz = V(:,:,3);
    V_valid = [Vx(Mask), Vy(Mask), Vz(Mask)];
    
    % (1) 透视天顶角 Theta: N 与 V 的夹角
    cos_theta = dot(N_valid, V_valid, 2);
    cos_theta = max(min(cos_theta, 1), -1);
    Theta_valid = acos(cos_theta);
    
    % (2) 透视方位角 Phi: 入射面与图像平面的交线
    Lx = V_valid(:,3).*N_valid(:,1) - N_valid(:,3).*V_valid(:,1);
    Ly = V_valid(:,3).*N_valid(:,2) - N_valid(:,3).*V_valid(:,2);
    Phi_valid = atan2(Ly, Lx);
    
    % 将计算结果映射回完整图像，背景填 NaN
    Theta_desired = NaN(row, col);
    Phi_desired = NaN(row, col);
    Theta_desired(Mask) = Theta_valid;
    Phi_desired(Mask) = Phi_valid;
end
function [Phi_desired, Theta_desired, N_desired] = getPerspectiveRand(V, row, col, Mask)
    rng(1);
    Theta_desired = rand(row, col) * (pi/2); 
    Phi_desired = rand(row, col) * 2 * pi - pi; 
    N_desired = getSurfaceNormal(V, Theta_desired, Phi_desired, Mask);
end

