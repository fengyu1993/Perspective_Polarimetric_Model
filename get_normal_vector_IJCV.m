function n_est = get_normal_vector_IJCV(I_0, I_45, I_90, I_135, mask, rays)
%% A Geometric Model for Polarization Imaging on Projective Cameras
    mask = mask == 1;
    %% 计算旋转矩阵
    rays_reshaped = reshape(rays, [], 3);
    r_z = rays_reshaped(mask(:), :)';
    vx = VecToso3([0; 1; 0]) * r_z;
    columnNorms = vecnorm(vx, 2, 1);
    r_x = vx ./ columnNorms;
    r_y = cross(r_z, r_x, 1);
    R_list = cat(2, reshape(r_x, 3, 1, []), reshape(r_y, 3, 1, []), reshape(r_z, 3, 1, [])); 
    %% 计算P_a
    a_0 = [cos(0); sin(0); 0];
    a_45 = [cos(pi/4); sin(pi/4); 0];
    a_90 = [cos(pi/2); sin(pi/2); 0];
    a_135 = [cos(3*pi/4); sin(3*pi/4); 0];
    P_alpha_0 = squeeze(pagemtimes(a_0', R_list));   
    P_alpha_45 = squeeze(pagemtimes(a_45', R_list));  
    P_alpha_90 = squeeze(pagemtimes(a_90', R_list)); 
    P_alpha_135 = squeeze(pagemtimes(a_135', R_list)); 
    % 计算\hat{\alpha}_i
    t_alpha_0 = VecToso3([0; 0; 1]) * P_alpha_0;     t_alpha_0 = t_alpha_0 ./ vecnorm(t_alpha_0, 2, 1);
    t_alpha_45 = VecToso3([0; 0; 1]) * P_alpha_45;   t_alpha_45 = t_alpha_45 ./ vecnorm(t_alpha_45, 2, 1);
    t_alpha_90 = VecToso3([0; 0; 1]) * P_alpha_90;   t_alpha_90 = t_alpha_90 ./ vecnorm(t_alpha_90, 2, 1);
    t_alpha_135 = VecToso3([0; 0; 1]) * P_alpha_135; t_alpha_135 = t_alpha_135 ./ vecnorm(t_alpha_135, 2, 1);
    alpha_0_modify = atan2(t_alpha_0(2,:), t_alpha_0(1,:))';
    alpha_45_modify = atan2(t_alpha_45(2,:), t_alpha_45(1,:))';
    alpha_90_modify = atan2(t_alpha_90(2,:), t_alpha_90(1,:))';
    alpha_135_modify = atan2(t_alpha_135(2,:), t_alpha_135(1,:))';
    %% 计算修正后的S
    I_list =  [I_0(mask), I_45(mask), I_90(mask), I_135(mask)]';
    S_list = get_S_modify(I_list, alpha_0_modify, alpha_45_modify, alpha_90_modify, alpha_135_modify);   
    phi_list = 0.5 * atan2(S_list(3,:), S_list(2,:));
    A_list = reshape([sin(phi_list); cos(phi_list); zeros(size(phi_list))], 3, 1, []);
    M_list = squeeze(pagemtimes(R_list,  A_list))';
    %% 估计法向量
    n_est = normal_from_eigen(M_list);


end

function n_est = normal_from_eigen(M)
    MM = M' * M;
    [EV, ED] = eig(MM);
    EW = diag(ED);
    [~, min_idx] = min(EW);
    n = EV(:, min_idx);
    if n(3) > 0
        n_est = -n;
    else
        n_est = n;
    end
end

function S_list = get_S_modify(I_list, alpha_0_modify, alpha_45_modify, alpha_90_modify, alpha_135_modify)
        % 批量计算系数 (0.5 是原代码中的系数)
    c0 = 0.5 * cos(2 * alpha_0_modify');
    s0 = 0.5 * sin(2 * alpha_0_modify');
    c45 = 0.5 * cos(2 * alpha_45_modify');
    s45 = 0.5 * sin(2 * alpha_45_modify');
    c90 = 0.5 * cos(2 * alpha_90_modify');
    s90 = 0.5 * sin(2 * alpha_90_modify');
    c135 = 0.5 * cos(2 * alpha_135_modify');
    s135 = 0.5 * sin(2 * alpha_135_modify');
    
    % 构造 A'A 矩阵的元素 (3x3 对称矩阵)
    % m11 m12 m13
    % m12 m22 m23
    % m13 m23 m33
    N = length(c0);
    m11 = 4 * (0.5^2) * ones(1, N); % 每个像素都是 1.0
    m12 = 0.5 * (c0 + c45 + c90 + c135);
    m13 = 0.5 * (s0 + s45 + s90 + s135);
    m22 = c0.^2 + c45.^2 + c90.^2 + c135.^2;
    m23 = c0.*s0 + c45.*s45 + c90.*s90 + c135.*s135;
    m33 = s0.^2 + s45.^2 + s90.^2 + s135.^2;
    
    % 构造 A'I 向量的元素 (3x1)
    b1 = 0.5 * sum(I_list, 1);
    b2 = c0.*I_list(1,:) + c45.*I_list(2,:) + c90.*I_list(3,:) + c135.*I_list(4,:);
    b3 = s0.*I_list(1,:) + s45.*I_list(2,:) + s90.*I_list(3,:) + s135.*I_list(4,:);
    
    % 计算行列式 det(M)
    detM = m11.*(m22.*m33 - m23.^2) - ...
           m12.*(m12.*m33 - m23.*m13) + ...
           m13.*(m12.*m23 - m22.*m13);
    
    % 计算伴随矩阵的元素 (用于求逆)
    invM11 = (m22.*m33 - m23.^2) ./ detM;
    invM12 = (m13.*m23 - m12.*m33) ./ detM;
    invM13 = (m12.*m23 - m13.*m22) ./ detM;
    invM22 = (m11.*m33 - m13.^2) ./ detM;
    invM23 = (m12.*m13 - m11.*m23) ./ detM;
    invM33 = (m11.*m22 - m12.^2) ./ detM;
    
    % 最终解 S = inv(M) * B
    S_list = zeros(3, N);
    S_list(1,:) = invM11.*b1 + invM12.*b2 + invM13.*b3;
    S_list(2,:) = invM12.*b1 + invM22.*b2 + invM23.*b3;
    S_list(3,:) = invM13.*b1 + invM23.*b2 + invM33.*b3;
end