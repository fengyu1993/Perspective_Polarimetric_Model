%% Simulation Error Statistics Specular and Diffuse Reflection: Plane, Hemisphere, Random
clc; clear; close all;
%%
Plane = load('./Data/Data_SimulationPlane.mat');
Hemisphere = load('./Data/Data_SimulationHemisphere.mat');
Random = load('./Data/Data_SimulationRandom.mat');
%%
[meanPlane, stdPlane, rmsePlane, maxPlane] = getStatistics(Plane);
[meanHemisphere, stdHemisphere, rmseHemisphere, maxHemisphere] = getStatistics(Hemisphere);
[meanRandom, stdRandom, rmseRandom, maxRandom] = getStatistics(Random);
%%
%% Plane
fprintf('\\#1: Plane & Orth. & $%.3f$ & $%.3f$ & $%.3f$ & & $%.3f$ & $%.3f$ & $%.3f$ \\\\ \n', ...
    meanPlane.orth.sp, stdPlane.orth.sp, rmsePlane.orth.sp, ...
    meanPlane.orth.dp, stdPlane.orth.dp, rmsePlane.orth.dp);
fprintf(' & GMPC & $%.3f$ & $%.3f$ & $%.3f$ & & $%.3f$ & $%.3f$ & $%.3f$ \\\\ \n', ...
    meanPlane.ijcv.sp, stdPlane.ijcv.sp, rmsePlane.ijcv.sp, ...
    meanPlane.ijcv.dp, stdPlane.ijcv.dp, rmsePlane.ijcv.dp);
fprintf(' & Ours & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ \\\\ \n', ...
    meanPlane.pers.sp, stdPlane.pers.sp, rmsePlane.pers.sp, ...
    meanPlane.pers.dp, stdPlane.pers.dp, rmsePlane.pers.dp);
fprintf('\\cdashline{1-9}\n');
fprintf('\\addlinespace[2pt]\n');
%% Hemisphere
fprintf('\\#2: Hemisphere & Orth. & $%.3f$ & $%.3f$ & $%.3f$ & & $%.3f$ & $%.3f$ & $%.3f$ \\\\ \n', ...
    meanHemisphere.orth.sp, stdHemisphere.orth.sp, rmseHemisphere.orth.sp, ...
    meanHemisphere.orth.dp, stdHemisphere.orth.dp, rmseHemisphere.orth.dp);
fprintf(' & GMPC & $%.3f$ & $%.3f$ & $%.3f$  & & $%.3f$ & $%.3f$ & $%.3f$ \\\\ \n', ...
    meanHemisphere.ijcv.sp, stdHemisphere.ijcv.sp, rmseHemisphere.ijcv.sp, ...
    meanHemisphere.ijcv.dp, stdHemisphere.ijcv.dp, rmseHemisphere.ijcv.dp);
fprintf(' & Ours & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ \\\\ \n', ...
    meanHemisphere.pers.sp, stdHemisphere.pers.sp, rmseHemisphere.pers.sp, ...
    meanHemisphere.pers.dp, stdHemisphere.pers.dp, rmseHemisphere.pers.dp);
fprintf('\\cdashline{1-9}\n');
fprintf('\\addlinespace[2pt]\n');
%% Random
fprintf('\\#3: Random & Orth. & $%.3f$ & $%.3f$ & $%.3f$ & & $%.3f$ & $%.3f$ & $%.3f$ \\\\ \n', ...
    meanRandom.orth.sp, stdRandom.orth.sp, rmseRandom.orth.sp,  ...
    meanRandom.orth.dp, stdRandom.orth.dp, rmseRandom.orth.dp);
fprintf(' & GMPC & $%.3f$ & $%.3f$ & $%.3f$ & & $%.3f$ & $%.3f$ & $%.3f$ \\\\ \n', ...
    meanRandom.ijcv.sp, stdRandom.ijcv.sp, rmseRandom.ijcv.sp, ...
    meanRandom.ijcv.dp, stdRandom.ijcv.dp, rmseRandom.ijcv.dp);
fprintf(' & Ours & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ \\\\ \n', ...
    meanRandom.pers.sp, stdRandom.pers.sp, rmseRandom.pers.sp, ...
    meanRandom.pers.dp, stdRandom.pers.dp, rmseRandom.pers.dp);
%%
function [meanData, stdData, rmseData, maxData] = getStatistics(Data)
    meanData.pers.sp = mean(Data.error_N_angle_sp(Data.Mask));
    meanData.orth.sp = mean(Data.error_N_angle_sp_orth(Data.Mask));
    meanData.ijcv.sp = mean(Data.error_N_angle_sp_IJCV(Data.Mask));
    stdData.pers.sp = std(Data.error_N_angle_sp(Data.Mask));
    stdData.orth.sp = std(Data.error_N_angle_sp_orth(Data.Mask));
    stdData.ijcv.sp = std(Data.error_N_angle_sp_IJCV(Data.Mask));
    rmseData.pers.sp = sqrt(mean(Data.error_N_angle_sp(Data.Mask).^2));
    rmseData.orth.sp = sqrt(mean(Data.error_N_angle_sp_orth(Data.Mask).^2));
    rmseData.ijcv.sp = sqrt(mean(Data.error_N_angle_sp_IJCV(Data.Mask).^2));
    maxData.pers.sp = max(Data.error_N_angle_sp(Data.Mask));
    maxData.orth.sp = max(Data.error_N_angle_sp_orth(Data.Mask));
    maxData.ijcv.sp = max(Data.error_N_angle_sp_IJCV(Data.Mask));


    meanData.pers.dp = mean(Data.error_N_angle_dp(Data.Mask));
    meanData.orth.dp = mean(Data.error_N_angle_dp_orth(Data.Mask));
    meanData.ijcv.dp = mean(Data.error_N_angle_dp_IJCV(Data.Mask));
    stdData.pers.dp = std(Data.error_N_angle_dp(Data.Mask));
    stdData.orth.dp = std(Data.error_N_angle_dp_orth(Data.Mask));
    stdData.ijcv.dp = std(Data.error_N_angle_dp_IJCV(Data.Mask));
    rmseData.pers.dp = sqrt(mean(Data.error_N_angle_dp(Data.Mask).^2));
    rmseData.orth.dp = sqrt(mean(Data.error_N_angle_dp_orth(Data.Mask).^2));
    rmseData.ijcv.dp = sqrt(mean(Data.error_N_angle_dp_IJCV(Data.Mask).^2));
    maxData.pers.dp = max(Data.error_N_angle_dp(Data.Mask));
    maxData.orth.dp = max(Data.error_N_angle_dp_orth(Data.Mask));
    maxData.ijcv.dp = max(Data.error_N_angle_dp_IJCV(Data.Mask));


end