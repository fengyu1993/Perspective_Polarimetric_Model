%% Get azimuth angle for the specular reflection
function Phi = getAzimuthAngleSpecularReflection_New(PolarImage, Mask)
    Phi_sp_raw = NaN(size(Mask));
    Phi_sp_raw(Mask) = 0.5 * atan2(PolarImage.I45(Mask) - PolarImage.I135(Mask) , ...
                     PolarImage.I0(Mask)  - PolarImage.I90(Mask)) + pi/2;
    Phi.sp1 = mod(Phi_sp_raw, pi);
    Phi.sp2 = mod(Phi_sp_raw + pi/2, pi);
    Phi.sp3 = Phi.sp1 - pi;
    Phi.sp4 = Phi.sp2 - pi;
end 