%% Sony Dataset: Surface Normals and Light Directions from Shading and Polarization
clc; 
clear; 
close all;
%%
% dataset = readSonyDataset('Data\SONY\');
dataset = load('./Data/Data_SonyDataset.mat');
%% parameters
[rows, cols] = size(dataset.bear1(1).polarImage.I0);
f = 12.5; pixelPitch = 2.5e-3; 
effectivePitch = 1 * pixelPitch;
fxy = f / effectivePitch;  
K = [fxy,  0,  cols/2; 0, -fxy, rows/2; 0,  0,  1];
cfg.ws = 0.5; 
cfg.kn = 100; 
cfg.lambda = 1;  
cfg.darkThreshold = 0.005;
%% 
nameList = dataset.nameList; % "bear1"    "bear2"    "cat"    "cup1"    "cup3"    "doll"    "squirrel"
N_Ngo2022_SonyDataset = NaN(rows, cols, 3, length(nameList));
N_Ngo2022Pers_SonyDataset = NaN(rows, cols, 3, length(nameList));
N_Desired_SonyDataset = NaN(rows, cols, 3, length(nameList));
Mask_SonyDataset = NaN(rows, cols, length(nameList));
for numName = 1 : length(nameList)
    objData = dataset.(nameList(numName)); 
    [N_Ngo2022, eta_Ngo2022] = getNormalNgo2022(objData, cfg);
    [N_Ngo2022Pers, eta_Ngo2022Pers] = getNormalNgo2022_Pers(objData, K, cfg);
%     N_Ngo2022 = N_Ngo2022Pers;
    N_desired = objData(1).normal;
    Mask = objData(1).mask;
    %%
    error_Ngo2022 = getErrorNormalAngle(N_Ngo2022, N_desired, Mask);  
    error_Ngo2022Pers = getErrorNormalAngle(N_Ngo2022Pers, N_desired, Mask);  
    %%
    N_Ngo2022_SonyDataset(:,:,:, numName) = N_Ngo2022;
    N_Ngo2022Pers_SonyDataset(:,:,:, numName) = N_Ngo2022Pers;
    N_Desired_SonyDataset(:,:,:, numName) = N_desired;
    Mask_SonyDataset(:,:,numName) = Mask;
    fprintf('Sony dataset %s-Ngo2022: MAE (deg) orth. / pers.: %.3f, %.3f\n', nameList(numName), rad2deg(mean(error_Ngo2022(Mask))), rad2deg(mean(error_Ngo2022Pers(Mask))) );
%     fprintf('Sony dataset %s-Ngo2022: SD (deg) orth. / pers.: %.3f, %.3f\n', nameList(numName), rad2deg(std(error_Ngo2022(Mask))), rad2deg(std(error_Ngo2022Pers(Mask))) );
    fprintf('Sony dataset %s-Ngo2022: MED (deg) orth. / pers.: %.3f, %.3f\n', nameList(numName), rad2deg(median(error_Ngo2022(Mask))), rad2deg(median(error_Ngo2022Pers(Mask))) );
%     fprintf('Sony dataset %s-Ngo2022: Max (deg) orth. / pers.: %.3f, %.3f\n', nameList(numName), rad2deg(max(error_Ngo2022(Mask))), rad2deg(max(error_Ngo2022Pers(Mask))) );
end
%%
nameSave = ['./Data/Data_ExperimentSonyDataset_OursVsNgo', '.mat'];
save(nameSave,'N_Ngo2022_SonyDataset', 'N_Ngo2022Pers_SonyDataset', 'N_Desired_SonyDataset', 'Mask_SonyDataset', 'nameList');


%%
function dataset = readSonyDataset(location)
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
                dataset.(objName)(k).intensity = double(load(fullfile(folderPath, 'Intensity.txt')));
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
