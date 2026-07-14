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
    I_sp_phipol_fun = @(Phi_pol)...
        I_sp_min .* (cos(Beta).^2 .* cos(Phi_pol - Phi_desired) + sin(Phi_desired - Psi) .* sin(Beta).^2 .* sin(Phi_pol - Psi)).^2 ./ (cos(Beta).^2 + sin(Beta).^2 .* sin(Phi_desired - Psi).^2) ...
        + I_sp_max .* (cos(Beta).^2 .* sin(Phi_pol - Phi_desired).^2) ./ (cos(Beta).^2 + sin(Beta).^2 .* sin(Phi_desired - Psi).^2);
    I_sp_phipol.I0 = I_sp_phipol_fun(0);
    I_sp_phipol.I45 = I_sp_phipol_fun(pi/4);
    I_sp_phipol.I90 = I_sp_phipol_fun(pi/2);
    I_sp_phipol.I135 = I_sp_phipol_fun(3*pi/4);
end