%% Simulation Diffuse Reflection: Plane, Hemisphere, Random
clc; clear; close all;
%%
Plane = load('./Data/Data_SimulationPlane.mat');
Hemisphere = load('./Data/Data_SimulationHemisphere.mat');
Random = load('./Data/Data_SimulationRandom.mat');
[row, col] = size(Plane.Beta);
%%
colors = [228,26,28; 55,126,184; 77,175,74]/255;
plotParameter.FontSize = 23;
plotParameter.LineWidth = 2;
plotParameter.Scale = 1.2;
plotParameter.Resolution = 300;
%% 
num = 30;
[errorBetaPlaneMean, errorBetaPlaneStd, betaPlaneList] = getErrorBetaMeanStd(Plane, num);
[errorBetaHemisphereMean, errorBetaHemisphereStd, betaHemisphereList] = getErrorBetaMeanStd(Hemisphere, num);
[errorBetaRandomMean, errorBetaRandomStd, betaRandomList] = getErrorBetaMeanStd(Random, num);
%
figPlaneMeanStd = figure('Position', [100, 100, 850, 450]);  
plotBetaMeanStd(figPlaneMeanStd, errorBetaPlaneMean, errorBetaPlaneStd, betaPlaneList, colors, plotParameter);
axis([0 0.55 0 1]);
set(gca, 'xtick', 0:0.1:0.6, 'ytick', 0:0.2:1, 'FontSize', plotParameter.FontSize*plotParameter.Scale, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth);
exportgraphics(figPlaneMeanStd, 'fig_Error_Beta_Normal_Angle_Plane_Diffuse.png', 'Resolution', plotParameter.Resolution);
%
figHemisphereMeanStd = figure('Position', [100, 100, 850, 450]);   
plotBetaMeanStd(figHemisphereMeanStd, errorBetaHemisphereMean, errorBetaHemisphereStd, betaHemisphereList, colors, plotParameter);
axis([0 0.55 0 1]);
set(gca, 'xtick', 0:0.1:0.6, 'ytick', 0:0.2:1, 'FontSize', plotParameter.FontSize*plotParameter.Scale, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth);
exportgraphics(figHemisphereMeanStd, 'fig_Error_Beta_Normal_Angle_Hemisphere_Diffuse.png', 'Resolution', plotParameter.Resolution);
%
figRandomMeanStd = figure('Position', [100, 100, 850, 450]);   
plotBetaMeanStd(figRandomMeanStd, errorBetaRandomMean, errorBetaRandomStd, betaRandomList, colors, plotParameter);
axis([0 0.55 0 1.2]);
set(gca, 'xtick', 0:0.1:0.6, 'ytick', 0:0.3:1.2, 'FontSize', plotParameter.FontSize*plotParameter.Scale, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth);
exportgraphics(figRandomMeanStd, 'fig_Error_Beta_Normal_Angle_Diffuse.png', 'Resolution', plotParameter.Resolution);
%% Plane
% perspective
figPlanePers = figure;
axPers = axes(figPlanePers);
imagesc(Plane.error_N_angle_dp); 
axis equal; axis([0, col, 0, row]);
set(axPers, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize', plotParameter.FontSize  * plotParameter.Scale, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth );
set(gca,'LineWidth', plotParameter.LineWidth );
xtickangle(0);
colormap(axPers, parula); 
colorbar(axPers); 
title('Ours', 'FontSize', plotParameter.FontSize * plotParameter.Scale, 'FontName', 'Times New Roman');
% orthographic 
figPlaneOrth = figure;
axOrth = axes(figPlaneOrth);
imagesc(Plane.error_N_angle_dp_orth); 
axis equal; axis([0, col, 0, row]);
set(axOrth, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize', plotParameter.FontSize  * plotParameter.Scale, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth );
set(axOrth,'LineWidth', plotParameter.LineWidth );
xtickangle(0);
colormap(axOrth, parula); 
colorbar(axOrth); 
title('Orth.', 'FontSize', plotParameter.FontSize * plotParameter.Scale , 'FontName', 'Times New Roman');
% IJCV
figPlaneIJCV = figure;
axIJCV = axes(figPlaneIJCV);
imagesc(Plane.error_N_angle_dp_IJCV); 
axis equal; axis([0, col, 0, row]);
set(axIJCV, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize', plotParameter.FontSize  * plotParameter.Scale, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth );
set(axIJCV,'LineWidth', plotParameter.LineWidth );
xtickangle(0);
colormap(axIJCV, parula); 
colorbar(axIJCV); 
title('GMPC', 'FontSize', plotParameter.FontSize * plotParameter.Scale , 'FontName', 'Times New Roman');
% setup
% climPers = get(axPers, 'CLim');
% climOrth = get(axOrth, 'CLim');
% climIJCV = get(axIJCV, 'CLim');
% max_val = max([climPers(2), climOrth(2), climIJCV(2)]);
% set(axPers, 'CLim', [0, max_val]);
% set(axOrth, 'CLim', [0, max_val]);
% set(axIJCV, 'CLim', [0, max_val]);
% output
exportgraphics(figPlanePers, 'fig_Error_Normal_Plane_Diffuse_pers.png', 'Resolution', plotParameter.Resolution);
exportgraphics(figPlaneOrth, 'fig_Error_Normal_Plane_Diffuse_orth.png', 'Resolution', plotParameter.Resolution);
exportgraphics(figPlaneIJCV, 'fig_Error_Normal_Plane_Diffuse_IJCV.png', 'Resolution', plotParameter.Resolution);
%% Hemisphere
% perspective
figHemispherePers = figure;
axPers = axes(figHemispherePers);
imagesc(Hemisphere.error_N_angle_dp); 
axis equal; axis([0, col, 0, row]);
set(axPers, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize', plotParameter.FontSize  * plotParameter.Scale, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth );
set(gca,'LineWidth', plotParameter.LineWidth );
xtickangle(0);
colormap(axPers, parula); 
colorbar(axPers); 
title('Ours', 'FontSize', plotParameter.FontSize * plotParameter.Scale , 'FontName', 'Times New Roman');
% orthographic 
figHemisphereOrth = figure;
axOrth = axes(figHemisphereOrth);
imagesc(Hemisphere.error_N_angle_dp_orth); 
axis equal; axis([0, col, 0, row]);
set(axOrth, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize', plotParameter.FontSize  * plotParameter.Scale, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth );
set(axOrth,'LineWidth', plotParameter.LineWidth );
xtickangle(0);
colormap(axOrth, parula); 
colorbar(axOrth); 
title('Orth.', 'FontSize', plotParameter.FontSize * plotParameter.Scale , 'FontName', 'Times New Roman');
% IJCV
figHemisphereIJCV = figure;
axIJCV = axes(figHemisphereIJCV);
imagesc(Hemisphere.error_N_angle_dp_IJCV); 
axis equal; axis([0, col, 0, row]);
set(axIJCV, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize', plotParameter.FontSize  * plotParameter.Scale, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth );
set(axIJCV,'LineWidth', plotParameter.LineWidth );
xtickangle(0);
colormap(axIJCV, parula); 
colorbar(axIJCV); 
title('GMPC', 'FontSize', plotParameter.FontSize * plotParameter.Scale , 'FontName', 'Times New Roman');
% setup
% climPers = get(axPers, 'CLim');
% climOrth = get(axOrth, 'CLim');
% climIJCV = get(axIJCV, 'CLim');
% max_val = max([climPers(2), climOrth(2), climIJCV(2)]);
% set(axPers, 'CLim', [0, max_val]);
% set(axOrth, 'CLim', [0, max_val]);
% set(axIJCV, 'CLim', [0, max_val]);
% output
exportgraphics(figHemispherePers, 'fig_Error_Normal_Hemisphere_Diffuse_pers.png', 'Resolution', plotParameter.Resolution);
exportgraphics(figHemisphereOrth, 'fig_Error_Normal_Hemisphere_Diffuse_orth.png', 'Resolution', plotParameter.Resolution);
exportgraphics(figHemisphereIJCV, 'fig_Error_Normal_Hemisphere_Diffuse_IJCV.png', 'Resolution', plotParameter.Resolution);
%% Random
% perspective
figRandomPers = figure;
axPers = axes(figRandomPers);
imagesc(Random.error_N_angle_dp); 
axis equal; axis([0, col, 0, row]);
set(axPers, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize', plotParameter.FontSize  * plotParameter.Scale, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth );
set(gca,'LineWidth', plotParameter.LineWidth );
xtickangle(0);
colormap(axPers, parula); 
colorbar(axPers); 
title('Ours', 'FontSize', plotParameter.FontSize * plotParameter.Scale , 'FontName', 'Times New Roman');
% orthographic 
figRandomOrth = figure;
axOrth = axes(figRandomOrth);
imagesc(Random.error_N_angle_dp_orth); 
axis equal; axis([0, col, 0, row]);
set(axOrth, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize', plotParameter.FontSize  * plotParameter.Scale, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth );
set(axOrth,'LineWidth', plotParameter.LineWidth );
xtickangle(0);
colormap(axOrth, parula); 
colorbar(axOrth); 
title('Orth.', 'FontSize', plotParameter.FontSize * plotParameter.Scale , 'FontName', 'Times New Roman');
% IJCV
figRandomIJCV = figure;
axIJCV = axes(figRandomIJCV);
imagesc(Random.error_N_angle_dp_IJCV); 
axis equal; axis([0, col, 0, row]);
set(axIJCV, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize', plotParameter.FontSize  * plotParameter.Scale, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth );
set(axIJCV,'LineWidth', plotParameter.LineWidth );
xtickangle(0);
colormap(axIJCV, parula); 
colorbar(axIJCV); 
title('GMPC', 'FontSize', plotParameter.FontSize * plotParameter.Scale , 'FontName', 'Times New Roman');
% setup
% climPers = get(axPers, 'CLim');
% climOrth = get(axOrth, 'CLim');
% climIJCV = get(axIJCV, 'CLim');
% max_val = max([climPers(2), climOrth(2), climIJCV(2)]);
% set(axPers, 'CLim', [0, max_val]);
% set(axOrth, 'CLim', [0, max_val]);
% set(axIJCV, 'CLim', [0, max_val]);
% output
exportgraphics(figRandomPers, 'fig_Error_Normal_Random_Diffuse_pers.png', 'Resolution', plotParameter.Resolution);
exportgraphics(figRandomOrth, 'fig_Error_Normal_Random_Diffuse_orth.png', 'Resolution', plotParameter.Resolution);
exportgraphics(figRandomIJCV, 'fig_Error_Normal_Random_Diffuse_IJCV.png', 'Resolution', plotParameter.Resolution);



%%
function [errorBetaMean, errorBetaStd, betaList] = getErrorBetaMeanStd(Data, num)
    maxBeta = max(Data.Beta(:));
    betaList = linspace(0, maxBeta, num);
    errorBetaMean.Peri = zeros(1, num-1); errorBetaStd.Peri = zeros(1, num-1);
    errorBetaMean.Orth = zeros(1, num-1); errorBetaStd.Orth = zeros(1, num-1);
    errorBetaMean.IJCV = zeros(1, num-1); errorBetaStd.IJCV = zeros(1, num-1);
    betaDown = 0;
    for i = 2 : num
        betaUp = betaList(i);
        mask = (Data.Beta >= betaDown) & (Data.Beta < betaUp);
        errorBetaMean.Peri(i-1) = mean(Data.error_N_angle_dp(mask));
        errorBetaStd.Peri(i-1) = std(Data.error_N_angle_dp(mask));
        errorBetaMean.Orth(i-1) = mean(Data.error_N_angle_dp_orth(mask));
        errorBetaStd.Orth(i-1) = std(Data.error_N_angle_dp_orth(mask));    
        errorBetaMean.IJCV(i-1) = mean(Data.error_N_angle_dp_IJCV(mask));
        errorBetaStd.IJCV(i-1) = std(Data.error_N_angle_dp_IJCV(mask));   
        betaDown = betaUp;
    end   
end
function plotBetaMeanStd(fig, errorBetaMean, errorBetaStd, betaList, colors, plotParameter)
    figure(fig);
    x = betaList(1:end-1);
    hold on; box on; grid on;
    upper_Peri = errorBetaMean.Peri + errorBetaStd.Peri;
    lower_Peri = errorBetaMean.Peri - errorBetaStd.Peri;
    fill([x, fliplr(x)], [upper_Peri, fliplr(lower_Peri)], colors(1,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    p1 = plot(x, errorBetaMean.Peri, 'color', colors(1,:),'LineWidth', plotParameter.LineWidth * plotParameter.Scale);
    upper_Orth = errorBetaMean.Orth + errorBetaStd.Orth;
    lower_Orth = errorBetaMean.Orth - errorBetaStd.Orth;
    fill([x, fliplr(x)], [upper_Orth, fliplr(lower_Orth)], colors(2,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    p2 = plot(x, errorBetaMean.Orth, 'color', colors(2,:),'LineWidth', plotParameter.LineWidth * plotParameter.Scale);
    upper_IJCV = errorBetaMean.IJCV + errorBetaStd.IJCV;
    lower_IJCV = errorBetaMean.IJCV - errorBetaStd.IJCV;
    fill([x, fliplr(x)], [upper_IJCV, fliplr(lower_IJCV)], colors(3,:),  'FaceAlpha', 0.2, 'EdgeColor', 'none');
    p3 = plot(x, errorBetaMean.IJCV, 'color', colors(3,:),'LineWidth', plotParameter.LineWidth * plotParameter.Scale);
    legend([p2, p3, p1], "Orth.", "GMPC", "Ours", 'Location', 'northwest', 'FontSize', plotParameter.FontSize, 'FontName', 'Times New Roman');
    set(gca,'LineWidth', plotParameter.LineWidth * plotParameter.Scale);
    xlabel('\beta', 'FontSize', plotParameter.FontSize*plotParameter.Scale, 'FontName', 'Times New Roman');
    ylabel('\Delta \gamma', 'FontSize', plotParameter.FontSize*plotParameter.Scale, 'FontName', 'Times New Roman');
end
















