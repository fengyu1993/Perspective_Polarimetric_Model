% Get surface normal
function N = getSurfaceNormal(V, Theta, Phi, Mask)
    Phi_valid = Phi(Mask);
    Theta_valid = Theta(Mask);
    Vx = V(:,:,1); Vy = V(:,:,2); Vz = V(:,:,3);
    V_valid = [Vx(Mask), Vy(Mask), Vz(Mask)];
    D = [cos(Phi_valid), sin(Phi_valid), zeros(length(Phi_valid), 1)];
    e_s = cross(V_valid, D, 2);
    e_s = e_s ./ sqrt(sum(e_s.^2, 2));
    e_p = cross(e_s, V_valid, 2);
    N_valid = V_valid .* cos(Theta_valid) + e_p .* sin(Theta_valid);
    [h, w] = size(Mask);
    Nx = NaN(h, w); Nx(Mask) = N_valid(:, 1); 
    Ny = NaN(h, w); Ny(Mask) = N_valid(:, 2); 
    Nz = NaN(h, w); Nz(Mask) = N_valid(:, 3); 
    N = cat(3, Nx, Ny, Nz);
end
