%% Simulation Error Statistics Experiment Plane
clc; clear; close all;
%%
PPA = load('./Data/Data_ExperimentPlanePPADataset.mat');
IJCV  = load('./Data/Data_ExperimentPlaneIJCVDataset.mat');
PPA.err_plot_ours_mean = rad2deg(PPA.err_plot_ours_mean);
PPA.err_plot_orth_mean = rad2deg(PPA.err_plot_orth_mean);
PPA.err_plot_IJCV_mean = rad2deg(PPA.err_plot_IJCV_mean);
IJCV.err_plot_ours_mean = rad2deg(IJCV.err_plot_ours_mean);
IJCV.err_plot_orth_mean = rad2deg(IJCV.err_plot_orth_mean);
IJCV.err_plot_IJCV_mean = rad2deg(IJCV.err_plot_IJCV_mean);
%% PPA
% Perspective
PPAOurs.MAE = mean(PPA.err_plot_ours_mean(PPA.id));
PPAOurs.SD = std(PPA.err_plot_ours_mean(PPA.id));
PPAOurs.RMSE = sqrt(mean(PPA.err_plot_ours_mean(PPA.id).^2));
PPAOurs.Max = max(PPA.err_plot_ours_mean(PPA.id));
% Orthographic 
PPAOrth.MAE = mean(PPA.err_plot_orth_mean(PPA.id));
PPAOrth.SD = std(PPA.err_plot_orth_mean(PPA.id));
PPAOrth.RMSE = sqrt(mean(PPA.err_plot_orth_mean(PPA.id).^2));
PPAOrth.Max = max(PPA.err_plot_orth_mean(PPA.id));
% IJCV  
PPAIJCV.MAE = mean(PPA.err_plot_IJCV_mean(PPA.id));
PPAIJCV.SD = std(PPA.err_plot_IJCV_mean(PPA.id));
PPAIJCV.RMSE = sqrt(mean(PPA.err_plot_IJCV_mean(PPA.id).^2));
PPAIJCV.Max = max(PPA.err_plot_IJCV_mean(PPA.id));
%% IJCV
% Perspective
IJCVOurs.MAE = mean(IJCV.err_plot_ours_mean(IJCV.id));
IJCVOurs.SD = std(IJCV.err_plot_ours_mean(IJCV.id));
IJCVOurs.RMSE = sqrt(mean(IJCV.err_plot_ours_mean(IJCV.id).^2));
IJCVOurs.Max = max(IJCV.err_plot_ours_mean(IJCV.id));
% Orthographic 
IJCVOrth.MAE = mean(IJCV.err_plot_orth_mean(IJCV.id));
IJCVOrth.SD = std(IJCV.err_plot_orth_mean(IJCV.id));
IJCVOrth.RMSE = sqrt(mean(IJCV.err_plot_orth_mean(IJCV.id).^2));
IJCVOrth.Max = max(IJCV.err_plot_orth_mean(IJCV.id));
% IJCV  
IJCVIJCV.MAE = mean(IJCV.err_plot_IJCV_mean(IJCV.id));
IJCVIJCV.SD = std(IJCV.err_plot_IJCV_mean(IJCV.id));
IJCVIJCV.RMSE = sqrt(mean(IJCV.err_plot_IJCV_mean(IJCV.id).^2));
IJCVIJCV.Max = max(IJCV.err_plot_IJCV_mean(IJCV.id));
%%
fprintf('Ours & $\\mathbf{%.2f}$  & $\\mathbf{%.2f}$ & & $\\mathbf{%.3f}$ & $\\mathbf{%.2f}$ \\\\ \n', ...
    PPAOurs.MAE, PPAOurs.SD, ...
    IJCVOurs.MAE, IJCVOurs.SD);
fprintf('GMPC & $%.2f$ & $%.2f$  & & $%.3f$ & $%.2f$ \\\\ \n', ...
    PPAIJCV.MAE, PPAIJCV.SD, ...
    IJCVIJCV.MAE, IJCVIJCV.SD);
fprintf('Orth. & $%.2f$ & $%.2f$  & & $%.2f$ & $%.2f$ \\\\ \n', ...
    PPAOrth.MAE, PPAOrth.SD, ...
    IJCVOrth.MAE, IJCVOrth.SD);






