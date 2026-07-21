% Get perspective distortion angle
function Beta = getPerspectiveDistortionAngle(V, Mask)
    Beta = NaN(size(Mask));
    V_z = V(:, :, 3);
    Beta(Mask) = acos(abs(V_z(Mask)));
end