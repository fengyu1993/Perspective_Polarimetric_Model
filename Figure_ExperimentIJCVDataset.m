%% Experiment IJCV Dataset
clc; clear; close all;
%%
load('./Data/Data_ExperimentPlaneIJCVDataset.mat');
%%
[row, col] = size(err_plot_mean);
plotParameter.FontSize = 23;
plotParameter.LineWidth = 2;
plotParameter.Scale = 1.2;
plotParameter.Resolution = 300;
%%
% perspective
figPers = figure('Position', [100, 100, 620, 420]);
ax = axes(figPers);
h = imagesc(err_plot_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'w'); 
axis equal; axis([0, col, 0, row]);
set(ax, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize', plotParameter.FontSize * plotParameter.Scale , 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth );
set(gca,'LineWidth', plotParameter.LineWidth );
xtickangle(0);
colormap(ax, parula); 
colorbar(ax); 
title('Ours', 'FontSize', plotParameter.FontSize * plotParameter.Scale, 'FontName', 'Times New Roman');
% orthographic 
figOrth = figure('Position', [100, 100, 620, 420]);
ax = axes(figOrth);
h = imagesc(err_plot_orth_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'w'); 
axis equal; axis([0, col, 0, row]);
set(ax, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize', plotParameter.FontSize * plotParameter.Scale , 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth );
set(gca,'LineWidth', plotParameter.LineWidth );
xtickangle(0);
colormap(ax, parula); 
colorbar(ax); 
title('Orth.', 'FontSize', plotParameter.FontSize * plotParameter.Scale, 'FontName', 'Times New Roman');
% IJCV
figIJCV = figure('Position', [100, 100, 620, 420]);
ax = axes(figIJCV);
h = imagesc(err_plot_IJCV_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'w'); 
axis equal; axis([0, col, 0, row]);
set(ax, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize', plotParameter.FontSize  * plotParameter.Scale, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth );
set(ax,'LineWidth', plotParameter.LineWidth );
xtickangle(0);
colormap(ax, parula); 
colorbar(ax); 
title('GMPC', 'FontSize', plotParameter.FontSize * plotParameter.Scale, 'FontName', 'Times New Roman');
%%
exportgraphics(figPers, 'fig_exp_IJCV_dataset_Error_Normal_pers.png', 'Resolution', plotParameter.Resolution);
exportgraphics(figOrth, 'fig_exp_IJCV_dataset_Error_Normal_orth.png', 'Resolution', plotParameter.Resolution);
exportgraphics(figIJCV, 'fig_exp_IJCV_dataset_Error_Normal_IJCV.png', 'Resolution', plotParameter.Resolution);






