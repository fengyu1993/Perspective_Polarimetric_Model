%% Real Data (DeepSfP Dataset) Complex Surfaces Comparision: select parameter
clc; clear; close all;
%% 
location = ['.\Data\', '20260731_Data_DeepSfP_Test\'];
methodName = ["sp", "dp", "spdp", "spdp_2"];
objectName = ["box", "dragon", "father_christmas", "flamingo", "horse", "vase"];
caseName = ["indoor", "outdoor_cloudy", "outdoor_sunny"];
otherName = ["Data_DeepSfP_dataset_", "test_A_FXY_", ".mat"];
%% Object
Err_pers = zeros(5, 35);
Err_orth = zeros(5, 35);
for methodNum = 3 : 3%length(methodName)
    for objectNum = 1 : length(objectName)
        for caseNum = 1 : length(caseName)
            fprintf("%s -- %s -- %s\n", caseName(caseNum), objectName(objectNum), methodName(methodNum));
            data = load([location, char(otherName(1)), char(caseName(caseNum)), '_', char(objectName(objectNum)), '_', char(otherName(2)), char(methodName(methodNum)), char(otherName(3))]);
            Err_pers = Err_pers + data.error_all_N_angle;
            Err_orth = Err_orth + data.error_all_N_angle_orth;
        end
        Err_pers = Err_pers / length(caseName);
        Err_orth = Err_orth / length(caseName);
        figure; hold on; grid on;
        %% plot
        mesh(data.A, data.F_XY, rad2deg(Err_pers), 'EdgeColor', 'r'); 
        mesh(data.A, data.F_XY, rad2deg(Err_orth), 'EdgeColor', 'g');
        view([30,10]);
        legend('Ours', 'Orthographic');
        xlabel('a'); ylabel('f'); zlabel('Mean Error');
        title(objectName(objectNum) + "  " + methodName(methodNum))
    end

end
%% select F_xy
Err_pers = NaN(3, 6);
numF = 4;
aMat = NaN(3, 6);
for methodNum = 3 : 3%length(methodName)
    for caseNum = 1 : length(caseName)
        for objectNum = 1 : length(objectName)
            fprintf("%s -- %s -- %s\n", caseName(caseNum), objectName(objectNum), methodName(methodNum));
            data = load([location, char(otherName(1)), char(caseName(caseNum)), '_', char(objectName(objectNum)), '_', char(otherName(2)), char(methodName(methodNum)), char(otherName(3))]);
            %%
            [k, col] = min(data.error_all_N_angle(numF, :));
            aMat(caseNum, objectNum) = col;
            Err_pers(caseNum, objectNum) = k;
            A(caseNum, objectNum) = data.A(numF, col);
            F(caseNum, objectNum) = data.F_XY(numF, col);  
            Err_orth(caseNum, objectNum) = data.error_all_N_angle_orth(numF, col); 
        end
    end
end
fprintf("Ours / Orthographic: %.3f, %.3f\n", rad2deg(mean(Err_pers(:))), rad2deg(mean(Err_orth(:))));
fprintf("Best f_xy: %i\n", F(1,1));
%% select a
mean(A)
%% test
Err_pers = NaN(3, 6);
Err_orth = NaN(3, 6);
A = NaN(3, 6);
F = NaN(3, 6);
for methodNum = 3 : 3%length(methodName)
    for caseNum = 1 : length(caseName)
        for objectNum = 1 : length(objectName)
            fprintf("%s -- %s -- %s\n", caseName(caseNum), objectName(objectNum), methodName(methodNum));
            data = load([location, char(otherName(1)), char(caseName(caseNum)), '_', char(objectName(objectNum)), '_', char(otherName(2)), char(methodName(methodNum)), char(otherName(3))]);
            %%
            k = min(data.error_all_N_angle(:));
            [row, col] = find(data.error_all_N_angle == k);
            Err_pers(caseNum, objectNum) = k;
            A(caseNum, objectNum) = data.A(row, col);
            F(caseNum, objectNum) = data.F_XY(row, col);  
            Err_orth(caseNum, objectNum) = data.error_all_N_angle_orth(row, col); 
            %% plot
            figure; hold on; grid on;
            mesh(data.A, data.F_XY, rad2deg(data.error_all_N_angle), 'EdgeColor', 'r'); 
            mesh(data.A, data.F_XY, rad2deg(data.error_all_N_angle_orth), 'EdgeColor', 'g'); 
            view([30,10]);
            legend('Ours', 'Orthographic');
            xlabel('a'); ylabel('f'); zlabel('Mean Error');
            title(caseName(caseNum) + "  " + objectName(objectNum) + "  " + methodName(methodNum))
        end
    end
end
fprintf("Ours / Orthographic: %.3f, %.3f\n", rad2deg(mean(Err_pers(:))), rad2deg(mean(Err_orth(:))));

%% Case
Err_pers = zeros(5, 35);
Err_orth = zeros(5, 35);
for methodNum = 3 : 3%length(methodName)
    for caseNum = 1 : length(caseName)
        for objectNum = 1 : length(objectName)
            fprintf("%s -- %s -- %s\n", caseName(caseNum), objectName(objectNum), methodName(methodNum));
            data = load([location, char(otherName(1)), char(caseName(caseNum)), '_', char(objectName(objectNum)), '_', char(otherName(2)), char(methodName(methodNum)), char(otherName(3))]);
            Err_pers = Err_pers + data.error_all_N_angle;
            Err_orth = Err_orth + data.error_all_N_angle_orth;
        end
        Err_pers = Err_pers / length(objectName);
        Err_orth = Err_orth / length(objectName);
        figure; hold on; grid on;
        %% plot
        mesh(data.A, data.F_XY, rad2deg(Err_pers), 'EdgeColor', 'r'); 
        mesh(data.A, data.F_XY, rad2deg(Err_orth), 'EdgeColor', 'g');
        view([30,10]);
        legend('Ours', 'Orthographic');
        xlabel('a'); ylabel('f'); zlabel('Mean Error');
        title(caseName(caseNum) + "  " + methodName(methodNum))
    end

end






            k = min(rad2deg(data.error_all_N_angle(:)));
            [row, col] = find(rad2deg(data.error_all_N_angle) == k);
            data.A(row, col)
            data.F_XY(row, col)


%% 期望参数
% 焦距
f_xy = 3478;
%% dragon: indoor, outdoor_cloudy, outdoor_sunny
% spdp2: a = 1;
% spdp: a = 0.2323 f_xy = 1739; (better)
%% father_christmas: indoor, outdoor_cloudy, outdoor_sunny
% spdp: a = 0.1264 f_xy = 1739; 
%% flamingo: indoor, outdoor_cloudy, outdoor_sunny
% spdp: a = 0.205 f_xy = 2319; 





            %% plot
%             figure; hold on; grid on;
%             mesh(data.A, data.F_XY, rad2deg(data.error_all_N_angle), 'EdgeColor', 'r'); 
%             mesh(data.A, data.F_XY, rad2deg(data.error_all_N_angle_orth), 'EdgeColor', 'g'); 
%             view([30,10]);
%             legend('Ours', 'Orthographic');
%             xlabel('a'); ylabel('f'); zlabel('Mean Error');
%             title(caseName(caseNum) + "  " + objectName(objectNum) + "  " + methodName(methodNum))




