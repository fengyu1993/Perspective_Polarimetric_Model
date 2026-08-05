%% Experiment DeepSfP Dataset
clc; clear; close all;
FontSize = 23;
%%
dataResult = load('./Data/Data_ExperimentPlaneDeepSfPDataset.mat');
load('./Data/Data_Result_deepSfP.mat');
%%
location = './Data/DeepSfPData/SurfaceNormals/objects/';
caseName = ["indoor/", "outdoor_cloudy/", "indoor/", "outdoor_cloudy/", "outdoor_sunny/", "outdoor_sunny/"];
objectName = ["box_l", "dragon_l", "father_christmas_f", "flamingo_queen_l", "horse_l", "vase2_l"];
%%
row = 1024; col = 1224;
V_orth = zeros(row, col, 3); V_orth(:,:,3) = -1;
Beta_orth = zeros(row, col); 
eta = 1.5;
a_list = [1, 0.24, 0.11, 0.14, 0.29, 0.11];
f_xy = 3478;
K = [f_xy, 0, 612; 0, -f_xy, 512; 0, 0, 1];
%%
iList = [1, 2, 4, 5];
for ii = 1 : length(iList)
    i = iList(ii);
    fprintf("%s -- %s: \n", caseName(i), objectName(i));
    a = a_list(i);
    [polarImage, Mask, N_desired] = readDeepSfPData([location, char(caseName(i))], [char(objectName(i)), '.mat']);
    V = getViewingDirection(K, Mask); 
    Beta = getPerspectiveDistortionAngle(V, Mask);
    %% Perspective
    N = get_Perspective_SurfaceNormal(polarImage, Beta, V, eta, a, Mask);
    N = getRefinedSurfaceNormal(N, N_desired);
    error_normal = getErrorNormalAngle(N, N_desired, Mask);
    fprintf("\t Perspective MAE: %.3f degree\n", mean(error_normal(Mask)));
    fprintf("\t Perspective SD: %.3f degree\n", std(error_normal(Mask)));
    fprintf("\t Perspective RMSE: %.3f degree\n", sqrt(mean(error_normal(Mask).^2)));
    %% Polar Image
%     fig = figure;
%     polarImage.I0(~Mask) = 1;
%     borderWidth = 6; 
%     polarImage.I0(1:borderWidth, :, :) = 0;           
%     polarImage.I0(end-borderWidth+1:end, :, :) = 0; 
%     polarImage.I0(:, 1:borderWidth, :) = 0;          
%     polarImage.I0(:, end-borderWidth+1:end, :) = 0; 
%     imshow(polarImage.I0);
%     fullPath = fullfile('./imageDeepSfP', ['fig_', char(objectName(i)), '.png']);
%     imwrite(polarImage.I0, fullPath);
    %% Resize
    [r_min, r_max, c_min, c_max] = getrange(Mask);
    figure; imshow(polarImage.I0(r_min : r_max, c_min : c_max));
    Mask = Mask(r_min : r_max, c_min : c_max);
    N_desired = N_desired(r_min : r_max, c_min : c_max,:);
    N = N(r_min : r_max, c_min : c_max,:);
    error_normal = error_normal(r_min : r_max, c_min : c_max);
    %% Plot: Ground Truth
    fig_desired = figure;
    plot3DShape(fig_desired, N_desired, Mask, false);
    fullPath = fullfile('./imageDeepSfP', ['fig_', char(objectName(i)), '_ground_truth.png']);
    exportgraphics(fig_desired, fullPath, 'Resolution', 300);
    %% Plot: Perspective
    fig_pers = figure;
    plot3DShape(fig_pers, N, Mask, false);
    fullPath = fullfile('./imageDeepSfP', ['fig_', char(objectName(i)), '_pers.png']);
    exportgraphics(fig_pers, fullPath, 'Resolution', 300);  
    %
    fig_pers_error = figure;
    ax = axes(fig_pers_error);
    h = imagesc(error_normal); 
    set(h, 'AlphaData', Mask); 
    set(ax, 'Color', 'w'); 
    axis equal; 
    colormap(ax, parula); 
    cb = colorbar(ax); 
    axis(ax, 'off');
    cbPos = cb.Position; 
    oldWidth = cbPos(3);
    newWidth = oldWidth * 0.5;
    cbPos(3) = newWidth;
    cbPos(1) = cbPos(1) + (oldWidth - newWidth) + 0.03; 
    cb.Position = cbPos;
    set(cb, 'FontName', 'Times New Roman', 'FontSize', FontSize);
    fullPath = fullfile('./imageDeepSfP', ['fig_', char(objectName(i)), '_pers_error.png']);
    exportgraphics(fig_pers_error, fullPath, 'Resolution', 300);
    %% DeePSfP
    N_DeePSfP = deepSfP.N_pred{i};
    N_DeePSfP_gt = deepSfP.N_gt{i};
    Mask_DeePSfP = deepSfP.Mask{i} == 1;
    error_DeePSfP = getErrorNormalAngle(N_DeePSfP, N_DeePSfP_gt, Mask_DeePSfP);
    fprintf("\t DeePSfP MAE: %.3f degree\n", mean(error_DeePSfP(Mask_DeePSfP)));
    fprintf("\t DeePSfP SD: %.3f degree\n", std(error_DeePSfP(Mask_DeePSfP)));
    fprintf("\t DeePSfP RMSE: %.3f degree\n", sqrt(mean(error_DeePSfP(Mask_DeePSfP).^2)));   
    %
    [r_min, r_max, c_min, c_max] = getrange(deepSfP.Mask{i});
    N_DeePSfP = N_DeePSfP(r_min : r_max, c_min : c_max, :);
    Mask_DeePSfP = Mask_DeePSfP(r_min : r_max, c_min : c_max);
    error_DeePSfP = error_DeePSfP(r_min : r_max, c_min : c_max);
    %
    fig_DeePSfP = figure;
    plot3DShape(fig_DeePSfP, N_DeePSfP, Mask_DeePSfP, false);
    fullPath = fullfile('./imageDeepSfP', ['fig_', char(objectName(i)), '_DeepSfP.png']);  
    exportgraphics(fig_DeePSfP, fullPath, 'Resolution', 300);    
    %
    fig_DeePSfP_error = figure;
    ax = axes(fig_DeePSfP_error);
    h = imagesc(error_DeePSfP); 
    set(h, 'AlphaData', Mask); 
    set(ax, 'Color', 'w'); 
    axis equal; 
    colormap(ax, parula); 
    cb = colorbar(ax); 
    axis(ax, 'off');
    cbPos = cb.Position; 
    oldWidth = cbPos(3);
    newWidth = oldWidth * 0.5;
    cbPos(3) = newWidth;
    cbPos(1) = cbPos(1) + (oldWidth - newWidth) + 0.03; 
    cb.Position = cbPos;
    set(cb, 'FontName', 'Times New Roman', 'FontSize', FontSize);
    fullPath = fullfile('./imageDeepSfP', ['fig_', char(objectName(i)), '_DeePSfP_error.png']);
    exportgraphics(fig_DeePSfP_error, fullPath, 'Resolution', 300);
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

function [r_min, r_max, c_min, c_max] = getrange(Mask)

    [rows, cols] = find(Mask);
    
    margin = 10; 
    [h, w] = size(Mask); 

        
    min_r = min(rows); max_r = max(rows);
    min_c = min(cols); max_c = max(cols);
    
    obj_h = max_r - min_r;
    obj_w = max_c - min_c;
    
    center_r = (min_r + max_r) / 2;
    center_c = (min_c + max_c) / 2;
    
    square_side = max(obj_h, obj_w) + 2 * margin;
    
    r_min = round(center_r - square_side / 2);
    r_max = round(center_r + square_side / 2);
    c_min = round(center_c - square_side / 2);
    c_max = round(center_c + square_side / 2);
    
    if r_min < 1
        r_min = 1; 
    end

    if r_max > h
        r_max = h; 
    end
    
    if c_min < 1
        c_min = 1; 
    end

    if c_max > w
        c_max = w; 
    end
    
    r_min = max(1, r_min); r_max = min(h, r_max);
    c_min = max(1, c_min); c_max = min(w, c_max);

end

function N_RGB = getNRGB(N, Mask)
    Nx = N(:,:,1);
    Ny = N(:,:,2);
    Nz = N(:,:,3);
    
    R = (Nx + 1) / 2;
    G = (Ny + 1) / 2;
    B = (Nz + 1) / 2; 
    
    N_RGB = cat(3, R, G, B);
    Mask_3D = repmat(Mask, [1, 1, 3]); 
    N_RGB(~Mask_3D) = 1;
end