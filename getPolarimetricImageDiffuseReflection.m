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
    I_dp_phipol_fun = @(Phi_pol)...
        I_dp_max .* (cos(Beta).^2 .* cos(Phi_pol - Phi_desired) + sin(Phi_desired - Psi) .* sin(Beta).^2 .* sin(Phi_pol - Psi)).^2 ./ (cos(Beta).^2 + sin(Beta).^2 .* sin(Phi_desired - Psi).^2) ...
        + I_dp_min .* (cos(Beta).^2 .* sin(Phi_pol - Phi_desired).^2) ./ (cos(Beta).^2 + sin(Beta).^2 .* sin(Phi_desired - Psi).^2);
    I_dp_phipol.I0 = I_dp_phipol_fun(0);
    I_dp_phipol.I45 = I_dp_phipol_fun(pi/4);
    I_dp_phipol.I90 = I_dp_phipol_fun(pi/2);
    I_dp_phipol.I135 = I_dp_phipol_fun(3*pi/4);
end