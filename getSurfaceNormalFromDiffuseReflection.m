%% Get surface normal from diffuse reflection 
function N = getSurfaceNormalFromDiffuseReflection(PolarImage_dp, Beta, V, eta, Mask)
    Phi_dp = getAzimuthAngleDiffuseReflection(PolarImage_dp, Mask);
    Rho_dp = getDoLP(PolarImage_dp, Mask);
    Theta_dp = getZenithAngleDiffuseReflection(Rho_dp, Mask, Beta, eta);
    N.dp1 = getSurfaceNormal(V, Theta_dp.dp1, Phi_dp.dp1, Mask);
    N.dp2 = getSurfaceNormal(V, Theta_dp.dp1, Phi_dp.dp3, Mask);
    N.dp3 = getSurfaceNormal(V, Theta_dp.dp2, Phi_dp.dp2, Mask);
    N.dp4 = getSurfaceNormal(V, Theta_dp.dp2, Phi_dp.dp4, Mask);
end