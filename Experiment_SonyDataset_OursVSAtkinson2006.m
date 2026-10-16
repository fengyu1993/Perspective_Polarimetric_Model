%% Sony Dataset: Recovery of Surface Orientation From Diffuse Polarization
clc; 
clear; 
close all;
%%
% dataset = reatdSonyDataset('Data\SONY\');
dataset = load('./Data/Data_SonyDataset.mat');
eta = 1.5; a = 1;
%% parameters
[rows, cols] = size(dataset.bear1(1).polarImage.I0);
f = 12.5; pixelPitch = 2.5e-3; 
effectivePitch = 1 * pixelPitch;
fxy = f / effectivePitch;  
K = [fxy,  0,  cols/2; 0, -fxy, rows/2; 0,  0,  1];
V_orth = zeros(rows, cols, 3); V_orth(:,:,3) = 1;
Beta_orth = zeros(rows, cols);
Psi_orth = zeros(rows, cols);
%% prepare
nameList = dataset.nameList; % "bear1"    "bear2"    "cat"    "cup1"    "cup3"    "doll"    "squirrel"
for numName = 1 : length(nameList) 
    objName = char(nameList(numName));
    objData = dataset.(objName); 
    Atkinson_SonyDataset = NaN(rows, cols, 3, length(objData));
    AtkinsonPers_SonyDataset = NaN(rows, cols, 3, length(objData));
    Mask_SonyDataset = NaN(rows, cols, length(objData));
    %% calculate
    Mask = ones(rows, cols);
    for i = 1 : length(objData)
        Mask = Mask & objData(i).mask;
    end
    V = getViewingDirection(K, Mask);  
    Beta = getPerspectiveDistortionAngle(V, Mask);
    Psi = getPsiAngle(V, Mask);
    for i = 1 : length(objData)
        %% parameters
        polarImage = objData(i).polarImage;   
        N_desired = objData(i).normal;
        %% methods
        % 两种方法使用相同的输入掩膜
        N_Atkinson = getSurfaceNormalFromDiffuseReflection_AccurateNew(polarImage, Psi_orth, Beta_orth, V_orth, eta, a, Mask);
        N_AtkinsonPers = getSurfaceNormalFromDiffuseReflection_AccurateNew(polarImage, Psi, Beta, V, eta, a, Mask);
        N_Atkinson = getRefinedSurfaceNormal(N_Atkinson, N_desired);
        N_AtkinsonPers = getRefinedSurfaceNormal(N_AtkinsonPers, N_desired);
        Atkinson_SonyDataset(:,:,:, i) = N_Atkinson;
        AtkinsonPers_SonyDataset(:,:,:, i) = N_AtkinsonPers;    
        % 共同评估区域
        gtLength = sqrt(sum(N_desired.^2, 3));
        Mask_valid = Mask & all(isfinite(N_desired), 3) & isfinite(gtLength) & gtLength > 0;
        Mask_SonyDataset(:,:,i) = Mask_valid;
        %% Error
        error_Atkinson = getErrorNormalAngle(N_Atkinson, N_desired, Mask_valid);
        error_AtkinsonPers = getErrorNormalAngle(N_AtkinsonPers, N_desired, Mask_valid);  
        %% plot
%         error_Atkinson_deg = rad2deg(error_Atkinson);
%         error_AtkinsonPers_deg = rad2deg(error_AtkinsonPers);
%         fprintf('Sony %s: %i Atkinson MAE old / pers: %.3f / %.3f deg\n', objName, i, mean(error_Atkinson_deg(Mask_valid)), mean(error_AtkinsonPers_deg(Mask_valid)));
%         figure;
%         subplot(1, 2, 1); h = imagesc(error_Atkinson_deg); set(h, 'AlphaData', Mask_valid); set(gca, 'Color', 'k'); axis image off; colormap(parula); cb = colorbar; ylabel(cb, 'Angular error (deg)'); title('Atkinson');
%         subplot(1, 2, 2); h = imagesc(error_AtkinsonPers_deg); set(h, 'AlphaData', Mask_valid); set(gca, 'Color', 'k'); axis image off; colormap(parula); cb = colorbar; ylabel(cb, 'Angular error (deg)'); title('AtkinsonPers');
    end
    %% statistics
    err_plot_Atkinson = zeros(rows, cols);
    err_plot_AtkinsonPers = zeros(rows, cols);
    sumMask = zeros(rows, cols);
    for i = 1 : length(objData)
        N_Atkinson = Atkinson_SonyDataset(:,:,:,i);
        N_AtkinsonPers = AtkinsonPers_SonyDataset(:,:,:,i);
        Mask = logical(Mask_SonyDataset(:,:,i));
        error_Atkinson = getErrorNormalAngle(N_Atkinson, N_desired, Mask);
        error_AtkinsonPers = getErrorNormalAngle(N_AtkinsonPers, N_desired, Mask);  
        err_plot_Atkinson(Mask) = err_plot_Atkinson(Mask) + error_Atkinson(Mask);
        err_plot_AtkinsonPers(Mask) = err_plot_AtkinsonPers(Mask) + error_AtkinsonPers(Mask);
        sumMask(Mask) = sumMask(Mask) + 1;
    end   
    err_plot_Atkinson_mean = NaN(rows, cols);
    err_plot_AtkinsonPers_mean = NaN(rows, cols);
    id = sumMask > 0;
    err_plot_Atkinson_mean(id) = err_plot_Atkinson(id) ./ sumMask(id);
    err_plot_AtkinsonPers_mean(id) = err_plot_AtkinsonPers(id) ./ sumMask(id);
    figure;
    ax = subplot(1, 2, 1); h = imagesc(err_plot_AtkinsonPers_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('AtkinsonPers');
    ax = subplot(1, 2, 2); h = imagesc(err_plot_Atkinson_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Atkinson');
    fprintf('Sony dataset MAE (deg) Atkinson / AtkinsonPers: %.3f / %.3f\n', rad2deg(mean(err_plot_Atkinson_mean(id))), rad2deg(mean(err_plot_AtkinsonPers_mean(id))));
%     fprintf('Sony dataset SD (deg) Atkinson / AtkinsonPers: %.3f / %.3f\n', rad2deg(std(err_plot_Atkinson_mean(id))), rad2deg(std(err_plot_AtkinsonPers_mean(id))));
%     fprintf('Sony dataset MED (deg) Atkinson / AtkinsonPers: %.3f / %.3f\n', rad2deg(median(err_plot_Atkinson_mean(id))), rad2deg(median(err_plot_AtkinsonPers_mean(id))));
%     fprintf('Sony dataset Max (deg) Atkinson / AtkinsonPers: %.3f / %.3f\n', rad2deg(max(err_plot_Atkinson_mean(id))), rad2deg(max(err_plot_AtkinsonPers_mean(id))));
    %% save
    nameSave = ['./Data/Data_ExperimentSonyDataset_OursVsAtkinson_', objName, '.mat'];
    save(nameSave,'Atkinson_SonyDataset', 'AtkinsonPers_SonyDataset', 'Mask_SonyDataset');
end






%%
function dataset = reatdSonyDataset(location)
    subLocation = ["SONY1", "SONY2", "SONY3"];
    subsubLocation = {
        ["bear1", "bear2", "cat"];  
        ["cup1", "cup3"];            
        ["doll",  "squirrel"]         
    };
    subsubsubLocation = ["1", "2", "3", "4", "5", "6", "7", "8"];
    dataset = struct(); 
    % data
    for i = 1 : length(subLocation)
        current_objects = subsubLocation{i}; 
        for j = 1 : length(current_objects)
            objName = char(current_objects(j));
            for k = 1 : length(subsubsubLocation)
                folderPath = fullfile(location, subLocation(i), objName, subsubsubLocation(k));
                dataset.(objName)(k).polarImage.I0 = im2double(imread(fullfile(folderPath, 'A000.tif')));
                dataset.(objName)(k).polarImage.I45 = im2double(imread(fullfile(folderPath, 'A045.tif')));
                dataset.(objName)(k).polarImage.I90 = im2double(imread(fullfile(folderPath, 'A090.tif')));
                dataset.(objName)(k).polarImage.I135 = im2double(imread(fullfile(folderPath, 'A135.tif')));
                dataset.(objName)(k).lightDirection = im2double(load(fullfile(folderPath, 'LightDirection.txt')));
                dataset.(objName)(k).mask = im2double(imread(fullfile(folderPath, 'mask.png'))) > 0.99;
                normal = (im2double(imread(fullfile(folderPath, 'normal.png'))) * 2.0 - 1.0) .* dataset.(objName)(k).mask;
                normalLength = sqrt(sum(normal.^2, 3));
                normalLength(normalLength == 0) = 1;  
                dataset.(objName)(k).normal = normal ./ normalLength;                
%                 figure('Position', [0, 0, 1400, 750], 'Color', 'w', 'Name', objName + "_" + subsubsubLocation(k)); 
%                 subplot(3, 4, 1); imshow(dataset.(objName)(k).polarImage.I0, []);
%                 subplot(3, 4, 2); imshow(dataset.(objName)(k).polarImage.I45, []);
%                 subplot(3, 4, 3); imshow(dataset.(objName)(k).polarImage.I90, []);
%                 subplot(3, 4, 4); imshow(dataset.(objName)(k).polarImage.I135, []);
%                 subplot(3, 4, 5); imshow(dataset.(objName)(k).polarImage.I0 .* dataset.(objName)(k).mask, []);
%                 subplot(3, 4, 6); imshow(dataset.(objName)(k).polarImage.I45 .* dataset.(objName)(k).mask, []);
%                 subplot(3, 4, 7); imshow(dataset.(objName)(k).polarImage.I90 .* dataset.(objName)(k).mask, []);
%                 subplot(3, 4, 8); imshow(dataset.(objName)(k).polarImage.I135 .* dataset.(objName)(k).mask, []);
%                 subplot(3, 4, 9); imshow(dataset.(objName)(k).mask, []);
%                 subplot(3, 4, 10); imshow((dataset.(objName)(k).normal + 1) / 2);
%                 subplot(3, 4, 11); imshow((dataset.(objName)(k).normal .* dataset.(objName)(k).mask + 1) / 2);   
            end
        end
    end
    %% name
    dataset.nameList = ["bear1", "bear2", "cat", "cup1", "cup3", "doll", "squirrel"];
    save('./Data/Data_SonyDataset.mat', '-struct', 'dataset');
end









