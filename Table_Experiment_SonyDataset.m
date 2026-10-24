%% 对比Sony Dataset
clc; clear; close all;
nameList = ["Bear1", "Bear2", "Doll", "Squirrel"];
% load data
OursVsNgo = load('./Data/Data_ExperimentSonyDataset_OursVsNgo.mat');
OursVsNgoResult(1) = get_DataNgo(OursVsNgo, 1);
OursVsNgoResult(2) = get_DataNgo(OursVsNgo, 2);
OursVsNgoResult(3) = get_DataNgo(OursVsNgo, 6);
OursVsNgoResult(4) = get_DataNgo(OursVsNgo, 7);
% load data
OursVsAtkinsonResult(1) = load('./Data/Data_ExperimentSonyDataset_OursVsAtkinson_bear1.mat');
OursVsAtkinsonResult(2) = load('./Data/Data_ExperimentSonyDataset_OursVsAtkinson_bear2.mat');
OursVsAtkinsonResult(3) = load('./Data/Data_ExperimentSonyDataset_OursVsAtkinson_doll.mat');
OursVsAtkinsonResult(4) = load('./Data/Data_ExperimentSonyDataset_OursVsAtkinson_squirrel.mat');
% load data
OursVsSmithResult(1) = load('./Data/Data_ExperimentSonyDataset_OursVsSmith_bear1.mat');
OursVsSmithResult(2) = load('./Data/Data_ExperimentSonyDataset_OursVsSmith_bear2.mat');
OursVsSmithResult(3) = load('./Data/Data_ExperimentSonyDataset_OursVsSmith_doll.mat');
OursVsSmithResult(4) = load('./Data/Data_ExperimentSonyDataset_OursVsSmith_squirrel.mat');
%% statistic
OursVsAtkinson_MAE = NaN(3, length(OursVsAtkinsonResult));
for i = 1 : length(OursVsAtkinsonResult)
    [Ours, Others] = get_result(OursVsAtkinsonResult(i));
    OursVsAtkinson_MAE(1,i) = Others.MAE(end);
    OursVsAtkinson_MAE(2,i) = Ours.MAE(end);
end
OursVsAtkinson_MAE(3,:) = (OursVsAtkinson_MAE(1,:) - OursVsAtkinson_MAE(2,:)) ./ OursVsAtkinson_MAE(1,:) * 100;
%% statistic
OursVsSmith_MAE = NaN(3, length(OursVsSmithResult));
for i = 1 : length(OursVsSmithResult)
    [Ours, Others] = get_result(OursVsSmithResult(i));
    OursVsSmith_MAE(1,i) = Others.MAE(end);
    OursVsSmith_MAE(2,i) = Ours.MAE(end);
end
OursVsSmith_MAE(3,:) = (OursVsSmith_MAE(1,:) - OursVsSmith_MAE(2,:)) ./ OursVsSmith_MAE(1,:) * 100;
%% statistic
OursVsNgo_MAE = NaN(3, length(OursVsNgoResult));
for i = 1 : length(OursVsNgoResult)
    [Ours, Others] = get_result(OursVsNgoResult(i));
    OursVsNgo_MAE(1,i) = Others.MAE(end);
    OursVsNgo_MAE(2,i) = Ours.MAE(end);
end
OursVsNgo_MAE(3,:) = (OursVsNgo_MAE(1,:) - OursVsNgo_MAE(2,:)) ./ OursVsNgo_MAE(1,:) * 100;
%% statistic
OursVsLyu_MAE = NaN(3, numel(nameList));


%% statistic
OursVsBa_MAE = NaN(3, numel(nameList));



%% output
OursVsNgo_MAE
OursVsSmith_MAE
OursVsAtkinson_MAE


for i = 1 : length(nameList)
    fprintf(['\\textit{%s}' ...
        '& %.2f & $\\mathbf{%.2f}$ & %.2f\\%% & ' ...
        '& %.2f & $\\mathbf{%.2f}$ & %.2f\\%% & ' ...
        '& %.2f & $\\mathbf{%.2f}$ & %.2f\\%% & ' ...
        '& %.2f & $\\mathbf{%.2f}$ & %.2f\\%% & ' ...
        '& %.2f & $\\mathbf{%.2f}$ & %.2f\\%% \\\\ \n'], nameList(i), ...
        OursVsNgo_MAE(1, i), OursVsNgo_MAE(2, i), OursVsNgo_MAE(3, i),...
        OursVsSmith_MAE(1, i), OursVsSmith_MAE(2, i), OursVsSmith_MAE(3, i),...
        OursVsAtkinson_MAE(1, i), OursVsAtkinson_MAE(2, i), OursVsAtkinson_MAE(3, i),...
        OursVsLyu_MAE(1, i), OursVsLyu_MAE(2, i), OursVsLyu_MAE(3, i), ...
        OursVsBa_MAE(1, i), OursVsBa_MAE(2, i), OursVsBa_MAE(3, i));
end

















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
        error_Other = rad2deg(getErrorNormalAngle(N_Other, N_desired, Mask));
        error_Ours= rad2deg(getErrorNormalAngle(N_Ours, N_desired, Mask));  
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

 end