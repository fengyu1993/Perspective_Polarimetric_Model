%% Get phi theta from normal N (Returns physically valid N_new)
function [Phi, Theta, N_new] = getPhiTheta_New(N, V, Mask)
    Phi = NaN(size(Mask));
    Theta = NaN(size(Mask));
    
    Nx = N(:,:,1); Ny = N(:,:,2); Nz = N(:,:,3);
    N_valid = [Nx(Mask), Ny(Mask), Nz(Mask)];
    Vx = V(:,:,1); Vy = V(:,:,2); Vz = V(:,:,3);
    V_valid = [Vx(Mask), Vy(Mask), Vz(Mask)];
    
    dot_prod = sum(V_valid .* N_valid, 2);
    
    is_backfacing = dot_prod < 0;
    N_valid(is_backfacing, :) = -N_valid(is_backfacing, :);
    dot_prod(is_backfacing) = -dot_prod(is_backfacing); 
    
    dot_prod = min(max(dot_prod, 0), 1); 
    Theta_valid = acos(dot_prod);
    Theta(Mask) = Theta_valid;
    
    e_s = cross(V_valid, N_valid, 2);
    e_s_norm = max(sqrt(sum(e_s.^2, 2)), 1e-12);
    e_s = e_s ./ e_s_norm;
    Phi_valid = atan2(-e_s(:,1), e_s(:,2));
    
    Proj = N_valid - sum(N_valid .* V_valid, 2) .* V_valid;
    D1 = [cos(Phi_valid), sin(Phi_valid), zeros(length(Phi_valid), 1)];
    id = sum(Proj .* D1, 2) < 0;
    Phi_valid(id) = Phi_valid(id) + pi;
    
    Phi(Mask) = wrapToPi(Phi_valid);
    
    [h, w, ~] = size(N);
    Nx_new = NaN(h, w); Nx_new(Mask) = N_valid(:, 1);
    Ny_new = NaN(h, w); Ny_new(Mask) = N_valid(:, 2);
    Nz_new = NaN(h, w); Nz_new(Mask) = N_valid(:, 3);
    N_new = cat(3, Nx_new, Ny_new, Nz_new);
end