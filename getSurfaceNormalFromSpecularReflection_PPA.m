function N = getSurfaceNormalFromSpecularReflection_PPA(polarImage, Mask, rays)
%% Perspective Phase Angle Model for Polarimetric 3D Reconstruction
    %% 计算M并估计法向量
    s_1 = polarImage.I0(Mask) - polarImage.I90(Mask);
    s_2 = polarImage.I45(Mask) - polarImage.I135(Mask);
    phi = 1/2 * atan2(s_2, s_1);
    phi_p = phi + pi/2;
    rays_reshaped = reshape(rays, [], 3);
    v = rays_reshaped(Mask(:), :)';
    M = [-v(3,:)'.*sin(phi_p), ...
        -v(3,:)'.*cos(phi_p), ...
        v(2,:)' .* cos(phi_p) + v(1,:)' .* sin(phi_p)];
    N = getNormalFromEigen(M);
end


