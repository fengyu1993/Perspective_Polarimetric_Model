%% zenith ambiguity in specular polarimetric shape recovery
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
rho_sp = zeros(1, N);
rho_sp_orth = zeros(1, N);
for i = 1 : N
    theta = theta_list(i);
    g = sqrt(eta^2 - sin(theta)^2);
    R_p = (g - eta^2*cos(theta))^2 / (g + eta^2*cos(theta))^2;
    R_s = (g - cos(theta))^2 / (g + cos(theta))^2;
    rho_sp(i) = (R_s - R_p*cos(beta)^2) / (R_s + R_p*cos(beta)^2);
    rho_sp_orth(i) = (R_s - R_p) / (R_s + R_p);
end
%% rho_sp -> theta
rho_val = 0.5;
Lambda_sp = 1 / cos(beta)^2 * (1 - rho_val) / (1 + rho_val);
S = [sqrt(Lambda_sp); -sqrt(Lambda_sp)];
K = (1 - S) ./ (1 + S);
cos_theta = sqrt((2 + K.^2 * (eta^2 - 1) - K.*sqrt(K.^2 * (eta^2 - 1)^2 + 4*eta^2)) ./ (2 * (1 - K.^2)));
theta_val = acos(cos_theta);
%% rho_sp_orth -> theta
Q_sp_orth = (1 - rho_val) / (1 + rho_val);
S_orth = [sqrt(Q_sp_orth); -sqrt(Q_sp_orth)];
K_orth = (1 - S_orth) ./ (1 + S_orth);
cos_theta_orth = sqrt((2 + K_orth.^2 * (eta^2 - 1) - K_orth.*sqrt(K_orth.^2 * (eta^2 - 1)^2 + 4*eta^2)) ./ (2 * (1 - K_orth.^2)));
theta_val_orth = acos(cos_theta_orth);
%% Brewster angle
theta_B = acos(1 / sqrt(1 + eta^2));
%% Plot
fig = figure; hold on; grid on; box on;
plot(theta_list, rho_sp,'-', 'Color', [0.4660 0.6740 0.1880], 'LineWidth', LineWidth);
plot(theta_list, rho_sp_orth,'--', 'Color', [0.4660 0.6740 0.1880], 'LineWidth', LineWidth);
plot(theta_list, rho_val*ones(1, length(theta_list)), ':', 'Color', [0.4 0.4 0.4], 'LineWidth', 2);
plot(theta_val, [rho_val, rho_val], 'r+', 'MarkerSize', 10, 'LineWidth', 3);
plot(theta_val_orth, [rho_val, rho_val], 'rx', 'MarkerSize', 10, 'LineWidth', 3);
axis([0, 1.6, 0, 1]);
set(gca,'xtick',0:0.4:1.6,'FontSize',FontSize,'FontName','Times New Roman');
yticks([0 0.25 0.5 0.75 1]);
set(gca,'FontSize',FontSize,'FontName','Times New Roman');
xlabel('Zenith angle $\theta$ (rad)','interpreter','latex', 'FontSize',FontSize);
ylabel('Degree of polarization', 'FontSize',FontSize);
set(gca,'LineWidth', LineWidth);
% Plot Brewster angle
plot(ones(N, 1) * theta_B, linspace(0, 1, N), '--', 'Color', [0.4 0.4 0.4], 'LineWidth', 2);
ax = gca;
current_ticks = ax.XTick;
[new_ticks, idx] = sort([current_ticks, theta_B]);
ax.XTick = new_ticks;
labels = cell(size(new_ticks));
for i = 1:length(new_ticks)
    if new_ticks(i) == theta_B
        labels{i} = '\theta_B'; 
    else
        labels{i} = num2str(new_ticks(i), '%.1f'); 
    end
end
ax.XTickLabel = labels;
legend('$\rho^{sp}$', '$\rho^{sp}_{orth}$','interpreter','latex', 'Location', 'northwest', 'FontSize',FontSize);
%% 
exportgraphics(fig, 'zenith_specular.png', 'Resolution', Resolution);

