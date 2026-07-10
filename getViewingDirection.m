% Get light propagation direction
function V = getViewingDirection(K, Mask)  
    [h, w] = size(Mask);
    [U_coord, V_coord] = meshgrid(1:w, 1:h);
    u_valid = U_coord(Mask);
    v_valid = V_coord(Mask);

    P_pixels = [u_valid'; v_valid'; ones(1, length(u_valid))];
    P_norm = K \ P_pixels;
    vec_lengths = sqrt(sum(P_norm.^2, 1));
    V_valid = -P_norm ./ vec_lengths;
    
    Vx = zeros(h, w); Vx(Mask) = V_valid(1, :);
    Vy = zeros(h, w); Vy(Mask) = V_valid(2, :);
    Vz = zeros(h, w); Vz(Mask) = V_valid(3, :);
    
    V = cat(3, Vx, Vy, Vz);
end