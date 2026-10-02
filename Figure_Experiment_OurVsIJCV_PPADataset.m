%% Experiment Our VS IJCV: PPA Dataset
clc; clear; close all;
%%
load('./Data/Data_ExperimentPlanePPADataset.mat');
S = load('./Data/Data_PPA_dataset_test_A_ETA.mat');
%%
FontSize = 23;
LineWidth = 2;
Scale = 1.2;
Resolution = 300;
%% Comparison across a and eta
A   = S.A;
ETA = S.ETA;

E_ours = S.error_all_N_angle;
E_gmpc = S.error_all_N_angle_IJCV;
E_orth = S.error_all_N_angle_orth;

errorsInRadians = true;   % Set false if already in degrees
if errorsInRadians
    E_ours = rad2deg(E_ours);
    E_gmpc = rad2deg(E_gmpc);
    E_orth = rad2deg(E_orth);
end

% Consistent method colors
colors = [237, 33, 35;     % Ours
           72, 192, 170;   % GMPC
           57, 83, 164] / 255; % Orth

cOurs = colors(1,:);
cGMPC = colors(2,:);
cOrth = colors(3,:);
%%
errors  = {E_ours, E_gmpc, E_orth};
methods = {'Ours', 'GMPC', 'Orth.'};
%
for k = 1:numel(errors)
    E = errors{k};

    valid = isfinite(E) & isfinite(A) & isfinite(ETA);
    idxValid = find(valid);

    if isempty(idxValid)
        fprintf('%s: No valid results.\n', methods{k});
        continue;
    end

    [minError, j] = min(E(idxValid));
    idxBest = idxValid(j);

    fprintf('%s: eta = %.6g, a = %.6g, MAE = %.6f deg\n', ...
        methods{k}, ETA(idxBest), A(idxBest), minError);
end
%
tol = 0;   % Degrees
D = E_gmpc - E_ours;

winner = nan(size(D));
winner(:) = 0;
winner(D >  tol) = -1;
winner(D < -tol) =  1;

flagWin = winner == -1;
flagFal = winner == 1;
fprintf("Ours winner: %.2f%%\n", sum(flagWin(:)) / (sum(flagWin(:)) + sum(flagFal(:))) * 100);
fprintf("GMPC winner: %.2f%%\n", sum(flagFal(:)) / (sum(flagWin(:)) + sum(flagFal(:))) * 100);
%
err_plot_ours_mean(id) = rad2deg(err_plot_ours_mean(id));
err_plot_IJCV_mean(id) = rad2deg(err_plot_IJCV_mean(id));
err_plot_orth_mean(id) = rad2deg(err_plot_orth_mean(id));
fprintf('Best eta and a: MAE: ours / IJCV / Orth: %.2f, %.2f %.2f\n', mean(err_plot_ours_mean(id)), mean(err_plot_IJCV_mean(id)), mean(err_plot_orth_mean(id)));
%% Figure 1: Three methods 
fig1 = figure('Color', 'w', 'Position', [100, 100, 850, 560]);
ax1 = axes(fig1);
hold(ax1, 'on');

h = gobjects(3, 1);

for k = 1:3
    E = errors{k};

    % Logarithmic axes require positive values
    E(~isfinite(E) | E <= 0) = NaN;

    h(k) = surf(ax1, A, ETA, E, ...
        'FaceColor', colors(k,:), ...
        'FaceAlpha', 0.5, ...
        'EdgeColor', colors(k,:), ...
        'EdgeAlpha', 0.5, ...
        'LineWidth', LineWidth);
end

xlabel(ax1, '$a$', 'Interpreter', 'latex', 'FontName', 'Times New Roman');
ylabel(ax1, '$\eta$', 'Interpreter', 'latex', 'FontName', 'Times New Roman');
zlabel(ax1, 'MAE $(^\circ)$', 'Interpreter', 'latex', 'FontName', 'Times New Roman');

legend(ax1, h, methods, 'Location', 'best');

view(ax1, -15, 20);
axis(ax1, 'tight');
xlim(ax1, [0.4, 0.8]); ylim(ax1, [1.4, 1.7]); zlim(ax1, [0, 20]);
xticks(ax1, 0.4:0.1:0.8); yticks(ax1, 1.4:0.1:1.7); zticks(ax1, 0:4:20);

grid(ax1, 'on');
box(ax1, 'on');

set(ax1, ...
        'FontName', 'Times New Roman', ...
        'FontSize', FontSize*Scale, ...
        'LineWidth', LineWidth, ...
        'LabelFontSizeMultiplier', 1, ...
        'TitleFontSizeMultiplier', 1);

set([ax1.XLabel, ax1.YLabel, ax1.ZLabel, ax1.Title], ...
        'FontSize', FontSize*Scale);
set(gca, 'Units', 'normalized');
ti = get(gca, 'TightInset'); 
set(gca, 'Position', [ti(1) ti(2) 1-ti(3)-ti(1) 1-ti(4)-ti(2)]);

exportgraphics(fig1, 'fig_eta_a_map_PPA_dataset_MAE.png', 'Resolution', Resolution);
%% Figure 2: Qualitative comparison of Ours and GMPC
fig2 = figure('Position', [100, 100, 850, 420], 'Color', 'w'); 
ax2 = axes(fig2);

% Discrete grid markers avoid interpolating categorical labels.
% Every square represents one evaluated parameter pair.

hold(ax2, 'on');

idxOurs = valid & winner == -1;
idxGMPC = valid & winner ==  1;
idxEqual = valid & winner == 0;

hOurs = scatter(ax2, A(idxOurs), ETA(idxOurs), ...
    65, cOurs, 's', 'filled');

hGMPC = scatter(ax2, A(idxGMPC), ETA(idxGMPC), ...
    65, cGMPC, 's', 'filled');

handles = [hOurs, hGMPC];
labels = {'Ours lower', 'GMPC lower'};

if any(idxEqual(:))
    hEqual = scatter(ax2, A(idxEqual), ETA(idxEqual), ...
        65, [0.75, 0.75, 0.75], 's', 'filled');

    handles(end+1) = hEqual;
    if tol == 0
        labels{end+1} = 'Equal';
    else
        labels{end+1} = 'Within tolerance';
    end
end

colorbar(ax2, 'off');

legend(ax2, handles, labels, ...
    'Location', 'northoutside', ...
    'Orientation', 'horizontal', ...
    'Box', 'off', ...
    'FontName', 'Times New Roman', ...
    'FontSize', FontSize*1.1);

caxis(ax2, [-1.5, 1.5]);

cb.Ticks = [-1, 0, 1];
if tol == 0
    cb.TickLabels = {'Ours lower', 'Equal', 'GMPC lower'};
else
    cb.TickLabels = {'Ours lower', 'Within tolerance', 'GMPC lower'};
end

xlabel(ax2, '$a$', 'Interpreter', 'latex');
ylabel(ax2, '$\eta$', 'Interpreter', 'latex');

% Add margins to prevent boundary markers from being clipped
aValues = A(valid);
etaValues = ETA(valid);
assert(~isempty(aValues), 'No jointly valid parameter pairs.');

aMargin = 0.01 * max(max(aValues) - min(aValues), eps);
etaMargin = 0.02 * max(max(etaValues) - min(etaValues), eps);

xlim(ax2, [0.4-aMargin,   0.8+aMargin]); ylim(ax2, [1.4-etaMargin, 1.7+etaMargin]);
xticks(ax2, 0.4:0.1:0.8); yticks(ax2, 1.4:0.1:1.7); 

box(ax2, 'on');
set(ax2, ...
        'FontName', 'Times New Roman', ...
        'FontSize', FontSize*Scale, ...
        'LineWidth', LineWidth, ...
        'LabelFontSizeMultiplier', 1, ...
        'TitleFontSizeMultiplier', 1);
set([ax2.XLabel, ax2.YLabel, ax2.ZLabel, ax2.Title], ...
        'FontSize', FontSize*Scale);
set(gca, 'Units', 'normalized');
ti = get(gca, 'TightInset'); 
set(gca, 'Position', [ti(1) ti(2) 1-ti(3)-ti(1) 1-ti(4)-ti(2)-0.2]);
exportgraphics(fig2, 'fig_eta_a_map_PPA_dataset_VS.png', 'Resolution', Resolution);

%% Error maps
[row, col] = size(err_plot_ours_mean);
% perspective
figPers = figure('Position', [100, 100, 620, 420]);
axPers = axes(figPers);
h = imagesc(err_plot_ours_mean); set(h, 'AlphaData', id); set(axPers, 'Color', 'w'); 
axis equal; axis([0, col, 0, row]);
set(gca, 'FontSize', FontSize * Scale*1.2, 'FontName', 'Times New Roman', 'LineWidth', LineWidth);
set(gca, 'XTick', []);
set(gca, 'YTick', []);
xtickangle(0);
colormap(axPers, parula); 
% colorbar(axPers); 
% orthographic 
figOrth = figure('Position', [100, 100, 620, 420]);
axOrth = axes(figOrth);
h = imagesc(err_plot_orth_mean); set(h, 'AlphaData', id); set(axOrth, 'Color', 'w'); 
axis equal; axis([0, col, 0, row]);
set(gca, 'FontSize', FontSize * Scale*1.2, 'FontName', 'Times New Roman', 'LineWidth', LineWidth);
set(gca, 'XTick', []);
set(gca, 'YTick', []);
xtickangle(0);
colormap(axOrth, parula); 
% colorbar(axOrth); 
% IJCV
figIJCV = figure('Position', [100, 100, 620, 420]);
axIJCV = axes(figIJCV);
h = imagesc(err_plot_IJCV_mean); set(h, 'AlphaData', id); set(axIJCV, 'Color', 'w'); 
axis equal; axis([0, col, 0, row]);
set(gca, 'FontSize', FontSize * Scale*1.2, 'FontName', 'Times New Roman', 'LineWidth', LineWidth);
set(gca, 'XTick', []);
set(gca, 'YTick', []);
xtickangle(0);
colormap(axIJCV, parula); 
% colorbar(axIJCV);  
% setup
climPers = get(axPers, 'CLim');
climOrth = get(axOrth, 'CLim');
climIJCV = get(axIJCV, 'CLim');
max_val = max([climPers(2), climOrth(2), climIJCV(2)]);
set(axIJCV, 'CLim', [0, max_val]);
set(axPers, 'CLim', [0, max_val]);
set(axOrth, 'CLim', [0, max_val]);
% bottom colorbar
figOrthBottom = figure('Position', [100, 100, 620, 420]);
axOrthBottom = axes(figOrthBottom);

h = imagesc(axOrthBottom, err_plot_orth_mean);
set(h, 'AlphaData', id);

axis(axOrthBottom, 'equal');
axis(axOrthBottom, [0, col, 0, row]);

set(axOrthBottom, ...
    'Color', 'w', ...
    'FontSize', FontSize * Scale * 1.2, ...
    'FontName', 'Times New Roman', ...
    'LineWidth', LineWidth, ...
    'XTick', [], ...
    'YTick', [], ...
    'CLim', [0, max_val]);

colormap(axOrthBottom, parula);

cb = colorbar(axOrthBottom, 'southoutside');
set(cb, ...
    'FontSize', FontSize * Scale * 1.2, ...
    'FontName', 'Times New Roman');
% save
exportgraphics(figPers, 'fig_PPA_dataset_Error_Normal_pers.png', 'Resolution', Resolution);
exportgraphics(figOrth, 'fig_PPA_dataset_Error_Normal_orth.png', 'Resolution', Resolution);
exportgraphics(figIJCV, 'fig_PPA_dataset_Error_Normal_IJCV.png', 'Resolution', Resolution);
exportgraphics(figOrthBottom, 'fig_PPA_dataset_Error_Normal_colorbar.png', 'Resolution', Resolution);
%%


