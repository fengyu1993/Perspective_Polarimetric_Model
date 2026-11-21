%% 对比Sphere Dataset
clc;
clear; 
close all;
%% Data
[Atkinson, Smith, Ngo, Ba, Beta] = getdata(".\Data");
%% Error
AtkinsonError = getError(Atkinson);
SmithError = getError(Smith);
NgoError = getErrorNgo(Ngo);
BaError = getErrorBa(Ba);
%%
[AtkinsonOrthResult, AtkinsonPersResult] = getStatistics(AtkinsonError);
[SmithOrthResult, SmithPersResult] = getStatistics(SmithError);
[NgoOrthResult, NgoPersResult] = getStatistics(NgoError);
[BaOrthResult, BaPersResult] = getStatistics(BaError);
%% 输出 LaTeX 表格行：由表中显示的数值计算降幅和增益
methods = {'Ngo2022', 'Smith2019', 'Atkinson2006', 'Ba2020'};
orth = {NgoOrthResult, SmithOrthResult, AtkinsonOrthResult, BaOrthResult};
pers = {NgoPersResult, SmithPersResult, AtkinsonPersResult, BaPersResult};
fields = {'P10', 'P20', 'P30'};

for i = 1:numel(methods)
    O = orth{i};
    P = pers{i};

    % 1. MAE：先保留两位小数，再计算相对降幅
    o = round(O.MAE, 2);
    p = round(P.MAE, 2);
    [oText, pText] = formatPair(o, p, true, '');

    if o > 0
        reduction = round(100 * (o - p) / o, 2);
        reductionText = [sprintf('%.2f', reduction), '\%'];
    else
        reductionText = '--';
    end

    fprintf('\\textit{%s} & %s & %s & %s', ...
        methods{i}, oText, pText, reductionText);

    % 2. 阈值比例：先将百分数保留两位，再计算百分点差
    for j = 1:numel(fields)
        o = round(O.(fields{j}), 2);
        p = round(P.(fields{j}), 2);
        gain = round(p - o, 2);

        [oText, pText] = formatPair(o, p, false, '\%');
        fprintf(' & & %s & %s & %+.2f', oText, pText, gain);
    end

    fprintf(' %s\n', '\\');
end

%% 辅助函数：较优值连同百分号一起加粗；相等时均不加粗
function [aText, bText] = formatPair(a, b, lowerIsBetter, suffix)
    aText = sprintf('%.2f%s', a, suffix);
    bText = sprintf('%.2f%s', b, suffix);

    if a == b
        return;
    end

    if (lowerIsBetter && a < b) || (~lowerIsBetter && a > b)
        aText = ['\textbf{' aText '}'];
    else
        bText = ['\textbf{' bText '}'];
    end
end

function [orthResult, persResult] = getStatistics(Error)
    nameList = fieldnames(Error);
    errOrthList = [];
    errPersList = [];
    for i = 1 : length(nameList)
        objName = char(nameList(i));
        err = Error.(objName);
        E_orthList = double(err.error_Orth);
        E_persList = double(err.error_Pers);
        [~, ~, nums] = size(E_orthList);
        for k = 1 : nums
            E_orth = E_orthList(:,:,k);
            E_pers = E_persList(:,:,k);
            Mask = isfinite(E_orth) & isfinite(E_pers);
            errOrthList = [errOrthList; E_orth(Mask)];
            errPersList = [errPersList; E_pers(Mask)];
        end
    end
    %%
    orthResult.MAE = mean(errOrthList);
    persResult.MAE = mean(errPersList);
    %%
    angles = [10; 20; 30];
    for i = 1 : length(angles)
        id = find(errOrthList <= angles(i));
        pOrth = length(id) / length(errOrthList) * 100;
        id = find(errPersList <= angles(i));
        pPers = length(id) / length(errPersList) * 100;
        orthResult.(['P', num2str(angles(i))]) = pOrth;
        persResult.(['P', num2str(angles(i))]) = pPers;
    end
end



function [Atkinson, Smith, Ngo, Ba, Beta] = getdata(dataDir)
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
    %% Ngo
    for numObj = 1:numel(nameList)
        objName = char(nameList(numObj));
        fileName = fullfile(dataDir,  ['Data_ExperimentSphereDataset_OursVsNgo_', objName, '.mat']);
        Ngo.(objName) = load(fileName);
    end
    %% Ba
    for numObj = 1:numel(nameList)
        objName = char(nameList(numObj));
        fileName = fullfile(dataDir,  ['Data_ExperimentSphereDataset_OursVsBa2020_', objName, '.mat']);
        Ba.(objName) = load(fileName);
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

function Error = getErrorBa(data)
    nameList = "P" + string(1:16);
    lList = [1, 2];
    for pNum = 1 : 16
        objName = char(nameList(pNum));
        for j = 1 : length(lList)
            lNum = lList(j);
            N_orth = data.(objName).N_Orth(:,:,:,lNum);
            N_pers = data.(objName).N_Pers(:,:,:,lNum);
            N_desired = data.(objName).N_Desired(:,:,:,lNum);
            Mask = data.(objName).maskAll(:,:,lNum);
            Error.(objName).error_Orth(:,:, j) = rad2deg(getErrorNormalAngle(N_orth, N_desired, Mask));
            Error.(objName).error_Pers(:,:, j) = rad2deg(getErrorNormalAngle(N_pers, N_desired, Mask));    
        end
    end

end
