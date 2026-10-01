%% Simulation Random
clc; clear; close all;
%%
Random = load('./Data/Data_SimulationRandom.mat');
Hemisphere = load('./Data/Data_SimulationHemisphere.mat');
[row, col] = size(Random.Beta);
Random = Rad2Deg(Random);
%%
colors = [237, 33, 35; 57, 83, 164]/255;
plotParameter.FontSize = 23;
plotParameter.LineWidth = 2;
plotParameter.Scale = 1.2;
plotParameter.Resolution = 300;
%% 3D Shape
% Random
fig_3DRandom = figure; 
plot3DShape(fig_3DRandom, Random.N_desired, Random.Mask);
exportgraphics(fig_3DRandom, 'fig_3D_Random.png', 'Resolution', plotParameter.Resolution);
% Hemisphere
fig_3DHemisphere = figure; 
plot3DShape(fig_3DHemisphere, Hemisphere.N_desired, Hemisphere.Mask);
exportgraphics(fig_3DHemisphere, 'fig_3D_hemisphere.png', 'Resolution', plotParameter.Resolution);
%% Beta -- Error
num = 30;
% Random specular
[errorBetaRandomMean_sp, errorBetaRandomStd_sp, betaRandomList_sp] = getErrorBetaMeanStd_sp(Random, num);
figRandomMeanStd_sp = figure('Position', [100, 100, 750, 420]);  
plotBetaMeanStd(figRandomMeanStd_sp, errorBetaRandomMean_sp, errorBetaRandomStd_sp, betaRandomList_sp, colors, plotParameter);
axis([0 betaRandomList_sp(end) 0 40]);
set(gca, 'xtick', 0:15:45, 'ytick', 0:10:40, 'FontSize', plotParameter.FontSize*plotParameter.Scale*1.2, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth);
exportgraphics(figRandomMeanStd_sp, 'fig_Error_Beta_Normal_Angle_Random_Specular.png', 'Resolution', plotParameter.Resolution);
% Random diffuse
[errorBetaRandomMean_dp, errorBetaRandomStd_dp, betaRandomList_dp] = getErrorBetaMeanStd_dp(Random, num);
figRandomMeanStd_dp = figure('Position', [100, 100, 750, 420]);  
plotBetaMeanStd(figRandomMeanStd_dp, errorBetaRandomMean_dp, errorBetaRandomStd_dp, betaRandomList_dp, colors, plotParameter);
axis([0 betaRandomList_dp(end) 0 60]);
set(gca, 'xtick', 0:15:45, 'ytick', 0:20:60, 'FontSize', plotParameter.FontSize*plotParameter.Scale*1.2, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth);
exportgraphics(figRandomMeanStd_dp, 'fig_Error_Beta_Normal_Angle_Random_Diffuse.png', 'Resolution', plotParameter.Resolution);
%% Random specular
% perspective
figRandomPers = figure('Position', [100, 100, 620, 420]);
axPers = axes(figRandomPers);
h = imagesc(Random.error_N_angle_sp); set(h, 'AlphaData', Random.Mask); set(axPers, 'Color', 'w'); 
axis equal; axis([0, col, 0, row]);
set(gca, 'FontSize', plotParameter.FontSize * plotParameter.Scale*1.2, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth);
set(gca, 'XTick', []);
set(gca, 'YTick', []);
set(gca,'LineWidth', plotParameter.LineWidth );
xtickangle(0);
colormap(axPers, parula); 
colorbar(axPers); 
% orthographic 
figRandomOrth = figure('Position', [100, 100, 620, 420]);
axOrth = axes(figRandomOrth);
h = imagesc(Random.error_N_angle_sp_orth); set(h, 'AlphaData', Random.Mask); set(axOrth, 'Color', 'w'); 
axis equal; axis([0, col, 0, row]);
set(gca, 'FontSize', plotParameter.FontSize * plotParameter.Scale*1.2, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth);
set(gca, 'XTick', []);
set(gca, 'YTick', []);
xtickangle(0);
colormap(axOrth, parula); 
colorbar(axOrth); 
% setup
climPers = get(axPers, 'CLim');
climOrth = get(axOrth, 'CLim');
max_val = max([climPers(2), climOrth(2)]);
set(axPers, 'CLim', [0, max_val]);
set(axOrth, 'CLim', [0, max_val]);
% output
exportgraphics(figRandomPers, 'fig_Error_Normal_Random_Specular_pers.png', 'Resolution', plotParameter.Resolution);
exportgraphics(figRandomOrth, 'fig_Error_Normal_Random_Specular_orth.png', 'Resolution', plotParameter.Resolution);
%% Random diffuse
% perspective
figRandomPers = figure('Position', [100, 100, 620, 420]);
axPers = axes(figRandomPers);
h = imagesc(Random.error_N_angle_dp); set(h, 'AlphaData', Random.Mask); set(axPers, 'Color', 'w'); 
axis equal; axis([0, col, 0, row]);
set(gca, 'FontSize', plotParameter.FontSize * plotParameter.Scale*1.2, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth);
set(gca, 'XTick', []);
set(gca, 'YTick', []);
xtickangle(0);
colormap(axPers, parula); 
colorbar(axPers); 
% orthographic 
figRandomOrth = figure('Position', [100, 100, 620, 420]);
axOrth = axes(figRandomOrth);
h = imagesc(Random.error_N_angle_dp_orth); set(h, 'AlphaData', Random.Mask); set(axOrth, 'Color', 'w'); 
axis equal; axis([0, col, 0, row]);
set(gca, 'FontSize', plotParameter.FontSize * plotParameter.Scale*1.2, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth);
set(gca, 'XTick', []);
set(gca, 'YTick', []);
xtickangle(0);
colormap(axOrth, parula); 
colorbar(axOrth); 
% setup
climPers = get(axPers, 'CLim');
climOrth = get(axOrth, 'CLim');
max_val = max([climPers(2), climOrth(2)]);
set(axPers, 'CLim', [0, max_val]);
set(axOrth, 'CLim', [0, max_val]);
% output
exportgraphics(figRandomPers, 'fig_Error_Normal_Random_Diffuse_pers.png', 'Resolution', plotParameter.Resolution);
exportgraphics(figRandomOrth, 'fig_Error_Normal_Random_Diffuse_orth.png', 'Resolution', plotParameter.Resolution);

%%
function [errorBetaMean, errorBetaStd, betaList] = getErrorBetaMeanStd_sp(Data, num)
    beta = Data.Beta(Data.Mask);
    maxBeta = max(beta);
    betaList = linspace(0, maxBeta, num);
    errorBetaMean.Peri = zeros(1, num-1); errorBetaStd.Peri = zeros(1, num-1);
    errorBetaMean.Orth = zeros(1, num-1); errorBetaStd.Orth = zeros(1, num-1);
    errorBetaMean.IJCV = zeros(1, num-1); errorBetaStd.IJCV = zeros(1, num-1);
    betaDown = 0;
    err_sp = Data.error_N_angle_sp(Data.Mask);
    err_sp_orth = Data.error_N_angle_sp_orth(Data.Mask);
    err_sp_IJCV = Data.error_N_angle_sp_IJCV(Data.Mask);
    for i = 2 : num
        betaUp = betaList(i);
        mask = (beta >= betaDown) & (beta < betaUp);
        errorBetaMean.Peri(i-1) = mean(err_sp(mask));
        errorBetaStd.Peri(i-1) = std(err_sp(mask));
        errorBetaMean.Orth(i-1) = mean(err_sp_orth(mask));
        errorBetaStd.Orth(i-1) = std(err_sp_orth(mask));    
        errorBetaMean.IJCV(i-1) = mean(err_sp_IJCV(mask));
        errorBetaStd.IJCV(i-1) = std(err_sp_IJCV(mask));   
        betaDown = betaUp;
    end   
end
function [errorBetaMean, errorBetaStd, betaList] = getErrorBetaMeanStd_dp(Data, num)
    beta = Data.Beta(Data.Mask);
    maxBeta = max(beta);
    betaList = linspace(0, maxBeta, num);
    errorBetaMean.Peri = zeros(1, num-1); errorBetaStd.Peri = zeros(1, num-1);
    errorBetaMean.Orth = zeros(1, num-1); errorBetaStd.Orth = zeros(1, num-1);
    errorBetaMean.IJCV = zeros(1, num-1); errorBetaStd.IJCV = zeros(1, num-1);
    betaDown = 0;
    err_dp = Data.error_N_angle_dp(Data.Mask);
    err_dp_orth = Data.error_N_angle_dp_orth(Data.Mask);
    err_dp_IJCV = Data.error_N_angle_dp_IJCV(Data.Mask);
    for i = 2 : num
        betaUp = betaList(i);
        mask = (beta >= betaDown) & (beta < betaUp);
        errorBetaMean.Peri(i-1) = mean(err_dp(mask));
        errorBetaStd.Peri(i-1) = std(err_dp(mask));
        errorBetaMean.Orth(i-1) = mean(err_dp_orth(mask));
        errorBetaStd.Orth(i-1) = std(err_dp_orth(mask));    
        errorBetaMean.IJCV(i-1) = mean(err_dp_IJCV(mask));
        errorBetaStd.IJCV(i-1) = std(err_dp_IJCV(mask));   
        betaDown = betaUp;
    end   
end
function plotBetaMeanStd(fig, errorBetaMean, errorBetaStd, betaList, colors, plotParameter)
    figure(fig);
    x = linspace(betaList(1), betaList(end), length(betaList)-1);
    hold on; box on; grid on;
    upper_Peri = errorBetaMean.Peri + errorBetaStd.Peri;
    lower_Peri = errorBetaMean.Peri - errorBetaStd.Peri;
    fill([x, fliplr(x)], [upper_Peri, fliplr(lower_Peri)], colors(1,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    p1 = plot(x, errorBetaMean.Peri, 'color', colors(1,:),'LineWidth', plotParameter.LineWidth * plotParameter.Scale);
    upper_Orth = errorBetaMean.Orth + errorBetaStd.Orth;
    lower_Orth = errorBetaMean.Orth - errorBetaStd.Orth;
    fill([x, fliplr(x)], [upper_Orth, fliplr(lower_Orth)], colors(2,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    p2 = plot(x, errorBetaMean.Orth, 'color', colors(2,:),'LineWidth', plotParameter.LineWidth * plotParameter.Scale);
    legend([p1, p2], "Ours", "Orth.", 'Location', 'northwest', 'FontSize', plotParameter.FontSize*plotParameter.Scale*1.1, 'FontName', 'Times New Roman');
    set(gca,'LineWidth', plotParameter.LineWidth * plotParameter.Scale);
    xlabel('Perspective distortion angle \beta (\circ)', 'FontSize', plotParameter.FontSize*plotParameter.Scale, 'FontName', 'Times New Roman');
    ylabel('Errors \Delta \gamma (\circ)', 'FontSize', plotParameter.FontSize*plotParameter.Scale, 'FontName', 'Times New Roman');
end
function data_deg = Rad2Deg(data_rad)
    data_deg = data_rad;
    data_deg.Beta = rad2deg(data_rad.Beta);
    data_deg.error_N_angle_dp = rad2deg(data_rad.error_N_angle_dp_pers);
    data_deg.error_N_angle_dp_IJCV = rad2deg(data_rad.error_N_angle_dp_IJCV);
    data_deg.error_N_angle_dp_orth = rad2deg(data_rad.error_N_angle_dp_orth);
    data_deg.error_N_angle_sp = rad2deg(data_rad.error_N_angle_sp_pers);
    data_deg.error_N_angle_sp_IJCV = rad2deg(data_rad.error_N_angle_sp_IJCV);
    data_deg.error_N_angle_sp_orth = rad2deg(data_rad.error_N_angle_sp_orth);
end













