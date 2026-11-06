%% Our sphere dataset
clc; 
clear; 
close all;
if isempty(gcp('nocreate'))
    parpool('local', 2);
end
%% load data
% dataset = getSphereDataset_20261103(".\Data\Sphere\data_20261103");
% dataset = getSphereDataset_20261104_undistort(".\Data\Sphere\data_20261104");
% dataset = load("Data\Data_SphereDataset_20261103.mat");
dataset = load("Data\Data_SphereDataset_20261104_undistort.mat");
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
Flag = 2;
numLights = 8;
%%
if Flag == 1
    %% Atkinson2006
    maeOrth = NaN(length(nameList), numLights);
    maePers = NaN(length(nameList), numLights);
    fprintf("Atkinson2006 method (Sphere dataset)\n");
    for numObj = 1 : length(nameList)
        objData = dataset.(nameList(numObj));
        errorAll_Orth = NaN(rows, cols, 4);
        errorAll_Pers = NaN(rows, cols, 4);
        maskAll = false(rows, cols, 4);
        for numLight = 1 : numLights
            polarImage = objData(numLight).polarImage;
            Mask = objData(numLight).mask;
            % desired
            [N_desired, ~, Mask_valid, ~] = getSphereNormalFromViewingDirection(V, objData(numLight).maskAll);
            % methods
            N_Atkinson = getSurfaceNormalFromDiffuseReflection_AccurateNew(polarImage, Psi_orth, Beta_orth, V_orth, eta, a, Mask_valid);
            N_AtkinsonPers = getSurfaceNormalFromDiffuseReflection_AccurateNew(polarImage, Psi, Beta, V, eta, a, Mask_valid);
            N_Atkinson = getRefinedSurfaceNormal(N_Atkinson, N_desired);
            N_AtkinsonPers = getRefinedSurfaceNormal(N_AtkinsonPers, N_desired);    
            % error
            error_Orth = rad2deg(getErrorNormalAngle(N_Atkinson, N_desired, Mask_valid));
            error_Pers = rad2deg(getErrorNormalAngle(N_AtkinsonPers, N_desired, Mask_valid));  
            errorAll_Orth(:,:, numLight) = error_Orth;
            errorAll_Pers(:,:, numLight) = error_Pers;
            maskAll(:,:, numLight) = Mask_valid;
            maeOrth(numObj, numLight) = mean(error_Orth(Mask_valid));
            maePers(numObj, numLight) = mean(error_Pers(Mask_valid));
            % output
    %         figure('Position', [0, 0, 1400, 750], 'Color', 'w'); 
    %         subplot(2, 2, 1); imshow(polarImage.I0, []);
    %         subplot(2, 2, 2); imshow(polarImage.I45, []);
    %         subplot(2, 2, 3); imshow(polarImage.I90, []);
    %         subplot(2, 2, 4); imshow(polarImage.I135, []);
    %         fig = figure('Position', [0, 0, 1400, 750], 'Color', 'w'); 
    %         ax = subplot(2, 3, 1); h = imagesc(error_Orth); set(h, 'AlphaData', Mask_valid); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Orth.');
    %         ax = subplot(2, 3, 3); h = imagesc(error_Pers); set(h, 'AlphaData', Mask_valid); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Pers.');
    %         subplot(2,3,4); plot3DShape(fig, N_desired, Mask_valid); title("Desired");
    %         subplot(2,3,5); plot3DShape(fig, N_Atkinson, Mask_valid); title("Orth.");
    %         subplot(2,3,6); plot3DShape(fig, N_AtkinsonPers, Mask_valid); title("Pers.");
        end
        statistic_Orth = getStatistic(errorAll_Orth, maskAll);
        statistic_Pers = getStatistic(errorAll_Pers, maskAll);  
        fprintf("\tP%i: \t\tOrth. / Pers. \t\t\t\t\t\tOrth. / Pers.  \n", numObj);
        fprintf("\t\tMAE:  %.3f / %.3f / %.3f%%", statistic_Orth.MAE, statistic_Pers.MAE, (statistic_Orth.MAE - statistic_Pers.MAE) / statistic_Orth.MAE * 100);
        fprintf("\t\tMED:  %.3f / %.3f / %.3f%%\n", statistic_Orth.MED, statistic_Pers.MED, (statistic_Orth.MED - statistic_Pers.MED) / statistic_Orth.MED * 100);
    end
    nameSave = ['./Data/Data_ExperimentSphereDataset20261104_OursVsAtkinson2006','.mat'];
    save(nameSave, 'maeOrth', 'maePers');
elseif Flag == 2
    %% Smith2019
    maeOrth = NaN(length(nameList), numLights);
    maePers = NaN(length(nameList), numLights);
    fprintf("Smith2019 method (Sphere dataset)\n");
    for numObj = 14 : length(nameList)
        objData = dataset.(nameList(numObj));
        errorAll_Orth = NaN(rows, cols, 4);
        errorAll_Pers = NaN(rows, cols, 4);
        maskAll = false(rows, cols, 4);
        parfor numLight = 1 : numLights
            polarImage = objData(numLight).polarImage;
            Mask = objData(numLight).mask;
            lightDirection = objData(numLight).lightDirection';
            % desired
            [N_desired, ~, Mask_valid, ~] = getSphereNormalFromViewingDirection(V, objData(numLight).maskAll);
            Mask_valid = Mask_valid & Mask;
            % methods
            [N_Smith, Mask_SmithOrth] = getSurfaceNormal_Smith2019(polarImage, eta, Mask_valid, lightDirection');  
            [N_SmithPers, Mask_SmithPers] = getSurfaceNormal_Smith2019Pers(polarImage, eta, Mask_valid, lightDirection', Psi, Beta);   
            Mask_Smith = Mask_valid & Mask_SmithOrth & Mask_SmithPers;
            % error
            error_Orth = rad2deg(getErrorNormalAngle(N_Smith, N_desired, Mask_Smith));
            error_Pers = rad2deg(getErrorNormalAngle(N_SmithPers, N_desired, Mask_Smith));  
            errorAll_Orth(:,:, numLight) = error_Orth;
            errorAll_Pers(:,:, numLight) = error_Pers;
            maskAll(:,:, numLight) = Mask_Smith;
            maeOrth(numObj, numLight) = mean(error_Orth(Mask_Smith));
            maePers(numObj, numLight) = mean(error_Pers(Mask_Smith));
            % output
    %         figure('Position', [0, 0, 1400, 750], 'Color', 'w'); 
    %         subplot(2, 2, 1); imshow(polarImage.I0, []);
    %         subplot(2, 2, 2); imshow(polarImage.I45, []);
    %         subplot(2, 2, 3); imshow(polarImage.I90, []);
    %         subplot(2, 2, 4); imshow(polarImage.I135, []);
    %         fig = figure('Position', [0, 0, 1400, 750], 'Color', 'w'); 
    %         ax = subplot(2, 3, 1); h = imagesc(error_Orth); set(h, 'AlphaData', Mask_valid); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Orth.');
    %         ax = subplot(2, 3, 3); h = imagesc(error_Pers); set(h, 'AlphaData', Mask_valid); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Pers.');
    %         subplot(2,3,4); plot3DShape(fig, N_desired, Mask_valid); title("Desired");
    %         subplot(2,3,5); plot3DShape(fig, N_Smith2019, Mask_valid); title("Orth.");
    %         subplot(2,3,6); plot3DShape(fig, N_Smith2019Pers, Mask_valid); title("Pers.");
        end
        statistic_Orth = getStatistic(errorAll_Orth, maskAll);
        statistic_Pers = getStatistic(errorAll_Pers, maskAll);
        fprintf("\tP%i: \t\tOrth. / Pers. \t\t\t\t\t\tOrth. / Pers.  \n", numObj);
        fprintf("\t\tMAE:  %.3f / %.3f / %.3f%%", statistic_Orth.MAE, statistic_Pers.MAE, (statistic_Orth.MAE - statistic_Pers.MAE) / statistic_Orth.MAE * 100);
        fprintf("\t\tMED:  %.3f / %.3f / %.3f%%\n", statistic_Orth.MED, statistic_Pers.MED, (statistic_Orth.MED - statistic_Pers.MED) / statistic_Orth.MED * 100);
    end
    nameSave = ['./Data/Data_ExperimentSphereDataset20261104_OursVsSmith2019','.mat'];
    save(nameSave, 'maeOrth', 'maePers');
elseif Flag == 3
    %% Ngo2022
    id = [5, 6, 17, 18, 29, 30, 31, 32];
    nameList = nameList(id);
    cfg.ws = 0.5; 
    cfg.kn = 100; 
    cfg.lambda = 1;  
    cfg.darkThreshold = 0.08;
    fprintf("Ngo2022 method (Sphere dataset)\n");
    combinations = nchoosek(1:8, 6);
    numComb = size(combinations, 1);
    maeOrth = NaN(length(nameList), numComb);
    maePers = NaN(length(nameList), numComb);
    for numObj = 1 : length(nameList)
        objName = char(nameList(numObj));
        allData = dataset.(objName);
        [N_desired, ~, Mask_geometry, ~] = getSphereNormalFromViewingDirection(V, allData(1).maskAll);
        Mask_geometry = Mask_geometry & all(isfinite(N_desired), 3);    
        for k = 1 : numComb
            lightIds = combinations(k,:);
            objData = allData(lightIds);
            Mask_input = Mask_geometry;
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
            % output
%             fig = figure('Position', [0, 0, 1400, 750], 'Color', 'w'); 
%             ax = subplot(2, 3, 1); h = imagesc(error_Orth); set(h, 'AlphaData', Mask); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Orth.');
%             ax = subplot(2, 3, 3); h = imagesc(error_Pers); set(h, 'AlphaData', Mask); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Pers.');
%             subplot(2,3,4); plot3DShape(fig, N_desired, Mask); title("Desired");
%             subplot(2,3,5); plot3DShape(fig, N_Ngo2022, Mask); title("Orth.");
%             subplot(2,3,6); plot3DShape(fig, N_Ngo2022Pers, Mask); title("Pers.");
            % statistic
            statistic_Orth = getStatistic(error_Orth, Mask_eval);
            statistic_Pers = getStatistic(error_Pers, Mask_eval);
            maeOrth(numObj, k) = statistic_Orth.MAE;
            maePers(numObj, k) = statistic_Pers.MAE;
            fprintf("\tP%i: \t\tOrth. / Pers. \t\t\t\t\t\tOrth. / Pers.  \n", numObj);
            fprintf("\t\tMAE:  %.3f / %.3f / %.3f%%", statistic_Orth.MAE, statistic_Pers.MAE, (statistic_Orth.MAE - statistic_Pers.MAE) / statistic_Orth.MAE * 100);
            fprintf("\t\tMED:  %.3f / %.3f / %.3f%%\n", statistic_Orth.MED, statistic_Pers.MED, (statistic_Orth.MED - statistic_Pers.MED) / statistic_Orth.MED * 100);
        end
    end
    nameSave = ['./Data/Data_ExperimentSphereDataset20261104_OursVsNgo2022_P17_18_L6','.mat'];
    save(nameSave, 'maeOrth', 'maePers', 'combinations');
end 





















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

function dataset = getSphereDataset_20261104_undistort(location)
    posNum = "P" + string(1:32);
    lightNum = "L" + string(1:8);
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
    save('./Data/Data_SphereDataset_20261104_undistort.mat', '-struct', 'dataset');
end
