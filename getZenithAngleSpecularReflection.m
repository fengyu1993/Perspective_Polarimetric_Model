%% Get zenith angle for the specular reflection
function Theta = getZenithAngleSpecularReflection(Rho, Mask, Beta, eta)
    Theta.sp1 = zeros(size(Mask));
    Theta.sp2 = zeros(size(Mask));
    epsilon = 1e-8;
    % Lambda_sp
    rho_valid = min(max(Rho(Mask), 0), 1);
    beta_valid = Beta(Mask);
    Lambda_sp = 1 ./ cos(beta_valid).^2 .* (1 - rho_valid) ./ (1 + rho_valid);
    Lambda_sp = max(Lambda_sp, 0);
    % K
    S = sqrt(Lambda_sp);
    Xi_p = (1 - S) ./ (1 + S);
    Xi_n = (1 + S) ./ (1 - S);
    % cos\theta
    solve_cos2 = @(Xi) (2 + Xi.^2 * (eta^2 - 1) - Xi.*sqrt(Xi.^2 * (eta^2 - 1)^2 + 4*eta^2)) ./ (2 * (1 - Xi.^2));
    brewster_cos2 = 1 / (1 + eta^2);
    % 1st root
    inner_p = solve_cos2(Xi_p);
    inner_p(abs(Xi_p - 1) < epsilon) = brewster_cos2;
    inner_p = max(inner_p, 0);
    cos_theta_p = min(max(sqrt(inner_p), -1), 1);
    Theta.sp1(Mask) = acos(cos_theta_p);
    % 2nd root
    inner_n = solve_cos2(Xi_n);
    inner_n(abs(Xi_n - 1) < epsilon) = brewster_cos2; 
    inner_n = max(inner_n, 0);                    
    cos_theta_n = min(max(sqrt(inner_n), -1), 1);
    Theta.sp2(Mask) = acos(cos_theta_n);
end 
