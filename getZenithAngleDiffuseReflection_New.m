%% Get zenith angle for the diffuse reflection
function Theta = getZenithAngleDiffuseReflection_New(Rho, Mask, Beta, eta)
    Theta.dp1 = NaN(size(Mask));
    epsilon = 1e-12;
    rho_valid = min(max(Rho(Mask), 0), 1 - epsilon);
    beta_valid = Beta(Mask);
    Omega_beta = 1/4 * (sec(beta_valid) + cos(beta_valid)).^2;
    Lambda_dp = (1 ./ Omega_beta) .* (1 + rho_valid) ./ (1 - rho_valid);
    S_dp = sqrt(Lambda_dp);
    S_dp = min(max(S_dp, 1), eta - epsilon);
    cos_theta = (eta - S_dp) ./ sqrt((S_dp.^2 - 1)*eta^2 + (S_dp - eta).^2);
    cos_theta = min(max(cos_theta, 0), 1);
    Theta.dp1(Mask) = acos(cos_theta);
end 