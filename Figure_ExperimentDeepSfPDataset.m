%% Experiment DeepSfP Dataset
clc; clear; close all;
%%
dataResult = load('./Data/Data_ExperimentPlaneDeepSfPDataset.mat');
%%
location = './Data/DeepSfPData/SurfaceNormals/objects/';
caseName = ["indoor/", "outdoor_cloudy/", "indoor/", "outdoor_cloudy/", "outdoor_sunny/", "outdoor_sunny/"];
objectName = ["box_l", "dragon_l", "father_christmas_f", "flamingo_queen_l", "horse_l", "vase2_l"];
%%
row = 1024; col = 1224;
V_orth = zeros(row, col, 3); V_orth(:,:,3) = -1;
Beta_orth = zeros(row, col); 
eta = 1.5;
% a_list = [0.24, 0.24, 0.11, 0.14, 0.29, 0.12];
a_list = [1, 0.24, 0.11, 0.14, 0.29, 0.11];
% a_list = 0.24*ones(1, 6);
f_xy = 3478;
K = [f_xy, 0, 612; 0, -f_xy, 512; 0, 0, 1];
%% Save Image
for i = 1 : length(objectName)
    fprintf("%s -- %s: \n", caseName(i), objectName(i));
    a = a_list(i);
    [polarImage, Mask, N_desired] = readDeepSfPData([location, char(caseName(i))], [char(objectName(i)), '.mat']);
    V = getViewingDirection(K, Mask);  
    Beta = getPerspectiveDistortionAngle(V, Mask);
    %% Polar Image
    fig = figure;
    imshow(polarImage.I0);
    fullPath = fullfile('./imageDeepSfP', [char(objectName(i)), '.png']);
    imwrite(polarImage.I0, fullPath);
    %% Ground Truth
    fig_desired = figure;
    plot3DShape(fig_desired, N_desired, Mask);
    fullPath = fullfile('./imageDeepSfP', [char(objectName(i)), '_ground_truth.png']);
    exportgraphics(fig_desired, fullPath, 'Resolution', 300);
    %% Perspective
    N = get_Perspective_SurfaceNormal(polarImage, Beta, V, eta, a, Mask);
    N = getRefinedSurfaceNormal(N, N_desired);
    error_normal = getErrorNormalAngle(N, N_desired, Mask);
    fig_pers = figure;
    plot3DShape(fig_pers, N, Mask);
    fullPath = fullfile('./imageDeepSfP', [char(objectName(i)), '_pers.png']);
    exportgraphics(fig_desired, fullPath, 'Resolution', 300);  
    fprintf("\t Perspective MAE: %.3f degree\n", rad2deg(mean(error_normal(Mask))));
    %% Orthographic
    N_orth = get_Perspective_SurfaceNormal(polarImage, Beta_orth, V_orth, eta, a, Mask);
    N_orth = getRefinedSurfaceNormal(N_orth, N_desired);
    error_normal_orth = getErrorNormalAngle(N_orth, N_desired, Mask);
    fig_orth = figure;
    plot3DShape(fig_orth, N_orth, Mask);
    fullPath = fullfile('./imageDeepSfP', [char(objectName(i)), '_orth.png']);
    exportgraphics(fig_orth, fullPath, 'Resolution', 300);  
    fprintf("\t Orthographic MAE: %.3f degree\n", rad2deg(mean(error_normal_orth(Mask))));
end


















%%
function [polarImage, Mask, N_desired] = readDeepSfPData(location, name)
    data = load([location, name]);
    polarImage.I0 = data.images(:,:,1);
    polarImage.I45 = data.images(:,:,2);
    polarImage.I90 = data.images(:,:,3);
    polarImage.I135 = data.images(:,:,4);
    Mask = data.mask == 1;
    N_desired = data.normals_gt;
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