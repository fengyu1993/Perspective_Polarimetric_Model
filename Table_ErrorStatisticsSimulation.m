%% Simulation Error Statistics Specular and Diffuse Reflection: Plane, Hemisphere, Random
clc; clear; close all;
%%
Plane = load('./Data/Data_SimulationPlane.mat');
Hemisphere = load('./Data/Data_SimulationHemisphere.mat');
Random = load('./Data/Data_SimulationRandom.mat');
%%
[meanPlane, stdPlane, midPlane, maxPlane] = getStatistics(Plane);
[meanRandom, stdRandom, midRandom, maxRandom] = getStatistics(Random);
%%
%% Plane
fprintf('\\#1: Plane  & Ours & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ \\\\ \n', ...
    meanPlane.pers.sp, stdPlane.pers.sp, midPlane.pers.sp, maxPlane.pers.sp, ...
    meanPlane.pers.dp, stdPlane.pers.dp, midPlane.pers.dp, maxPlane.pers.dp);
fprintf('& Orth. & $%.2f$ & $%.2f$ & $%.2f$ & $%.2f$ & & $%.2f$ & $%.2f$ & $%.2f$ & $%.2f$ \\\\ \n', ...
    meanPlane.orth.sp, stdPlane.orth.sp, midPlane.orth.sp, maxPlane.orth.sp, ...
    meanPlane.orth.dp, stdPlane.orth.dp, midPlane.orth.dp, maxPlane.orth.dp);
fprintf('\\cdashline{1-11}\n');
fprintf('\\addlinespace[2pt]\n');
%% Random
fprintf('\\#2: Random  & Ours & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ & $\\mathbf{%.2f}$ \\\\ \n', ...
    meanRandom.pers.sp, stdRandom.pers.sp, midRandom.pers.sp, maxRandom.pers.sp, ....
    meanRandom.pers.dp, stdRandom.pers.dp, midRandom.pers.dp, maxRandom.pers.dp);
fprintf('& Orth. & $%.2f$ & $%.2f$ & $%.2f$ & $%.2f$ & & $%.2f$ & $%.2f$ & $%.2f$ & $%.2f$ \\\\ \n', ...
    meanRandom.orth.sp, stdRandom.orth.sp, midRandom.orth.sp,  maxRandom.orth.sp, ...
    meanRandom.orth.dp, stdRandom.orth.dp, midRandom.orth.dp,  maxRandom.orth.dp);
%%
function [meanData, stdData, medData, maxData] = getStatistics(Data)
    meanData.pers.sp = mean(rad2deg(Data.error_N_angle_sp_pers(Data.Mask)));
    meanData.orth.sp = mean(rad2deg(Data.error_N_angle_sp_orth(Data.Mask)));
    meanData.ijcv.sp = mean(rad2deg(Data.error_N_angle_sp_IJCV(Data.Mask)));
    stdData.pers.sp = std(rad2deg(Data.error_N_angle_sp_pers(Data.Mask)));
    stdData.orth.sp = std(rad2deg(Data.error_N_angle_sp_orth(Data.Mask)));
    stdData.ijcv.sp = std(rad2deg(Data.error_N_angle_sp_IJCV(Data.Mask)));
    medData.pers.sp = median(rad2deg(Data.error_N_angle_sp_pers(Data.Mask)));
    medData.orth.sp = median(rad2deg(Data.error_N_angle_sp_orth(Data.Mask)));
    medData.ijcv.sp = median(rad2deg(Data.error_N_angle_sp_IJCV(Data.Mask)));
    maxData.pers.sp = max(rad2deg(Data.error_N_angle_sp_pers(Data.Mask)));
    maxData.orth.sp = max(rad2deg(Data.error_N_angle_sp_orth(Data.Mask)));
    maxData.ijcv.sp = max(rad2deg(Data.error_N_angle_sp_IJCV(Data.Mask)));


    meanData.pers.dp = mean(rad2deg(Data.error_N_angle_dp_pers(Data.Mask)));
    meanData.orth.dp = mean(rad2deg(Data.error_N_angle_dp_orth(Data.Mask)));
    meanData.ijcv.dp = mean(rad2deg(Data.error_N_angle_dp_IJCV(Data.Mask)));
    stdData.pers.dp = std(rad2deg(Data.error_N_angle_dp_pers(Data.Mask)));
    stdData.orth.dp = std(rad2deg(Data.error_N_angle_dp_orth(Data.Mask)));
    stdData.ijcv.dp = std(rad2deg(Data.error_N_angle_dp_IJCV(Data.Mask)));
    medData.pers.dp = median(rad2deg(Data.error_N_angle_dp_pers(Data.Mask)));
    medData.orth.dp = median(rad2deg(Data.error_N_angle_dp_orth(Data.Mask)));
    medData.ijcv.dp = median(rad2deg(Data.error_N_angle_dp_IJCV(Data.Mask)));
    maxData.pers.dp = max(rad2deg(Data.error_N_angle_dp_pers(Data.Mask)));
    maxData.orth.dp = max(rad2deg(Data.error_N_angle_dp_orth(Data.Mask)));
    maxData.ijcv.dp = max(rad2deg(Data.error_N_angle_dp_IJCV(Data.Mask)));


end