%% Get azimuth angle for the specular reflection
function Phi = getAzimuthAngleSpecularReflection(PolarImage, Mask)
    Phi_sp = zeros(size(Mask));
    Phi_sp(Mask) = 0.5 * atan2(PolarImage.I45(Mask) - PolarImage.I135(Mask) , ...
                     PolarImage.I0(Mask)  - PolarImage.I90(Mask)) + pi/2;
    Phi.sp1 = mod(Phi_sp, pi);
    Phi.sp2 = Phi.sp1 - pi;
end 