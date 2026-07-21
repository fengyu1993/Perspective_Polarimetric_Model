%% Simulation Specular Reflection: Plane, Hemisphere, Random
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
%% 3D Shape
% Plane
fig_3DPlane = figure; 
plot3DShape(fig_3DPlane, Plane.N_desired, Plane.Mask);
exportgraphics(fig_3DPlane, 'fig_3D_plane.png', 'Resolution', plotParameter.Resolution);
% Hemisphere
fig_3DHemisphere = figure; 
plot3DShape(fig_3DHemisphere, Hemisphere.N_desired, Hemisphere.Mask);
exportgraphics(fig_3DHemisphere, 'fig_3D_hemisphere.png', 'Resolution', plotParameter.Resolution);
% Random
fig_3DRandom = figure; 
plot3DShape(fig_3DRandom, Random.N_desired, Random.Mask);
exportgraphics(fig_3DRandom, 'fig_3D_random.png', 'Resolution', plotParameter.Resolution);
%% Beta -- Error
num = 30;
[errorBetaPlaneMean, errorBetaPlaneStd, betaPlaneList] = getErrorBetaMeanStd(Plane, num);
[errorBetaHemisphereMean, errorBetaHemisphereStd, betaHemisphereList] = getErrorBetaMeanStd(Hemisphere, num);
[errorBetaRandomMean, errorBetaRandomStd, betaRandomList] = getErrorBetaMeanStd(Random, num);
% Plane
figPlaneMeanStd = figure('Position', [100, 100, 850, 450]);  
plotBetaMeanStd(figPlaneMeanStd, errorBetaPlaneMean, errorBetaPlaneStd, betaPlaneList, colors, plotParameter);
axis([0 betaPlaneList(end) 0 0.45]);
set(gca, 'xtick', 0:0.1:0.6, 'ytick', 0:0.15:0.45, 'FontSize', plotParameter.FontSize*plotParameter.Scale, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth);
exportgraphics(figPlaneMeanStd, 'fig_Error_Beta_Normal_Angle_Plane_Specular.png', 'Resolution', plotParameter.Resolution);
% Hemisphere
figHemisphereMeanStd = figure('Position', [100, 100, 850, 450]);   
plotBetaMeanStd(figHemisphereMeanStd, errorBetaHemisphereMean, errorBetaHemisphereStd, betaHemisphereList, colors, plotParameter);
axis([0 betaHemisphereList(end) 0 0.5]);
set(gca, 'xtick', 0:0.1:0.6, 'ytick', 0:0.1:0.5, 'FontSize', plotParameter.FontSize*plotParameter.Scale, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth);
exportgraphics(figHemisphereMeanStd, 'fig_Error_Beta_Normal_Angle_Hemisphere_Specular.png', 'Resolution', plotParameter.Resolution);
% Random
figRandomMeanStd = figure('Position', [100, 100, 850, 450]);   
plotBetaMeanStd(figRandomMeanStd, errorBetaRandomMean, errorBetaRandomStd, betaRandomList, colors, plotParameter);
axis([0 betaRandomList(end) 0 0.5]);
set(gca, 'xtick', 0:0.1:0.6, 'ytick', 0:0.1:0.5, 'FontSize', plotParameter.FontSize*plotParameter.Scale, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth);
exportgraphics(figRandomMeanStd, 'fig_Error_Beta_Normal_Angle_Specular.png', 'Resolution', plotParameter.Resolution);
%% Plane
% perspective
figPlanePers = figure('Position', [100, 100, 620, 420]);
ax = axes(figPlanePers);
h = imagesc(Plane.error_N_angle_sp); set(h, 'AlphaData', Plane.Mask); set(ax, 'Color', 'k'); 
axis equal; axis([0, col, 0, row]);
set(ax, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize', plotParameter.FontSize * plotParameter.Scale , 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth );
set(gca,'LineWidth', plotParameter.LineWidth );
xtickangle(0);
colormap(ax, parula); 
colorbar(ax); 
title('Ours', 'FontSize', plotParameter.FontSize * plotParameter.Scale, 'FontName', 'Times New Roman');
% orthographic 
figPlaneOrth = figure('Position', [100, 100, 620, 420]);
ax = axes(figPlaneOrth);
h = imagesc(Plane.error_N_angle_sp_orth); set(h, 'AlphaData', Plane.Mask); set(ax, 'Color', 'k'); 
axis equal; axis([0, col, 0, row]);
set(ax, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize', plotParameter.FontSize * plotParameter.Scale, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth );
set(ax,'LineWidth', plotParameter.LineWidth );
xtickangle(0);
colormap(ax, parula); 
colorbar(ax); 
title('Orth.', 'FontSize', plotParameter.FontSize * plotParameter.Scale, 'FontName', 'Times New Roman');
% IJCV
figPlaneIJCV = figure('Position', [100, 100, 620, 420]);
ax = axes(figPlaneIJCV);
h = imagesc(Plane.error_N_angle_sp_IJCV); set(h, 'AlphaData', Plane.Mask); set(ax, 'Color', 'k'); 
axis equal; axis([0, col, 0, row]);
set(ax, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize', plotParameter.FontSize  * plotParameter.Scale, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth );
set(ax,'LineWidth', plotParameter.LineWidth );
xtickangle(0);
colormap(ax, parula); 
colorbar(ax); 
title('GMPC', 'FontSize', plotParameter.FontSize * plotParameter.Scale, 'FontName', 'Times New Roman');
% setup
% climPers = get(axPers, 'CLim');
% climOrth = get(axOrth, 'CLim');
% climIJCV = get(axIJCV, 'CLim');
% max_val = max([climPers(2), climOrth(2), climIJCV(2)]);
% set(axPers, 'CLim', [0, max_val]);
% set(axOrth, 'CLim', [0, max_val]);
% set(axIJCV, 'CLim', [0, max_val]);
% output
exportgraphics(figPlanePers, 'fig_Error_Normal_Plane_Specular_pers.png', 'Resolution', plotParameter.Resolution);
exportgraphics(figPlaneOrth, 'fig_Error_Normal_Plane_Specular_orth.png', 'Resolution', plotParameter.Resolution);
exportgraphics(figPlaneIJCV, 'fig_Error_Normal_Plane_Specular_IJCV.png', 'Resolution', plotParameter.Resolution);
%% Hemisphere
% perspective
figHemispherePers = figure('Position', [100, 100, 620, 420]);
ax = axes(figHemispherePers);
h = imagesc(Hemisphere.error_N_angle_sp); set(h, 'AlphaData', Hemisphere.Mask); set(ax, 'Color', 'k'); 
axis equal; axis([0, col, 0, row]);
set(ax, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize', plotParameter.FontSize  * plotParameter.Scale , 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth );
set(gca,'LineWidth', plotParameter.LineWidth );
xtickangle(0);
colormap(ax, parula); 
cb = colorbar(ax); 
title('Ours', 'FontSize', plotParameter.FontSize * plotParameter.Scale , 'FontName', 'Times New Roman');
% orthographic 
figHemisphereOrth = figure('Position', [100, 100, 620, 420]);
ax = axes(figHemisphereOrth);
h = imagesc(Hemisphere.error_N_angle_sp_orth); set(h, 'AlphaData', Hemisphere.Mask); set(ax, 'Color', 'k'); 
axis equal; axis([0, col, 0, row]);
set(ax, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize', plotParameter.FontSize  * plotParameter.Scale, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth );
set(ax,'LineWidth', plotParameter.LineWidth );
xtickangle(0);
colormap(ax, parula); 
colorbar(ax); 
title('Orth.', 'FontSize', plotParameter.FontSize * plotParameter.Scale , 'FontName', 'Times New Roman');
% IJCV
figHemisphereIJCV = figure('Position', [100, 100, 620, 420]);
ax = axes(figHemisphereIJCV);
h = imagesc(Hemisphere.error_N_angle_sp_IJCV); set(h, 'AlphaData', Hemisphere.Mask); set(ax, 'Color', 'k'); 
axis equal; axis([0, col, 0, row]);
set(ax, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize', plotParameter.FontSize  * plotParameter.Scale, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth );
set(ax,'LineWidth', plotParameter.LineWidth );
xtickangle(0);
colormap(ax, parula); 
colorbar(ax); 
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
exportgraphics(figHemispherePers, 'fig_Error_Normal_Hemisphere_Specular_pers.png', 'Resolution', plotParameter.Resolution);
exportgraphics(figHemisphereOrth, 'fig_Error_Normal_Hemisphere_Specular_orth.png', 'Resolution', plotParameter.Resolution);
exportgraphics(figHemisphereIJCV, 'fig_Error_Normal_Hemisphere_Specular_IJCV.png', 'Resolution', plotParameter.Resolution);
%% Random
% perspective
figRandomPers = figure('Position', [100, 100, 620, 420]);
ax = axes(figRandomPers);
h = imagesc(Random.error_N_angle_sp); set(h, 'AlphaData', Random.Mask); set(ax, 'Color', 'k'); 
axis equal; axis([0, col, 0, row]);
set(ax, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize', plotParameter.FontSize , 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth );
set(gca,'LineWidth', plotParameter.LineWidth );
xtickangle(0);
colormap(ax, parula); 
colorbar(ax); 
title('Ours', 'FontSize', plotParameter.FontSize * plotParameter.Scale , 'FontName', 'Times New Roman');
% orthographic 
figRandomOrth = figure('Position', [100, 100, 620, 420]);
ax = axes(figRandomOrth);
h = imagesc(Random.error_N_angle_sp_orth); set(h, 'AlphaData', Random.Mask); set(ax, 'Color', 'k'); 
axis equal; axis([0, col, 0, row]);
set(ax, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize', plotParameter.FontSize  * plotParameter.Scale, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth );
set(ax,'LineWidth', plotParameter.LineWidth );
xtickangle(0);
colormap(ax, parula); 
colorbar(ax); 
title('Orth.', 'FontSize', plotParameter.FontSize * plotParameter.Scale , 'FontName', 'Times New Roman');
% IJCV
figRandomIJCV = figure('Position', [100, 100, 620, 420]);
ax = axes(figRandomIJCV);
h = imagesc(Random.error_N_angle_sp_IJCV); set(h, 'AlphaData', Random.Mask); set(ax, 'Color', 'k'); 
axis equal; axis([0, col, 0, row]);
set(ax, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize', plotParameter.FontSize  * plotParameter.Scale, 'FontName', 'Times New Roman', 'LineWidth', plotParameter.LineWidth );
set(ax,'LineWidth', plotParameter.LineWidth );
xtickangle(0);
colormap(ax, parula); 
colorbar(ax); 
title('GMPC', 'FontSize', plotParameter.FontSize * plotParameter.Scale, 'FontName', 'Times New Roman');
% setup
% climPers = get(axPers, 'CLim');
% climOrth = get(axOrth, 'CLim');
% climIJCV = get(axIJCV, 'CLim');
% max_val = max([climPers(2), climOrth(2), climIJCV(2)]);
% set(axPers, 'CLim', [0, max_val]);
% set(axOrth, 'CLim', [0, max_val]);
% set(axIJCV, 'CLim', [0, max_val]);
% output
exportgraphics(figRandomPers, 'fig_Error_Normal_Random_Specular_pers.png', 'Resolution', plotParameter.Resolution);
exportgraphics(figRandomOrth, 'fig_Error_Normal_Random_Specular_orth.png', 'Resolution', plotParameter.Resolution);
exportgraphics(figRandomIJCV, 'fig_Error_Normal_Random_Specular_IJCV.png', 'Resolution', plotParameter.Resolution);





%%
function [errorBetaMean, errorBetaStd, betaList] = getErrorBetaMeanStd(Data, num)
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
    upper_IJCV = errorBetaMean.IJCV + errorBetaStd.IJCV;
    lower_IJCV = errorBetaMean.IJCV - errorBetaStd.IJCV;
    fill([x, fliplr(x)], [upper_IJCV, fliplr(lower_IJCV)], colors(3,:),  'FaceAlpha', 0.2, 'EdgeColor', 'none');
    p3 = plot(x, errorBetaMean.IJCV, 'color', colors(3,:),'LineWidth', plotParameter.LineWidth * plotParameter.Scale);
    legend([p2, p3, p1], "Orth.", "GMPC", "Ours", 'Location', 'northwest', 'FontSize', plotParameter.FontSize, 'FontName', 'Times New Roman');
    set(gca,'LineWidth', plotParameter.LineWidth * plotParameter.Scale);
    xlabel('\beta', 'FontSize', plotParameter.FontSize*plotParameter.Scale, 'FontName', 'Times New Roman');
    ylabel('\Delta \gamma', 'FontSize', plotParameter.FontSize*plotParameter.Scale, 'FontName', 'Times New Roman');
end














