%% Experiment Sony Dataset
clc; clear; close all;
%% Ours Vs Ngo2022
% load data
OursVsNgo = load('./Data/Data_ExperimentSonyDataset_OursVsNgo.mat');
OursVsNgo_bear1 = get_DataNgo(OursVsNgo, 1);
OursVsNgo_bear2 = get_DataNgo(OursVsNgo, 2);
OursVsNgo_doll = get_DataNgo(OursVsNgo, 6);
OursVsNgo_squirrel = get_DataNgo(OursVsNgo, 7);
% plot
[statisticsNgo_Ours_bear1, statisticsNgo_Other_bear1] = get_result(OursVsNgo_bear1);
plot3DShapeRGB(OursVsNgo_bear1, 'bear1', 'Ngo2022');
[statisticsNgo_Ours_bear2, statisticsNgo_Other_bear2] = get_result(OursVsNgo_bear2);
plot3DShapeRGB(OursVsNgo_bear2, 'bear2', 'Ngo2022');
[statisticsNgo_Ours_doll, statisticsNgo_Other_doll] = get_result(OursVsNgo_doll);
plot3DShapeRGB(OursVsNgo_doll, 'doll', 'Ngo2022');
[statisticsNgo_Ours_squirrel, statisticsNgo_Other_squirrel] = get_result(OursVsNgo_squirrel);
plot3DShapeRGB(OursVsNgo_squirrel, 'squirrel', 'Ngo2022');
%% Ours Vs Atkinson2006 TIP
% load data
OursVsAtkinson_bear1 = load('./Data/Data_ExperimentSonyDataset_OursVsAtkinson_bear1.mat');
OursVsAtkinson_bear2 = load('./Data/Data_ExperimentSonyDataset_OursVsAtkinson_bear2.mat');
OursVsAtkinson_doll = load('./Data/Data_ExperimentSonyDataset_OursVsAtkinson_doll.mat');
OursVsAtkinson_squirrel = load('./Data/Data_ExperimentSonyDataset_OursVsAtkinson_squirrel.mat');
% % plot
[statisticsAtkinson_Ours_bear1, statisticsAtkinson_Other_bear1] = get_result(OursVsAtkinson_bear1);
plot3DShapeRGB(OursVsAtkinson_bear1, 'bear1', 'Atkinson2006');
[statisticsAtkinson_Ours_bear2, statisticsAtkinson_Other_bear2] = get_result(OursVsAtkinson_bear2);
plot3DShapeRGB(OursVsAtkinson_bear2, 'bear2', 'Atkinson2006');
[statisticsAtkinson_Ours_doll, statisticsAtkinson_Other_doll] = get_result(OursVsAtkinson_doll);
plot3DShapeRGB(OursVsAtkinson_doll, 'doll', 'Atkinson2006');
[statisticsAtkinson_Ours_squirrel, statisticsAtkinson_Other_squirrel] = get_result(OursVsAtkinson_squirrel);
plot3DShapeRGB(OursVsAtkinson_squirrel, 'squirrel', 'Atkinson2006');
%% Ours Vs Smith2019 TPAMI
% load data
OursVsSmith_bear1 = load('./Data/Data_ExperimentSonyDataset_OursVsSmith_bear1.mat');
OursVsSmith_bear2 = load('./Data/Data_ExperimentSonyDataset_OursVsSmith_bear2.mat');
OursVsSmith_doll = load('./Data/Data_ExperimentSonyDataset_OursVsSmith_doll.mat');
OursVsSmith_squirrel = load('./Data/Data_ExperimentSonyDataset_OursVsSmith_squirrel.mat');
% plot
[statisticsSmith2019_Ours_bear1, statisticsSmith2019_Other_bear1] = get_result(OursVsSmith_bear1);
plot3DShapeRGB(OursVsSmith_bear1, 'bear1', 'Smith2019');
[statisticsSmith2019_Ours_bear2, statisticsSmith2019_Other_bear2] = get_result(OursVsSmith_bear2);
plot3DShapeRGB(OursVsSmith_bear2, 'bear2', 'Smith2019');
[statisticsSmith2019_Ours_doll, statisticsSmith2019_Other_doll] = get_result(OursVsSmith_doll);
plot3DShapeRGB(OursVsSmith_doll, 'doll', 'Smith2019');
[statisticsSmith2019_Ours_squirrel, statisticsSmith2019_Other_squirrel] = get_result(OursVsSmith_squirrel);
plot3DShapeRGB(OursVsSmith_squirrel, 'squirrel', 'Smith2019');



%%
function OursVsNgo_num = get_DataNgo(data, num)
    OursVsNgo_num.OtherN_est = data.N_Ngo2022_SonyDataset(:,:,:,num);
    OursVsNgo_num.OursN_est = data.N_Ngo2022Pers_SonyDataset(:,:,:,num);
    OursVsNgo_num.N_desired = data.N_Desired_SonyDataset(:,:,:,num);
    OursVsNgo_num.Mask_SonyDataset = data.Mask_SonyDataset(:,:,num);
end

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
    outputData(statisticsOther.SD, statisticsOurs.SD, "SD");
    outputData(statisticsOther.MED, statisticsOurs.MED, "MED");
    outputData(statisticsOther.MAX, statisticsOurs.MAX, "MAX");

 end


%% plot 3D Normal RGB
function fig = plot3DShapeRGB(OursVsOther, objName, methName)
    %%  
    Mask = OursVsOther.Mask_SonyDataset;
    [r, c] = find(Mask);
    offset = 60;
    r1 = min(r) - offset; r2 = max(r) + offset;
    c1 = min(c)- offset; c2 = max(c) + offset;
    Mask_crop = Mask(r1:r2, c1:c2);
    %%
    fig.Desired = figure;
    N_desired_crop = OursVsOther.N_desired(r1:r2, c1:c2, :);
    plot3DShape(fig.Desired, N_desired_crop, Mask_crop, false);
    fullPath = fullfile(['./imageSony/', char(methName)], ['fig_', char(objName), '_desired.png']);
    exportgraphics(fig.Desired, fullPath, 'Resolution', 300);
    %%
    fig.Ours = figure;
    N_est_ours_crop = OursVsOther.OursN_est(r1:r2, c1:c2, :);
    plot3DShape(fig.Ours, N_est_ours_crop, Mask_crop, false);
    fullPath = fullfile(['./imageSony/', char(methName)], ['fig_', char(objName), '_pers.png']);
    exportgraphics(fig.Ours, fullPath, 'Resolution', 300);
    %%
    fig.Other = figure;
    N_est_other_crop = OursVsOther.OtherN_est(r1:r2, c1:c2, :);
    plot3DShape(fig.Other, N_est_other_crop, Mask_crop, false);
    fullPath = fullfile(['./imageSony/', char(methName)], ['fig_', char(objName), '_orth.png']);
    exportgraphics(fig.Other, fullPath, 'Resolution', 300);
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