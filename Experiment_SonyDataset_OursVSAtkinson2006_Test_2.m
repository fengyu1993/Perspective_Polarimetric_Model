%% 数据分析
clc; clear; close all;
%%
data = load("Data\Data_ExperimentSonyDataset_OursVSAtkinson2006_test_A_ETA.mat");
A = data.A;
ETA = data.ETA;
objNames = ["bear1"    "bear2"    "cat"    "cup1"    "cup3"    "doll"    "squirrel"];
[rows, cols, pages, books] = size(data.error_all_N_angle_Ours);
%%
%% Plot
for i = 1 : pages
    error_Ours_all = zeros(size(A));
    error_Atkinson2006_all = zeros(size(A));
    for j = 1 : books
        error_Ours = data.error_all_N_angle_Ours(:,:,i,j);
        error_Atkinson2006 = data.error_all_N_angle_Atkinson2006(:,:,i,j);
        error_Ours_all = error_Ours * data.sumMask(i,j);
        error_Atkinson2006_all = error_Atkinson2006 * data.sumMask(i,j);
    end
    error_Ours_all = error_Ours_all ./ sum(data.sumMask(i,:));
    minE = min(error_Ours_all(:));
    [rowE, colE] = find(error_Ours_all == minE);
    bestA = A(rowE, colE);
    bestETA = ETA(rowE, colE);
    fprintf("%s--%i: Best a / eta = %.2f, %.2f\n", objNames(i), j, bestA, bestETA);
end
%% Plot
for i = 1 : pages
    figure; 
    for j = 1 : books
        error_Ours = data.error_all_N_angle_Ours(:,:,i,j);
        error_Atkinson2006 = data.error_all_N_angle_Atkinson2006(:,:,i,j);
        subplot(2,4,j);
        hold on; grid on;
        surf(A, ETA, rad2deg(error_Ours), 'FaceAlpha', 0.8, 'EdgeColor', 'none'); 
        mesh(A, ETA, rad2deg(error_Atkinson2006), 'EdgeColor', 'g'); 
        view([30,10]);
        xlabel('a'); ylabel('\eta'); zlabel('Mean Error');
    end

end







