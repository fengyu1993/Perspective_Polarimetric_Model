%% Get surface normal from specular reflection
function N = getSurfaceNormalFromSpecularReflection_Accurate(PolarImage_sp, Psi, Beta, V, eta, Mask)
    Phi_sp = getAzimuthAngleSpecularReflection_Accurate(PolarImage_sp, Mask, Beta, Psi);    
    Theta_sp = getZenithAngleSpecularReflection_Accurate(PolarImage_sp, Mask, Beta, Psi, eta);
    N.sp1 = getSurfaceNormal(V, Theta_sp.sp1, Phi_sp.sp1, Mask);
    N.sp2 = getSurfaceNormal(V, Theta_sp.sp1, Phi_sp.sp2, Mask);
    N.sp3 = getSurfaceNormal(V, Theta_sp.sp2, Phi_sp.sp1, Mask);
    N.sp4 = getSurfaceNormal(V, Theta_sp.sp2, Phi_sp.sp2, Mask);
end