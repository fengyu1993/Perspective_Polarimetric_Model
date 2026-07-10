%% Get psi angle
function Psi = getPsiAngle(V, Mask)
    Psi = zeros(size(Mask));
    V_x = V(:, :, 1);
    V_y = V(:, :, 2);
    Psi(Mask) = atan2(-V_y, -V_x);
end