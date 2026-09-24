%% Get surface normal from diffuse reflection 
function N = getSurfaceNormalFromDiffuseReflection_Accurate(PolarImage_dp, Psi, Beta, V, eta, Mask)
    Phi_dp = getAzimuthAngleDiffuseReflection_Accurate(PolarImage_dp, Mask, Beta, Psi);
    Theta_dp = getZenithAngleDiffuseReflection_Accurate(PolarImage_dp, Mask, Beta, Psi, eta);
    N.dp1 = getSurfaceNormal(V, Theta_dp.dp1, Phi_dp.dp1, Mask);
    N.dp2 = getSurfaceNormal(V, Theta_dp.dp1, Phi_dp.dp2, Mask);
end