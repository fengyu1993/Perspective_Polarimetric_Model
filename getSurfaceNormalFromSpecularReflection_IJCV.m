%% Get surface normal specular reflection IJCV Method
% A Geometric Model for Polarization Imaging on Projective Cameras
function N_IJCV = getSurfaceNormalFromSpecularReflection_IJCV(PolarImage_sp, V, eta, Mask)
    I_0 = PolarImage_sp.I0; I_45 = PolarImage_sp.I45; I_90 = PolarImage_sp.I90; I_135 = PolarImage_sp.I135;
    %% Step 2
    rays_reshaped = reshape(V, [], 3);
    r_z = rays_reshaped(Mask(:), :)';
    vx = VecToso3([0; 1; 0]) * r_z;
    columnNorms = vecnorm(vx, 2, 1);
    r_x = vx ./ columnNorms;
    r_y = cross(r_z, r_x, 1);
    R_list = cat(2, reshape(r_x, 3, 1, []), reshape(r_y, 3, 1, []), reshape(r_z, 3, 1, [])); 
    %% Step 3
    t = pi/2;
    a_0 = [cos(0 + t); sin(0 + t); 0];
    a_45 = [cos(pi/4 + t); sin(pi/4 + t); 0];
    a_90 = [cos(pi/2 + t); sin(pi/2 + t); 0];
    a_135 = [cos(3*pi/4 + t); sin(3*pi/4 + t); 0];
    P_alpha_0 = squeeze(pagemtimes(a_0', R_list));   
    P_alpha_45 = squeeze(pagemtimes(a_45', R_list));  
    P_alpha_90 = squeeze(pagemtimes(a_90', R_list)); 
    P_alpha_135 = squeeze(pagemtimes(a_135', R_list)); 
    t_alpha_0 = VecToso3([0; 0; 1]) * P_alpha_0;     t_alpha_0 = t_alpha_0 ./ vecnorm(t_alpha_0, 2, 1);
    t_alpha_45 = VecToso3([0; 0; 1]) * P_alpha_45;   t_alpha_45 = t_alpha_45 ./ vecnorm(t_alpha_45, 2, 1);
    t_alpha_90 = VecToso3([0; 0; 1]) * P_alpha_90;   t_alpha_90 = t_alpha_90 ./ vecnorm(t_alpha_90, 2, 1);
    t_alpha_135 = VecToso3([0; 0; 1]) * P_alpha_135; t_alpha_135 = t_alpha_135 ./ vecnorm(t_alpha_135, 2, 1);
    alpha_0_modify = atan2(t_alpha_0(2,:), t_alpha_0(1,:))';
    alpha_45_modify = atan2(t_alpha_45(2,:), t_alpha_45(1,:))';
    alpha_90_modify = atan2(t_alpha_90(2,:), t_alpha_90(1,:))';
    alpha_135_modify = atan2(t_alpha_135(2,:), t_alpha_135(1,:))';
    %% Step 4
    I_list =  [I_0(Mask), I_45(Mask), I_90(Mask), I_135(Mask)]';
    S_list = get_S_modify(I_list, alpha_0_modify, alpha_45_modify, alpha_90_modify, alpha_135_modify);   
    %% Step 5
    Phi_sp =  zeros(size(Mask));
    Rho_sp =  zeros(size(Mask));
    Phi_sp(Mask) = 0.5 * atan2(S_list(3,:), S_list(2,:)) + pi/2;
    Phi.sp1 = mod(Phi_sp, pi);
    Phi.sp2 = Phi.sp1 - pi;
    Rho_sp(Mask) = sqrt(S_list(2,:).^2 + S_list(3,:).^2) ./ S_list(1,:);
    Theta_sp = getZenithAngleSpecularReflection(Rho_sp, Mask, zeros(size(Mask)), eta);
    %% Step 6
    [row, col] = size(Mask);
    V_orth = zeros(row, col, 3); V_orth(:,:,3) = 1;
    N_sp_local_1 = getSurfaceNormal(V_orth, Theta_sp.sp1, Phi.sp1, Mask);
    N_sp_local_2 = getSurfaceNormal(V_orth, Theta_sp.sp2, Phi.sp1, Mask);
    N_sp_local_3 = getSurfaceNormal(V_orth, Theta_sp.sp1, Phi.sp2, Mask);
    N_sp_local_4 = getSurfaceNormal(V_orth, Theta_sp.sp2, Phi.sp2, Mask);   
    %% Step 7
    num_pixels = size(R_list, 3);
    N_loc_flat1 = reshape(N_sp_local_1(repmat(Mask, [1 1 3])), [], 3)'; 
    N_loc_flat2 = reshape(N_sp_local_2(repmat(Mask, [1 1 3])), [], 3)'; 
    N_loc_flat3 = reshape(N_sp_local_3(repmat(Mask, [1 1 3])), [], 3)'; 
    N_loc_flat4 = reshape(N_sp_local_4(repmat(Mask, [1 1 3])), [], 3)'; 
    N_loc_page1 = reshape(N_loc_flat1, 3, 1, num_pixels);
    N_loc_page2 = reshape(N_loc_flat2, 3, 1, num_pixels);
    N_loc_page3 = reshape(N_loc_flat3, 3, 1, num_pixels);
    N_loc_page4 = reshape(N_loc_flat4, 3, 1, num_pixels);
    N_glo_page1 = pagemtimes(R_list, N_loc_page1);
    N_glo_page2 = pagemtimes(R_list, N_loc_page2);
    N_glo_page3 = pagemtimes(R_list, N_loc_page3);
    N_glo_page4 = pagemtimes(R_list, N_loc_page4);
    N_IJCV.sp1 = zeros(row, col, 3); 
    N_IJCV.sp2 = zeros(row, col, 3);
    N_IJCV.sp3 = zeros(row, col, 3); 
    N_IJCV.sp4 = zeros(row, col, 3);
    N_IJCV.sp1(repmat(Mask, [1 1 3])) = reshape(squeeze(N_glo_page1)', [], 1);
    N_IJCV.sp2(repmat(Mask, [1 1 3])) = reshape(squeeze(N_glo_page2)', [], 1);
    N_IJCV.sp3(repmat(Mask, [1 1 3])) = reshape(squeeze(N_glo_page3)', [], 1);
    N_IJCV.sp4(repmat(Mask, [1 1 3])) = reshape(squeeze(N_glo_page4)', [], 1);
end







%%
function so3 = VecToso3(V)
    so3 = [0, -V(3), V(2); V(3), 0, -V(1); -V(2), V(1), 0];
end
function S_list = get_S_modify(I_list, alpha_0_modify, alpha_45_modify, alpha_90_modify, alpha_135_modify)
    c0 = 0.5 * cos(2 * alpha_0_modify');
    s0 = 0.5 * sin(2 * alpha_0_modify');
    c45 = 0.5 * cos(2 * alpha_45_modify');
    s45 = 0.5 * sin(2 * alpha_45_modify');
    c90 = 0.5 * cos(2 * alpha_90_modify');
    s90 = 0.5 * sin(2 * alpha_90_modify');
    c135 = 0.5 * cos(2 * alpha_135_modify');
    s135 = 0.5 * sin(2 * alpha_135_modify');
    % m11 m12 m13
    % m12 m22 m23
    % m13 m23 m33
    N = length(c0);
    m11 = 4 * (0.5^2) * ones(1, N); 
    m12 = 0.5 * (c0 + c45 + c90 + c135);
    m13 = 0.5 * (s0 + s45 + s90 + s135);
    m22 = c0.^2 + c45.^2 + c90.^2 + c135.^2;
    m23 = c0.*s0 + c45.*s45 + c90.*s90 + c135.*s135;
    m33 = s0.^2 + s45.^2 + s90.^2 + s135.^2;
    % A'I (3x1)
    b1 = 0.5 * sum(I_list, 1);
    b2 = c0.*I_list(1,:) + c45.*I_list(2,:) + c90.*I_list(3,:) + c135.*I_list(4,:);
    b3 = s0.*I_list(1,:) + s45.*I_list(2,:) + s90.*I_list(3,:) + s135.*I_list(4,:);
    % det(M)
    detM = m11.*(m22.*m33 - m23.^2) - ...
           m12.*(m12.*m33 - m23.*m13) + ...
           m13.*(m12.*m23 - m22.*m13);
    % inv(M)
    invM11 = (m22.*m33 - m23.^2) ./ detM;
    invM12 = (m13.*m23 - m12.*m33) ./ detM;
    invM13 = (m12.*m23 - m13.*m22) ./ detM;
    invM22 = (m11.*m33 - m13.^2) ./ detM;
    invM23 = (m12.*m13 - m11.*m23) ./ detM;
    invM33 = (m11.*m22 - m12.^2) ./ detM;
    % S = inv(M) * B
    S_list = zeros(3, N);
    S_list(1,:) = invM11.*b1 + invM12.*b2 + invM13.*b3;
    S_list(2,:) = invM12.*b1 + invM22.*b2 + invM23.*b3;
    S_list(3,:) = invM13.*b1 + invM23.*b2 + invM33.*b3;
end

%% Debug
%     num = 120;
%     R = R_list(:,:,num);
%     alpha_0 = 0; alpha_45 = pi/4; alpha_90 = pi/2; alpha_135 = 3*pi/4; 
%     P_0 = R' * [cos(alpha_0); sin(alpha_0); 0];
%     P_45 = R' * [cos(alpha_45); sin(alpha_45); 0];
%     P_90 = R' * [cos(alpha_90); sin(alpha_90); 0];
%     P_135 = R' * [cos(alpha_135); sin(alpha_135); 0];
%     Z = [0; 0; 1];
%     t_0 = cross(Z, P_0);
%     t_45 = cross(Z, P_45);
%     t_90 = cross(Z, P_90);
%     t_135 = cross(Z, P_135);
%     alpha_0_modify_num = atan2(t_0(2), t_0(1));
%     alpha_45_modify_num = atan2(t_45(2), t_45(1));
%     alpha_90_modify_num = atan2(t_90(2), t_90(1));
%     alpha_135_modify_num = atan2(t_135(2), t_135(1));
% 
%     alpha_0_modify_num - alpha_0_modify(num)
%     alpha_45_modify_num - alpha_45_modify(num)
%     alpha_90_modify_num - alpha_90_modify(num)
%     alpha_135_modify_num - alpha_135_modify(num)
% 
%     I_0_mask = I_0(Mask); I_45_mask = I_45(Mask); I_90_mask = I_90(Mask); I_135_mask = I_135(Mask); 
%     M = 0.5 * [1, cos(2*alpha_0_modify_num), sin(2*alpha_0_modify_num), 0;...
%                1, cos(2*alpha_45_modify_num), sin(2*alpha_45_modify_num), 0;...
%                1, cos(2*alpha_90_modify_num), sin(2*alpha_90_modify_num), 0;...
%                1, cos(2*alpha_135_modify_num), sin(2*alpha_135_modify_num), 0];
%     I = [I_0_mask(num); I_45_mask(num); I_90_mask(num); I_135_mask(num)];
%     S = pinv(M) * I;
%     S_list(:, num) - S(1:3)
% 
%     Phi_num = 0.5 * atan2(S(3), S(2));
%     Rho_num = sqrt(S(2)^2 + S(3)^2) / S(1);
%     Theta_num = getZenithAngleSpecularReflection(Rho_num, true, zeros(size(Mask)), eta);
%     Phi_num - Phi_sp(num, 1)
%     Rho_num - Rho_sp(num, 1)
%     Theta_num.sp1 - Theta_sp.sp1(num, 1)
%     Theta_num.sp2 - Theta_sp.sp2(num, 1)
% 
%     N_sp_local_1_num = getSurfaceNormal(V_orth(num, 1,:), Theta_num.sp1, Phi_num, true);
%     N_sp_local_2_num = getSurfaceNormal(V_orth(num, 1,:), Theta_num.sp2, Phi_num, true);
%     norm(squeeze(N_sp_local_1_num) - squeeze(N_sp_local_1(num, 1,:)))
%     norm(squeeze(N_sp_local_2_num) - squeeze(N_sp_local_2(num, 1,:)))
% 
%     N_sp_1_num = R_list(:, :, num) * squeeze(N_sp_local_1_num);
%     N_sp_2_num = R_list(:, :, num) * squeeze(N_sp_local_2_num);
%     norm(N_sp_1_num - squeeze(N_IJCV.sp1(num, 1, :)))
%     norm(N_sp_2_num - squeeze(N_IJCV.sp2(num, 1, :)))