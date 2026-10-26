%% Sony Dataset: Surface Normals and Light Directions from Shading and Polarization
clc; 
clear; 
close all;
%%
% dataset = reatdSonyDataset('Data\SONY\');
dataset = load('./Data/Data_SonyDataset.mat');
eta = 1.5;
%% parameters
[rows, cols] = size(dataset.bear1(1).polarImage.I0);
f = 12.5; pixelPitch = 2.5e-3; 
effectivePitch = 1 * pixelPitch;
fxy = f / effectivePitch;  
K = [fxy,  0,  cols/2; 0, -fxy, rows/2; 0,  0,  1];
%% prepare
nameList = dataset.nameList; % "bear1"    "bear2"    "cat"    "cup1"    "cup3"    "doll"    "squirrel"
for numName = 1 : length(nameList) 
    objName = char(nameList(numName));
    objData = dataset.(objName); 
    Smith_SonyDataset = NaN(rows, cols, 3, length(objData));
    SmithPers_SonyDataset = NaN(rows, cols, 3, length(objData));
    Mask_SonyDataset = ones(rows, cols);
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
        E = double(objData(i).intensity);
        fields = {'I0', 'I45', 'I90', 'I135'};
        for k = 1:4
            polarImage.(fields{k}) = polarImage.(fields{k}) ./ E;
        end
        N_desired = objData(i).normal;
        lightDirection = objData(i).lightDirection;
        %% methods
        % 两种方法使用相同的输入掩膜
        [N_Smith, Mask_Smith] = getSurfaceNormal_Smith2019(polarImage, eta, Mask, lightDirection');  
        [N_SmithPers, Mask_Pers] = getSurfaceNormal_Smith2019Pers(polarImage, eta, Mask, lightDirection', Psi, Beta);   
        Smith_SonyDataset(:,:,:, i) = N_Smith;
        SmithPers_SonyDataset(:,:,:, i) = N_SmithPers;    
        % 共同评估区域
        gtLength = sqrt(sum(N_desired.^2, 3));
        Mask_valid = Mask & Mask_Smith & Mask_Pers & all(isfinite(N_desired), 3) & isfinite(gtLength) & gtLength > 0;
        Mask_SonyDataset = Mask_SonyDataset & Mask_valid;
        %% Error
        error_Smith = getErrorNormalAngle(N_Smith, N_desired, Mask_valid);
        error_SmithPers = getErrorNormalAngle(N_SmithPers, N_desired, Mask_valid);  
        %% plot
        error_Smith_deg = rad2deg(error_Smith);
        error_SmithPers_deg = rad2deg(error_SmithPers);
        fprintf('Sony %s: %i Smith MAE old / pers: %.3f / %.3f deg\n', objName, i, mean(error_Smith_deg(Mask_valid)), mean(error_SmithPers_deg(Mask_valid)));
%         figure;
%         subplot(1, 2, 1); h = imagesc(error_Smith_deg); set(h, 'AlphaData', Mask_valid); set(gca, 'Color', 'k'); axis image off; colormap(parula); cb = colorbar; ylabel(cb, 'Angular error (deg)'); title('Smith');
%         subplot(1, 2, 2); h = imagesc(error_SmithPers_deg); set(h, 'AlphaData', Mask_valid); set(gca, 'Color', 'k'); axis image off; colormap(parula); cb = colorbar; ylabel(cb, 'Angular error (deg)'); title('SmithPers');
    end
    %% statistics
    err_plot_Smith = zeros(rows, cols);
    err_plot_SmithPers = zeros(rows, cols);
    sumMask = zeros(rows, cols);
    Mask = logical(Mask_SonyDataset);
    for i = 1 : length(objData)
        N_Smith = Smith_SonyDataset(:,:,:,i);
        N_SmithPers = SmithPers_SonyDataset(:,:,:,i);
        error_Smith = getErrorNormalAngle(N_Smith, N_desired, Mask);
        error_SmithPers = getErrorNormalAngle(N_SmithPers, N_desired, Mask);  
        err_plot_Smith(Mask) = err_plot_Smith(Mask) + error_Smith(Mask);
        err_plot_SmithPers(Mask) = err_plot_SmithPers(Mask) + error_SmithPers(Mask);
        sumMask(Mask) = sumMask(Mask) + 1;
    end   
    err_plot_Smith_mean = NaN(rows, cols);
    err_plot_SmithPers_mean = NaN(rows, cols);
    id = sumMask > 0;
    err_plot_Smith_mean(id) = err_plot_Smith(id) ./ sumMask(id);
    err_plot_SmithPers_mean(id) = err_plot_SmithPers(id) ./ sumMask(id);
    figure;
    ax = subplot(1, 2, 1); h = imagesc(err_plot_SmithPers_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('SmithPers');
    ax = subplot(1, 2, 2); h = imagesc(err_plot_Smith_mean); set(h, 'AlphaData', id); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Smith');
    fprintf('Sony dataset MAE (deg) Smith / SmithPers: %.3f / %.3f\n', rad2deg(mean(err_plot_Smith_mean(id))), rad2deg(mean(err_plot_SmithPers_mean(id))));
    fprintf('Sony dataset SD (deg) Smith / SmithPers: %.3f / %.3f\n', rad2deg(std(err_plot_Smith_mean(id))), rad2deg(std(err_plot_SmithPers_mean(id))));
    fprintf('Sony dataset MED (deg) Smith / SmithPers: %.3f / %.3f\n', rad2deg(median(err_plot_Smith_mean(id))), rad2deg(median(err_plot_SmithPers_mean(id))));
    fprintf('Sony dataset Max (deg) Smith / SmithPers: %.3f / %.3f\n', rad2deg(max(err_plot_Smith_mean(id))), rad2deg(max(err_plot_SmithPers_mean(id))));
    %% save
    nameSave = ['./Data/Data_ExperimentSonyDataset_OursVsSmith_', objName, '.mat'];
    OtherN_est = Smith_SonyDataset;
    OursN_est = SmithPers_SonyDataset;
    save(nameSave,'OtherN_est', 'OursN_est', 'Mask_SonyDataset', 'N_desired');
end







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
            Mask =  dataset.(objName)(1).mask & dataset.(objName)(2).mask & dataset.(objName)(3).mask & dataset.(objName)(4).mask ...
                      & dataset.(objName)(5).mask & dataset.(objName)(6).mask & dataset.(objName)(7).mask & dataset.(objName)(8).mask;
            dataset.(objName)(1).mask = Mask; dataset.(objName)(2).mask = Mask; 
            dataset.(objName)(3).mask = Mask; dataset.(objName)(4).mask = Mask; 
            dataset.(objName)(5).mask = Mask; dataset.(objName)(6).mask = Mask; 
            dataset.(objName)(7).mask = Mask; dataset.(objName)(8).mask = Mask; 

        end
    end
    %% name
    dataset.nameList = ["bear1", "bear2", "cat", "cup1", "cup3", "doll", "squirrel"];
    save('./Data/Data_SonyDataset.mat', '-struct', 'dataset');
end