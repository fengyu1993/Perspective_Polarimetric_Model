%% Get azimuth angle for the diffuse reflection
function Phi = getAzimuthAngleDiffuseReflection(PolarImage, Mask)
    Phi_dp_raw = NaN(size(Mask));
    Phi_dp_raw(Mask) = 0.5 * atan2(PolarImage.I45(Mask) - PolarImage.I135(Mask), ...
                     PolarImage.I0(Mask) - PolarImage.I90(Mask));
    Phi.dp1 = mod(Phi_dp_raw, pi); 
    Phi.dp2 = mod(Phi_dp_raw + pi/2, pi); 
    Phi.dp3 = Phi.dp1 - pi; 
    Phi.dp4 = Phi.dp2 - pi; 
end 