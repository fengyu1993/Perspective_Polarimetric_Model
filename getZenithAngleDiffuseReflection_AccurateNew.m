%% Get zenith angle for the diffuse reflection
function Theta = getZenithAngleDiffuseReflection_AccurateNew(PolarImage, Mask, Beta, Psi, eta, a)
    Theta.dp1 = NaN(size(Mask));
 
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

    Rho_0 = sqrt(((h11 - h22).^2 + 4*h12.^2)) ./ (h11 + h22);
    Rho_0  = Rho_0 / a;

    epsilon = 1e-12;
    rho_valid = min(max(Rho_0, 0), 1 - epsilon);

    Lambda_dp = (1 + rho_valid) ./ (1 - rho_valid);
    S_dp = sqrt(Lambda_dp);
    S_dp = min(max(S_dp, 1), eta - epsilon);
    cos_theta = (eta - S_dp) ./ sqrt((S_dp.^2 - 1)*eta^2 + (S_dp - eta).^2);
    cos_theta = min(max(cos_theta, 0), 1);
    Theta.dp1(Mask) = acos(cos_theta);
end 


