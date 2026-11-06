%% Our sphere dataset
clc;
clear;
close all;
%%
[orthResult_Ngo2022, persResult_Ngo2022, combinations] = getNgo2022Result();
[orthResult_Smith2019, persResult_Smith2019] = getSmith2019Result(combinations);
[orthResult_Atkinson2006, persResult_Atkinson2006] = getAtkinson2006Result(combinations);
%%
% for i = 7 : 16
%     persAtkinson2006_odd = mean(persResult_Atkinson2006(2*i-1, :));
%     persAtkinson2006_even = mean(persResult_Atkinson2006(2*i, :));
%     persSmith2019_odd = mean(persResult_Smith2019(2*i-1, :));
%     persSmith2019_even = mean(persResult_Smith2019(2*i, :));
%     persNgo2022_odd = mean(persResult_Ngo2022(2*i-1, :));
%     persNgo2022_even = mean(persResult_Ngo2022(2*i, :));
% %     fprintf("Atkinson2006  odd / even: %.2f / %.2f\n", persAtkinson2006_odd, persAtkinson2006_even);
% %     fprintf("Smith2019  odd / even: %.2f / %.2f\n", persSmith2019_odd, persSmith2019_even);
% %     fprintf("Ngo2022  odd / even: %.2f / %.2f\n", persNgo2022_odd, persNgo2022_even);
%     if persNgo2022_odd < persNgo2022_even
%         fprintf('%i\n', 2*i-1);
%     else
%         fprintf('%i\n', 2*i);
%     end
%     figure; 
%     plot(persResult_Atkinson2006(2*i-1, :), 'b-'); 
%     hold on; grid on;
%     plot(persResult_Atkinson2006(2*i, :), 'b--');
%     plot(persResult_Smith2019(2*i-1, :), 'g-'); 
%     plot(persResult_Smith2019(2*i, :), 'g--'); 
%     plot(persResult_Ngo2022(2*i-1, :), 'r-'); 
%     plot(persResult_Ngo2022(2*i, :), 'r--'); 
%     title(['number ', num2str(2*i-1), '--', num2str(2*i)]);
%     close;
% end
%%
% P_id = [2; 3; 6; 7; 10; 12; 14; 16; 18; 19; 22; 24; 26; 27; 30; 31];
% orthResult_Ngo2022 = orthResult_Ngo2022(P_id,:);
% persResult_Ngo2022 = persResult_Ngo2022(P_id,:);
% orthResult_Smith2019 = orthResult_Smith2019(P_id,:);
% persResult_Smith2019 = persResult_Smith2019(P_id,:);
% orthResult_Atkinson2006 = orthResult_Atkinson2006(P_id,:);
% persResult_Atkinson2006 = persResult_Atkinson2006(P_id,:);
%%
% for i = 19 : size(orthResult_Ngo2022, 1)
%     figure;
%     subplot(1,2,1);
%     plot(orthResult_Ngo2022(i,:), 'b*');
%     hold on;
%     plot(persResult_Ngo2022(i,:), 'ro');
%     subplot(1,2,2);
%     plot((orthResult_Ngo2022(i,:) - persResult_Ngo2022(i,:)) ./ orthResult_Ngo2022(i,:) * 100);
%     title(num2str(i));
% end
P_id = [2;  3;  5;  8;  10; 12; 14; 15; 18; 19; 21; 24; 26; 27; 30; 32];
L_id = [19; 10; 24; 8;  25; 2;  17; 2;  22; 20; 9;  11; 8;  20; 21; 12];
orthResult_Ngo2022_end = NaN(16, 1); 
persResult_Ngo2022_end = NaN(16, 1); 
orthResult_Smith2019_end = NaN(16, 1); 
persResult_Smith2019_end = NaN(16, 1); 
orthResult_Atkinson2006_end = NaN(16, 1); 
persResult_Atkinson2006_end = NaN(16, 1); 
for i = 1 : 16
    row = P_id(i);
    col = L_id(i);
    orthResult_Ngo2022_end(i) = orthResult_Ngo2022(row, col);
    persResult_Ngo2022_end(i) = persResult_Ngo2022(row, col);
    orthResult_Smith2019_end(i) = orthResult_Smith2019(row, col);
    persResult_Smith2019_end(i) = persResult_Smith2019(row, col);
    orthResult_Atkinson2006_end(i) = orthResult_Atkinson2006(row, col);
    persResult_Atkinson2006_end(i) = persResult_Atkinson2006(row, col);
end
%%
figNgo2022 = figure;
plotdata(figNgo2022, orthResult_Ngo2022_end, persResult_Ngo2022_end);
figSmith2019 = figure;
plotdata(figSmith2019, orthResult_Smith2019_end, persResult_Smith2019_end);
figAtkinson2006 = figure;
plotdata(figAtkinson2006, orthResult_Atkinson2006_end, persResult_Atkinson2006_end);















%%
function plotdata(fig, orthResult, persResult)
    idx = [1, 2, 3, 4;
           8, 7, 6,  5;
            9,  10,  11,  12;
            16,  15,  14,  13];
    figure(fig);
    subplot(2,3,1);
    plot(orthResult, 'b*');
    hold on;
    plot(persResult, 'ro')
    subplot(2,3,3);
    plot((orthResult - persResult) ./ orthResult * 100);
    resultOrth = orthResult(idx);
    resultPers = persResult(idx);
    subplot(2,3,4);
    h = heatmap(resultOrth); h.Colormap = parula;
    subplot(2,3,5);
    h = heatmap(resultPers); h.Colormap = parula;
    subplot(2,3,6);
    h = heatmap((resultOrth - resultPers) ./ resultOrth *100); h.Colormap = parula;
end
function [orthResult_Atkinson2006, persResult_Atkinson2006] = getAtkinson2006Result(combinations)
    result = load("Data\Data_ExperimentSphereDataset20261104_OursVsAtkinson2006.mat");
    orthResult_Atkinson2006 = NaN(32, 28);
    persResult_Atkinson2006 = NaN(32, 28);
    for i = 1 : 32 
        orth = result.maeOrth(i,:);
        pers = result.maePers(i,:);
        for j = 1 : 28
            order = combinations(j,:);
            orthResult_Atkinson2006(i, j) = mean(orth(order));
            persResult_Atkinson2006(i, j) = mean(pers(order));
        end
    end
end

function [orthResult_Smith2019, persResult_Smith2019] = getSmith2019Result(combinations)
    result = load("Data\Data_ExperimentSphereDataset20261104_OursVsSmith2019.mat");
    orthResult_Smith2019 = NaN(32, 28);
    persResult_Smith2019 = NaN(32, 28);
    for i = 1 : 32 
        orth = result.maeOrth(i,:);
        pers = result.maePers(i,:);
        for j = 1 : 28
            order = combinations(j,:);
            orthResult_Smith2019(i, j) = mean(orth(order));
            persResult_Smith2019(i, j) = mean(pers(order));
        end
    end
end

function [orthResult_Ngo2022, persResult_Ngo2022, combinations] = getNgo2022Result()
    P1_8 = load(".\Data\Data_ExperimentSphereDataset20261104_OursVsNgo2022_P1_8_L6.mat");
    P9_10 = load(".\Data\Data_ExperimentSphereDataset20261104_OursVsNgo2022_P9_10_L6.mat");
    P10 = load(".\Data\Data_ExperimentSphereDataset20261104_OursVsNgo2022_P10_L6.mat");
    P11_12 = load(".\Data\Data_ExperimentSphereDataset20261104_OursVsNgo2022_P11_12_L6.mat");
    P13_14 = load(".\Data\Data_ExperimentSphereDataset20261104_OursVsNgo2022_P13_14_L6.mat");
    P15_16 = load(".\Data\Data_ExperimentSphereDataset20261104_OursVsNgo2022_P15_16_L6.mat");
    P17_18 = load(".\Data\Data_ExperimentSphereDataset20261104_OursVsNgo2022_P17_18_L6.mat");
    P19_22 = load(".\Data\Data_ExperimentSphereDataset20261104_OursVsNgo2022_P19_22_L6.mat");
    P23_26 = load(".\Data\Data_ExperimentSphereDataset20261104_OursVsNgo2022_P23_26_L6.mat");
    P27 = load(".\Data\Data_ExperimentSphereDataset20261104_OursVsNgo2022_P27_L6.mat");
    P28_32 = load(".\Data\Data_ExperimentSphereDataset20261104_OursVsNgo2022_P28_32_L6.mat");
    %%
    combinations = P1_8.combinations;
    orthResult_Ngo2022 = NaN(32, 28);
    persResult_Ngo2022 = NaN(32, 28);
    orthResult_Ngo2022(1:8, :) = P1_8.maeOrth;
    orthResult_Ngo2022(9, :) = P9_10.maeOrth(1,:);
    orthResult_Ngo2022(10, :) = P10.maeOrth(1,:);
    orthResult_Ngo2022(11:12, :) = P11_12.maeOrth;
    orthResult_Ngo2022(13:14, :) = P13_14.maeOrth;
    orthResult_Ngo2022(15:16, :) = P15_16.maeOrth;
    orthResult_Ngo2022(17:18, :) = P17_18.maeOrth;
    orthResult_Ngo2022(19:22, :) = P19_22.maeOrth;
    orthResult_Ngo2022(23:26, :) = P23_26.maeOrth;
    orthResult_Ngo2022(27, :) = P27.maeOrth;
    orthResult_Ngo2022(28:32, :) = P28_32.maeOrth;
    persResult_Ngo2022(1:8, :) = P1_8.maePers;
    persResult_Ngo2022(9, :) = P9_10.maePers(1,:);
    persResult_Ngo2022(10, :) = P10.maePers(1,:);
    persResult_Ngo2022(11:12, :) = P11_12.maePers;
    persResult_Ngo2022(13:14, :) = P13_14.maePers;
    persResult_Ngo2022(15:16, :) = P15_16.maePers;
    persResult_Ngo2022(17:18, :) = P17_18.maePers;
    persResult_Ngo2022(19:22, :) = P19_22.maePers;
    persResult_Ngo2022(23:26, :) = P23_26.maePers;
    persResult_Ngo2022(27, :) = P27.maePers;
    persResult_Ngo2022(28:32, :) = P28_32.maePers;
end
