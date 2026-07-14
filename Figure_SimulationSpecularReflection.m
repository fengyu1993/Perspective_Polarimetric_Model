%% Simulation Specular Reflection: Plane, Hemisphere, Random
clc; clear; close all;
%%
Plane = load('./Data/Data_SimulationPlane.mat');
Hemisphere = load('./Data/Data_SimulationHemisphere.mat');
Random = load('./Data/Data_SimulationRandom.mat');
[row, col] = size(Plane.Beta);
%%
colors = [142 207 201; 255 190 122; 142 207 201; 255 190 122]/255;
FontSize = 22;
LineWidth = 1.2;
scale = 1;
Resolution = 300;
%% Plane
% perspective
figPlanePers = figure;
axPers = axes(figPlanePers);
imagesc(Plane.error_N_angle_sp); 
axis equal; axis([0, col, 0, row]);
set(axPers, 'xtick', 0:300:1200, 'ytick', 0:200:1000, 'FontSize', FontSize*scale, 'FontName', 'Times New Roman', 'LineWidth', LineWidth*scale);
set(gca,'LineWidth', LineWidth*scale);
colormap(axPers, parula); 
colorbar(axPers); 
title('Ours', 'FontSize', FontSize*scale, 'FontName', 'Times New Roman');
% orthographic 
figPlaneOrth = figure;
axOrth = axes(figPlaneOrth);
imagesc(Plane.error_N_angle_sp_orth); 
axis equal; axis([0, col, 0, row]);
set(axOrth, 'xtick', 0:300:1200, 'ytick', 0:200:1000, 'FontSize', FontSize*scale, 'FontName', 'Times New Roman', 'LineWidth', LineWidth*scale);
set(axOrth,'LineWidth', LineWidth*scale);
colormap(axOrth, parula); 
colorbar(axOrth); 
title('Orth.', 'FontSize', FontSize*scale, 'FontName', 'Times New Roman');
% IJCV
figPlaneIJCV = figure;
axIJCV = axes(figPlaneIJCV);
imagesc(Plane.error_N_angle_sp_IJCV); 
axis equal; axis([0, col, 0, row]);
set(axIJCV, 'xtick', 0:300:1200, 'ytick', 0:200:1000, 'FontSize', FontSize*scale, 'FontName', 'Times New Roman', 'LineWidth', LineWidth*scale);
set(axIJCV,'LineWidth', LineWidth*scale);
colormap(axIJCV, parula); 
colorbar(axIJCV); 
title('GMPC', 'FontSize', FontSize*scale, 'FontName', 'Times New Roman');
% setup
% climPers = get(axPers, 'CLim');
% climOrth = get(axOrth, 'CLim');
% climIJCV = get(axIJCV, 'CLim');
% max_val = max([climPers(2), climOrth(2), climIJCV(2)]);
% set(axPers, 'CLim', [0, max_val]);
% set(axOrth, 'CLim', [0, max_val]);
% set(axIJCV, 'CLim', [0, max_val]);
% output
exportgraphics(figPlanePers, 'fig_Error_Normal_Plane_Specular_pers.png', 'Resolution', Resolution);
exportgraphics(figPlaneOrth, 'fig_Error_Normal_Plane_Specular_orth.png', 'Resolution', Resolution);
exportgraphics(figPlaneIJCV, 'fig_Error_Normal_Plane_Specular_IJCV.png', 'Resolution', Resolution);
%% Hemisphere
% perspective
figHemispherePers = figure;
axPers = axes(figHemispherePers);
imagesc(Hemisphere.error_N_angle_sp); 
axis equal; axis([0, col, 0, row]);
set(axPers, 'xtick', 0:300:1200, 'ytick', 0:200:1000, 'FontSize', FontSize*scale, 'FontName', 'Times New Roman', 'LineWidth', LineWidth*scale);
set(gca,'LineWidth', LineWidth*scale);
colormap(axPers, parula); 
colorbar(axPers); 
title('Ours', 'FontSize', FontSize*scale, 'FontName', 'Times New Roman');
% orthographic 
figHemisphereOrth = figure;
axOrth = axes(figHemisphereOrth);
imagesc(Hemisphere.error_N_angle_sp_orth); 
axis equal; axis([0, col, 0, row]);
set(axOrth, 'xtick', 0:300:1200, 'ytick', 0:200:1000, 'FontSize', FontSize*scale, 'FontName', 'Times New Roman', 'LineWidth', LineWidth*scale);
set(axOrth,'LineWidth', LineWidth*scale);
colormap(axOrth, parula); 
colorbar(axOrth); 
title('Orth.', 'FontSize', FontSize*scale, 'FontName', 'Times New Roman');
% IJCV
figHemisphereIJCV = figure;
axIJCV = axes(figHemisphereIJCV);
imagesc(Hemisphere.error_N_angle_sp_IJCV); 
axis equal; axis([0, col, 0, row]);
set(axIJCV, 'xtick', 0:300:1200, 'ytick', 0:200:1000, 'FontSize', FontSize*scale, 'FontName', 'Times New Roman', 'LineWidth', LineWidth*scale);
set(axIJCV,'LineWidth', LineWidth*scale);
colormap(axIJCV, parula); 
colorbar(axIJCV); 
title('GMPC', 'FontSize', FontSize*scale, 'FontName', 'Times New Roman');
% setup
% climPers = get(axPers, 'CLim');
% climOrth = get(axOrth, 'CLim');
% climIJCV = get(axIJCV, 'CLim');
% max_val = max([climPers(2), climOrth(2), climIJCV(2)]);
% set(axPers, 'CLim', [0, max_val]);
% set(axOrth, 'CLim', [0, max_val]);
% set(axIJCV, 'CLim', [0, max_val]);
% output
exportgraphics(figHemispherePers, 'fig_Error_Normal_Hemisphere_Specular_pers.png', 'Resolution', Resolution);
exportgraphics(figHemisphereOrth, 'fig_Error_Normal_Hemisphere_Specular_orth.png', 'Resolution', Resolution);
exportgraphics(figHemisphereIJCV, 'fig_Error_Normal_Hemisphere_Specular_IJCV.png', 'Resolution', Resolution);
%% Random
% perspective
figRandomPers = figure;
axPers = axes(figRandomPers);
imagesc(Random.error_N_angle_sp); 
axis equal; axis([0, col, 0, row]);
set(axPers, 'xtick', 0:300:1200, 'ytick', 0:200:1000, 'FontSize', FontSize*scale, 'FontName', 'Times New Roman', 'LineWidth', LineWidth*scale);
set(gca,'LineWidth', LineWidth*scale);
colormap(axPers, parula); 
colorbar(axPers); 
title('Ours', 'FontSize', FontSize*scale, 'FontName', 'Times New Roman');
% orthographic 
figRandomOrth = figure;
axOrth = axes(figRandomOrth);
imagesc(Random.error_N_angle_sp_orth); 
axis equal; axis([0, col, 0, row]);
set(axOrth, 'xtick', 0:300:1200, 'ytick', 0:200:1000, 'FontSize', FontSize*scale, 'FontName', 'Times New Roman', 'LineWidth', LineWidth*scale);
set(axOrth,'LineWidth', LineWidth*scale);
colormap(axOrth, parula); 
colorbar(axOrth); 
title('Orth.', 'FontSize', FontSize*scale, 'FontName', 'Times New Roman');
% IJCV
figRandomIJCV = figure;
axIJCV = axes(figRandomIJCV);
imagesc(Random.error_N_angle_sp_IJCV); 
axis equal; axis([0, col, 0, row]);
set(axIJCV, 'xtick', 0:300:1200, 'ytick', 0:200:1000, 'FontSize', FontSize*scale, 'FontName', 'Times New Roman', 'LineWidth', LineWidth*scale);
set(axIJCV,'LineWidth', LineWidth*scale);
colormap(axIJCV, parula); 
colorbar(axIJCV); 
title('GMPC', 'FontSize', FontSize*scale, 'FontName', 'Times New Roman');
% setup
climPers = get(axPers, 'CLim');
climOrth = get(axOrth, 'CLim');
climIJCV = get(axIJCV, 'CLim');
max_val = max([climPers(2), climOrth(2), climIJCV(2)]);
set(axPers, 'CLim', [0, max_val]);
set(axOrth, 'CLim', [0, max_val]);
set(axIJCV, 'CLim', [0, max_val]);
% output
exportgraphics(figRandomPers, 'fig_Error_Normal_Random_Specular_pers.png', 'Resolution', Resolution);
exportgraphics(figRandomOrth, 'fig_Error_Normal_Random_Specular_orth.png', 'Resolution', Resolution);
exportgraphics(figRandomIJCV, 'fig_Error_Normal_Random_Specular_IJCV.png', 'Resolution', Resolution);





















