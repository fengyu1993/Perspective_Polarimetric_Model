%% Sony Dataset: Recovery of Surface Orientation From Diffuse Polarization
clc; 
% clear; 
close all;
%%
% dataset = reatdSonyDataset('Data\SONY\');
dataset = load('./Data/Data_SonyDataset.mat');
%% parameters
[rows, cols] = size(dataset.bear1(1).polarImage.I0);
f = 12.5; pixelPitch = 2.5e-3; 
effectivePitch = 2 * pixelPitch;
fxy = f / effectivePitch;  
K = [fxy,  0,  cols/2; 0, -fxy, rows/2; 0,  0,  1];
V_orth = zeros(rows, cols, 3); V_orth(:,:,3) = 1;
Beta_orth = zeros(rows, cols);
Psi_orth = zeros(rows, cols);
num_A = 2; % 30
num_ETA = 2; % 25
a_list = linspace(0.6, 1.0, num_A);
eta_list = linspace(1.5, 2.5, num_ETA);
[A, ETA] = meshgrid(a_list, eta_list);
%% calculate
error_all_N_angle_Ours = NaN(num_ETA, num_A, length(dataset.nameList), length(dataset.bear1));
error_all_N_angle_Atkinson2006 = NaN(num_ETA, num_A, length(dataset.nameList), length(dataset.bear1));
sumMask = NaN(length(dataset.nameList), length(dataset.bear1));
for a_cnt = 1 : length(a_list)
    a = a_list(a_cnt);
    for eta_cnt = 1 : length(eta_list)
        eta = eta_list(eta_cnt);
        nameList = dataset.nameList;
%         nameList = nameList(1);
        for num = 1 : length(nameList)
            objName = char(nameList(num));
            objData = dataset.(objName);
%             objData = objData(1);
            for i = 1 : length(objData)
                %% parameters
                polarImage = objData(i).polarImage;   
                Mask = objData(i).mask;
                N_desired = objData(i).normal;
                lightDirection = objData(i).lightDirection;
                V = getViewingDirection(K, Mask);  
                Beta = getPerspectiveDistortionAngle(V, Mask);
                Psi = getPsiAngle(V, Mask);
                %% methods
                % ours
                N_Ours = getSurfaceNormalFromDiffuseReflection_AccurateNew(polarImage, Psi, Beta, V, eta, a, Mask);
                % Atkinson2006
                N_Atkinson2006 = getSurfaceNormalFromDiffuseReflection_AccurateNew(polarImage, Psi_orth, Beta_orth, V_orth, eta, a, Mask);
                %% Error
                error_Ours = getErrorNormalAngle(N_Ours, N_desired, Mask);
                error_Atkinson2006 = getErrorNormalAngle(N_Atkinson2006, N_desired, Mask);       
                %% Statistics
                error_all_N_angle_Ours(eta_cnt, a_cnt, num, i) = mean(error_Ours(Mask));
                error_all_N_angle_Atkinson2006(eta_cnt, a_cnt, num, i) = mean(error_Atkinson2006(Mask));
                sumMask(num, i) = sum(Mask(:));
                %% Output
                fprintf('Sony dataset %s--%i MAE Ours/Atkinson2006: %.3f / %.3f\n', nameList(num), i, error_all_N_angle_Ours(eta_cnt, a_cnt), error_all_N_angle_Atkinson2006(eta_cnt, a_cnt));
            end
        end
    end
end
%%
for i = 1 : length(nameList)
    figure; 
    hold on; grid on;
    error_ours = error_all_N_angle_Ours(:,:,i,1);
    error_Atkinson2006 = error_all_N_angle_Atkinson2006(:,:,i,1);
    surf(A, ETA, rad2deg(error_ours), 'FaceAlpha', 0.8, 'EdgeColor', 'none'); 
    mesh(A, ETA, rad2deg(error_Atkinson2006), 'EdgeColor', 'g'); 
    view([30,10]);
    legend('Ours', 'Atkinson2006');
    xlabel('a'); ylabel('\eta'); zlabel('Mean Error');
end

%%
% save('./Data/Data_ExperimentSonyDataset_OursVSAtkinson2006_test_A_ETA.mat', 'A', 'ETA', 'sumMask',...
%     'error_all_N_angle_Ours', 'error_all_N_angle_Atkinson2006');




%%
function dataset = reatdSonyDataset(location)
    subLocation = ["SONY1", "SONY2", "SONY3"];
    subsubLocation = {
        ["bear1", "bear2", "cat"];  
        ["cup1", "cup3"];            
        ["doll",  "squirrel"]         
    };
    subsubsubLocation = ["1", "2", "3", "4", "5", "6", "7", "8"];
    dataset = struct(); 
    % data
    for i = 1 : length(subLocation)
        current_objects = subsubLocation{i}; 
        for j = 1 : length(current_objects)
            objName = char(current_objects(j));
            for k = 1 : length(subsubsubLocation)
                folderPath = fullfile(location, subLocation(i), objName, subsubsubLocation(k));
                dataset.(objName)(k).polarImage.I0 = im2double(imread(fullfile(folderPath, 'A000.tif')));
                dataset.(objName)(k).polarImage.I45 = im2double(imread(fullfile(folderPath, 'A045.tif')));
                dataset.(objName)(k).polarImage.I90 = im2double(imread(fullfile(folderPath, 'A090.tif')));
                dataset.(objName)(k).polarImage.I135 = im2double(imread(fullfile(folderPath, 'A135.tif')));
                dataset.(objName)(k).lightDirection = im2double(load(fullfile(folderPath, 'LightDirection.txt')));
                dataset.(objName)(k).mask = im2double(imread(fullfile(folderPath, 'mask.png'))) > 0.99;
                normal = (im2double(imread(fullfile(folderPath, 'normal.png'))) * 2.0 - 1.0) .* dataset.(objName)(k).mask;
                normalLength = sqrt(sum(normal.^2, 3));
                normalLength(normalLength == 0) = 1;  
                dataset.(objName)(k).normal = normal ./ normalLength;                
%                 figure('Position', [0, 0, 1400, 750], 'Color', 'w', 'Name', objName + "_" + subsubsubLocation(k)); 
%                 subplot(3, 4, 1); imshow(dataset.(objName)(k).polarImage.I0, []);
%                 subplot(3, 4, 2); imshow(dataset.(objName)(k).polarImage.I45, []);
%                 subplot(3, 4, 3); imshow(dataset.(objName)(k).polarImage.I90, []);
%                 subplot(3, 4, 4); imshow(dataset.(objName)(k).polarImage.I135, []);
%                 subplot(3, 4, 5); imshow(dataset.(objName)(k).polarImage.I0 .* dataset.(objName)(k).mask, []);
%                 subplot(3, 4, 6); imshow(dataset.(objName)(k).polarImage.I45 .* dataset.(objName)(k).mask, []);
%                 subplot(3, 4, 7); imshow(dataset.(objName)(k).polarImage.I90 .* dataset.(objName)(k).mask, []);
%                 subplot(3, 4, 8); imshow(dataset.(objName)(k).polarImage.I135 .* dataset.(objName)(k).mask, []);
%                 subplot(3, 4, 9); imshow(dataset.(objName)(k).mask, []);
%                 subplot(3, 4, 10); imshow((dataset.(objName)(k).normal + 1) / 2);
%                 subplot(3, 4, 11); imshow((dataset.(objName)(k).normal .* dataset.(objName)(k).mask + 1) / 2);   
            end
        end
    end
    %% name
    dataset.nameList = ["bear1", "bear2", "cat", "cup1", "cup3", "doll", "squirrel"];
    save('./Data/Data_SonyDataset.mat', '-struct', 'dataset');
end









