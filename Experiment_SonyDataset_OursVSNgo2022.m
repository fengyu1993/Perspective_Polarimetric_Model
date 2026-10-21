%% Sony Dataset: Surface Normals and Light Directions from Shading and Polarization
clc; 
% clear; 
close all;
%%
% dataset = reatdSonyDataset('Data\SONY\');
% dataset = load('./Data/Data_SonyDataset.mat');
eta = 1.5;
%% parameters
[rows, cols] = size(dataset.bear1(1).polarImage.I0);
f = 12.5; pixelPitch = 2.5e-3; 
effectivePitch = 1 * pixelPitch;
fxy = f / effectivePitch;  
K = [fxy,  0,  cols/2; 0, -fxy, rows/2; 0,  0,  1];
%% 
nameList = dataset.nameList; % "bear1"    "bear2"    "cat"    "cup1"    "cup3"    "doll"    "squirrel"
for numName = 1 : length(nameList)
    objData = dataset.(nameList(numName)); 
    [N_Ngo2022, eta_est] = getNormalNgo2022(objData);

end







%% single pixel 
Mask = ones(size(objData(1).polarImage.I0)) == 1;
for num = 1 : length(objData)
    Mask = objData(num).mask & Mask;
end
[rowValid, colValid] = find(Mask == 1);
error = NaN(size(Mask));
for cnt = 1 : length(rowValid)
    row = rowValid(cnt); col = colValid(cnt);
%     row = 578; col = 414;
    polarPixel.I0 = []; polarPixel.I45 = []; polarPixel.I90 = []; polarPixel.I135 = [];
    numLights = numel(objData);
    lightDirection = zeros(numLights, 3);
    for num = 1 : length(objData)
        polarPixel.I0 = [polarPixel.I0; objData(num).polarImage.I0(row, col)];
        polarPixel.I45 = [polarPixel.I45; objData(num).polarImage.I45(row, col)];
        polarPixel.I90 = [polarPixel.I90; objData(num).polarImage.I90(row, col)];
        polarPixel.I135 = [polarPixel.I135; objData(num).polarImage.I135(row, col)];
        lightDirection(num,:) = objData(num).lightDirection(:).';
    end
    lightDirection = lightDirection ./ vecnorm(lightDirection, 2,2);
    %%
    n_Desired = reshape(objData(1).normal(row,col,:), 3, 1);
    [n_Ngo2022, eta_est, info] = get_normal_Ngo2022_pixel(polarPixel, lightDirection);




    
    error(row, col) = rad2deg(acos(n_Ngo2022' * n_Desired));
    rad2deg(acos(n_Ngo2022' * n_Desired))
end
mean(error(Mask))




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
