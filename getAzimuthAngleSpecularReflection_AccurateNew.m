%% Get azimuth angle for the specular reflection
function Phi = getAzimuthAngleSpecularReflection_AccurateNew(PolarImage, Mask, Beta, Psi)
    Phi.sp1 = NaN(size(Mask));
    Phi.sp2 = NaN(size(Mask));

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



    gamma_max = 0.5 * atan2(2*h12, h11-h22);
    gamma_parallel = gamma_max + pi/2;
    delta = atan2(c .* sin(gamma_parallel), cos(gamma_parallel));

    Phi.sp1(Mask) = mod(Psi + delta, pi);
    Phi.sp2(Mask)  = Phi.sp1(Mask) - pi;
end 
