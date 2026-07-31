%% Experiment DeepSfP Dataset
clc; clear; close all;
%%
load('./Data/Data_ExperimentPlaneDeepSfPDataset_pers_orth.mat');
%%
row = 1024; col = 1224;
FontSize = 23;
LineWidth = 2;
Scale = 1.2;
Resolution = 300;
%% statistics
casename = ["indoor", "outdoor_cloudy", "outdoor_sunny"];
for caseNum = 1 : 3
    fprintf("%s:\n", casename(caseNum));
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
    fprintf('\t MAE \t %.3f \t %.3f\n', mean(Err_pers_sta(Id)), mean(Err_orth_sta(Id)));
    fprintf('\t SD \t %.3f \t %.3f\n', std(Err_pers_sta(Id)), std(Err_orth_sta(Id)));
    fprintf('\t RMSE \t %.3f \t %.3f\n', sqrt(mean(Err_pers_sta(Id).^2)), sqrt(mean(Err_orth_sta(Id).^2)));
    fprintf('\t MAX \t %.3f \t %.3f\n', max(Err_pers_sta(Id)), max(Err_orth_sta(Id)));
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
%% Plot indoor
% perspective
figPers = figure('Position', [100, 100, 620, 420]);
ax = axes(figPers);
h = imagesc(Err_pers_indoor); set(h, 'AlphaData', Id_indoor); set(ax, 'Color', 'w'); 
axis equal; axis([0, col, 0, row]);
set(ax, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize',  FontSize *  Scale , 'FontName', 'Times New Roman', 'LineWidth',  LineWidth );
set(gca,'LineWidth',  LineWidth );
xtickangle(0);
colormap(ax, parula); 
colorbar(ax); 
title('Ours', 'FontSize',  FontSize *  Scale, 'FontName', 'Times New Roman');
exportgraphics(figPers, 'fig_exp_DeepSfP_dataset_indoor_pers.png', 'Resolution', Resolution);
% orthographic 
figOrth = figure('Position', [100, 100, 620, 420]);
ax = axes(figOrth);
h = imagesc(Err_orth_indoor); set(h, 'AlphaData', Id_indoor); set(ax, 'Color', 'w'); 
axis equal; axis([0, col, 0, row]);
set(ax, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize',  FontSize *  Scale , 'FontName', 'Times New Roman', 'LineWidth',  LineWidth );
set(gca,'LineWidth',  LineWidth );
xtickangle(0);
colormap(ax, parula); 
colorbar(ax); 
title('Orth.', 'FontSize',  FontSize *  Scale, 'FontName', 'Times New Roman');
exportgraphics(figOrth, 'fig_exp_DeepSfP_dataset_indoor_orth.png', 'Resolution', Resolution);
%% Plot outdoor_cloudy
% perspective
figPers = figure('Position', [100, 100, 620, 420]);
ax = axes(figPers);
h = imagesc(Err_pers_outdoor_cloudy); set(h, 'AlphaData', Id_outdoor_cloudy); set(ax, 'Color', 'w'); 
axis equal; axis([0, col, 0, row]);
set(ax, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize',  FontSize *  Scale , 'FontName', 'Times New Roman', 'LineWidth',  LineWidth );
set(gca,'LineWidth',  LineWidth );
xtickangle(0);
colormap(ax, parula); 
colorbar(ax); 
title('Ours', 'FontSize',  FontSize *  Scale, 'FontName', 'Times New Roman');
exportgraphics(figPers, 'fig_exp_DeepSfP_dataset_outdoor_cloudy_pers.png', 'Resolution', Resolution);
% orthographic 
figOrth = figure('Position', [100, 100, 620, 420]);
ax = axes(figOrth);
h = imagesc(Err_orth_outdoor_cloudy); set(h, 'AlphaData', Id_outdoor_cloudy); set(ax, 'Color', 'w'); 
axis equal; axis([0, col, 0, row]);
set(ax, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize',  FontSize *  Scale , 'FontName', 'Times New Roman', 'LineWidth',  LineWidth );
set(gca,'LineWidth',  LineWidth );
xtickangle(0);
colormap(ax, parula); 
colorbar(ax); 
title('Orth.', 'FontSize',  FontSize *  Scale, 'FontName', 'Times New Roman');
exportgraphics(figOrth, 'fig_exp_DeepSfP_dataset_outdoor_cloudy_orth.png', 'Resolution', Resolution);
%% Plot outdoor_sunny
% perspective
figPers = figure('Position', [100, 100, 620, 420]);
ax = axes(figPers);
h = imagesc(Err_pers_outdoor_sunny); set(h, 'AlphaData', Id_outdoor_sunny); set(ax, 'Color', 'w'); 
axis equal; axis([0, col, 0, row]);
set(ax, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize',  FontSize *  Scale , 'FontName', 'Times New Roman', 'LineWidth',  LineWidth );
set(gca,'LineWidth',  LineWidth );
xtickangle(0);
colormap(ax, parula); 
colorbar(ax); 
title('Ours', 'FontSize',  FontSize *  Scale, 'FontName', 'Times New Roman');
exportgraphics(figPers, 'fig_exp_DeepSfP_dataset_outdoor_sunny_pers.png', 'Resolution', Resolution);
% orthographic 
figOrth = figure('Position', [100, 100, 620, 420]);
ax = axes(figOrth);
h = imagesc(Err_orth_outdoor_sunny); set(h, 'AlphaData', Id_outdoor_sunny); set(ax, 'Color', 'w'); 
axis equal; axis([0, col, 0, row]);
set(ax, 'xtick', 0:400:1200, 'ytick', 0:250:1000, 'FontSize',  FontSize *  Scale , 'FontName', 'Times New Roman', 'LineWidth',  LineWidth );
set(gca,'LineWidth',  LineWidth );
xtickangle(0);
colormap(ax, parula); 
colorbar(ax); 
title('Orth.', 'FontSize',  FontSize *  Scale, 'FontName', 'Times New Roman');
exportgraphics(figOrth, 'fig_exp_DeepSfP_dataset_outdoor_sunny_orth.png', 'Resolution', Resolution);











for objectNum = 1 : length(index.name)
    fprintf("%s:\n", index.name(objectNum));
    for caseNum = 1 : 3
        fprintf("%s:\n\t\t\t Pers.\t\t Orth. \n", casename(caseNum));
        err_pers = Err_pers(:,:,caseNum, objectNum);
        err_orth = Err_orth(:,:,caseNum, objectNum);
        mask_sum = Mask_sum(:,:,caseNum, objectNum);
        id = ID(:,:,caseNum, objectNum) == 1;
        err_sta =  rad2deg(err_pers(id) ./ mask_sum(id));
        err_orth_sta = rad2deg(err_orth(id) ./ mask_sum(id));   
        fprintf('\t MAE \t %.3f \t %.3f\n', mean(err_sta), mean(err_orth_sta));
        fprintf('\t SD \t %.3f \t %.3f\n', std(err_sta), std(err_orth_sta));
        fprintf('\t RMSE \t %.3f \t %.3f\n', sqrt(mean(err_sta.^2)), sqrt(mean(err_orth_sta.^2)));
        fprintf('\t MAX \t %.3f \t %.3f\n', max(err_sta), max(err_orth_sta));
    end
end










