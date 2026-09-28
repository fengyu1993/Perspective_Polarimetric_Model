%% Real Data (PPA Dataset) Plane Comparision Ours VS. PPA
clc; clear; close all;
%% Initialization
[location, name] = get_name_PPA();
row = 1024; col = 1224;
V_orth = zeros(row, col, 3); V_orth(:,:,3) = -1;
Beta_orth = zeros(row, col);
%% Calculate
err_plot_ours = zeros(row, col);
err_plot_PPA = zeros(row, col);
sumMask = zeros(row, col);
for i = 1 : length(name)
    %% Data 
    % polarimetric image
    polarImage = readPolarimetricImage([location, '\images\'], [char(name{i}), '.png']); 
    % mask
    Mask = load([location, '\images\', char(name{i}), '_mask.mat']).data == 1;
    % V
    rays = NaN([size(polarImage.I0), 3]);
    [extrinsic, intrinsic, undistort] = read_data([location, '\cams\'], [char(name{i}), '_cam.txt']);
    [rows, cols] = find(Mask == 1);
    K = intrinsic;
    for cut = 1 : length(rows)
        x = [cols(cut); rows(cut); 1];
        v = K \ x;
        rays(rows(cut), cols(cut), :) = v / norm(v);
    end
    V = -rays;
    V(:,:,1) = -V(:,:,1);
    % Beta
    Beta = getPerspectiveDistortionAngle(V, Mask);
    % normal
    normal_w = [-0.12410584; -0.31629185; -0.94050901];
    n = extrinsic(1:3, 1:3) * normal_w;
    N_desired = repmat(reshape(n, 1, 1, 3), 1024, 1224);
    %% Methods--ours
    



    N = getSurfaceNormalFromSpecularReflection(polarImage, Beta, V, eta, a, Mask);
    N.sp1(:,:,1) = -N.sp1(:,:,1);   N.sp2(:,:,1) = -N.sp2(:,:,1);
    N.sp3(:,:,1) = -N.sp3(:,:,1);   N.sp4(:,:,1) = -N.sp4(:,:,1);




end

































function [location, name] = get_name_PPA()
    num = ["000", "024", "048", "072", "096", "120", "144", "168", "192", "216", "240", "264"];
    location = '.\Data\PPA\data\single_normal';
    name = "00000" + num;
end





