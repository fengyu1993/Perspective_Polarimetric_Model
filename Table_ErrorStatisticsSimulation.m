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
fprintf('Plane & Orth. & $%.3f$ & $%.3f$ & $%.3f$ & $%.3f$ & & $%.3f$ & $%.3f$ & $%.3f$ & $%.3f$\\\\ \n', ...
    meanPlane.orth.sp, stdPlane.orth.sp, medianPlane.orth.sp, maxPlane.orth.sp, ...
    meanPlane.orth.dp, stdPlane.orth.dp, medianPlane.orth.dp, maxPlane.orth.dp);
fprintf(' & GMPC & $%.3f$ & $%.3f$ & $%.3f$ & $%.3f$ & & $%.3f$ & $%.3f$ & $%.3f$ & $%.3f$\\\\ \n', ...
    meanPlane.ijcv.sp, stdPlane.ijcv.sp, medianPlane.ijcv.sp, maxPlane.ijcv.sp, ...
    meanPlane.ijcv.dp, stdPlane.ijcv.dp, medianPlane.ijcv.dp, maxPlane.ijcv.dp);
fprintf(' & Ours & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$\\\\ \n', ...
    meanPlane.pers.sp, stdPlane.pers.sp, medianPlane.pers.sp, maxPlane.pers.sp, ...
    meanPlane.pers.dp, stdPlane.pers.dp, medianPlane.pers.dp, maxPlane.pers.dp);
%% Hemisphere
fprintf('Hemisphere & Orth. & $%.3f$ & $%.3f$ & $%.3f$ & $%.3f$ & & $%.3f$ & $%.3f$ & $%.3f$ & $%.3f$\\\\ \n', ...
    meanHemisphere.orth.sp, stdHemisphere.orth.sp, medianHemisphere.orth.sp, maxHemisphere.orth.sp, ...
    meanHemisphere.orth.dp, stdHemisphere.orth.dp, medianHemisphere.orth.dp, maxHemisphere.orth.dp);
fprintf(' & GMPC & $%.3f$ & $%.3f$ & $%.3f$ & $%.3f$ & & $%.3f$ & $%.3f$ & $%.3f$ & $%.3f$\\\\ \n', ...
    meanHemisphere.ijcv.sp, stdHemisphere.ijcv.sp, medianHemisphere.ijcv.sp, maxHemisphere.ijcv.sp, ...
    meanHemisphere.ijcv.dp, stdHemisphere.ijcv.dp, medianHemisphere.ijcv.dp, maxHemisphere.ijcv.dp);
fprintf(' & Ours & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$\\\\ \n', ...
    meanHemisphere.pers.sp, stdHemisphere.pers.sp, medianHemisphere.pers.sp, maxHemisphere.pers.sp, ...
    meanHemisphere.pers.dp, stdHemisphere.pers.dp, medianHemisphere.pers.dp, maxHemisphere.pers.dp);
%% Random
fprintf('Random & Orth. & $%.3f$ & $%.3f$ & $%.3f$ & $%.3f$ & & $%.3f$ & $%.3f$ & $%.3f$ & $%.3f$\\\\ \n', ...
    meanRandom.orth.sp, stdRandom.orth.sp, medianRandom.orth.sp, maxRandom.orth.sp, ...
    meanRandom.orth.dp, stdRandom.orth.dp, medianRandom.orth.dp, maxRandom.orth.dp);
fprintf(' & GMPC & $%.3f$ & $%.3f$ & $%.3f$ & $%.3f$ & & $%.3f$ & $%.3f$ & $%.3f$ & $%.3f$\\\\ \n', ...
    meanRandom.ijcv.sp, stdRandom.ijcv.sp, medianRandom.ijcv.sp, maxRandom.ijcv.sp, ...
    meanRandom.ijcv.dp, stdRandom.ijcv.dp, medianRandom.ijcv.dp, maxRandom.ijcv.dp);
fprintf(' & Ours & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$\\\\ \n', ...
    meanRandom.pers.sp, stdRandom.pers.sp, medianRandom.pers.sp, maxRandom.pers.sp, ...
    meanRandom.pers.dp, stdRandom.pers.dp, medianRandom.pers.dp, maxRandom.pers.dp);

%%
function [meanData, stdData, medianData, maxData] = getStatistics(Data)
    meanData.pers.sp = mean(Data.error_N_angle_sp(Data.Mask));
    meanData.orth.sp = mean(Data.error_N_angle_sp_orth(Data.Mask));
    meanData.ijcv.sp = mean(Data.error_N_angle_sp_IJCV(Data.Mask));
    stdData.pers.sp = std(Data.error_N_angle_sp(Data.Mask));
    stdData.orth.sp = std(Data.error_N_angle_sp_orth(Data.Mask));
    stdData.ijcv.sp = std(Data.error_N_angle_sp_IJCV(Data.Mask));
    medianData.pers.sp = median(Data.error_N_angle_sp(Data.Mask));
    medianData.orth.sp = median(Data.error_N_angle_sp_orth(Data.Mask));
    medianData.ijcv.sp = median(Data.error_N_angle_sp_IJCV(Data.Mask));
    maxData.pers.sp = max(Data.error_N_angle_sp(Data.Mask));
    maxData.orth.sp = max(Data.error_N_angle_sp_orth(Data.Mask));
    maxData.ijcv.sp = max(Data.error_N_angle_sp_IJCV(Data.Mask));

    meanData.pers.dp = mean(Data.error_N_angle_dp(Data.Mask));
    meanData.orth.dp = mean(Data.error_N_angle_dp_orth(Data.Mask));
    meanData.ijcv.dp = mean(Data.error_N_angle_dp_IJCV(Data.Mask));
    stdData.pers.dp = std(Data.error_N_angle_dp(Data.Mask));
    stdData.orth.dp = std(Data.error_N_angle_dp_orth(Data.Mask));
    stdData.ijcv.dp = std(Data.error_N_angle_dp_IJCV(Data.Mask));
    medianData.pers.dp = median(Data.error_N_angle_dp(Data.Mask));
    medianData.orth.dp = median(Data.error_N_angle_dp_orth(Data.Mask));
    medianData.ijcv.dp = median(Data.error_N_angle_dp_IJCV(Data.Mask));
    maxData.pers.dp = max(Data.error_N_angle_dp(Data.Mask));
    maxData.orth.dp = max(Data.error_N_angle_dp_orth(Data.Mask));
    maxData.ijcv.dp = max(Data.error_N_angle_dp_IJCV(Data.Mask));
end