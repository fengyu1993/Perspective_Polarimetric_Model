%% Experiment DeepSfP Dataset
clc; clear; close all;
%%
load('./Data/Data_ExperimentPlaneDeepSfPDataset_pers_orth.mat');
%% statistics
row = 1024; col = 1224;
casename = ["indoor", "outdoor_cloudy", "outdoor_sunny"];
for caseNum = 1 : 3
    Err_pers_sta = zeros(row, col);
    Err_orth_sta = zeros(row, col);
    Mask_sum_sta = zeros(row, col);
    for objectNum = 1 : length(index.name)   
        err_pers = Err_pers(:,:,caseNum, objectNum);
        err_orth = Err_orth(:,:,caseNum, objectNum);
        mask_sum = Mask_sum(:,:,caseNum, objectNum);
        id = ID(:,:,caseNum, objectNum) == 1;
        Err_pers_sta(id) = Err_pers_sta(id) + err_pers(id);
        Err_orth_sta(id) = Err_orth_sta(id) + err_orth(id);
        Mask_sum_sta(id) = Mask_sum_sta(id) + mask_sum(id);
    end
    %%
    Id = Mask_sum_sta > 0;
    Err_pers_sta(Id) = Err_pers_sta(Id) ./ Mask_sum_sta(Id);
    Err_pers_sta(~Id) = NaN;
    Err_orth_sta(Id) = Err_orth_sta(Id) ./ Mask_sum_sta(Id);
    Err_orth_sta(~Id) = NaN;
    %%
    switch caseNum
        case 1
            Err_pers_indoor = Err_pers_sta;
            Err_orth_indoor = Err_orth_sta;
            Id_indoor = Id;
        case 2
            Err_pers_outdoor_cloudy = Err_pers_sta;
            Err_orth_outdoor_cloudy = Err_orth_sta;
            Id_outdoor_cloudy = Id;
        case 3
            Err_pers_outdoor_sunny = Err_pers_sta;
            Err_orth_outdoor_sunny = Err_orth_sta;
            Id_outdoor_sunny = Id;
    end
end
% indoor
IndoorPers.MAE = mean(Err_pers_indoor(Id_indoor));
IndoorPers.SD = std(Err_pers_indoor(Id_indoor));
IndoorPers.RMSE = sqrt(mean(Err_pers_indoor(Id_indoor).^2));
IndoorPers.Max = max(Err_pers_indoor(Id_indoor));
IndoorOrth.MAE = mean(Err_orth_indoor(Id_indoor));
IndoorOrth.SD = std(Err_orth_indoor(Id_indoor));
IndoorOrth.RMSE = sqrt(mean(Err_orth_indoor(Id_indoor).^2));
IndoorOrth.Max = max(Err_orth_indoor(Id_indoor));
% outdoor_cloudy 
Outdoor_cloudyPers.MAE = mean(Err_pers_outdoor_cloudy(Id_outdoor_cloudy));
Outdoor_cloudyPers.SD = std(Err_pers_outdoor_cloudy(Id_outdoor_cloudy));
Outdoor_cloudyPers.RMSE = sqrt(mean(Err_pers_outdoor_cloudy(Id_outdoor_cloudy).^2));
Outdoor_cloudyPers.Max = max(Err_pers_outdoor_cloudy(Id_outdoor_cloudy));
Outdoor_cloudyOrth.MAE = mean(Err_orth_outdoor_cloudy(Id_outdoor_cloudy));
Outdoor_cloudyOrth.SD = std(Err_orth_outdoor_cloudy(Id_outdoor_cloudy));
Outdoor_cloudyOrth.RMSE = sqrt(mean(Err_orth_outdoor_cloudy(Id_outdoor_cloudy).^2));
Outdoor_cloudyOrth.Max = max(Err_orth_outdoor_cloudy(Id_outdoor_cloudy));
% outdoor_sunny  
Outdoor_sunnyPers.MAE = mean(Err_pers_outdoor_sunny(Id_outdoor_sunny));
Outdoor_sunnyPers.SD = std(Err_pers_outdoor_sunny(Id_outdoor_sunny));
Outdoor_sunnyPers.RMSE = sqrt(mean(Err_pers_outdoor_sunny(Id_outdoor_sunny).^2));
Outdoor_sunnyPers.Max = max(Err_pers_outdoor_sunny(Id_outdoor_sunny));
Outdoor_sunnyOrth.MAE = mean(Err_orth_outdoor_sunny(Id_outdoor_sunny));
Outdoor_sunnyOrth.SD = std(Err_orth_outdoor_sunny(Id_outdoor_sunny));
Outdoor_sunnyOrth.RMSE = sqrt(mean(Err_orth_outdoor_sunny(Id_outdoor_sunny).^2));
Outdoor_sunnyOrth.Max = max(Err_orth_outdoor_sunny(Id_outdoor_sunny));
%%
fprintf('Indoor & Ours & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ \\\\\n & Orth. & $%.3f$ & $%.3f$ & $%.3f$ & $%.3f$\\\\ \n', ...
    IndoorPers.MAE, IndoorPers.SD, IndoorPers.RMSE, IndoorPers.Max, ...
    IndoorOrth.MAE, IndoorOrth.SD, IndoorOrth.RMSE, IndoorOrth.Max);
fprintf('\\cdashline{1-6}\n');
fprintf('\\addlinespace[2pt]\n');
fprintf('Outdoor cloudy & Ours & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ \\\\\n  & Orth. & $%.3f$ & $%.3f$ & $%.3f$ & $%.3f$\\\\ \n', ...
    Outdoor_cloudyPers.MAE, Outdoor_cloudyPers.SD, Outdoor_cloudyPers.RMSE, Outdoor_cloudyPers.Max, ...
    Outdoor_cloudyOrth.MAE, Outdoor_cloudyOrth.SD, Outdoor_cloudyOrth.RMSE, Outdoor_cloudyOrth.Max);
fprintf('\\cdashline{1-6}\n');
fprintf('\\addlinespace[2pt]\n');
fprintf('Outdoor sunny & Ours & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ \\\\\n  & Orth. & $%.3f$ & $%.3f$ & $%.3f$ & $%.3f$\\\\ \n', ...
    Outdoor_sunnyPers.MAE, Outdoor_sunnyPers.SD, Outdoor_sunnyPers.RMSE, Outdoor_sunnyPers.Max, ...
    Outdoor_sunnyOrth.MAE, Outdoor_sunnyOrth.SD, Outdoor_sunnyOrth.RMSE, Outdoor_sunnyOrth.Max);
