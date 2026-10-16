%% Sony Dataset: Recovery of Surface Orientation From Diffuse Polarization
clc; 
clear; 
close all;
%%
% dataset = reatdSonyDataset('Data\SONY\');
dataset = load('./Data/Data_SonyDataset.mat');
%% parameters
[rows, cols] = size(dataset.bear1(1).polarImage.I0);
f = 12.5; pixelPitch = 2.5e-3; 
effectivePitch = 2 * pixelPitch;
fxy = f / effectivePitch;  
K = [fxy,  0,  cols/2; 0, -fxy, rows/2; 0,  0,  1];
V_orth = zeros(rows, cols, 3); V_orth(:,:,3) = 1;
Beta_orth = zeros(rows, cols);
Psi_orth = zeros(rows, cols);
etaList = [1.91, 1.60, 1.81, 1.91, 1.88, 1.92, 1.89];
aList = [0.60, 0.84, 0.60, 0.60, 0.60, 0.60, 0.60];
etaList = ones(1,7)*1.9;
aList = ones(1,7)*0.6;
%% calculate
err_plot_Ours = zeros(rows, cols); 
err_plot_Atkinson2006 = zeros(rows, cols);
sumMask = zeros(rows, cols);
nameList = dataset.nameList;
nameList = dataset.nameList(1:2);
for num = 1 : length(nameList)
    eta = etaList(num);
    a = aList(num);
    objName = char(nameList(num));
    objData = dataset.(objName);
%     objData = dataset.(objName)(1);
    for i = 1 : length(objData)
        %% parameters
        polarImage = objData(i).polarImage;   
        Mask = objData(i).mask;
        N_desired = objData(i).normal;
        lightDirection = objData(i).lightDirection;
        V = getViewingDirection(K, Mask);  
        Beta = getPerspectiveDistortionAngle(V, Mask);
        Psi = getPsiAngle(V, Mask);
        %% methods
        % ours
        N_Ours = getSurfaceNormalFromDiffuseReflection_AccurateNew(polarImage, Psi, Beta, V, eta, a, Mask);
        % Atkinson2006
        N_Atkinson2006 = getSurfaceNormalFromDiffuseReflection_AccurateNew(polarImage, Psi_orth, Beta_orth, V_orth, eta, a, Mask);
        %% Error
        error_Ours = getErrorNormalAngle(N_Ours, N_desired, Mask);
        error_Atkinson2006 = getErrorNormalAngle(N_Atkinson2006, N_desired, Mask);       
        %% Statistics
        err_plot_Ours(Mask) = err_plot_Ours(Mask) + error_Ours(Mask);
        err_plot_Atkinson2006(Mask) = err_plot_Atkinson2006(Mask) + error_Atkinson2006(Mask);
        sumMask(Mask) = sumMask(Mask) + 1;
    end
end
%% plot
err_plot_Ours_mean = NaN(rows, cols);
err_plot_Atkinson2006_mean = NaN(rows, cols);
id = sumMask > 0;
err_plot_Ours_mean(id) = err_plot_Ours(id) ./ sumMask(id);
err_plot_Atkinson2006_mean(id) = err_plot_Atkinson2006(id) ./ sumMask(id);
figure;
ax = subplot(1, 2, 1); h = imagesc(err_plot_Ours_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Ours');
ax = subplot(1, 2, 2); h = imagesc(err_plot_Atkinson2006_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Atkinson2006');
fprintf('Sony dataset MAE (deg) Ours/Atkinson2006: %.3f / %.3f\n', rad2deg(mean(err_plot_Ours_mean(id))), rad2deg(mean(err_plot_Atkinson2006_mean(id))));
fprintf('Sony dataset SD (deg) Ours/Atkinson2006: %.3f / %.3f\n', rad2deg(std(err_plot_Ours_mean(id))), rad2deg(std(err_plot_Atkinson2006_mean(id))));
fprintf('Sony dataset MED (deg) Ours/Atkinson2006: %.3f / %.3f\n', rad2deg(median(err_plot_Ours_mean(id))), rad2deg(median(err_plot_Atkinson2006_mean(id))));
fprintf('Sony dataset Max (deg) Ours/Atkinson2006: %.3f / %.3f\n', rad2deg(max(err_plot_Ours_mean(id))), rad2deg(max(err_plot_Atkinson2006_mean(id))));
%%
% save('./Data/Data_ExperimentSonyDataset.mat', 'id', 'sumMask',...
%     'err_plot_Ours_mean', 'err_plot_Atkinson2006_mean');







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









