%% Get phi theta from normal N 
function [Phi, Theta] = getPhiTheta(N, V, Mask)
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
    e_s_norm = sqrt(sum(e_s.^2, 2));
    hasAzimuth = e_s_norm > 1e-12;
    
    Phi_valid = NaN(size(dot_prod));
    
    Phi_valid(hasAzimuth) = atan2( ...
        -e_s(hasAzimuth, 1), e_s(hasAzimuth, 2));
    
    Phi(Mask) = Phi_valid;
end