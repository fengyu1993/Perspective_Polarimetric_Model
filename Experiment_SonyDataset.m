%% Lemenera Dataset: Surface Normals and Light Directions from Shading and Polarization
clc; 
% clear; 
close all;
%%
% data = reatdSonyDataset('Data\SONY\');
% load('./Data/Data_SonyDataset.mat');

imshow(bear1(1).polarImage.I0, []);
%% 
rows = 780; cols = 1032;
f = 12.5; pixelPitch = 2.5e-3; 
effectivePitch = 2 * pixelPitch;
fxy = f / effectivePitch;  
K = [fxy,  0,  cols/2; 0, -fxy, rows/2; 0,  0,  1];
%%



















































%%
function data = readSonyDataset(location)
    subLocation = ["SONY1", "SONY2", "SONY3"];
    subsubLocation = {
        ["bear1", "bear2", "bunny", "cat"];  
        ["cup1", "cup2", "cup3"];           
        ["doll", "egg", "squirrel"]         
    };
    subsubsubLocation = ["1", "2", "3", "4", "5", "6", "7", "8"];
    data = struct(); 
    % data
    for i = 1 : length(subLocation)
        current_objects = subsubLocation{i}; 
        for j = 1 : length(current_objects)
            objName = char(current_objects(j));
            for k = 1 : length(subsubsubLocation)
                folderPath = fullfile(location, subLocation(i), objName, subsubsubLocation(k));
                data.(objName)(k).polarImage.I0 = double(imread(fullfile(folderPath, 'A000.tif')));
                data.(objName)(k).polarImage.I45 = double(imread(fullfile(folderPath, 'A045.tif')));
                data.(objName)(k).polarImage.I90 = double(imread(fullfile(folderPath, 'A090.tif')));
                data.(objName)(k).polarImage.I135 = double(imread(fullfile(folderPath, 'A135.tif')));
                data.(objName)(k).lightDirection = double(load(fullfile(folderPath, 'LightDirection.txt')));
                data.(objName)(k).mask = ones(780, 1032) == 1;
                data.(objName)(k).normal = ones(780, 1032, 3);
            end
        end
    end
    %% name
    data.nameList = ["bear1", "bear2", "bunny", "cat", "cup1", "cup2", "cup3", "doll", "egg", "squirrel"];
    save('./Data/Data_SonyDataset.mat', '-struct', 'data');
end









