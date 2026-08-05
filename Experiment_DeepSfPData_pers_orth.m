%% Real Data (DeepSfP Dataset) Complex Surfaces Comparision
clc; clear; close all;
%%
[location, name] = get_name_DeepSfP();
index = get_DeepSfP_test_name(name);
%%
row = 1024; col = 1224;
V_orth = zeros(row, col, 3); V_orth(:,:,3) = -1;
Beta_orth = zeros(row, col); 
mask = ones(row, col);  Mask = mask == 1;
%%
eta = 1.5;
% a_list = [1, 0.24, 0.11, 0.14, 0.29, 0.11];
a_list = [1, 0.24, 0.14, 0.29];
f_xy = 3478;
K = [f_xy, 0, 612; 0, -f_xy, 512; 0, 0, 1];
%% 
Err_pers = NaN(row, col, 3, length(index.name));
Err_orth = NaN(row, col, 3, length(index.name));
Mask_sum = NaN(row, col, 3, length(index.name));
ID = NaN(row, col, 3, length(index.name));
%% 
for objectNum = 1 : length(index.name)
    a = a_list(objectNum);
    for caseNum = 1 : 3
        caseName = index.name{objectNum};
        rangeIndoorNum = index.indoorNumber{objectNum};
        rangeOutdoorCloudyNum = index.outdoorCloudyNumber{objectNum};
        rangeOutdoorSunnyNum = index.outdoorSunnyNumber{objectNum};
        %% test
        err = zeros(row, col);
        err_orth = zeros(row, col);
        sumMask = zeros(row, col);
        switch caseNum
            case 1
                %% Indoor
                for i = 1 : length(rangeIndoorNum)             
                    fprintf('Processing Image Indoor: case = %s, a = %.3f, f  = %.3f, k =  %i/%i ...\n', caseName, a, f_xy, i, length(rangeIndoorNum));
                    %% Data 
                    [polarImage, Mask, N_desired] = readDeepSfPData(location.indoor, name.indoor{rangeIndoorNum(i)});
                    V = getViewingDirection(K, Mask);  
                    Beta = getPerspectiveDistortionAngle(V, Mask);
                    N = getSurfaceNormalFromSpecularReflection(polarImage, Beta, V, eta, a, Mask);
                    N.sp1 = -N.sp1; N.sp2 = -N.sp2; N.sp3 = -N.sp3; N.sp4 = -N.sp4; 
                    N_orth = getSurfaceNormalFromSpecularReflection(polarImage, Beta_orth, V_orth, eta, a, Mask);
                    N_orth.sp1 = -N_orth.sp1; N_orth.sp2 = -N_orth.sp2; N_orth.sp3 = -N_orth.sp3; N_orth.sp4 = -N_orth.sp4; 
                    %% Error
                    error_n = getErrorNormalAngle(N, N_desired, Mask);
                    error_n_orth = getErrorNormalAngle(N_orth, N_desired, Mask);
                    %% Statistics
                    err(Mask) = err(Mask) + error_n(Mask);
                    err_orth(Mask) = err_orth(Mask) + error_n_orth(Mask);
                    sumMask(Mask) = sumMask(Mask) + 1;
                end
            case 2
                %% Outdoor Cloudy
                for i = 1 : length(rangeOutdoorCloudyNum)             
                    fprintf('Processing Image Outdoor Cloudy: case = %s, a = %.3f, f = %.3f, k =  %i/%i ...\n', caseName, a, f_xy, i, length(rangeOutdoorCloudyNum));
                    %% Data 
                    [polarImage, Mask, N_desired] = readDeepSfPData(location.outdoor_cloudy, name.outdoor_cloudy{rangeOutdoorCloudyNum(i)});
                    V = getViewingDirection(K, Mask);  
                    Beta = getPerspectiveDistortionAngle(V, Mask);
                    N = getSurfaceNormalFromSpecularReflection(polarImage, Beta, V, eta, a, Mask);
                    N.sp1 = -N.sp1; N.sp2 = -N.sp2; N.sp3 = -N.sp3; N.sp4 = -N.sp4; 
                    N_orth = getSurfaceNormalFromSpecularReflection(polarImage, Beta_orth, V_orth, eta, a, Mask);
                    N_orth.sp1 = -N_orth.sp1; N_orth.sp2 = -N_orth.sp2; N_orth.sp3 = -N_orth.sp3; N_orth.sp4 = -N_orth.sp4; 
                    %% Error
                    error_n = getErrorNormalAngle(N, N_desired, Mask);
                    error_n_orth = getErrorNormalAngle(N_orth, N_desired, Mask);
                    %% Statistics
                    err(Mask) = err(Mask) + error_n(Mask);
                    err_orth(Mask) = err_orth(Mask) + error_n_orth(Mask);
                    sumMask(Mask) = sumMask(Mask) + 1;
                end
            case 3
                %% Outdoor Sunny
                for i = 1 : length(rangeOutdoorSunnyNum)             
                    fprintf('Processing Image Outdoor Sunny: case = %s, a = %.3f, f = %.3f, k =  %i/%i ...\n', caseName, a, f_xy, i, length(rangeOutdoorSunnyNum));
                    %% Data 
                    [polarImage, Mask, N_desired] = readDeepSfPData(location.outdoor_sunny, name.outdoor_sunny{rangeOutdoorSunnyNum(i)});
                    V = getViewingDirection(K, Mask);  
                    Beta = getPerspectiveDistortionAngle(V, Mask);
                    N = getSurfaceNormalFromSpecularReflection(polarImage, Beta, V, eta, a, Mask);
                    N.sp1 = -N.sp1; N.sp2 = -N.sp2; N.sp3 = -N.sp3; N.sp4 = -N.sp4; 
                    N_orth = getSurfaceNormalFromSpecularReflection(polarImage, Beta_orth, V_orth, eta, a, Mask);
                    N_orth.sp1 = -N_orth.sp1; N_orth.sp2 = -N_orth.sp2; N_orth.sp3 = -N_orth.sp3; N_orth.sp4 = -N_orth.sp4; 
                    %% Error
                    error_n = getErrorNormalAngle(N, N_desired, Mask);
                    error_n_orth = getErrorNormalAngle(N_orth, N_desired, Mask);
                    %% Statistics
                    err(Mask) = err(Mask) + error_n(Mask);
                    err_orth(Mask) = err_orth(Mask) + error_n_orth(Mask);
                    sumMask(Mask) = sumMask(Mask) + 1;
                end
        end
        Err_pers(:,:,caseNum, objectNum) = err;
        Err_orth(:,:,caseNum, objectNum) = err_orth;
        Mask_sum(:,:,caseNum, objectNum) = sumMask;
        ID(:,:,caseNum, objectNum) = sumMask > 0;
     end   
end
%% Statistics
casename = ["indoor", "outdoor_cloudy", "outdoor_sunny"];
for objectNum = 1 : length(index.name)
    fprintf("%s:\n", index.name(objectNum));
    for caseNum = 1 : 3
        fprintf("%s:\n\t\t\t Pers.\t\t Orth. \n", casename(caseNum));
        err_pers = Err_pers(:,:,caseNum, objectNum);
        err_orth = Err_orth(:,:,caseNum, objectNum);
        mask_sum = Mask_sum(:,:,caseNum, objectNum);
        id = ID(:,:,caseNum, objectNum) == 1;
        err_sta =  rad2deg(err_pers(id) ./ mask_sum(id));
        err_orth_sta = rad2deg(err_orth(id) ./ mask_sum(id));   
        fprintf('\t MAE \t %.3f \t %.3f\n', mean(err_sta), mean(err_orth_sta));
        fprintf('\t SD \t %.3f \t %.3f\n', std(err_sta), std(err_orth_sta));
        fprintf('\t RMSE \t %.3f \t %.3f\n', sqrt(mean(err_sta.^2)), sqrt(mean(err_orth_sta.^2)));
        fprintf('\t MAX \t %.3f \t %.3f\n', max(err_sta), max(err_orth_sta));
    end
end
%%
save('./Data/Data_ExperimentPlaneDeepSfPDataset_pers_orth.mat', 'index', ...
    'Err_pers', 'Err_orth', 'Mask_sum', 'ID');


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
    index.name = ["box"; "dragon"; "father_christmas"; "flamingo"; "horse"; "vase"]; % a_list = [1, 0.24, 0.11, 0.14, 0.29, 0.11];
    index.name = ["box"; "dragon"; "flamingo"; "horse"]; % a_list = [1, 0.24, 0.14, 0.29];
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