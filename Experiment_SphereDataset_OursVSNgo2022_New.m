%% Our sphere dataset
clc; 
clear; 
close all;
%% load data
% dataset = getSphereDataset(".\Data\Sphere\data");
dataset = load("Data\Data_SphereDataset.mat");
nameList = dataset.nameList;
%% parameters
eta = 1.5; 
a = 1;
[rows, cols] = size(dataset.P1(1).polarImage.I0);
V_orth = zeros(rows, cols, 3); V_orth(:,:,3) = 1;
Beta_orth = zeros(rows, cols);
Psi_orth = zeros(rows, cols);
V = dataset.view_dirs;
Beta = getPerspectiveDistortionAngle(V, true(rows, cols));
Psi = getPsiAngle(V, true(rows, cols));
numLights = 6;
cfg.ws = 0.5; 
cfg.kn = 100; 
cfg.lambda = 1;  
cfg.darkThreshold = 0.08;
%% Ngo2022
maeOrth = NaN(length(nameList), 1);
maePers = NaN(length(nameList), 1);
fprintf("Ngo2022 method (Sphere dataset)\n");
for numObj = 1 : length(nameList)
    objName = char(nameList(numObj));
    objData = dataset.(objName); 
    N_desired = objData(1).N_desired;
    Mask_input = all(isfinite(N_desired), 3); 
    for j = 1:numel(objData)
        Mask_input = Mask_input & logical(objData(j).mask);
    end
    for j = 1:numel(objData)
        objData(j).mask = Mask_input;
    end
    % methods
    [N_Ngo2022, eta_Ngo2022] = getNormalNgo2022(objData, cfg);
    [N_Ngo2022Pers, eta_Ngo2022Pers] = getNormalNgo2022_Pers(objData, V, cfg);
    % error
    Mask_eval = Mask_input & all(isfinite(N_Ngo2022), 3) & all(isfinite(N_Ngo2022Pers), 3);
    error_Orth = rad2deg(getErrorNormalAngle(N_Ngo2022, N_desired, Mask_eval));
    error_Pers = rad2deg(getErrorNormalAngle(N_Ngo2022Pers, N_desired, Mask_eval));  
    maeOrth(numObj, 1) = mean(error_Orth(Mask_eval));
    maePers(numObj, 1) = mean(error_Pers(Mask_eval));  
    % output
    fprintf("\tP%i: \t\tOrth. / Pers. \t\t\t\t\t\tOrth. / Pers.  \n", numObj);
    fprintf("\t\tMAE:  %.3f / %.3f / %.3f%%\n", mean(maeOrth(numObj,:)), mean(maePers(numObj,:)), mean((maeOrth(numObj,:) - maePers(numObj,:)) ./ maeOrth(numObj,:)) * 100);
    % save
    N_Orth = N_Ngo2022;
    N_Pers = N_Ngo2022Pers;
    N_Desired = N_desired;
    maskAll = Mask_eval; 
    nameSave = ['./Data/Data_ExperimentSphereDataset_OursVsNgo_', objName, '.mat'];
    save(nameSave, 'N_Orth', 'N_Pers', 'maskAll', 'N_Desired');
end
%% plot
maeOrth = mean(maeOrth, 2);
maePers = mean(maePers, 2);
figure;
subplot(2,3,1);
plot(1:length(nameList), maeOrth);
hold on;
plot(1:length(nameList), maePers);
legend("Orth.", "Pers.");
subplot(2,3,3);
plot(1:length(nameList), (maeOrth - maePers) ./ maeOrth *100);
hold on;
plot(1:length(nameList), zeros(1, length(nameList)), '--');
%
idx = [1, 2, 3, 4;
       8, 7, 6,  5;
       9,  10,  11,  12;
       16,  15,  14,  13];
resultOrth = maeOrth(idx);
resultPers = maePers(idx);
subplot(2,3,4);
h = heatmap(resultOrth); h.Colormap = parula;
subplot(2,3,5);
h = heatmap(resultPers); h.Colormap = parula;
subplot(2,3,6);
h = heatmap((resultOrth - resultPers) ./ resultOrth *100); h.Colormap = parula;























%%
function statistic = getStatistic(errorList, maskList)
    [~, ~, pags] = size(errorList);
    errVect = [];
    for num = 1 : pags
        mask = maskList(:,:, num);
        error = errorList(:,:, num);
        errVect = [errVect; error(mask)];
    end
    statistic.MAE = mean(errVect);
    statistic.SD = std(errVect);
    statistic.MED = median(errVect);
    statistic.MAX = max(errVect);
end



function dataset = getSphereDataset(location)
    posNum = "P" + string(1:16);
    lightNum = "L" + string(1:6);
    dataset = struct(); 
    dataset.view_dirs = load(fullfile(location, 'view_dirs.mat')).dirs;
    dataset.cameraParams = load(fullfile(location, 'cameraParams.mat')).cameraParams;
    % data
    for j = 1 : length(posNum)
        folderPath = fullfile(location, string(posNum(j)));  
        current_objects = char(posNum(j));
        for k = 1 : length(lightNum)
            folderPathSub = fullfile(folderPath, string(lightNum(k)));

            dataset.(current_objects)(k).polarImage.I0 = rgb2gray(im2double(imread(fullfile(folderPathSub, '1_0°.png'))));
            dataset.(current_objects)(k).polarImage.I45 = rgb2gray(im2double(imread(fullfile(folderPathSub, '1_45°.png'))));
            dataset.(current_objects)(k).polarImage.I90 = rgb2gray(im2double(imread(fullfile(folderPathSub, '1_90°.png'))));
            dataset.(current_objects)(k).polarImage.I135 = rgb2gray(im2double(imread(fullfile(folderPathSub, '1_135°.png'))));
            
            dataset.(current_objects)(k).lightDirection = str2num(char(extractBetween(fileread(fullfile(folderPathSub, 'LightDirection.txt')), '[', ']'))); 
            dataset.(current_objects)(k).lightDirection = dataset.(current_objects)(k).lightDirection ./ norm(dataset.(current_objects)(k).lightDirection);
            txtPath = fullfile(folderPathSub, 'Intensity.txt');
            dataset.(current_objects)(k).intensity = sscanf(fileread(txtPath), 'Intensity: %f');
            dataset.(current_objects)(k).mask = im2double(imread(fullfile(folderPath, 'mask.png'))) > 0.99;
            dataset.(current_objects)(k).N_desired = im2double(imread(fullfile(folderPath, 'normal.png'))) .* 2 - 1;
%             figure; imshow(normal);
%             figure('Position', [0, 0, 1400, 750], 'Color', 'w'); 
%             subplot(2, 4, 1); imshow(dataset.(current_objects)(k).polarImage.I0, []);
%             subplot(2, 4, 2); imshow(dataset.(current_objects)(k).polarImage.I45, []);
%             subplot(2, 4, 3); imshow(dataset.(current_objects)(k).polarImage.I90, []);
%             subplot(2, 4, 4); imshow(dataset.(current_objects)(k).polarImage.I135, []);
%             dataset.(current_objects)(k).polarImage.I0(~dataset.(current_objects)(k).mask) = 0;
%             dataset.(current_objects)(k).polarImage.I45(~dataset.(current_objects)(k).mask) = 0;
%             dataset.(current_objects)(k).polarImage.I90(~dataset.(current_objects)(k).mask) = 0;
%             dataset.(current_objects)(k).polarImage.I135(~dataset.(current_objects)(k).mask) = 0;
%             subplot(2, 4, 5); imshow(dataset.(current_objects)(k).polarImage.I0, []);
%             subplot(2, 4, 6); imshow(dataset.(current_objects)(k).polarImage.I45, []);
%             subplot(2, 4, 7); imshow(dataset.(current_objects)(k).polarImage.I90, []);
%             subplot(2, 4, 8); imshow(dataset.(current_objects)(k).polarImage.I135, []);         
        end
        close all;
    end 
    %% save
    dataset.nameList = posNum;
    save('./Data/Data_SphereDataset.mat', '-struct', 'dataset');
end
