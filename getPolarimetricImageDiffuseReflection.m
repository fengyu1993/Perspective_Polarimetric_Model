%% Get polarimetric image diffuse reflection
function I_dp_phipol = getPolarimetricImageDiffuseReflection(Phi_desired, Theta_desired, Parameter_dp)
    Psi = Parameter_dp.Psi; Beta = Parameter_dp.Beta; eta = Parameter_dp.eta; Id = Parameter_dp.Id;
    G = sqrt(eta^2 - sin(Theta_desired).^2);
    % diffuse reflection
    T_p = 4 * eta^2 * G .* cos(Theta_desired) ./ (G + eta^2 * cos(Theta_desired)).^2;
    T_s = 4 * G .* cos(Theta_desired) ./ (G + cos(Theta_desired)).^2;
    I_dp_max = T_p ./ (T_s + T_p) * Id;
    I_dp_min = T_s ./ (T_s + T_p) * Id;
    % function
    I_p = I_dp_max;
    I_s = I_dp_min;
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
    I_dp_phipol.I0 = I_phipol_fun(0);
    I_dp_phipol.I45 = I_phipol_fun(pi/4);
    I_dp_phipol.I90 = I_phipol_fun(pi/2);
    I_dp_phipol.I135 = I_phipol_fun(3*pi/4);
end