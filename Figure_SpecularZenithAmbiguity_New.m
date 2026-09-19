%% zenith ambiguity in specular polarimetric shape recovery
clc;
clear;
close all;
%%
eta = 1.5;
beta = pi/3;
plotParameter.FontSize = 23;
plotParameter.LineWidth = 2;
plotParameter.Scale = 1.2;
plotParameter.Resolution = 300;
%%
N = 1000;
theta_list = linspace(0, pi/2, N);
rho_sp = zeros(1, N);
rho_sp_orth = zeros(1, N);
Omega_beta = 1/4 * (sec(beta) + cos(beta))^2;
for i = 1 : N
    theta = theta_list(i);
    g = sqrt(eta^2 - sin(theta)^2);
    R_p = (g - eta^2*cos(theta))^2 / (g + eta^2*cos(theta))^2;
    R_s = (g - cos(theta))^2 / (g + cos(theta))^2;
    rho_sp(i) = (R_s - R_p*Omega_beta) / (R_s + R_p*Omega_beta);
    rho_sp_orth(i) = (R_s - R_p) / (R_s + R_p);
end
%% rho_sp -> theta
rho_val = 0.5;
Lambda_sp = 1 / Omega_beta * (1 - rho_val) / (1 + rho_val);
S = [sqrt(Lambda_sp); -sqrt(Lambda_sp)];
Xi = (1 - S) ./ (1 + S);
cos_theta = sqrt((2 + Xi.^2 * (eta^2 - 1) - Xi.*sqrt(Xi.^2 * (eta^2 - 1)^2 + 4*eta^2)) ./ (2 * (1 - Xi.^2)));
theta_val = acos(cos_theta);
%% rho_sp_orth -> theta
Lambda_sp_orth = (1 - rho_val) / (1 + rho_val);
S_orth = [sqrt(Lambda_sp_orth); -sqrt(Lambda_sp_orth)];
Xi_orth = (1 - S_orth) ./ (1 + S_orth);
cos_theta_orth = sqrt((2 + Xi_orth.^2 * (eta^2 - 1) - Xi_orth.*sqrt(Xi_orth.^2 * (eta^2 - 1)^2 + 4*eta^2)) ./ (2 * (1 - Xi_orth.^2)));
theta_val_orth = acos(cos_theta_orth);
%% Brewster angle
theta_B = acos(1 / sqrt(1 + eta^2));
%% rad 2 deg
theta_list = rad2deg(theta_list);
theta_val = rad2deg(theta_val);
theta_val_orth = rad2deg(theta_val_orth);
theta_B = rad2deg(theta_B);
%% Plot
fig = figure('Position', [100, 100, 850, 450]); hold on; grid on; box on;
plot(theta_list, rho_sp,'-', 'Color', [0.4660 0.6740 0.1880], 'LineWidth', plotParameter.Scale * plotParameter.LineWidth);
plot(theta_list, rho_sp_orth,'--', 'Color', [0.4660 0.6740 0.1880], 'LineWidth', plotParameter.Scale * plotParameter.LineWidth);
plot(theta_list, rho_val*ones(1, length(theta_list)), ':', 'Color', [0.4 0.4 0.4], 'LineWidth', 2);
plot(theta_val, [rho_val, rho_val], 'r+', 'MarkerSize', 10, 'LineWidth', 3);
plot(theta_val_orth, [rho_val, rho_val], 'rx', 'MarkerSize', 10, 'LineWidth', 3);
axis([0, 90, 0, 1]);
set(gca,'xtick',0:30:90,'FontSize', plotParameter.Scale * plotParameter.FontSize,'FontName','Times New Roman');
yticks([0 0.25 0.5 0.75 1]);
set(gca,'FontSize', plotParameter.Scale * plotParameter.FontSize,'FontName','Times New Roman');
xlabel('Zenith angle $\theta$ ($^\circ$)','interpreter','latex', 'FontSize', plotParameter.Scale * plotParameter.FontSize);
ylabel('Degree of polarization', 'FontSize', plotParameter.Scale * plotParameter.FontSize);
set(gca,'LineWidth', plotParameter.Scale * plotParameter.LineWidth);
% Plot Brewster angle
plot(ones(N, 1) * theta_B, linspace(0, 1, N), '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 2);
ax = gca;
current_ticks = ax.XTick;
[new_ticks, idx] = sort([current_ticks, theta_B]);
ax.XTick = new_ticks;
labels = cell(size(new_ticks));
for i = 1:length(new_ticks)
    if new_ticks(i) == theta_B
        labels{i} = ''; 
    else
        labels{i} = ['  ', num2str(new_ticks(i), '%d')]; 
    end
end
ax.XTickLabel = labels;
text(theta_B - 4, +0.06, '$\theta_B$', 'Interpreter', 'latex', ...
    'FontSize', plotParameter.Scale * plotParameter.FontSize, 'HorizontalAlignment', 'center');
legend('$\rho^{sp}$', '$\rho^{sp}_{orth}$','interpreter','latex', 'Location', 'northwest', 'FontSize', plotParameter.Scale * plotParameter.FontSize);
%% 
exportgraphics(fig, 'fig_zenith_specular_new.png', 'Resolution', plotParameter.Resolution);


