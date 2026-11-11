%% 对比Sphere Dataset
clc;
% clear; 
close all;
%% Data
% [Atkinson, Smith, Ngo, Beta] = getdata(".\Data");
% dataset = load("Data\Data_SphereDataset.mat");
%% Error
% AtkinsonError = getError(Atkinson);
% SmithError = getError(Smith);
% NgoError = getErrorNgo(Ngo);
%%
[T_Ngo, P_Ngo] = getMethodStatistics(NgoError, 'Ngo2022');
[T_Smith, P_Smith] = getMethodStatistics(SmithError, 'Smith2019');
[T_Atkinson, P_Atkinson] = getMethodStatistics(AtkinsonError, 'Atkinson2006');
[T_Ba, P_Ba] = getMethodStatistics(AtkinsonError, 'Ba2020');


T = [T_Ngo; T_Smith; T_Atkinson; T_Ba];
disp(T)

for i = 1:height(T)
    fprintf('\\textit{%s} & %.2f & $\\mathbf{%.2f}$ & %.2f\\%% & %s \\\\ \n', ...
        char(T.Method(i)), ...
        T.Orth_MAE_deg(i), ...
        T.Pers_MAE_deg(i), ...
        T.Reduction_percent(i), ...
        char(T.Improved_positions(i)));
end



%%
function [summary, perPosition] = getMethodStatistics(Error, methodName)
    % 输入误差单位：deg
    nameList = "P" + string(1:16);
    numPositions = numel(nameList);

    maeOrth = NaN(numPositions, 1);
    maePers = NaN(numPositions, 1);
    numPixels = zeros(numPositions, 1);

    for p = 1:numPositions
        objName = char(nameList(p));
        D = Error.(objName);

        E_orth = double(D.error_Orth);
        E_pers = double(D.error_Pers);

        assert(isequal(size(E_orth), size(E_pers)), ...
            '%s：两种方法的误差尺寸不一致。', objName);

        % 两种方法使用相同的有效观测
        valid = isfinite(E_orth) & isfinite(E_pers);

        if isfield(D, 'Mask')
            valid = valid & logical(D.Mask);
        end

        E_orth(~valid) = NaN;
        E_pers(~valid) = NaN;

        % 1. 每个像素对光照取平均
        % Ngo 的二维误差图数值保持不变
        pixelOrth = mean(E_orth, 3, 'omitnan');
        pixelPers = mean(E_pers, 3, 'omitnan');

        Mask = any(valid, 3);
        numPixels(p) = nnz(Mask);

        assert(numPixels(p) > 0, ...
            '%s：没有共同有效像素，无法计算完整的16位置统计。', objName);

        % 2. 每个位置对有效像素取平均
        maeOrth(p) = mean(pixelOrth(Mask));
        maePers(p) = mean(pixelPers(Mask));
    end

    %% 3. 对16个位置等权平均
    overallOrth = mean(maeOrth);
    overallPers = mean(maePers);

    reduction = NaN;
    if overallOrth > 0
        reduction = (overallOrth - overallPers) / overallOrth * 100;
    end

    improved = maePers < maeOrth;
    improvedPositions = string(nnz(improved)) + "/" + string(numPositions);

    %% Summary table
    summary = table( ...
        string(methodName), overallOrth, overallPers, ...
        reduction, improvedPositions, ...
        'VariableNames', {'Method', 'Orth_MAE_deg', 'Pers_MAE_deg', ...
                          'Reduction_percent', 'Improved_positions'});

    %% Per-position results
    reductionPerPosition = NaN(numPositions, 1);
    validRate = maeOrth > 0;

    reductionPerPosition(validRate) = ...
        (maeOrth(validRate) - maePers(validRate)) ...
        ./ maeOrth(validRate) * 100;

    perPosition = table( ...
        nameList(:), maeOrth, maePers, reductionPerPosition, ...
        improved, numPixels, ...
        'VariableNames', {'Position', 'Orth_MAE_deg', 'Pers_MAE_deg', ...
                          'Reduction_percent', 'Improved', 'NumPixels'});
end

function [Atkinson, Smith, Ngo, Beta] = getdata(dataDir)
    nameList = "P" + string(1:16);
    %% Atkinson
    for numObj = 1:numel(nameList)
        objName = char(nameList(numObj));
        fileName = fullfile(dataDir,  ['Data_ExperimentSphereDataset_OursVsAtkinson_', objName, '.mat']);
        Atkinson.(objName) = load(fileName);
    end
    %% Smith
    for numObj = 1:numel(nameList)
        objName = char(nameList(numObj));
        fileName = fullfile(dataDir,  ['Data_ExperimentSphereDataset_OursVsSmith_', objName, '.mat']);
        Smith.(objName) = load(fileName);
    end
    %% Smith
    for numObj = 1:numel(nameList)
        objName = char(nameList(numObj));
        fileName = fullfile(dataDir,  ['Data_ExperimentSphereDataset_OursVsNgo_', objName, '.mat']);
        Ngo.(objName) = load(fileName);
    end
    %%
    fileName = fullfile(dataDir,  'Data_ExperimentSphereDataset_Beta.mat');
    Beta = load(fileName).Beta;
end

function Error = getError(data)
    nameList = "P" + string(1:16);
    for pNum = 1 : 16
        objName = char(nameList(pNum));
        for lNum = 1 : 6
            N_orth = data.(objName).N_Orth(:,:,:,lNum);
            N_pers = data.(objName).N_Pers(:,:,:,lNum);
            N_desired = data.(objName).N_Desired(:,:,:,lNum);
            Mask = data.(objName).maskAll(:,:,lNum);
            Error.(objName).error_Orth(:,:, lNum) = rad2deg(getErrorNormalAngle(N_orth, N_desired, Mask));
            Error.(objName).error_Pers(:,:, lNum) = rad2deg(getErrorNormalAngle(N_pers, N_desired, Mask));    
        end
    end

end

function NgoError = getErrorNgo(Ngo)
    nameList = "P" + string(1:16);
    for pNum = 1 : 16
        objName = char(nameList(pNum));
        N_orth = Ngo.(objName).N_Orth;
        N_pers = Ngo.(objName).N_Pers;
        N_desired = Ngo.(objName).N_Desired;
        Mask = Ngo.(objName).maskAll;
        NgoError.(objName).error_Orth = rad2deg(getErrorNormalAngle(N_orth, N_desired, Mask));
        NgoError.(objName).error_Pers = rad2deg(getErrorNormalAngle(N_pers, N_desired, Mask));    
    end
end