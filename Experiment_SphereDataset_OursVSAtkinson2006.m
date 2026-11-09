%% Our sphere dataset
clc; 
clear; 
close all;
if isempty(gcp('nocreate'))
    parpool('local', 2);
end
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
%% Atkinson2006
maeOrth = NaN(length(nameList), numLights);
maePers = NaN(length(nameList), numLights);
fprintf("Atkinson2006 method (Sphere dataset)\n");
for numObj = 1 : length(nameList)
    N_Orth = NaN(rows, cols, 3, numLights);
    N_Pers = NaN(rows, cols, 3, numLights);
    N_Desired = NaN(rows, cols, 3, numLights);
    maskAll = false(rows, cols, numLights);
    objName = char(nameList(numObj));
    objData = dataset.(objName); 
    parfor numLight = 1 : numLights
        polarImage = objData(numLight).polarImage;
        Mask = objData(numLight).mask;
        % desired
        [N_desired, ~, Mask_valid, ~] = getSphereNormalFromViewingDirection(V, objData(numLight).maskAll);
        Mask_valid = Mask_valid & Mask;
        % methods
        N_Atkinson = getSurfaceNormalFromDiffuseReflection_AccurateNew(polarImage, Psi_orth, Beta_orth, V_orth, eta, a, Mask_valid);
        N_AtkinsonPers = getSurfaceNormalFromDiffuseReflection_AccurateNew(polarImage, Psi, Beta, V, eta, a, Mask_valid);
        N_Atkinson = getRefinedSurfaceNormal(N_Atkinson, N_desired);
        N_AtkinsonPers = getRefinedSurfaceNormal(N_AtkinsonPers, N_desired);    
        % error
        error_Orth = rad2deg(getErrorNormalAngle(N_Atkinson, N_desired, Mask_valid));
        error_Pers = rad2deg(getErrorNormalAngle(N_AtkinsonPers, N_desired, Mask_valid));  
        maeOrth(numObj, numLight) = mean(error_Orth(Mask_valid));
        maePers(numObj, numLight) = mean(error_Pers(Mask_valid));  
        % save
        N_Orth(:,:,:,numLight) = N_Atkinson;
        N_Pers(:,:,:,numLight) = N_AtkinsonPers;
        N_Desired(:,:,:,numLight) = N_desired;
        maskAll(:,:, numLight) = Mask_valid;  
    end
    % output
    fprintf("\tP%i: \t\tOrth. / Pers. \t\t\t\t\t\tOrth. / Pers.  \n", numObj);
    fprintf("\t\tMAE:  %.3f / %.3f / %.3f%%\n", mean(maeOrth(numObj,:)), mean(maePers(numObj,:)), mean((maeOrth(numObj,:) - maePers(numObj,:)) ./ maeOrth(numObj,:)) * 100);
    % save
    nameSave = ['./Data/Data_ExperimentSphereDataset_OursVsAtkinson_', objName, '.mat'];
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

            dataset.(current_objects)(k).polarImage.I0 = rgb2gray(im2double(imread(fullfile(folderPathSub, '2_0°.png'))));
            dataset.(current_objects)(k).polarImage.I45 = rgb2gray(im2double(imread(fullfile(folderPathSub, '2_45°.png'))));
            dataset.(current_objects)(k).polarImage.I90 = rgb2gray(im2double(imread(fullfile(folderPathSub, '2_90°.png'))));
            dataset.(current_objects)(k).polarImage.I135 = rgb2gray(im2double(imread(fullfile(folderPathSub, '2_135°.png'))));
            
            dataset.(current_objects)(k).lightDirection = str2num(char(extractBetween(fileread(fullfile(folderPathSub, 'LightDirection.txt')), '[', ']'))); 
            dataset.(current_objects)(k).lightDirection = dataset.(current_objects)(k).lightDirection ./ norm(dataset.(current_objects)(k).lightDirection);
            txtPath = fullfile(folderPathSub, 'Intensity.txt');
            dataset.(current_objects)(k).intensity = sscanf(fileread(txtPath), 'Intensity: %f');
            dataset.(current_objects)(k).mask = im2double(imread(fullfile(folderPath, 'mask_2.png'))) > 0.99;
            dataset.(current_objects)(k).maskAll = im2double(imread(fullfile(folderPath, 'mask_B.png'))) > 0.99;
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

