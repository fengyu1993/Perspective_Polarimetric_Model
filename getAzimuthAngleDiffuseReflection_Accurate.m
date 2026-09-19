%% Get azimuth angle for the diffuse reflection
function Phi = getAzimuthAngleDiffuseReflection_Accurate(PolarImage, Mask, Beta, Psi)
    Phi.dp1 = NaN(size(Mask));
    Phi.dp2 = NaN(size(Mask));

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

    gamma_max = 0.5 * atan2(2*h12, h11-h22);
    gamma_parallel = gamma_max;
    delta = atan2(c .* sin(gamma_parallel), cos(gamma_parallel));

    Phi.dp1(Mask) = mod(Psi + delta, pi);
    Phi.dp2(Mask)  = Phi.dp1(Mask) - pi;
end 
