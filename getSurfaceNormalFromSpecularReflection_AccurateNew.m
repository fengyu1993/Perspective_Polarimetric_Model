%% Get surface normal from specular reflection
function N = getSurfaceNormalFromSpecularReflection_AccurateNew(PolarImage, Psi, Beta, V, eta, a, Mask)

    Psi = Psi(Mask);
    Beta = Beta(Mask);

    c = cos(Beta);

    q = @(angle) cos(angle - Psi).^2 + c.^2 .* sin(angle - Psi).^2;
    I0   = q(0)        .* PolarImage.I0(Mask);
    I45  = q(pi/4)     .* PolarImage.I45(Mask);
    I90  = q(pi/2)     .* PolarImage.I90(Mask);
    I135 = q(3*pi/4)   .* PolarImage.I135(Mask);
    a0 = (I0 + I45 + I90 + I135) / 4;
    a1 = (I0 - I90) / 2;
    a2 = (I45 - I135) / 2;
    b1 =  a1 .* cos(2*Psi) + a2 .* sin(2*Psi);
    b2 = -a1 .* sin(2*Psi) + a2 .* cos(2*Psi);
    h11 = (a0 + b1);
    h12 = b2 ./ c;
    h22 = (a0 - b1)  ./ (c.^2);
    %% Phi
    Phi.sp1 = NaN(size(Mask));
    Phi.sp2 = NaN(size(Mask));

    gamma_max = 0.5 * atan2(2*h12, h11-h22);
    gamma_parallel = gamma_max + pi/2;
    delta = atan2(c .* sin(gamma_parallel), cos(gamma_parallel));

    Phi.sp1(Mask) = mod(Psi + delta, pi);
    Phi.sp2(Mask)  = Phi.sp1(Mask) - pi;
    %% Theta
    Theta.sp1 = NaN(size(Mask));
    Theta.sp2 = NaN(size(Mask));

    Rho_0 = sqrt(((h11 - h22).^2 + 4*h12.^2)) ./ (h11 + h22);
    Rho_0 = Rho_0 / a;
    
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

    %%
    N.sp1 = getSurfaceNormal(V, Theta.sp1, Phi.sp1, Mask);
    N.sp2 = getSurfaceNormal(V, Theta.sp1, Phi.sp2, Mask);
    N.sp3 = getSurfaceNormal(V, Theta.sp2, Phi.sp1, Mask);
    N.sp4 = getSurfaceNormal(V, Theta.sp2, Phi.sp2, Mask);
end