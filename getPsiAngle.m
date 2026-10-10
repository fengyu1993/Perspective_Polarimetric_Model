%% Get psi angle
function Psi = getPsiAngle(V, Mask)
    Psi = NaN(size(Mask));
    V_x = V(:, :, 1);
    V_y = V(:, :, 2);
    Psi(Mask) = atan2(V_y(Mask), V_x(Mask));
    onAxis = Mask & (V_x == 0) & (V_y == 0);
    Psi(onAxis) = 0;
end