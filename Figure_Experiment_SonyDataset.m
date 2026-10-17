%% Experiment Sony Dataset
clc; clear; close all;
%% load data
% Ours Vs Atkinson2006 TIP
OursVsAtkinson_bear1 = load('./Data/Data_ExperimentSonyDataset_OursVsAtkinson_bear1.mat');
OursVsAtkinson_bear2 = load('./Data/Data_ExperimentSonyDataset_OursVsAtkinson_bear2.mat');
OursVsAtkinson_cat = load('./Data/Data_ExperimentSonyDataset_OursVsAtkinson_cat.mat');
OursVsAtkinson_doll = load('./Data/Data_ExperimentSonyDataset_OursVsAtkinson_doll.mat');
OursVsAtkinson_squirrel = load('./Data/Data_ExperimentSonyDataset_OursVsAtkinson_squirrel.mat');
% Ours Vs Smith2019 TPAMI
OursVsSmith_bear1 = load('./Data/Data_ExperimentSonyDataset_OursVsSmith_bear1.mat');
OursVsSmith_bear2 = load('./Data/Data_ExperimentSonyDataset_OursVsSmith_bear2.mat');
OursVsSmith_cat = load('./Data/Data_ExperimentSonyDataset_OursVsSmith_cat.mat');
OursVsSmith_doll = load('./Data/Data_ExperimentSonyDataset_OursVsSmith_doll.mat');
OursVsSmith_squirrel = load('./Data/Data_ExperimentSonyDataset_OursVsSmith_squirrel.mat');
%% Ours Vs Smith 2019
% [statisticsOurs_bear1, statisticsOther_bear1] = get_result(OursVsSmith_bear1);
% figs = plot3DShapeRGB(OursVsSmith_bear1);
% [statisticsOurs_bear2, statisticsOther_bear2] = get_result(OursVsSmith_bear2);
% figs = plot3DShapeRGB(OursVsSmith_bear2);
% [statisticsOurs_cat, statisticsOther_cat] = get_result(OursVsSmith_cat);
% figs = plot3DShapeRGB(OursVsSmith_cat);
% [statisticsOurs_doll, statisticsOther_doll] = get_result(OursVsSmith_doll);
% figs = plot3DShapeRGB(OursVsSmith_doll);
[statisticsOurs_squirrel, statisticsOther_squirrel] = get_result(OursVsSmith_squirrel);
figs = plot3DShapeRGB(OursVsSmith_squirrel);
%% Ours Vs Atkinson 2006
% [statisticsOurs_bear1, statisticsOther_bear1] = get_result(OursVsAtkinson_bear1);
% figs = plot3DShapeRGB(OursVsAtkinson_bear1);
% [statisticsOurs_bear2, statisticsOther_bear2] = get_result(OursVsAtkinson_bear2);
% figs = plot3DShapeRGB(OursVsAtkinson_bear2);
% [statisticsOurs_cat, statisticsOther_cat] = get_result(OursVsAtkinson_cat);
% figs = plot3DShapeRGB(OursVsAtkinson_cat);
% [statisticsOurs_doll, statisticsOther_doll] = get_result(OursVsAtkinson_doll);
% figs = plot3DShapeRGB(OursVsAtkinson_doll);
% [statisticsOurs_squirrel, statisticsOther_squirrel] = get_result(OursVsAtkinson_squirrel);
% figs = plot3DShapeRGB(OursVsAtkinson_squirrel);


%%
function [statisticsOurs, statisticsOther] = get_result(OurVsOther)
    %% statistics
    [rows,cols,~,pags] = size(OurVsOther.OtherN_est);
    err_All_Other = [];
    err_All_Ours = [];
    for i = 1 : pags
        N_desired = OurVsOther.N_desired;
        N_Other= OurVsOther.OtherN_est(:,:,:,i);
        N_Ours = OurVsOther.OursN_est(:,:,:,i);
        Mask = logical(OurVsOther.Mask_SonyDataset);
        error_Other = getErrorNormalAngle(N_Other, N_desired, Mask);
        error_Ours= getErrorNormalAngle(N_Ours, N_desired, Mask);  
        statisticsOther.MAE(i) = mean(error_Other(Mask));
        statisticsOther.SD(i) = std(error_Other(Mask));
        statisticsOther.MED(i) = median(error_Other(Mask));
        statisticsOther.MAX(i) = max(error_Other(Mask));
        statisticsOurs.MAE(i) = mean(error_Ours(Mask));
        statisticsOurs.SD(i) = std(error_Ours(Mask));
        statisticsOurs.MED(i) = median(error_Ours(Mask));
        statisticsOurs.MAX(i) = max(error_Ours(Mask));
        err_All_Other = [err_All_Other; error_Other(Mask)];
        err_All_Ours = [err_All_Ours; error_Ours(Mask)];
    end   
    statisticsOther.MAE(pags + 1) = mean(err_All_Other);
    statisticsOther.SD(pags + 1) = std(err_All_Other);
    statisticsOther.MED(pags + 1) = median(err_All_Other);
    statisticsOther.MAX(pags + 1) = max(err_All_Other);
    statisticsOurs.MAE(pags + 1) = mean(err_All_Ours);
    statisticsOurs.SD(pags + 1) = std(err_All_Ours);
    statisticsOurs.MED(pags + 1) = median(err_All_Ours);
    statisticsOurs.MAX(pags + 1) = max(err_All_Ours);
    %%
    outputData(statisticsOther.MAE, statisticsOurs.MAE, "MAE");
%     outputData(statisticsOther.SD, statisticsOurs.SD, "SD");
    outputData(statisticsOther.MED, statisticsOurs.MED, "MED");
%     outputData(statisticsOther.MAX, statisticsOurs.MAX, "MAX");

 end


%% plot 3D Normal RGB
function fig = plot3DShapeRGB(OursVsOther)
    Mask = OursVsOther.Mask_SonyDataset;
    [r, c] = find(Mask);
    offset = 10;
    r1 = min(r) - offset; r2 = max(r) + offset;
    c1 = min(c)- offset; c2 = max(c) + offset;
    Mask_crop = Mask(r1:r2, c1:c2);
    %%
    fig.Desired = figure;
    N_desired_crop = OursVsOther.N_desired(r1:r2, c1:c2, :);
    plot3DShape(fig.Desired, N_desired_crop, Mask_crop, false);
    %%
    fig.Ours = figure;
    N_est_ours_crop = OursVsOther.OursN_est(r1:r2, c1:c2, :);
    plot3DShape(fig.Ours, N_est_ours_crop, Mask_crop, false);
    %%
    fig.Other = figure;
    N_est_other_crop = OursVsOther.OtherN_est(r1:r2, c1:c2, :);
    plot3DShape(fig.Other, N_est_other_crop, Mask_crop, false);
end


function outputData(dataOther, dataOurs, name)
    fprintf("statistics \n\t%s:\n\t\tOther:\t", name);
    for i = 1 : length(dataOther)
        fprintf("\t%.3f,",dataOther(i));
    end
    fprintf("\n\t\tOurs:\t");
    for i = 1 : length(dataOurs)
        fprintf("\t%.3f,",dataOurs(i));
    end
    fprintf("\n\t\tRate:\t");
    for i = 1 : length(dataOurs)
        fprintf("\t%.2f%%,",(dataOther(i) - dataOurs(i)) / dataOther(i) * 100);
    end
    fprintf("\n");
end