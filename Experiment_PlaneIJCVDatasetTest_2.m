%% Real Data (IJCV Dataset) Plane Comparision 
clc; clear; close all;
%%
% D303 = load('./Data/Data_IJCV_dataset_test_A_ETA_D303.mat');
% A107 = load('./Data/Data_IJCV_dataset_test_A_ETA_A107.mat');
% 
% num_A = 30;
% num_ETA = 25;
% a_list = linspace(0.4, 0.8, num_A);
% eta_list = linspace(1.4, 1.7, num_ETA);
% [A, ETA] = meshgrid(a_list, eta_list);
% error_all_N_angle_ours = NaN(num_ETA, num_A);
% error_all_N_angle_orth = NaN(num_ETA, num_A);
% error_all_N_angle_IJCV = NaN(num_ETA, num_A);
% 
% A(:, 1:15) = A107.A;    
% ETA(:, 1:15) = A107.ETA;
% error_all_N_angle_ours(:, 1:15) = A107.error_all_N_angle_ours;
% error_all_N_angle_orth(:, 1:15) = A107.error_all_N_angle_orth;
% error_all_N_angle_IJCV(:, 1:15) = A107.error_all_N_angle_IJCV;
% 
% A(:, 16:30) = D303.A;    
% ETA(:, 16:30) = D303.ETA;
% error_all_N_angle_ours(:, 16:30) = D303.error_all_N_angle_ours;
% error_all_N_angle_orth(:, 16:30) = D303.error_all_N_angle_orth;
% error_all_N_angle_IJCV(:, 16:30) = D303.error_all_N_angle_IJCV;
% 
% 
% save('./Data/Data_IJCV_dataset_test_A_ETA.mat', 'A', 'ETA', ...
%     'error_all_N_angle_ours', 'error_all_N_angle_orth', 'error_all_N_angle_IJCV');
%%
load(".\Data\Data_IJCV_dataset_test_A_ETA.mat");
%%
figure; 
hold on; grid on;
surf(A, ETA, rad2deg(error_all_N_angle_ours), 'FaceAlpha', 0.8, 'EdgeColor', 'none'); 
mesh(A, ETA, rad2deg(error_all_N_angle_IJCV), 'EdgeColor', 'r'); 
view([30,10]);
legend('Ours',  'IJCV');
xlabel('a'); ylabel('\eta'); zlabel('Mean Error');
%%
valid_mask = error_all_N_angle_ours < error_all_N_angle_IJCV;
error_all_N_angle_valid = error_all_N_angle_ours(valid_mask);
A_valid = A(valid_mask);
ETA_valid = ETA(valid_mask);
aetaLise = [A_valid, ETA_valid];
%%
[min_val, min_idx] = min(error_all_N_angle_valid);
min_A = A_valid(min_idx);
min_ETA = ETA_valid(min_idx);
fprintf('Min a = %f, eta = %f\n', min_A, min_ETA);
%%
err = abs(error_all_N_angle_ours(valid_mask) - error_all_N_angle_IJCV(valid_mask));
[~, max_idx] = max(err);
max_A = A_valid(max_idx);
max_ETA = ETA_valid(max_idx);
fprintf('Max a = %f, eta = %f\n', max_A, max_ETA);
