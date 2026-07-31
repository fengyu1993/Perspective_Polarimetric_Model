%% Real Data (DeepSfP Dataset) Complex Surfaces Comparision
clc; clear; close all;
%%
[location, name] = get_name_DeepSfP();
index = get_DeepSfP_test_name(name);
%% 
row = 1024; col = 1224;
V_orth = zeros(row, col, 3); V_orth(:,:,3) = -1;
Beta_orth = zeros(row, col); 
eta = 1.5;
a_list = [0.24, 0.24, 0.11, 0.14, 0.29, 0.12];
% a_list = 0.24*ones(1, 6);
f_xy = 3478;
K = [f_xy, 0, 612; 0, -f_xy, 512; 0, 0, 1];
for caseNum = 6 % : length(index.name)
    a = a_list(caseNum);
    caseName = index.name{caseNum};
    rangeIndoorNum = index.indoorNumber{caseNum};
    rangeOutdoorCloudyNum = index.outdoorCloudyNumber{caseNum};
    rangeOutdoorSunnyNum = index.outdoorSunnyNumber{caseNum};
    %% Indoor
    for i = 1 : length(rangeIndoorNum)             
        fprintf('Processing Image Indoor: case = %s, image = %s ...\n', caseName, name.indoor{rangeIndoorNum(i)});
        %% Data 
        [polarImage, Mask, N_desired] = readDeepSfPData(location.indoor, name.indoor{rangeIndoorNum(i)});
        figure;
        subplot(2, 3, 1); imshow(polarImage.I0);
        subplot(2, 3, 2); imshow(polarImage.I45);
        subplot(2, 3, 3); imshow(polarImage.I90);
        subplot(2, 3, 4); imshow(polarImage.I135);
        subplot(2, 3, 5); imshow(Mask);
        %% Estimate
        Mask_ = ones(row, col) == 1;
        V = getViewingDirection(K, Mask_);  
        Beta = getPerspectiveDistortionAngle(V, Mask_);
        % Perspective 
        N = getSurfaceNormalFromSpecularReflection(polarImage, Beta, V, eta, a, Mask);
        N.sp1 = -N.sp1;   N.sp2 = -N.sp2;
        N.sp3 = -N.sp3;   N.sp4 = -N.sp4;
        % Orthographic 
        N_orth = getSurfaceNormalFromSpecularReflection(polarImage, Beta_orth, V_orth, eta, a, Mask);
        N_orth.sp1 = -N_orth.sp1;   N_orth.sp2 = -N_orth.sp2;
        N_orth.sp3 = -N_orth.sp3;   N_orth.sp4 = -N_orth.sp4;
        %% Error
        error_n = getErrorNormalAngle(N, N_desired, Mask);
        error_n_orth = getErrorNormalAngle(N_orth, N_desired, Mask);         
        %% Refine
        N = getRefinedSurfaceNormal(N, N_desired);
        N(:,:,3) = -N(:,:,3);   
        N_orth = getRefinedSurfaceNormal(N_orth, N_desired);
        N_orth(:,:,3) = -N_orth(:,:,3); 

        rad2deg(mean(error_n(Mask)))
        rad2deg(mean(error_n_orth(Mask)))
        %% Plot
        fig_desired = figure;
        plot3DShape(fig_desired, N_desired, Mask);
        fig = figure;
        plot3DShape(fig, N, Mask);
        fig_orth = figure;
        plot3DShape(fig_orth, N_orth, Mask);
    end
    %% Outdoor Cloudy
    for i = 1 : length(rangeOutdoorCloudyNum)             
        fprintf('Processing Image Outdoor Cloudy: case = %s, image = %s ...\n', caseName, name.outdoor_cloudy{rangeOutdoorCloudyNum(i)});
        %% Data 
        [polarImage, Mask, N_desired] = readDeepSfPData(location.outdoor_cloudy, name.outdoor_cloudy{rangeOutdoorCloudyNum(i)});
        figure;
        subplot(2, 3, 1); imshow(polarImage.I0);
        subplot(2, 3, 2); imshow(polarImage.I45);
        subplot(2, 3, 3); imshow(polarImage.I90);
        subplot(2, 3, 4); imshow(polarImage.I135);
        subplot(2, 3, 5); imshow(Mask);
    end
    %% Outdoor Sunny
    for i = 1 : length(rangeOutdoorSunnyNum)             
        fprintf('Processing Image Outdoor Sunny: case = %s, image = %s ...\n', caseName, name.outdoor_sunny{rangeOutdoorSunnyNum(i)});
        %% Data 
        [polarImage, Mask, N_desired] = readDeepSfPData(location.outdoor_sunny, name.outdoor_sunny{rangeOutdoorSunnyNum(i)});
        figure;
        subplot(2, 3, 1); imshow(polarImage.I0);
        subplot(2, 3, 2); imshow(polarImage.I45);
        subplot(2, 3, 3); imshow(polarImage.I90);
        subplot(2, 3, 4); imshow(polarImage.I135);
        subplot(2, 3, 5); imshow(Mask);
    end
end






%%
function [location, name] = get_name_DeepSfP()
    location.indoor = './Data/DeepSfPData/SurfaceNormals/objects/indoor/';
    location.outdoor_cloudy = './Data/DeepSfPData/SurfaceNormals/objects/outdoor_cloudy/';
    location.outdoor_sunny = './Data/DeepSfPData/SurfaceNormals/objects/outdoor_sunny/';
    filePattern.indoor = fullfile(location.indoor, '*.mat');
    filePattern.outdoor_cloudy = fullfile(location.outdoor_cloudy, '*.mat');
    filePattern.outdoor_sunny = fullfile(location.outdoor_sunny, '*.mat');
    dirData.indoor = dir(filePattern.indoor);
    dirData.outdoor_cloudy = dir(filePattern.outdoor_cloudy);
    dirData.outdoor_sunny = dir(filePattern.outdoor_sunny);
    name.indoor = {dirData.indoor.name};
    name.outdoor_cloudy = {dirData.outdoor_cloudy.name};
    name.outdoor_sunny = {dirData.outdoor_sunny.name};
end

function [polarImage, Mask, N_desired] = readDeepSfPData(location, name)
    data = load([location, name]);
    polarImage.I0 = data.images(:,:,1);
    polarImage.I45 = data.images(:,:,2);
    polarImage.I90 = data.images(:,:,3);
    polarImage.I135 = data.images(:,:,4);
    Mask = data.mask == 1;
    N_desired = data.normals_gt;
end

function index = get_DeepSfP_test_name(name)
    index.name = ["box"; "dragon"; "father_christmas"; "flamingo"; "horse"; "vase"];
    index.indoorNumber = cell(length(index.name), 1);
    index.outdoor_cloudyNumber = cell(length(index.name), 1);
    index.outdoor_sunnyNumber = cell(length(index.name), 1);
    for i = 1 : length(index.name)
        index.indoorNumber{i} = find(startsWith(name.indoor, index.name(i), 'IgnoreCase', true));
        index.outdoorCloudyNumber{i} = find(startsWith(name.outdoor_cloudy, index.name(i), 'IgnoreCase', true));
        index.outdoorSunnyNumber{i} = find(startsWith(name.outdoor_sunny, index.name(i), 'IgnoreCase', true));  
    end
end