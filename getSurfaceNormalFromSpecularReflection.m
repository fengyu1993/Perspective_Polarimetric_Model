%% Get surface normal from specular reflection 
function N = getSurfaceNormalFromSpecularReflection(PolarImage_sp, Beta, V, eta, a, Mask)
    Phi_sp = getAzimuthAngleSpecularReflection(PolarImage_sp, Mask);
    Rho_sp = getDoLP(PolarImage_sp, Mask);
    Theta_sp = getZenithAngleSpecularReflection(Rho_sp ./ a, Mask, Beta, eta);
    N.sp1 = getSurfaceNormal(V, Theta_sp.sp1, Phi_sp.sp1, Mask);
    N.sp2 = getSurfaceNormal(V, Theta_sp.sp2, Phi_sp.sp1, Mask);
    N.sp3 = getSurfaceNormal(V, Theta_sp.sp1, Phi_sp.sp2, Mask);
    N.sp4 = getSurfaceNormal(V, Theta_sp.sp2, Phi_sp.sp2, Mask);
end