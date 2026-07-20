%% Get zenith angle for the diffuse reflection
function Theta = getZenithAngleDiffuseReflection(Rho, Mask, Beta, eta)
    Theta.dp1 = NaN(size(Mask));
    Theta.dp2 = NaN(size(Mask));
    rho_valid = min(max(Rho(Mask), 0), 1);
    beta_valid = Beta(Mask);
    % rho > 0
    Lambda_dp_p = 1 ./ cos(beta_valid).^2 .* (1 + rho_valid) ./ (1 - rho_valid);
    Lambda_dp_p = max(Lambda_dp_p, 0);
    S_dp_p = sqrt(Lambda_dp_p);
    cos_theta_p = (eta - S_dp_p) ./ sqrt((S_dp_p.^2 - 1)*eta^2 + (S_dp_p - eta).^2);
    cos_theta_p = min(max(real(cos_theta_p), -1), 1);
    Theta.dp1(Mask) = acos(cos_theta_p);
    % rho < 0
    Lambda_dp_n = 1 ./ cos(beta_valid).^2 .* (1 - rho_valid) ./ (1 + rho_valid);
    Lambda_dp_n = max(Lambda_dp_n, 0);
    S_dp_n = sqrt(Lambda_dp_n);
    cos_theta_n = (eta - S_dp_n) ./ sqrt((S_dp_n.^2 - 1)*eta^2 + (S_dp_n - eta).^2);
    cos_theta_n = min(max(real(cos_theta_n), -1), 1);
    Theta.dp2(Mask) = acos(cos_theta_n);
end 