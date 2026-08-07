%% Experiment DeepSfP Dataset
clc; clear; close all;
%%
load('./Data/Data_ExperimentPlaneDeepSfPDataset.mat');
[location, name] = get_name_DeepSfP();
index = get_DeepSfP_test_name(name);
[Err_DeepSfP, Mask_id_DeepSfP] = getDeepSfPStatistics(location, name, index);
%% Statistics
% pers
Err_pers_box = Err_pers(:,:,1);
Err_pers_dragon = Err_pers(:,:,2);
Err_pers_father_christmas = Err_pers(:,:,3);
Err_pers_flamingo = Err_pers(:,:,4);
Err_pers_horse = Err_pers(:,:,5);
Err_pers_vase = Err_pers(:,:,6);
Id_pers_box = Mask_id(:,:,1) == 1;
Id_pers_dragon = Mask_id(:,:,2) == 1;
Id_pers_father_christmas = Mask_id(:,:,3) == 1;
Id_pers_flamingo = Mask_id(:,:,4) == 1;
Id_pers_horse = Mask_id(:,:,5) == 1;
Id_pers_vase = Mask_id(:,:,6) == 1;
% DeepSfP
Err_DeepSfP_box = Err_DeepSfP(:,:,1);
Err_DeepSfP_dragon = Err_DeepSfP(:,:,2);
Err_DeepSfP_father_christmas = Err_DeepSfP(:,:,3);
Err_DeepSfP_flamingo = Err_DeepSfP(:,:,4);
Err_DeepSfP_horse = Err_DeepSfP(:,:,5);
Err_DeepSfP_vase = Err_DeepSfP(:,:,6);
Id_DeepSfP_box = Mask_id_DeepSfP(:,:,1) == 1;
Id_DeepSfP_dragon = Mask_id_DeepSfP(:,:,2) == 1;
Id_DeepSfP_father_christmas = Mask_id_DeepSfP(:,:,3) == 1;
Id_DeepSfP_flamingo = Mask_id_DeepSfP(:,:,4) == 1;
Id_DeepSfP_horse = Mask_id_DeepSfP(:,:,5) == 1;
Id_DeepSfP_vase = Mask_id_DeepSfP(:,:,6) == 1;
%% MAE
% pers
box_pers.MAE = mean(Err_pers_box(Id_pers_box));
dragon_pers.MAE = mean(Err_pers_dragon(Id_pers_dragon));
father_christmas_pers.MAE = mean(Err_pers_father_christmas(Id_pers_father_christmas));
flamingo_pers.MAE = mean(Err_pers_flamingo(Id_pers_flamingo));
horse_pers.MAE = mean(Err_pers_horse(Id_pers_horse));
vase_pers.MAE = mean(Err_pers_vase(Id_pers_vase));
% DeepSfP
box_DeepSfP.MAE = mean(Err_DeepSfP_box(Id_DeepSfP_box));
dragon_DeepSfP.MAE = mean(Err_DeepSfP_dragon(Id_DeepSfP_dragon));
father_christmas_DeepSfP.MAE = mean(Err_DeepSfP_father_christmas(Id_DeepSfP_father_christmas));
flamingo_DeepSfP.MAE = mean(Err_DeepSfP_flamingo(Id_DeepSfP_flamingo));
horse_DeepSfP.MAE = mean(Err_DeepSfP_horse(Id_DeepSfP_horse));
vase_DeepSfP.MAE = mean(Err_DeepSfP_vase(Id_DeepSfP_vase));
%% SD
% pers
box_pers.SD = std(Err_pers_box(Id_pers_box));
dragon_pers.SD = std(Err_pers_dragon(Id_pers_dragon));
father_christmas_pers.SD = std(Err_pers_father_christmas(Id_pers_father_christmas));
flamingo_pers.SD = std(Err_pers_flamingo(Id_pers_flamingo));
horse_pers.SD = std(Err_pers_horse(Id_pers_horse));
vase_pers.SD = std(Err_pers_vase(Id_pers_vase));
% DeepSfP
box_DeepSfP.SD = std(Err_DeepSfP_box(Id_DeepSfP_box));
dragon_DeepSfP.SD = std(Err_DeepSfP_dragon(Id_DeepSfP_dragon));
father_christmas_DeepSfP.SD = std(Err_DeepSfP_father_christmas(Id_DeepSfP_father_christmas));
flamingo_DeepSfP.SD = std(Err_DeepSfP_flamingo(Id_DeepSfP_flamingo));
horse_DeepSfP.SD = std(Err_DeepSfP_horse(Id_DeepSfP_horse));
vase_DeepSfP.SD = std(Err_DeepSfP_vase(Id_DeepSfP_vase));
%% RMSE
% pers
box_pers.RMSE = sqrt(mean(Err_pers_box(Id_pers_box).^2));
dragon_pers.RMSE = sqrt(mean(Err_pers_dragon(Id_pers_dragon).^2));
father_christmas_pers.RMSE = sqrt(mean(Err_pers_father_christmas(Id_pers_father_christmas).^2));
flamingo_pers.RMSE = sqrt(mean(Err_pers_flamingo(Id_pers_flamingo).^2));
horse_pers.RMSE = sqrt(mean(Err_pers_horse(Id_pers_horse).^2));
vase_pers.RMSE = sqrt(mean(Err_pers_vase(Id_pers_vase).^2));
% DeepSfP
box_DeepSfP.RMSE = sqrt(mean(Err_DeepSfP_box(Id_DeepSfP_box).^2));
dragon_DeepSfP.RMSE = sqrt(mean(Err_DeepSfP_dragon(Id_DeepSfP_dragon).^2));
father_christmas_DeepSfP.RMSE = sqrt(mean(Err_DeepSfP_father_christmas(Id_DeepSfP_father_christmas).^2));
flamingo_DeepSfP.RMSE = sqrt(mean(Err_DeepSfP_flamingo(Id_DeepSfP_flamingo).^2));
horse_DeepSfP.RMSE = sqrt(mean(Err_DeepSfP_horse(Id_DeepSfP_horse).^2));
vase_DeepSfP.RMSE = sqrt(mean(Err_DeepSfP_vase(Id_DeepSfP_vase).^2));
%%
% box
fprintf('Box & DeepSfP & $%.3f$ & $%.3f$ & $%.3f$ \\\\ \n & Ours & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$  \\\\\n ', ...
    box_DeepSfP.MAE, box_DeepSfP.SD, box_DeepSfP.RMSE, ...
    box_pers.MAE, box_pers.SD, box_pers.RMSE);
fprintf('\\cdashline{1-5}\n');
fprintf('\\addlinespace[2pt]\n');
% dragon
fprintf('Dragon & DeepSfP & $%.3f$ & $%.3f$ & $%.3f$ \\\\ \n & Ours & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$  \\\\\n  ', ...
    dragon_DeepSfP.MAE, dragon_DeepSfP.SD, dragon_DeepSfP.RMSE, ...
    dragon_pers.MAE, dragon_pers.SD, dragon_pers.RMSE);
fprintf('\\cdashline{1-5}\n');
fprintf('\\addlinespace[2pt]\n');
% flamingo
fprintf('Flamingo & DeepSfP & $%.3f$ & $%.3f$ & $%.3f$ \\\\ \n  & Ours & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$  \\\\\n  ', ...
    flamingo_DeepSfP.MAE, flamingo_DeepSfP.SD, flamingo_DeepSfP.RMSE, ...
    flamingo_pers.MAE, flamingo_pers.SD, flamingo_pers.RMSE);
fprintf('\\cdashline{1-5}\n');
fprintf('\\addlinespace[2pt]\n');
% horse
fprintf('Horse & DeepSfP & $%.3f$ & $%.3f$ & $%.3f$ \\\\ \n & Ours & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$ & $\\mathbf{%.3f}$  \\\\\n  ', ...
    horse_DeepSfP.MAE, horse_DeepSfP.SD, horse_DeepSfP.RMSE, ...
    horse_pers.MAE, horse_pers.SD, horse_pers.RMSE);



%%
function [location, name] = get_name_DeepSfP()
    location = './Data/20260804_Result_DeepSfP_Test/ObjectName_98_normal_data/mat_results/';
    filePattern = fullfile(location, '*.mat');
    dirData = dir(filePattern);
    name = {dirData.name};
end
function index = get_DeepSfP_test_name(name)
    index.name = ["box"; "dragon"; "father_christmas"; "flamingo"; "horse"; "vase"];
    index.Number = cell(length(index.name), 1);
    for i = 1 : length(index.name)
        index.Number{i} = find(contains(name, index.name(i), 'IgnoreCase', true));
    end
end

function [Err_DeepSfP, Mask_id_DeepSfP] = getDeepSfPStatistics(location, name, index)
    Err_DeepSfP = NaN(1024, 1024, length(index.name));
    Mask_id_DeepSfP = NaN(1024, 1024, length(index.name));
    for i = 1 : length(index.name)
        Number = index.Number{i};
        sumErr = zeros(1024, 1024);
        sumMask = zeros(1024, 1024);
        for num = 1 : length(Number)
            data = load([location, name{Number(num)}]);
            Mask = data.Mask == 1;
            error_normal_angle = getErrorNormalAngle(data.N_pred, data.N_gt, Mask);
            sumErr(Mask) = sumErr(Mask) + error_normal_angle(Mask);
            sumMask(Mask) = sumMask(Mask) + 1;
        end
        Err_DeepSfP(:,:,i) = sumErr ./ sumMask;
        Mask_id_DeepSfP(:,:,i) = sumMask > 0;
    end
end