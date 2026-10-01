%% Get polarimetric image specular reflection
function I_sp_phipol = getPolarimetricImageSpecularReflection(Phi_desired, Theta_desired, Parameter_sp)
    Psi = Parameter_sp.Psi; Beta = Parameter_sp.Beta; eta = Parameter_sp.eta; Is = Parameter_sp.Is;
    G = sqrt(eta^2 - sin(Theta_desired).^2);
    % specular reflection
    R_p = ((G - eta^2 * cos(Theta_desired)) ./ (G + eta^2 * cos(Theta_desired))).^2;
    R_s = ((G - cos(Theta_desired)) ./ (G + cos(Theta_desired))).^2;
    I_sp_max = R_s ./ (R_s + R_p) * Is;
    I_sp_min = R_p ./ (R_s + R_p) * Is;
    % function
    I_p = I_sp_min;
    I_s = I_sp_max;
    function I_pol = I_phipol_fun(Phi_pol)
        epsilon = Phi_pol - Psi;
        delta = Phi_desired - Psi; 
        q = cos(epsilon).^2 + cos(Beta).^2.*sin(epsilon).^2;
        L = sqrt(cos(Beta).^2 + sin(Beta).^2.*sin(delta).^2);
        cos_gamma_p = cos(Beta) .* cos(delta) ./ L;
        sin_gamma_p = sin(delta) ./ L;
        I_pol = I_p ./ q .* (cos_gamma_p .* cos(epsilon) + cos(Beta).*sin_gamma_p.*sin(epsilon)).^2 + ...
            I_s ./ q .* (sin_gamma_p .* cos(epsilon) - cos(Beta).*cos_gamma_p.*sin(epsilon)).^2; 
    end
    % output
    I_sp_phipol.I0 = I_phipol_fun(0);
    I_sp_phipol.I45 = I_phipol_fun(pi/4);
    I_sp_phipol.I90 = I_phipol_fun(pi/2);
    I_sp_phipol.I135 = I_phipol_fun(3*pi/4);
end