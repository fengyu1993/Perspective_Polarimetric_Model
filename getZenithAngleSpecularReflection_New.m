%% Get zenith angle for the specular reflection
function Theta = getZenithAngleSpecularReflection_New(Rho, Mask, Beta, eta)
    Theta.pos1 = NaN(size(Mask));
    Theta.pos2 = NaN(size(Mask));
    Theta.neg1 = NaN(size(Mask));
    Theta.neg2 = NaN(size(Mask));
    
    epsilon = 1e-12;
    rho_valid = min(max(Rho(Mask), 0), 1 - epsilon);
    beta_valid = Beta(Mask);

    Omega_beta = 1/4 * (sec(beta_valid) + cos(beta_valid)).^2;

    Lambda_sp_pos = 1 ./ Omega_beta .* (1 - rho_valid) ./ (1 + rho_valid);
    Lambda_sp_pos = max(Lambda_sp_pos, 0);
    Lambda_sp_neg = 1 ./ Omega_beta .* (1 + rho_valid) ./ (1 - rho_valid);
    Lambda_sp_neg = max(Lambda_sp_neg, 0);

    S_pos_1 = sqrt(Lambda_sp_pos);
    S_pos_2 = -sqrt(Lambda_sp_pos);
    S_neg_1 = sqrt(Lambda_sp_neg);
    S_neg_2 = -sqrt(Lambda_sp_neg);

    Xi_pos_1 = (1 - S_pos_1) ./ (1 + S_pos_1);
    Xi_pos_2 = (1 - S_pos_2) ./ (1 + S_pos_2);
    Xi_neg_1 = (1 - S_neg_1) ./ (1 + S_neg_1);
    Xi_neg_2 = (1 - S_neg_2) ./ (1 + S_neg_2);

    brewster_cos2 = 1 / (1 + eta^2);
    solve_cos2 = @(Xi) (2 + Xi.^2 * (eta^2 - 1) - Xi.*sqrt(Xi.^2 * (eta^2 - 1)^2 + 4*eta^2)) ./ (2 * (1 - Xi.^2));
      
    function theta_val = compute_theta(Xi)
        inner = solve_cos2(Xi);
        inner(abs(abs(Xi) - 1) < epsilon) = brewster_cos2; 
        inner = min(max(inner, 0), 1); 
        theta_val = acos(sqrt(inner));
    end

    Theta.pos1(Mask) = compute_theta(Xi_pos_1);
    Theta.pos2(Mask) = compute_theta(Xi_pos_2);
    Theta.neg1(Mask) = compute_theta(Xi_neg_1);
    Theta.neg2(Mask) = compute_theta(Xi_neg_2);

end 


