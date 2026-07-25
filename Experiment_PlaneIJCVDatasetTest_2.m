%% Real Data (IJCV Dataset) Plane Comparision 
clc; clear; close all;
%%
load(".\Data\Data_IJCV_dataset_test_A_ETA_2.mat");
%%
figure; 
hold on; grid on;
surf(A, ETA, rad2deg(error_all_N_angle), 'FaceAlpha', 0.8, 'EdgeColor', 'none'); 
mesh(A, ETA, rad2deg(error_all_N_angle_IJCV), 'EdgeColor', 'r'); 
view([30,10]);
legend('Ours',  'IJCV');
xlabel('a'); ylabel('\eta'); zlabel('Mean Error');
%%
valid_mask = error_all_N_angle < error_all_N_angle_IJCV;
error_all_N_angle_valid = error_all_N_angle(valid_mask);
A_valid = A(valid_mask);
ETA_valid = ETA(valid_mask);
aetaLise = [A_valid, ETA_valid];
%%
[min_val, min_idx] = min(error_all_N_angle_valid);
min_A = A_valid(min_idx);
min_ETA = ETA_valid(min_idx);
fprintf('Min a = %f, eta = %f\n', min_A, min_ETA);
%%
err = abs(error_all_N_angle(valid_mask) - error_all_N_angle_IJCV(valid_mask));
[~, max_idx] = max(err);
max_A = A_valid(max_idx);
max_ETA = ETA_valid(max_idx);
fprintf('Max a = %f, eta = %f\n', max_A, max_ETA);
