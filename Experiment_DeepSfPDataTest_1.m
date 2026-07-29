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
num_A = 2;
a_list = linspace(0.1, 0.9, num_A);
eta = 1.5;
f_xy_list = [1159, 1739, 2319, 3478, 4638];
num_F = length(f_xy_list);
[A, F_XY] = meshgrid(a_list, f_xy_list);
%% 
for caseNum = 1 : length(index.name)
    caseName = index.name{caseNum};
    rangeIndoorNum = index.indoorNumber{caseNum};
    rangeOutdoorCloudyNum = index.outdoorCloudyNumber{caseNum};
    rangeOutdoorSunnyNum = index.outdoorSunnyNumber{caseNum};
    %% test
    error_all_N_angle = NaN(num_F, num_A);
    error_all_N_angle_orth = NaN(num_F, num_A);
    for a_cnt = 1 : length(a_list)
        a = a_list(a_cnt);
        for f_cnt = 1 : length(f_xy_list)
            f_xy = f_xy_list(f_cnt);
            K = [-f_xy, 0, 612; 0, f_xy, 512; 0, 0, 1];
            err_plot = zeros(row, col);
            err_plot_orth = zeros(row, col);
            err_plot_IJCV = zeros(row, col);
            sumMask = zeros(row, col);
            %% Indoor
            for i = 1 : length(rangeIndoorNum)             
                fprintf('Processing Image Indoor: case = %s, a_cnt = %i, f_cnt = %i, k =  %i/%i ...\n', caseName, a_cnt, f_cnt, i, length(rangeIndoorNum));
                %% Data 
                [polarImage, Mask, N_desired] = readDeepSfPData(location.indoor, name.indoor{rangeIndoorNum(i)});
                V = getViewingDirection(K, Mask);  
                Beta = getPerspectiveDistortionAngle(V, Mask);
                %% Methods
                % Perspective 
                N = getSurfaceNormalFromSpecularReflection(polarImage, Beta, V, eta, a, Mask);
                % Orthographic 
                N_orth = getSurfaceNormalFromSpecularReflection(polarImage, Beta_orth, V_orth, eta, a, Mask);
                %% Error
                error_n = getErrorNormalAngle(N, N_desired, Mask);
                error_n_orth = getErrorNormalAngle(N_orth, N_desired, Mask);
                %% Statistics
                err_plot(Mask) = err_plot(Mask) + error_n(Mask);
                err_plot_orth(Mask) = err_plot_orth(Mask) + error_n_orth(Mask);
                sumMask(Mask) = sumMask(Mask) + 1;
            end
            %% Outdoor Cloudy
            for i = 1 : length(rangeOutdoorCloudyNum)             
                fprintf('Processing Image Outdoor Cloudy: case = %s, a_cnt = %i, f_cnt = %i, k =  %i/%i ...\n', caseName, a_cnt, f_cnt, i, length(rangeOutdoorCloudyNum));
                %% Data 
                [polarImage, Mask, N_desired] = readDeepSfPData(location.outdoor_cloudy, name.outdoor_cloudy{rangeOutdoorCloudyNum(i)});
                V = getViewingDirection(K, Mask);  
                Beta = getPerspectiveDistortionAngle(V, Mask);
                %% Methods
                % Perspective 
                N = get_Perspective_SurfaceNormal(polarImage, Beta, V, eta, a, Mask);
                % Orthographic 
                N_orth = get_Perspective_SurfaceNormal(polarImage, Beta_orth, V_orth, eta, a, Mask);
                %% Error
                error_n = getErrorNormalAngle(N, N_desired, Mask);
                error_n_orth = getErrorNormalAngle(N_orth, N_desired, Mask);
                %% Statistics
                err_plot(Mask) = err_plot(Mask) + error_n(Mask);
                err_plot_orth(Mask) = err_plot_orth(Mask) + error_n_orth(Mask);
                sumMask(Mask) = sumMask(Mask) + 1;
            end
            %% Outdoor Sunny
            for i = 1 : length(rangeOutdoorSunnyNum)             
                fprintf('Processing Image Outdoor Sunny: case = %s, a_cnt = %i, f_cnt = %i, k =  %i/%i ...\n', caseName, a_cnt, f_cnt, i, length(rangeOutdoorSunnyNum));
                %% Data 
                [polarImage, Mask, N_desired] = readDeepSfPData(location.outdoor_sunny, name.outdoor_sunny{rangeOutdoorSunnyNum(i)});
                V = getViewingDirection(K, Mask);  
                Beta = getPerspectiveDistortionAngle(V, Mask);
                %% Methods
                % Perspective 
                N = get_Perspective_SurfaceNormal(polarImage, Beta, V, eta, a, Mask);
                % Orthographic 
                N_orth = get_Perspective_SurfaceNormal(polarImage, Beta_orth, V_orth, eta, a, Mask);
                %% Error
                error_n = getErrorNormalAngle(N, N_desired, Mask);
                error_n_orth = getErrorNormalAngle(N_orth, N_desired, Mask);
                %% Statistics
                err_plot(Mask) = err_plot(Mask) + error_n(Mask);
                err_plot_orth(Mask) = err_plot_orth(Mask) + error_n_orth(Mask);
                sumMask(Mask) = sumMask(Mask) + 1;
            end
            %% Statistics
            id = sumMask > 0;
            err_mean = err_plot(id) ./ sumMask(id);
            err_orth_mean = err_plot_orth(id) ./ sumMask(id);
            error_all_N_angle(f_cnt, a_cnt) = mean(err_mean(:));
            error_all_N_angle_orth(f_cnt, a_cnt) = mean(err_orth_mean(:));
            %% Plot
            fprintf('DeepSfP dataset MAE perspective/orthographic: %.3f / %.3f\n', rad2deg(error_all_N_angle(f_cnt, a_cnt)), rad2deg(error_all_N_angle_orth(f_cnt, a_cnt)));
        end
    end
    figure; 
    hold on; grid on;
    surf(A, F_XY, rad2deg(error_all_N_angle), 'FaceAlpha', 0.8, 'EdgeColor', 'none'); 
    mesh(A, F_XY, rad2deg(error_all_N_angle_orth), 'EdgeColor', 'g'); 
    view([30,10]);
    legend('Ours', 'Orthographic');
    xlabel('a'); ylabel('f'); zlabel('Mean Error');
    %%
    saveName = ['./Data/Data_DeepSfP_dataset_', caseName ,'_test_A_FXY.mat'];
    save(saveName, 'A', 'F_XY', 'error_all_N_angle', 'error_all_N_angle_orth');
    fprintf('save %s\n', saveName);
end




% figure; 
% [ height ] = lsqintegration(Plane.N_desired,Plane.Mask);
% figure;
% surf(height,'EdgeColor','none','FaceColor',[0 0 1],'FaceLighting','gouraud','AmbientStrength',0,'DiffuseStrength',1); 
% axis equal; light;
% 
% figure; 
% [ height ] = lsqintegration(Hemisphere.N_desired,Hemisphere.Mask);
% figure;
% surf(height,'EdgeColor','none','FaceColor',[0 0 1],'FaceLighting','gouraud','AmbientStrength',0,'DiffuseStrength',1); 
% axis equal; light;
% 
% figure; 
% [ height ] = lsqintegration(Random.N_desired,Random.Mask);
% figure;
% surf(height,'EdgeColor','none','FaceColor',[0 0 1],'FaceLighting','gouraud','AmbientStrength',0,'DiffuseStrength',1); 
% axis equal; light;

        %     
        %     
        %     figure;
        %     subplot(2, 3, 1); imshow(polarImage.I0);
        %     subplot(2, 3, 2); imshow(polarImage.I45);
        %     subplot(2, 3, 3); imshow(polarImage.I90);
        %     subplot(2, 3, 4); imshow(polarImage.I135);
        %     subplot(2, 3, 5); imshow(Mask);

%             % perspective
%             error_N_angle_sp = getErrorNormalAngle(N, N_desired, Mask);
%             fig_N_sp = figure; ax = subplot(1, 3, 1); h = imagesc(error_N_angle_sp); set(h, 'AlphaData', Mask); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Perspective Specular Reflection N Angle');
%             % orthographic
%             error_N_angle_sp_orth = getErrorNormalAngle(N_orth, N_desired, Mask);
%             figure(fig_N_sp); ax = subplot(1, 3, 2); h = imagesc(error_N_angle_sp_orth); set(h, 'AlphaData', Mask); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('Orthographic Specular Reflection N Angle');
%             % IJCV
%             error_N_angle_sp_IJCV = getErrorNormalAngle(N_IJCV, N_desired, Mask);
%             figure(fig_N_sp); ax = subplot(1, 3, 3); h = imagesc(error_N_angle_sp_IJCV); set(h, 'AlphaData', Mask); set(ax, 'Color', 'k'); colormap(parula); colorbar; title('IJCV Specular Reflection N Angle');
%             fprintf('MAE perspective/orthographic/IJCV: %.3f / %.3f / %.3f\n', mean(error_N_angle_sp(Mask)), mean(error_N_angle_sp_orth(Mask)), mean(error_N_angle_sp_IJCV(Mask)));


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
    N_desired(:,:,2) = -N_desired(:,:,2);
    N_desired(:,:,3) = -N_desired(:,:,3);
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
    Rho = getDoLP(polarImage, Mask);
    Theta_sp = getZenithAngleSpecularReflection(Rho ./ a, Mask, Beta, eta);
    Phi = getAzimuthAngleDiffuseReflection(polarImage, Mask);
    N.sp1dp1 = getSurfaceNormal(V, Theta_sp.sp1, Phi.dp1, Mask);
    N.sp1dp2 = getSurfaceNormal(V, Theta_sp.sp1, Phi.dp2, Mask);
    N.sp1dp3 = getSurfaceNormal(V, Theta_sp.sp1, Phi.dp3, Mask);
    N.sp1dp4 = getSurfaceNormal(V, Theta_sp.sp1, Phi.dp4, Mask);
    N.sp2dp1 = getSurfaceNormal(V, Theta_sp.sp2, Phi.dp1, Mask);
    N.sp2dp2 = getSurfaceNormal(V, Theta_sp.sp2, Phi.dp2, Mask);
    N.sp2dp3 = getSurfaceNormal(V, Theta_sp.sp2, Phi.dp3, Mask);
    N.sp2dp4 = getSurfaceNormal(V, Theta_sp.sp2, Phi.dp4, Mask); 
end