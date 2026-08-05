%% Real Data (DeepSfP Dataset) Complex Surfaces Comparision
clc; clear; close all;
%%
[location, name] = get_name_DeepSfP();
index = get_DeepSfP_test_name(name);
save("ObjectName.mat", 'location', 'name', 'index');
%%
row = 1024; col = 1224;
V_orth = zeros(row, col, 3); V_orth(:,:,3) = -1;
Beta_orth = zeros(row, col); 
mask = ones(row, col);  Mask = mask == 1;
%%
eta = 1.5;
a_list = [1, 0.24, 0.11, 0.14, 0.29, 0.11];
f_xy = 3478;
K = [f_xy, 0, 612; 0, -f_xy, 512; 0, 0, 1];
%% 
Err_pers = NaN(row, col, 6);
Err_orth = NaN(row, col, 6);
Mask_id= NaN(row, col, 6);
err_all = zeros(row, col);
err_orth_all = zeros(row, col);
sumMask_all = zeros(row, col);
%% 
for caseNum = 1 : length(index.name)
    a = a_list(caseNum);
    err = zeros(row, col);
    err_orth = zeros(row, col);
    sumMask = zeros(row, col);
    for flag_case = 1 : 3
        caseName = index.name{caseNum};
        rangeIndoorNum = index.indoorNumber{caseNum};
        rangeOutdoorCloudyNum = index.outdoorCloudyNumber{caseNum};
        rangeOutdoorSunnyNum = index.outdoorSunnyNumber{caseNum};
        %% test
        switch flag_case
            case 1
                %% Indoor
                for i = 1 : length(rangeIndoorNum)             
                    fprintf('Processing Image Indoor: case = %s, a = %.3f, f  = %.3f, k =  %i/%i ...\n', caseName, a, f_xy, i, length(rangeIndoorNum));
                    %% Data 
                    [polarImage, Mask, N_desired] = readDeepSfPData(location.indoor, name.indoor{rangeIndoorNum(i)});
                    V = getViewingDirection(K, Mask);  
                    Beta = getPerspectiveDistortionAngle(V, Mask);
                    N = get_Perspective_SurfaceNormal(polarImage, Beta, V, eta, a, Mask);
                    N_orth = get_Perspective_SurfaceNormal(polarImage, Beta_orth, V_orth, eta, a, Mask);
                    %% Error
                    error_n = getErrorNormalAngle(N, N_desired, Mask);
                    error_n_orth = getErrorNormalAngle(N_orth, N_desired, Mask);
                    %% Statistics
                    err(Mask) = err(Mask) + error_n(Mask);
                    err_orth(Mask) = err_orth(Mask) + error_n_orth(Mask);
                    sumMask(Mask) = sumMask(Mask) + 1;
                    err_all(Mask) = err_all(Mask) + error_n(Mask);
                    err_orth_all(Mask) = err_orth_all(Mask) + error_n_orth(Mask);
                    sumMask_all(Mask) = sumMask_all(Mask) + 1;
                end
            case 2
                %% Outdoor Cloudy
                for i = 1 : length(rangeOutdoorCloudyNum)             
                    fprintf('Processing Image Outdoor Cloudy: case = %s, a = %.3f, f = %.3f, k =  %i/%i ...\n', caseName, a, f_xy, i, length(rangeOutdoorCloudyNum));
                    %% Data 
                    [polarImage, Mask, N_desired] = readDeepSfPData(location.outdoor_cloudy, name.outdoor_cloudy{rangeOutdoorCloudyNum(i)});
                    V = getViewingDirection(K, Mask);  
                    Beta = getPerspectiveDistortionAngle(V, Mask);
                    N = get_Perspective_SurfaceNormal(polarImage, Beta, V, eta, a, Mask);
                    N_orth = get_Perspective_SurfaceNormal(polarImage, Beta_orth, V_orth, eta, a, Mask);
                    %% Error
                    error_n = getErrorNormalAngle(N, N_desired, Mask);
                    error_n_orth = getErrorNormalAngle(N_orth, N_desired, Mask);
                    %% Statistics
                    err(Mask) = err(Mask) + error_n(Mask);
                    err_orth(Mask) = err_orth(Mask) + error_n_orth(Mask);
                    sumMask(Mask) = sumMask(Mask) + 1;
                    err_all(Mask) = err_all(Mask) + error_n(Mask);
                    err_orth_all(Mask) = err_orth_all(Mask) + error_n_orth(Mask);
                    sumMask_all(Mask) = sumMask_all(Mask) + 1;
                end
            case 3
                %% Outdoor Sunny
                for i = 1 : length(rangeOutdoorSunnyNum)             
                    fprintf('Processing Image Outdoor Sunny: case = %s, a = %.3f, f = %.3f, k =  %i/%i ...\n', caseName, a, f_xy, i, length(rangeOutdoorSunnyNum));
                    %% Data 
                    [polarImage, Mask, N_desired] = readDeepSfPData(location.outdoor_sunny, name.outdoor_sunny{rangeOutdoorSunnyNum(i)});
                    V = getViewingDirection(K, Mask);  
                    Beta = getPerspectiveDistortionAngle(V, Mask);
                    N = get_Perspective_SurfaceNormal(polarImage, Beta, V, eta, a, Mask);
                    N_orth = get_Perspective_SurfaceNormal(polarImage, Beta_orth, V_orth, eta, a, Mask);
                    %% Error
                    error_n = getErrorNormalAngle(N, N_desired, Mask);
                    error_n_orth = getErrorNormalAngle(N_orth, N_desired, Mask);
                    %% Statistics
                    err(Mask) = err(Mask) + error_n(Mask);
                    err_orth(Mask) = err_orth(Mask) + error_n_orth(Mask);
                    sumMask(Mask) = sumMask(Mask) + 1;
                    err_all(Mask) = err_all(Mask) + error_n(Mask);
                    err_orth_all(Mask) = err_orth_all(Mask) + error_n_orth(Mask);
                    sumMask_all(Mask) = sumMask_all(Mask) + 1;
                end
        end
    end
    %% Statistics
    id = sumMask > 0;
    err_mean = err ./ sumMask;
    err_orth_mean = err_orth ./ sumMask;
    %% Record
    Err_pers(:,:, caseNum) = err_mean;
    Err_orth(:,:, caseNum) = err_orth_mean;
    Mask_id(:,:, caseNum) = id;    
end
%% Statistics
Mask_id_all = sumMask_all > 0;
Err_pers_all = err_all ./ sumMask_all;
Err_orth_all = err_orth_all ./ sumMask_all; 
%%
for caseNum = 1 : length(index.name)
    err_pers = Err_pers(:,:, caseNum);
    err_orth = Err_orth(:,:, caseNum);
    mask = Mask_id(:,:, caseNum) == 1;
    fprintf('%s: \n \t pers / orth --- %.3f, %.3f\n', index.name{caseNum}, rad2deg(mean(err_pers(mask))), rad2deg(mean(err_orth(mask))));
end
fprintf('Whole set: \n \t pers / orth --- %.3f, %.3f\n', rad2deg(mean(Err_pers_all(Mask_id_all))), rad2deg(mean(Err_orth_all(Mask_id_all))));
%%
name = index.name;
save('./Data/Data_ExperimentPlaneDeepSfPDataset.mat', 'name', 'Mask_id', 'Mask_id_all',...
    'Err_pers', 'Err_orth', 'Err_pers_all', 'Err_orth_all');


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

function N = get_Perspective_SurfaceNormal(polarImage, Beta, V, eta, a, Mask)
    %% spdp
    Rho = getDoLP(polarImage, Mask);
    Theta_sp = getZenithAngleSpecularReflection(Rho ./ a, Mask, Beta, eta);
    Phi = getAzimuthAngleDiffuseReflection(polarImage, Mask);
    N.sp1dp1 = -getSurfaceNormal(V, Theta_sp.sp1, Phi.dp1, Mask);
    N.sp1dp2 = -getSurfaceNormal(V, Theta_sp.sp1, Phi.dp2, Mask);
    N.sp1dp3 = -getSurfaceNormal(V, Theta_sp.sp1, Phi.dp3, Mask);
    N.sp1dp4 = -getSurfaceNormal(V, Theta_sp.sp1, Phi.dp4, Mask);
    N.sp2dp1 = -getSurfaceNormal(V, Theta_sp.sp2, Phi.dp1, Mask);
    N.sp2dp2 = -getSurfaceNormal(V, Theta_sp.sp2, Phi.dp2, Mask);
    N.sp2dp3 = -getSurfaceNormal(V, Theta_sp.sp2, Phi.dp3, Mask);
    N.sp2dp4 = -getSurfaceNormal(V, Theta_sp.sp2, Phi.dp4, Mask); 
end