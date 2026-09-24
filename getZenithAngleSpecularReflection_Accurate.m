%% Get zenith angle for the specular reflection
function Theta = getZenithAngleSpecularReflection_Accurate(PolarImage, Mask, Beta, Psi, eta)
    Theta.sp1 = NaN(size(Mask));
    Theta.sp2 = NaN(size(Mask));
 
    Psi = Psi(Mask);
    Beta = Beta(Mask);

    a0 = (PolarImage.I0(Mask) + PolarImage.I45(Mask) + PolarImage.I90(Mask) + PolarImage.I135(Mask)) / 4;
    a1 = (PolarImage.I0(Mask) - PolarImage.I90(Mask)) / 2;
    a2 = (PolarImage.I45(Mask) - PolarImage.I135(Mask)) / 2;

    b1 =  a1 .* cos(2*Psi) + a2 .* sin(2*Psi);
    b2 = -a1 .* sin(2*Psi) + a2 .* cos(2*Psi);
    
    c = cos(Beta);

    h11 = (a0 + b1) ./ (c.^2);
    h12 = b2 ./ c;
    h22 = a0 - b1;

    flag = (h11 + h22) < 0;
    if sum(flag) > 1
        h11(flag)
        h22(flag)
    end

    Rho_0 = sqrt(((h11 - h22).^2 + 4*h12.^2)) ./ (h11 + h22);
    
    epsilon = 1e-12;
    rho_valid = min(max(Rho_0, 0), 1 - epsilon);

    Lambda_sp =  (1 - rho_valid) ./ (1 + rho_valid);
    Lambda_sp = max(Lambda_sp, 0);
   
    S_sp_1 = sqrt(Lambda_sp);
    S_sp_2 = -sqrt(Lambda_sp);

    Xi_1 = (1 - S_sp_1) ./ (1 + S_sp_1);
    Xi_2 = (1 - S_sp_2) ./ (1 + S_sp_2);

    brewster_cos2 = 1 / (1 + eta^2);
    solve_cos2 = @(Xi) (2 + Xi.^2 * (eta^2 - 1) - Xi.*sqrt(Xi.^2 * (eta^2 - 1)^2 + 4*eta^2)) ./ (2 * (1 - Xi.^2));
      
    function theta_val = compute_theta(Xi)
        inner = solve_cos2(Xi);
        inner(abs(abs(Xi) - 1) < epsilon) = brewster_cos2; 
        inner = min(max(inner, 0), 1); 
        theta_val = acos(sqrt(inner));
    end

    Theta.sp1(Mask) = compute_theta(Xi_1);
    Theta.sp2(Mask) = compute_theta(Xi_2);
end 


