%% Formula Verification New Approximation Scale: Specular Reflection
clc; clear; close all;
rng(1);
%% Initialization
Is = 2;
Id = 3;
eta = 1.5;
beta = pi/3;
psi = pi/4;
Theta_desired = pi/5;
Phi_desired = pi/6;
fprintf('Ground truth: Theta = %.6f deg, Phi = %.6f deg\n', Theta_desired*180/pi, Phi_desired*180/pi);
%% Configuration
G = sqrt(eta^2 - sin(Theta_desired).^2);
% specular reflection
R_p = ((G - eta^2 * cos(Theta_desired)) ./ (G + eta^2 * cos(Theta_desired))).^2;
R_s = ((G - cos(Theta_desired)) ./ (G + cos(Theta_desired))).^2;
I_sp_max = R_s ./ (R_s + R_p) * Is;
I_sp_min = R_p ./ (R_s + R_p) * Is;
% Polarimetric image
I_sp_phipol = @(Phi_pol) ...
    I_sp_min .* (cos(beta).^2 .* cos(Phi_pol - Phi_desired) + sin(Phi_desired - psi) .* sin(beta).^2 .* sin(Phi_pol - psi)).^2 ./ (cos(beta).^2 + sin(beta).^2 .* sin(Phi_desired - psi).^2) ...
    + I_sp_max .* (cos(beta).^2 .* sin(Phi_pol - Phi_desired).^2) ./ (cos(beta).^2 + sin(beta).^2 .* sin(Phi_desired - psi).^2);
%% Image
% specular reflection
I_sp_0 = I_sp_phipol(0);         I_sp_45 = I_sp_phipol(pi/4);  
I_sp_90 = I_sp_phipol(pi/2);     I_sp_135 = I_sp_phipol(3*pi/4); 
I = [I_sp_0, I_sp_45, I_sp_90, I_sp_135];
% DoLP AoLP
S0 = sum(I)/2; S1 = I(1)-I(3); S2 = I(2)-I(4);
rho = hypot(S1,S2)/S0;
chi = 0.5*atan2(S2,S1);
%% Orthographic
phiOrth = mod(chi+pi/2,pi);
r = (1 - rho) / (1 + rho);
thetaOrth = get_theta(r, eta);
fprintf('Orthographic: Theta = %.6f / %.6f deg, Phi = %.6f deg\n', thetaOrth*180/pi, phiOrth*180/pi);
%% Approximate perspective 1
phiApproxPers_1 = mod(chi+pi/2,pi);
r = 1 / (cos(beta)^2) * (1 - rho) / (1 + rho);
thetaApproxPers_1 = get_theta(r, eta);  
fprintf('Approximate perspective 1: Theta = %.6f / %.6f deg, Phi = %.6f deg\n', thetaApproxPers_1*180/pi, phiApproxPers_1*180/pi);
%% Approximate perspective 2
phiApproxPers_2 = mod(chi+pi/2,pi);
r = 1/4 * (sec(beta) + cos(beta)).^2 * (1 - rho) / (1 + rho);
thetaApproxPers_2 = get_theta(r, eta);  
fprintf('Approximate perspective 2: Theta = %.6f / %.6f deg, Phi = %.6f deg\n', thetaApproxPers_2*180/pi, phiApproxPers_2*180/pi);
%% Perspective
c = cos(beta);
J = 0.5*[S0+S1, S2; S2, S0-S1];
R = [cos(psi), -sin(psi); sin(psi), cos(psi)];
Dinv = diag([1/c, 1]);
H = Dinv*R.'*J*R*Dinv;
H = (H+H.')/2;
[V, E] = eig(H);
[lambda, order] = sort(diag(E), 'ascend');
assert(lambda(1) >= -1e-10*max(lambda(2),realmin), ...
    'Recovered matrix is not positive semidefinite.');
lambda = max(lambda,0);
e_parallel = V(:,order(1)); % SPECULAR: I_parallel is the smaller value
gamma_parallel = atan2(e_parallel(2),e_parallel(1));
phiPers = mod(psi + atan2(c*sin(gamma_parallel), ...
    cos(gamma_parallel)), pi);
r = lambda(1)/lambda(2);
thetaPers = get_theta(r, eta);
fprintf('Perspective: Theta = %.6f / %.6f deg, Phi = %.6f deg\n', thetaPers*180/pi, phiPers*180/pi);


%%
function theta = get_theta(r, eta)
    s = [sqrt(r), -sqrt(r)];
    Xi = (1 - s) ./ (1 + s);
    cos2 = (2 + Xi.^2 * (eta^2 - 1) - Xi.*sqrt(Xi.^2 * (eta^2 - 1)^2 + 4*eta^2)) ./ (2 * (1 - Xi.^2));
    theta = sort(acos(sqrt(cos2)));   
end

































