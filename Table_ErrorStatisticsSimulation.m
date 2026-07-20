%% Simulation Error Statistics Specular and Diffuse Reflection: Plane, Hemisphere, Random
clc; clear; close all;
%%
Plane = load('./Data/Data_SimulationPlane.mat');
Hemisphere = load('./Data/Data_SimulationHemisphere.mat');
Random = load('./Data/Data_SimulationRandom.mat');
%%
[meanPlane, stdPlane, medianPlane, maxPlane] = getStatistics(Plane);
[meanHemisphere, stdHemisphere, medianHemisphere, maxHemisphere] = getStatistics(Hemisphere);
[meanRandom, stdRandom, medianRandom, maxRandom] = getStatistics(Random);
%% Plane
fprintf('Plane & Orth. & $%.2f$ & $%.2f$ & $%.2f$ & $%.2f$ & & $%.2f$ & $%.2f$ & $%.2f$ & $%.2f$\\\\ \n', ...
    meanPlane.orth.sp, stdPlane.orth.sp, medianPlane.orth.sp, maxPlane.orth.sp, ...
    meanPlane.orth.dp, stdPlane.orth.dp, medianPlane.orth.dp, maxPlane.orth.dp);
fprintf(' & GMPC & $%.2f$ & $%.2f$ & $%.2f$ & $%.2f$ & & $%.2f$ & $%.2f$ & $%.2f$ & $%.2f$\\\\ \n', ...
    meanPlane.ijcv.sp, stdPlane.ijcv.sp, medianPlane.ijcv.sp, maxPlane.ijcv.sp, ...
    meanPlane.ijcv.dp, stdPlane.ijcv.dp, medianPlane.ijcv.dp, maxPlane.ijcv.dp);
fprintf(' & Ours & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$\\\\ \n', ...
    meanPlane.pers.sp, stdPlane.pers.sp, medianPlane.pers.sp, maxPlane.pers.sp, ...
    meanPlane.pers.dp, stdPlane.pers.dp, medianPlane.pers.dp, maxPlane.pers.dp);
%% Hemisphere
fprintf('Hemisphere & Orth. & $%.2f$ & $%.2f$ & $%.2f$ & $%.2f$ & & $%.2f$ & $%.2f$ & $%.2f$ & $%.2f$\\\\ \n', ...
    meanHemisphere.orth.sp, stdHemisphere.orth.sp, medianHemisphere.orth.sp, maxHemisphere.orth.sp, ...
    meanHemisphere.orth.dp, stdHemisphere.orth.dp, medianHemisphere.orth.dp, maxHemisphere.orth.dp);
fprintf(' & GMPC & $%.2f$ & $%.2f$ & $%.2f$ & $%.2f$ & & $%.2f$ & $%.2f$ & $%.2f$ & $%.2f$\\\\ \n', ...
    meanHemisphere.ijcv.sp, stdHemisphere.ijcv.sp, medianHemisphere.ijcv.sp, maxHemisphere.ijcv.sp, ...
    meanHemisphere.ijcv.dp, stdHemisphere.ijcv.dp, medianHemisphere.ijcv.dp, maxHemisphere.ijcv.dp);
fprintf(' & Ours & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$\\\\ \n', ...
    meanHemisphere.pers.sp, stdHemisphere.pers.sp, medianHemisphere.pers.sp, maxHemisphere.pers.sp, ...
    meanHemisphere.pers.dp, stdHemisphere.pers.dp, medianHemisphere.pers.dp, maxHemisphere.pers.dp);
%% Random
fprintf('Random & Orth. & $%.2f$ & $%.2f$ & $%.2f$ & $%.2f$ & & $%.2f$ & $%.2f$ & $%.2f$ & $%.2f$\\\\ \n', ...
    meanRandom.orth.sp, stdRandom.orth.sp, medianRandom.orth.sp, maxRandom.orth.sp, ...
    meanRandom.orth.dp, stdRandom.orth.dp, medianRandom.orth.dp, maxRandom.orth.dp);
fprintf(' & GMPC & $%.2f$ & $%.2f$ & $%.2f$ & $%.2f$ & & $%.2f$ & $%.2f$ & $%.2f$ & $%.2f$\\\\ \n', ...
    meanRandom.ijcv.sp, stdRandom.ijcv.sp, medianRandom.ijcv.sp, maxRandom.ijcv.sp, ...
    meanRandom.ijcv.dp, stdRandom.ijcv.dp, medianRandom.ijcv.dp, maxRandom.ijcv.dp);
fprintf(' & Ours & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$\\\\ \n', ...
    meanRandom.pers.sp, stdRandom.pers.sp, medianRandom.pers.sp, maxRandom.pers.sp, ...
    meanRandom.pers.dp, stdRandom.pers.dp, medianRandom.pers.dp, maxRandom.pers.dp);

%%
function [meanData, stdData, medianData, maxData] = getStatistics(Data)
    meanData.pers.sp = mean(Data.error_N_angle_sp(:));
    meanData.orth.sp = mean(Data.error_N_angle_sp_orth(:));
    meanData.ijcv.sp = mean(Data.error_N_angle_sp_IJCV(:));
    stdData.pers.sp = std(Data.error_N_angle_sp(:));
    stdData.orth.sp = std(Data.error_N_angle_sp_orth(:));
    stdData.ijcv.sp = std(Data.error_N_angle_sp_IJCV(:));
    medianData.pers.sp = median(Data.error_N_angle_sp(:));
    medianData.orth.sp = median(Data.error_N_angle_sp_orth(:));
    medianData.ijcv.sp = median(Data.error_N_angle_sp_IJCV(:));
    maxData.pers.sp = max(Data.error_N_angle_sp(:));
    maxData.orth.sp = max(Data.error_N_angle_sp_orth(:));
    maxData.ijcv.sp = max(Data.error_N_angle_sp_IJCV(:));

    meanData.pers.dp = mean(Data.error_N_angle_dp(:));
    meanData.orth.dp = mean(Data.error_N_angle_dp_orth(:));
    meanData.ijcv.dp = mean(Data.error_N_angle_dp_IJCV(:));
    stdData.pers.dp = std(Data.error_N_angle_dp(:));
    stdData.orth.dp = std(Data.error_N_angle_dp_orth(:));
    stdData.ijcv.dp = std(Data.error_N_angle_dp_IJCV(:));
    medianData.pers.dp = median(Data.error_N_angle_dp(:));
    medianData.orth.dp = median(Data.error_N_angle_dp_orth(:));
    medianData.ijcv.dp = median(Data.error_N_angle_dp_IJCV(:));
    maxData.pers.dp = max(Data.error_N_angle_dp(:));
    maxData.orth.dp = max(Data.error_N_angle_dp_orth(:));
    maxData.ijcv.dp = max(Data.error_N_angle_dp_IJCV(:));
end