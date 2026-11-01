%% Our sphere dataset
clc; 
clear; 
close all;
%% load data
% dataset = getSphereDataset_20261031(".\Data\Sphere\data_20261031");
dataset = load("Data\Data_SphereDataset_20261031.mat");
nameList = dataset.nameList;
% number = [2 3 5 8 9 12 14 15 18 19 21 24 25 28 30 31];
% nameList = nameList(number);
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
cfg.ws = 0.5; 
cfg.kn = 100; 
cfg.lambda = 1;  
cfg.darkThreshold = 0.08;
%% Ngo2022
maeOrth = NaN(length(nameList), 1);
maePers = NaN(length(nameList), 1);
fprintf("Ngo2022 method (Sphere dataset)\n");
for numObj = 1 : length(nameList)
    objData = dataset.(nameList(numObj));
    [N_desired, ~, Mask_valid, ~] = getSphereNormalFromViewingDirection(V, objData(1).maskAll);
    for numLight = 1 : 4
        objData(numLight).mask = objData(numLight).mask & Mask_valid;
        objData(numLight).intensity = 1;
    end
    Mask = objData(1).mask;
    % methods
    [N_Ngo2022, eta_Ngo2022] = getNormalNgo2022(objData, cfg);
    [N_Ngo2022Pers, eta_Ngo2022Pers] = getNormalNgo2022_Pers(objData, V, cfg);
    % error
    %%
    error_Orth = rad2deg(getErrorNormalAngle(N_Ngo2022, N_desired, Mask));
    error_Pers = rad2deg(getErrorNormalAngle(N_Ngo2022Pers, N_desired, Mask));  
    % output
    fig = figure('Position', [0, 0, 1400, 750], 'Color', 'w'); 
    ax = subplot(2, 3, 1); h = imagesc(error_Orth); set(h, 'AlphaData', Mask); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Orth.');
    ax = subplot(2, 3, 3); h = imagesc(error_Pers); set(h, 'AlphaData', Mask); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Pers.');
    subplot(2,3,4); plot3DShape(fig, N_desired, Mask); title("Desired");
    subplot(2,3,5); plot3DShape(fig, N_Ngo2022, Mask); title("Orth.");
    subplot(2,3,6); plot3DShape(fig, N_Ngo2022Pers, Mask); title("Pers.");
    % statistic
    statistic_Orth = getStatistic(error_Orth, Mask);
    statistic_Pers = getStatistic(error_Pers, Mask);
    maeOrth(numObj) = statistic_Orth.MAE;
    maePers(numObj) = statistic_Pers.MAE;
    fprintf("\tP%i: \t\tOrth. / Pers. \t\t\t\t\t\tOrth. / Pers.  \n", numObj);
    fprintf("\t\tMAE:  %.3f / %.3f / %.3f%%", statistic_Orth.MAE, statistic_Pers.MAE, (statistic_Orth.MAE - statistic_Pers.MAE) / statistic_Orth.MAE * 100);
    fprintf("\t\tMED:  %.3f / %.3f / %.3f%%\n", statistic_Orth.MED, statistic_Pers.MED, (statistic_Orth.MED - statistic_Pers.MED) / statistic_Orth.MED * 100);
%     fprintf("\t\tMax:  %.3f / %.3f / %.3f%%", statistic_Atkinson.MAX, statistic_AtkinsonPers.MAX, (statistic_Atkinson.MAX - statistic_AtkinsonPers.MAX) / statistic_Atkinson.MAX * 100);
%     fprintf("\t\tSD:  %.3f / %.3f / %.3f%%\n", statistic_Atkinson.SD, statistic_AtkinsonPers.SD, (statistic_Atkinson.SD - statistic_AtkinsonPers.SD) / statistic_Atkinson.SD * 100);
end
% statistic
k = 1;
improveRate = (maeOrth - maePers) ./ maeOrth * 100;
id = find(improveRate > k);
fprintf('Improvement rate > %i%%: ', k);
fprintf('%i ', id);
fprintf('\n');
% plot
figure;
plot(1:length(nameList), maeOrth);
hold on;
plot(1:length(nameList), maePers);
legend("Orth.", "Pers.");
figure;
plot(1:length(nameList), improveRate);
hold on;
plot(1:length(nameList), zeros(1, length(nameList)), '--');
%
idx = [13, 14, 15, 16;
       12, 11, 10,  9;
        5,  6,  7,  8;
        4,  3,  2,  1];
resultOrth = maeOrth(idx);
resultPers = maePers(idx);
figure;
subplot(1,3,1);
h = heatmap(resultOrth); h.Colormap = parula;
subplot(1,3,2);
h = heatmap(resultPers); h.Colormap = parula;
subplot(1,3,3);
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


function dataset = getSphereDataset_20261031(location)
    posNum = "P" + string(1:32);
    lightNum = "L" + string(1:4);
    dataset = struct(); 
    dataset.view_dirs = load(fullfile(location, 'view_dirs.mat')).dirs;
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
            dataset.(current_objects)(k).lightDirection = -dataset.(current_objects)(k).lightDirection ./ norm(dataset.(current_objects)(k).lightDirection);
            dataset.(current_objects)(k).mask = im2double(imread(fullfile(folderPath, 'mask_1.png'))) > 0.99;
            dataset.(current_objects)(k).maskAll = im2double(imread(fullfile(folderPath, 'mask_A.png'))) > 0.99;
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
    save('./Data/Data_SphereDataset_20261031.mat', '-struct', 'dataset');
end


