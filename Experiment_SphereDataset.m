%% Our sphere dataset
clc; 
clear; 
close all;
%% load data
% dataset = getSphereDataset(".\Data\Sphere\data_20261026");
dataset = load("Data\Data_SphereDataset_20261026.mat");
%% parameters
eta = 1.5; 
a = 1;
[rows, cols] = size(dataset.sphere(1).polarImage.I0);
V_orth = zeros(rows, cols, 3); V_orth(:,:,3) = 1;
Beta_orth = zeros(rows, cols);
Psi_orth = zeros(rows, cols);
V = dataset.view_dirs;
Beta = getPerspectiveDistortionAngle(V, true(rows, cols));
Psi = getPsiAngle(V, true(rows, cols));
%% Atkinson2006
for num = 1 : length(dataset.sphere)
    polarImage = dataset.sphere(num).polarImage;
    Mask = dataset.sphere(num).mask;
%     desired
    [N_desired, ~, Mask_valid, ~] = getSphereNormalFromViewingDirection(V, Mask);
%     methods
    N_Atkinson = getSurfaceNormalFromDiffuseReflection_AccurateNew(polarImage, Psi_orth, Beta_orth, V_orth, eta, a, Mask_valid);
    N_AtkinsonPers = getSurfaceNormalFromDiffuseReflection_AccurateNew(polarImage, Psi, Beta, V, eta, a, Mask_valid);
    N_Atkinson = getRefinedSurfaceNormal(N_Atkinson, N_desired);
    N_AtkinsonPers = getRefinedSurfaceNormal(N_AtkinsonPers, N_desired);
%     error
    error_Atkinson = rad2deg(getErrorNormalAngle(N_Atkinson, N_desired, Mask_valid));
    error_AtkinsonPers = rad2deg(getErrorNormalAngle(N_AtkinsonPers, N_desired, Mask_valid));  
%     output
    statistic_Atkinson = getStatistic(error_Atkinson, Mask_valid);
    statistic_AtkinsonPers = getStatistic(error_AtkinsonPers, Mask_valid);
    fprintf("Sphere dataset %i --- Atkinson2006 method: Orth. / Pers.:  \n", num);
    fprintf("\tMAE:  %.3f / %.3f / %.3f%%", statistic_Atkinson.MAE, statistic_AtkinsonPers.MAE, (statistic_Atkinson.MAE - statistic_AtkinsonPers.MAE) / statistic_Atkinson.MAE * 100);
    fprintf("\tMED:  %.3f / %.3f / %.3f%%\n", statistic_Atkinson.MED, statistic_AtkinsonPers.MED, (statistic_Atkinson.MED - statistic_AtkinsonPers.MED) / statistic_Atkinson.MED * 100);
%     fprintf("\tMax:  %.3f / %.3f / %.3f%%", statistic_Atkinson.MAX, statistic_AtkinsonPers.MAX, (statistic_Atkinson.MAX - statistic_AtkinsonPers.MAX) / statistic_Atkinson.MAX * 100);
%     fprintf("\tSD:  %.3f / %.3f / %.3f%%\n", statistic_Atkinson.SD, statistic_AtkinsonPers.SD, (statistic_Atkinson.SD - statistic_AtkinsonPers.SD) / statistic_Atkinson.SD * 100);
    figure('Position', [0, 0, 1400, 750], 'Color', 'w'); 
    subplot(2, 2, 1); imshow(dataset.sphere(num).polarImage.I0, []);
    subplot(2, 2, 2); imshow(dataset.sphere(num).polarImage.I45, []);
    subplot(2, 2, 3); imshow(dataset.sphere(num).polarImage.I90, []);
    subplot(2, 2, 4); imshow(dataset.sphere(num).polarImage.I135, []);
    figure; 
    ax = subplot(1, 2, 1); h = imagesc(error_Atkinson); set(h, 'AlphaData', Mask_valid); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Orth.');
    ax = subplot(1, 2, 2); h = imagesc(error_AtkinsonPers); set(h, 'AlphaData', Mask_valid); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Pers.');
    fig = figure; plot3DShape(fig, N_desired, Mask_valid);
    fig = figure; plot3DShape(fig, N_Atkinson, Mask_valid);
    fig = figure; plot3DShape(fig, N_AtkinsonPers, Mask_valid);
end
%% Smith2019 
% lightDirection = [sin(pi/4)*cos(pi/4), sin(pi/4)*sin(pi/4), cos(pi/4)];
% for num = 1 : length(dataset.sphere)
%     polarImage = dataset.sphere(num).polarImage;
%     Mask = dataset.sphere(num).mask;
%     % desired
%     [N_desired, ~, Mask_valid, ~] = getSphereNormalFromViewingDirection(V, Mask);
%     % methods
%     [N_Smith, Mask_SmithOrth] = getSurfaceNormal_Smith2019(polarImage, eta, Mask_valid, lightDirection');  
%     [N_SmithPers, Mask_SmithPers] = getSurfaceNormal_Smith2019Pers(polarImage, eta, Mask_valid, lightDirection', Psi, Beta);   
%     Mask_Smith = Mask_valid & Mask_SmithOrth & Mask_SmithPers;
%     % error
%     error_Smith = rad2deg(getErrorNormalAngle(N_Smith, N_desired, Mask_Smith));
%     error_SmithPers = rad2deg(getErrorNormalAngle(N_SmithPers, N_desired, Mask_Smith));  
%     % output
%     statistic_Smith = getStatistic(error_Smith, Mask_Smith);
%     statistic_SmithPers = getStatistic(error_SmithPers, Mask_Smith);
%     fprintf("Sphere dataset---Smith2019 method: Orth. / Pers.:  \n")
%     fprintf("\tMAE:  %.3f / %.3f / %.3f%%", statistic_Smith.MAE, statistic_SmithPers.MAE, (statistic_Smith.MAE - statistic_SmithPers.MAE) / statistic_Smith.MAE * 100);
%     fprintf("\tMED:  %.3f / %.3f / %.3f%%\n", statistic_Smith.MED, statistic_SmithPers.MED, (statistic_Smith.MED - statistic_SmithPers.MED) / statistic_Smith.MED * 100);
%     fprintf("\tMax:  %.3f / %.3f / %.3f%%", statistic_Smith.MAX, statistic_SmithPers.MAX, (statistic_Smith.MAX - statistic_SmithPers.MAX) / statistic_Smith.MAX * 100);
%     fprintf("\tSD:  %.3f / %.3f / %.3f%%\n", statistic_Smith.SD, statistic_SmithPers.SD, (statistic_Smith.SD - statistic_SmithPers.SD) / statistic_Smith.SD * 100);
% end
%% Ngo2022 
% % methods
% [N_Ngo, eta_Ngo2022] = getNormalNgo2022(objData, cfg);
% [N_NgoPers, eta_Ngo2022Pers] = getNormalNgo2022_Pers(objData, K, cfg);
% % error
% error_Ngo = rad2deg(getErrorNormalAngle(N_Ngo, N_desired, Mask_valid));
% error_NgoPers = rad2deg(getErrorNormalAngle(N_NgoPers, N_desired, Mask_valid));  
% % output
% statistic_Ngo = getStatistic(error_Ngo, Mask_valid);
% statistic_NgoPers = getStatistic(error_NgoPers, Mask_valid);
% fprintf("Sphere dataset---Ngo2022 method: Orth. / Pers.:  \n")
% fprintf("\tMAE:  %.3f / %.3f / %.3f%%", statistic_Ngo.MAE, statistic_NgoPers.MAE, (statistic_Ngo.MAE - statistic_NgoPers.MAE) / statistic_Ngo.MAE * 100);
% fprintf("\tMED:  %.3f / %.3f / %.3f%%\n", statistic_Ngo.MED, statistic_NgoPers.MED, (statistic_Ngo.MED - statistic_NgoPers.MED) / statistic_Ngo.MED * 100);
% fprintf("\tMax:  %.3f / %.3f / %.3f%%", statistic_Ngo.MAX, statistic_NgoPers.MAX, (statistic_Ngo.MAX - statistic_NgoPers.MAX) / statistic_Ngo.MAX * 100);
% fprintf("\tSD:  %.3f / %.3f / %.3f%%", statistic_Ngo.SD, statistic_NgoPers.SD, (statistic_Ngo.SD - statistic_NgoPers.SD) / statistic_Ngo.SD * 100);

















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
    subLocation = ["pol000", "pol045", "pol090", "pol135", "mask"];
    dataset = struct(); 
    dataset.view_dirs = load(fullfile(location, 'view_dirs.mat')).dirs;
    nameList = ["1_", "2_", "3_", "4_", "5_", "6_", "7_", "8_"];
    angleName = ["0°.png", "45°.png", "90°.png", "135°.png"];
    % data
    for i = 1 : length(nameList)
        dataset.sphere(i).polarImage.I0 = rgb2gray(im2double(imread(fullfile(location, subLocation(1), [char(nameList(i)), char(angleName(1))]))));
        dataset.sphere(i).polarImage.I45 = rgb2gray(im2double(imread(fullfile(location, subLocation(2), [char(nameList(i)), char(angleName(2))]))));
        dataset.sphere(i).polarImage.I90 = rgb2gray(im2double(imread(fullfile(location, subLocation(3), [char(nameList(i)), char(angleName(3))]))));
        dataset.sphere(i).polarImage.I135 = rgb2gray(im2double(imread(fullfile(location, subLocation(4), [char(nameList(i)), char(angleName(4))]))));
        dataset.sphere(i).mask = im2double(imread(fullfile(location, subLocation(5), [char(nameList(i)), '0°.png']))) > 0.99;
%         figure('Position', [0, 0, 1400, 750], 'Color', 'w'); 
%         subplot(2, 4, 1); imshow(dataset.sphere(i).polarImage.I0, []);
%         subplot(2, 4, 2); imshow(dataset.sphere(i).polarImage.I45, []);
%         subplot(2, 4, 3); imshow(dataset.sphere(i).polarImage.I90, []);
%         subplot(2, 4, 4); imshow(dataset.sphere(i).polarImage.I135, []);
%         dataset.sphere(i).polarImage.I0(~dataset.sphere(i).mask) = 0;
%         dataset.sphere(i).polarImage.I45(~dataset.sphere(i).mask) = 0;
%         dataset.sphere(i).polarImage.I90(~dataset.sphere(i).mask) = 0;
%         dataset.sphere(i).polarImage.I135(~dataset.sphere(i).mask) = 0;
%         subplot(2, 4, 5); imshow(dataset.sphere(i).polarImage.I0, []);
%         subplot(2, 4, 6); imshow(dataset.sphere(i).polarImage.I45, []);
%         subplot(2, 4, 7); imshow(dataset.sphere(i).polarImage.I90, []);
%         subplot(2, 4, 8); imshow(dataset.sphere(i).polarImage.I135, []);   
    end
    %% save
    save('./Data/Data_SphereDataset_20261026.mat', '-struct', 'dataset');
end


























