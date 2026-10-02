%% Experiment Ours vs. PPA
clc; clear; close all;
%%
PPA = load('./Data/Data_ExperimentPlanePPADataset_OursVsPPA.mat');
IJCV = load('./Data/Data_ExperimentPlaneIJCVDataset_OursVsPPA.mat');
error_data_PPA = [PPA.err_plot_Ours, PPA.err_plot_PPA, PPA.err_plot_Orth];
error_data_IJCV = [IJCV.err_plot_Ours, IJCV.err_plot_PPA, IJCV.err_plot_Orth];
%%
FontSize = 22;
LineWidth = 2;
Scale = 1;
Resolution = 300;
labels = {'Ours', 'PPA', 'Orth.'};
colors = [237, 33, 35;    % Ours
          72, 192, 170;   % PPA
          57, 83, 164] / 255; % Orth
%% Combined PPA and IJCV Datasets in ONE Axis (with Legend)
fig_Combined = figure('Position', [100, 100, 850, 420], 'Color', 'w'); 
hold on;
% 
[num_obs_PPA, num_methods] = size(error_data_PPA);
[num_obs_IJCV, ~] = size(error_data_IJCV);
% x pos
x_pos_PPA  = [1, 2, 3];
x_pos_IJCV = [5, 6, 7]; 
% PPA dataset
h_legend = gobjects(1, num_methods);
for i = 1:num_methods
    b1 = boxchart(x_pos_PPA(i) * ones(num_obs_PPA, 1), error_data_PPA(:, i));
    b1.BoxFaceColor = colors(i, :);
    b1.BoxFaceAlpha = 0.2;             
    b1.WhiskerLineColor = [0.1 0.1 0.1]; 
    b1.MarkerStyle = '.';                
    b1.MarkerColor = colors(i, :);       
    b1.LineWidth = 1.5;                  
    h_legend(i) = b1; 
end
% IJCV dataset
for i = 1:num_methods
    b2 = boxchart(x_pos_IJCV(i) * ones(num_obs_IJCV, 1), error_data_IJCV(:, i));
    b2.BoxFaceColor = colors(i, :);
    b2.BoxFaceAlpha = 0.2;             
    b2.WhiskerLineColor = [0.1 0.1 0.1]; 
    b2.MarkerStyle = '.';                
    b2.MarkerColor = colors(i, :);       
    b2.LineWidth = 1.5;                  
end
% Mid line
y_limits = [0.05, 100];
line([4, 4], y_limits, 'Color', [0.5 0.5 0.5], 'LineStyle', '--', 'LineWidth', LineWidth, 'HandleVisibility', 'off');
% x y lim
xlim([0, 8]); 
ylim(y_limits);
set(gca, 'YScale', 'log');
%  x=2 (PPA)  x=6 (IJCV)
set(gca, 'XTick', [2, 6], 'XTickLabel', {'PPA dataset', 'GMPC dataset'}, 'FontName', 'Times New Roman'); 
set(gca, 'TickDir', 'out', 'TickLength', [0.015 0.015]); 
set(gca, 'YGrid', 'on', 'YMinorGrid', 'off', 'XGrid', 'off');
set(gca, 'GridLineStyle', '--', 'GridAlpha', 0.4);

% Y轴对数上标的 LaTeX 渲染
set(gca, 'YTick', [10^-1, 10^0, 10^1, 10^2], 'FontSize', FontSize*Scale);
set(gca, 'YTickLabel', {'$10^{-1}$', '$10^0$', '$10^1$', '$10^2$'}, 'FontSize', FontSize*Scale);
set(gca, 'TickLabelInterpreter', 'latex');

% 5. 文字标注与图例 (Legend)
ylabel('Errors \Delta \gamma (\circ)', 'FontSize', FontSize*Scale, 'FontName', 'Times New Roman');

% 【新增】：创建图例，水平排列，并放置在正上方偏内的位置
lgd = legend(h_legend, labels, 'Location', 'northwest', 'Orientation', 'vertical', ...
    'FontSize', FontSize*Scale, 'FontName', 'Times New Roman');
% legend boxoff; % 去掉图例的黑框，显得更高级
set(gca, 'FontSize', FontSize*Scale, 'FontName', 'Times New Roman', 'LineWidth', LineWidth);

% 6. 关闭默认 box，手动绘制顶部和右侧无刻度黑线
set(gca, 'Box', 'off');
line([0, 8], [100, 100], 'Color', 'k', 'LineWidth', LineWidth, 'HandleVisibility', 'off');
line([8, 8], [0.05, 100], 'Color', 'k', 'LineWidth', LineWidth, 'HandleVisibility', 'off');


%% Output
errors = [error_data_PPA; error_data_IJCV];
err_Ours = errors(:,1);
err_PPA = errors(:,2);
err_Orth = errors(:,3);
fprintf("MAE Ours / PPA / Orth: %.2f, %.2f, %.2f\n", mean(err_Ours), mean(err_PPA), mean(err_Orth));
(mean(err_PPA) - mean(err_Ours)) / mean(err_PPA) * 100
(mean(err_Orth) - mean(err_Ours)) / mean(err_Orth) * 100
%% Save Figure
exportgraphics(fig_Combined, 'fig_Error_PlaneNormal_PPAIJCVDataset.png', 'Resolution', Resolution);


























