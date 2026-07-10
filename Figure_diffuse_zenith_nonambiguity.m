%% zenith in diffuse polarimetric shape recovery
clc;
clear;
close all;
%%
eta = 1.5;
beta = pi/6;
FontSize = 25;
LineWidth = 2.5;
Resolution = 300;
%%
N = 1000;
theta_list = linspace(0, pi/2, N);
rho_dp = zeros(1, N);
rho_dp_orth = zeros(1, N);
for i = 1 : N
    theta = theta_list(i);
    g = sqrt(eta^2 - sin(theta)^2);
    T_p = 4*eta^2*g*cos(theta) / (g + eta^2*cos(theta))^2;
    T_s = 4*g*cos(theta) / (g + cos(theta))^2;
    rho_dp(i) = (T_p*cos(beta)^2 - T_s) / (T_p*cos(beta)^2 + T_s);
    rho_dp_orth(i) = (T_p - T_s) / (T_p + T_s);
end
%% rho_dp -> theta
rho_val = 0.2;
Q_dp = 1 / cos(beta)^2 * (1 + rho_val) / (1 - rho_val);
S = sqrt(Q_dp);
cos_theta = (eta - S) / sqrt((S^2 - 1)*eta^2 + (S - eta)^2);
theta_val = acos(cos_theta);
%% rho_dp_orth -> theta
Q_dp_orth = (1 + rho_val) / (1 - rho_val);
S_orth = sqrt(Q_dp_orth);
cos_theta_orth = (eta - S_orth) / sqrt((S_orth^2 - 1)*eta^2 + (S_orth - eta)^2);
theta_val_orth = acos(cos_theta_orth);
%% 设置
fig = figure; hold on; grid on; box on;
plot(theta_list, rho_dp,'-', 'Color', [0.4940 0.1840 0.5560], 'LineWidth', LineWidth);
plot(theta_list, rho_dp_orth,'--', 'Color', [0.4940 0.1840 0.5560], 'LineWidth', LineWidth);
plot(theta_list, rho_val*ones(1, length(theta_list)), ':', 'Color', [0.4 0.4 0.4], 'LineWidth', 2);
plot(theta_val, [rho_val, rho_val], 'r+', 'MarkerSize', 10, 'LineWidth', 3);
plot(theta_val_orth, [rho_val, rho_val], 'rx', 'MarkerSize', 10, 'LineWidth', 3);
axis([0, 1.6, -0.2, 0.4]);
set(gca,'xtick',0:0.4:1.6,'FontSize',FontSize,'FontName','Times New Roman');
yticks([-0.2 0 0.2 0.4]);
% yticklabels({'-0.6','-0.3','0','0.3','0.6','1'})
set(gca,'FontSize',FontSize,'FontName','Times New Roman');
xlabel('Zenith angle $\theta$ (rad)','interpreter','latex', 'FontSize',FontSize);
ylabel('Degree of polarization', 'FontSize',FontSize);
set(gca,'LineWidth', LineWidth);
legend('$\rho^{dp}$', '$\rho^{dp}_{orth}$','interpreter','latex', 'Location', 'northwest', 'FontSize',FontSize);
%%
exportgraphics(fig, 'zenith_diffuse.png', 'Resolution', Resolution);
