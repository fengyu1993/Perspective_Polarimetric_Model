%% Get surface normal from diffuse reflection 
function N = getSurfaceNormalFromDiffuseReflection(PolarImage_dp, Beta, V, eta, a, Mask)
    Phi_dp = getAzimuthAngleDiffuseReflection(PolarImage_dp, Mask);
    Rho_dp = getDoLP(PolarImage_dp, Mask);
    Theta_dp = getZenithAngleDiffuseReflection_New(Rho_dp ./ a, Mask, Beta, eta);
    N.dp1 = getSurfaceNormal(V, Theta_dp.dp1, Phi_dp.dp1, Mask);
    N.dp2 = getSurfaceNormal(V, Theta_dp.dp1, Phi_dp.dp2, Mask);
end