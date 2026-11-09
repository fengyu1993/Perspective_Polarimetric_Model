%% Sphere dataset: error versus beta
clc;
clear;
close all;

%% Parameters
dataDir = 'Data';
betaStep = 1;          % beta 分组宽度，单位：deg
minSamples = 30;       % 每组至少包含的有效观测数
showLight = 1;         % 展示第几个光照下的法向量
showNormals = true;

%% Load viewing directions
data = load(fullfile(dataDir, 'Data_SphereDataset.mat'), ...
    'view_dirs', 'nameList');

V = double(data.view_dirs);
nameList = data.nameList;
[rows, cols, ~] = size(V);

% 归一化视线
viewLength = sqrt(sum(V.^2, 3));
validView = all(isfinite(V), 3) & ...
    isfinite(viewLength) & viewLength > 0;

viewLength(~validView) = NaN;
V = V ./ viewLength;

% Beta：视线与 +z 光轴的夹角
Beta_deg = acosd(max(-1, min(1, V(:,:,3))));
Beta_deg(~validView) = NaN;

assert(any(validView(:)), '没有有效视线。');

%% Beta bins
maxBeta = max(Beta_deg(validView));
upperEdge = max(betaStep, ceil(maxBeta / betaStep) * betaStep);

betaEdges = 0:betaStep:upperEdge;
betaCenters = (betaEdges(1:end-1) + betaEdges(2:end)) / 2;
numBins = numel(betaCenters);

betaBin = discretize(Beta_deg, betaEdges);

% 所有位置、光照的累计结果
sumErrorOrth = zeros(numBins, 1);
sumErrorPers = zeros(numBins, 1);
sampleCount = zeros(numBins, 1);

results = struct();

%% Read each position
for numObj = 1:numel(nameList)
    objName = char(nameList(numObj));

    fileName = fullfile(dataDir, ...
        ['Data_ExperimentSphereDataset_OursVsAtkinson_', ...
         objName, '.mat']);

    S = load(fileName, 'N_Orth', 'N_Pers', ...
        'N_Desired', 'maskAll');

    assert(size(S.N_Orth,1) == rows && ...
           size(S.N_Orth,2) == cols, ...
        '%s 的结果与视线图尺寸不一致。', objName);

    numLights = size(S.N_Orth, 4);

    errorAllOrth = NaN(rows, cols, numLights);
    errorAllPers = NaN(rows, cols, numLights);
    maskEvalAll = false(rows, cols, numLights);

    maeOrth = NaN(1, numLights);
    maePers = NaN(1, numLights);

    for numLight = 1:numLights
        %% Read and normalize normals
        [N_Orth, validOrth] = normalizeNormal( ...
            S.N_Orth(:,:,:,numLight));

        [N_Pers, validPers] = normalizeNormal( ...
            S.N_Pers(:,:,:,numLight));

        [N_ref, validRef] = normalizeNormal( ...
            S.N_Desired(:,:,:,numLight));

        % 两种方法使用同一个评估区域
        Mask_eval = logical(S.maskAll(:,:,numLight)) & ...
            validView & validOrth & validPers & validRef & ...
            isfinite(betaBin);

        %% Per-pixel angular errors, in degrees
        dotOrth = sum(N_Orth .* N_ref, 3);
        dotPers = sum(N_Pers .* N_ref, 3);

        errorOrth = acosd(max(-1, min(1, dotOrth)));
        errorPers = acosd(max(-1, min(1, dotPers)));

        errorOrth(~Mask_eval) = NaN;
        errorPers(~Mask_eval) = NaN;

        errorAllOrth(:,:,numLight) = errorOrth;
        errorAllPers(:,:,numLight) = errorPers;
        maskEvalAll(:,:,numLight) = Mask_eval;

        if any(Mask_eval(:))
            maeOrth(numLight) = mean(errorOrth(Mask_eval));
            maePers(numLight) = mean(errorPers(Mask_eval));

            %% Accumulate errors in beta bins
            binIds = betaBin(Mask_eval);

            sumErrorOrth = sumErrorOrth + accumarray( ...
                binIds, errorOrth(Mask_eval), [numBins, 1], @sum, 0);

            sumErrorPers = sumErrorPers + accumarray( ...
                binIds, errorPers(Mask_eval), [numBins, 1], @sum, 0);

            sampleCount = sampleCount + accumarray( ...
                binIds, ones(size(binIds)), [numBins, 1], @sum, 0);
        end

        %% Show normal maps
        if showNormals && numLight == showLight && any(Mask_eval(:))
            fig = figure('Color', 'w', ...
                'Name', sprintf('%s, light %d', objName, numLight));

            subplot(1,3,1);
            plot3DShape(fig, N_ref, Mask_eval);
            title('Reference');

            subplot(1,3,2);
            plot3DShape(fig, N_Orth, Mask_eval);
            title('Orth.');

            subplot(1,3,3);
            plot3DShape(fig, N_Pers, Mask_eval);
            title('Pers.');
        end
    end

    %% Store processed data
    results.(objName).errorOrth = errorAllOrth;
    results.(objName).errorPers = errorAllPers;
    results.(objName).Mask_eval = maskEvalAll;
    results.(objName).maeOrth = maeOrth;
    results.(objName).maePers = maePers;

    % 汇总当前位置所有有效的像素—光照观测
    fprintf('%s: MAE Orth. / Pers. = %.3f / %.3f deg\n', ...
        objName, ...
        mean(errorAllOrth(maskEvalAll)), ...
        mean(errorAllPers(maskEvalAll)));
end

%% Mean error in each beta bin
meanErrorOrth = NaN(numBins, 1);
meanErrorPers = NaN(numBins, 1);

validBins = sampleCount >= minSamples;

meanErrorOrth(validBins) = ...
    sumErrorOrth(validBins) ./ sampleCount(validBins);

meanErrorPers(validBins) = ...
    sumErrorPers(validBins) ./ sampleCount(validBins);

%% Plot error versus beta
figure('Color', 'w');

subplot(2,1,1);
plot(betaCenters, meanErrorOrth, 'b-o', ...
    'LineWidth', 1.5, 'DisplayName', 'Orth.');
hold on;
plot(betaCenters, meanErrorPers, 'r-s', ...
    'LineWidth', 1.5, 'DisplayName', 'Pers.');
grid on;
xlabel('\beta (deg)');
ylabel('Mean angular error (deg)');
legend('Location', 'best');
title('Atkinson2006: error versus viewing angle');

subplot(2,1,2);
bar(betaCenters, sampleCount);
grid on;
xlabel('\beta (deg)');
ylabel('Observation count');
title('Valid pixel–light observations per bin');

%% Save processed results
% save(fullfile(dataDir, ...
%     'Data_Sphere_Atkinson2006_ErrorVsBeta.mat'), ...
%     'results', 'nameList', 'Beta_deg', ...
%     'betaEdges', 'betaCenters', ...
%     'meanErrorOrth', 'meanErrorPers', 'sampleCount', ...
%     'betaStep', 'minSamples', '-v7.3');

%% Helper
function [N, valid] = normalizeNormal(N)
    N = double(N);
    normalLength = sqrt(sum(N.^2, 3));

    valid = all(isfinite(N), 3) & ...
        isfinite(normalLength) & normalLength > 0;

    normalLength(~valid) = NaN;
    N = N ./ normalLength;
end