%% Our Sphere Dataset
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
%% polar image
% imageAll = NaN(1024, 1224);
% maskAll = NaN(1024, 1224);
% nameList = "P" + string(1:16);
% for numObj = 1 : 16 
%     objName = char(nameList(numObj));
%     objData = dataset.(objName); 
%     mask = objData(1).mask;
%     image = objData(1).polarImage.I0;
% %     maskAll(mask) = mask(:);
%     imageAll(mask) = image(mask);
% end
% fig = figure;
% imshow(imageAll);
% fullPath = fullfile('./imageSphere/', 'fig_PolarImageAll.png');
% exportgraphics(fig, fullPath, 'Resolution', 300);
%% Normal
% figRef = plotAllDesiredNormal(Atkinson);
% figNgo = plotAllNgoNormal(Ngo);
%% Normal error plot
% figAtkinson = plotAllNormalError(AtkinsonError);
% fullPath = fullfile('./imageSphere/', 'fig_ErrorAtkinsonOrth.png');
% exportgraphics(figAtkinson(1), fullPath, 'Resolution', 300);
% fullPath = fullfile('./imageSphere/', 'fig_ErrorAtkinsonPers.png');
% exportgraphics(figAtkinson(2), fullPath, 'Resolution', 300);
% fullPath = fullfile('./imageSphere/', 'fig_ErrorAtkinsonTemp.png');
% exportgraphics(figAtkinson(3), fullPath, 'Resolution', 300);
% figSmith = plotAllNormalError(SmithError);
% fullPath = fullfile('./imageSphere/', 'fig_ErrorSmithOrth.png');
% exportgraphics(figSmith(1), fullPath, 'Resolution', 300);
% fullPath = fullfile('./imageSphere/', 'fig_ErrorSmithPers.png');
% exportgraphics(figSmith(2), fullPath, 'Resolution', 300);
% fullPath = fullfile('./imageSphere/', 'fig_ErrorSmithTemp.png');
% exportgraphics(figSmith(3), fullPath, 'Resolution', 300);
% figNgo = plotAllNormalError(NgoError);
% fullPath = fullfile('./imageSphere/', 'fig_ErrorNgoOrth.png');
% exportgraphics(figNgo(1), fullPath, 'Resolution', 300);
% fullPath = fullfile('./imageSphere/', 'fig_ErrorNgoPers.png');
% exportgraphics(figNgo(2), fullPath, 'Resolution', 300);
% fullPath = fullfile('./imageSphere/', 'fig_ErrorNgoTemp.png');
% exportgraphics(figNgo(3), fullPath, 'Resolution', 300);
%% Beta all plot
[figAtkinsonBeta, betaAtkinsonStats] = plotErrorVsBeta(AtkinsonError, Beta);
[figSmithBeta, betaSmithStats] = plotErrorVsBeta(SmithError, Beta);
[figNgoBeta, betaNgoStats] = plotErrorVsBeta(NgoError, Beta);
fullPath = fullfile('./imageSphere/', 'fig_AtkinsonErrorBeta.png');
exportgraphics(figAtkinsonBeta, fullPath, 'Resolution', 300);
fullPath = fullfile('./imageSphere/', 'fig_SmithErrorBeta.png');
exportgraphics(figSmithBeta, fullPath, 'Resolution', 300);
fullPath = fullfile('./imageSphere/', 'fig_SmithNgoBeta.png');
exportgraphics(figNgoBeta, fullPath, 'Resolution', 300);
%% Normal plot
% nameList = "P" + string(1:16);
% for numObj = 1 : 16
%     objName = char(nameList(numObj));
%     %% Atkinson
%     fig = plotNormal(Atkinson.(objName), objName);
%     fig = plotNormalError(AtkinsonError.(objName), objName);
%     %% Smith
%     fig = plotNormal(Smith.(objName), objName);
%     fig = plotNormalError(SmithError.(objName), objName);    
%     %% Ngo
%     fig = plotNormalNgo(Ngo.(objName), objName);
%     fig = plotNormalErrorNgo(NgoError.(objName), objName);    
% end
%%



















%% 

function fig = plotAllDesiredNormal(data)
    nameList = "P" + string(1:16);
    [rows, cols, ~, ~] = size(data.P1.N_Desired);

    N_all = NaN(rows, cols, 3);
    Mask_all = false(rows, cols);

    for i = 1:numel(nameList)
        D = data.(char(nameList(i)));
        N = D.N_Desired(:,:,:,1);

        % 合并各光照的有效区域
        Mask = any(logical(D.maskAll), 3);
        normalLength = sqrt(sum(N.^2, 3));

        Mask = Mask & all(isfinite(N), 3) & ...
            isfinite(normalLength) & normalLength > 0;

        % 重叠区域保留先加入的位置，避免混合不同球面法向量
        Mask = Mask & ~Mask_all;
        normalLength(~Mask) = NaN;
        N = N ./ normalLength;

        for c = 1:3
            channel = N_all(:,:,c);
            source = N(:,:,c);
            channel(Mask) = source(Mask);
            N_all(:,:,c) = channel;
        end

        Mask_all = Mask_all | Mask;
    end

    assert(any(Mask_all(:)), '没有有效参考法向量。');

    fig = figure('Color', 'w');
    ax = axes('Parent', fig);
    plot3DShape(fig, N_all, Mask_all);

    axis(ax, 'image');
    set(ax, 'Visible', 'on', ...
        'Box', 'on', 'LineWidth', 1.2, ...
        'XColor', 'k', 'YColor', 'k', ...
        'XTick', [], 'YTick', []);

    fullPath = fullfile('./imageSphere/', 'fig_DesiredNormalAll.png');
    exportgraphics(fig, fullPath, 'Resolution', 300);
end

function fig = plotAllNgoNormal(Ngo)
    nameList = "P" + string(1:16);
    [rows, cols, ~] = size(Ngo.P1.N_Orth);

    N_orthAll = NaN(rows, cols, 3);
    N_persAll = NaN(rows, cols, 3);
    Mask_all = false(rows, cols);

    %% 合并16个位置
    for i = 1:numel(nameList)
        D = Ngo.(char(nameList(i)));

        N_orth = double(D.N_Orth);
        N_pers = double(D.N_Pers);

        lenOrth = sqrt(sum(N_orth.^2, 3));
        lenPers = sqrt(sum(N_pers.^2, 3));

        % 两种方法使用共同有效区域
        Mask = logical(D.maskAll) & ...
            all(isfinite(N_orth), 3) & ...
            all(isfinite(N_pers), 3) & ...
            isfinite(lenOrth) & lenOrth > 0 & ...
            isfinite(lenPers) & lenPers > 0;

        % 重叠区域保留先加入的位置
        Mask = Mask & ~Mask_all;

        lenOrth(~Mask) = NaN;
        lenPers(~Mask) = NaN;
        N_orth = N_orth ./ lenOrth;
        N_pers = N_pers ./ lenPers;

        for c = 1:3
            channelOrth = N_orthAll(:,:,c);
            channelPers = N_persAll(:,:,c);

            sourceOrth = N_orth(:,:,c);
            sourcePers = N_pers(:,:,c);

            channelOrth(Mask) = sourceOrth(Mask);
            channelPers(Mask) = sourcePers(Mask);

            N_orthAll(:,:,c) = channelOrth;
            N_persAll(:,:,c) = channelPers;
        end

        Mask_all = Mask_all | Mask;
    end

    assert(any(Mask_all(:)), '没有有效法向量。');

    %% 正交、透视分别绘图
    normals = {N_orthAll, N_persAll};
    fig = gobjects(2,1);

    for k = 1:2
        fig(k) = figure('Color', 'w');

        ax = axes('Parent', fig(k));
        plot3DShape(fig(k), normals{k}, Mask_all);

        axis(ax, 'image');
        set(ax, 'Visible', 'on', ...
            'Box', 'on', 'LineWidth', 1.2, ...
            'XColor', 'k', 'YColor', 'k', ...
            'XTick', [], 'YTick', []);
    end
    fullPath = fullfile('./imageSphere/', 'fig_NgoOrthNormalAll.png');
    exportgraphics(fig(1), fullPath, 'Resolution', 300);
    fullPath = fullfile('./imageSphere/', 'fig_NgoPersNormalAll.png');
    exportgraphics(fig(2), fullPath, 'Resolution', 300);
end


function [fig, stats] = plotErrorVsBeta(Error, Beta)
    %% Parameters
    betaStep = 1;       % beta 分组宽度，deg
    minSamples = 30;    % 每组最少有效样本数

    %% Beta bins
    Beta_deg = rad2deg(Beta);
    validBeta = isfinite(Beta_deg) & Beta_deg >= 0;

    assert(any(validBeta(:)), '没有有效 Beta 数据。');

    maxBeta = max(Beta_deg(validBeta));
    upperEdge = max(betaStep, ceil(maxBeta / betaStep) * betaStep);

    edges = 0:betaStep:upperEdge;
    centers = ((edges(1:end-1) + edges(2:end)) / 2).';
    binMap = discretize(Beta_deg, edges);
    numBins = numel(centers);

    sumOrth = zeros(numBins, 1);
    sumPers = zeros(numBins, 1);
    count = zeros(numBins, 1);

    %% Collect errors from all positions
    nameList = "P" + string(1:16);

    for i = 1:numel(nameList)
        objName = char(nameList(i));
        D = Error.(objName);

        E_orth = double(D.error_Orth);
        E_pers = double(D.error_Pers);

        assert(isequal(size(E_orth), size(E_pers)), ...
            '%s：Orth. 和 Pers. 的误差尺寸不一致。', objName);

        assert(size(E_orth,1) == size(Beta,1) && ...
               size(E_orth,2) == size(Beta,2), ...
            '%s：误差图与 Beta 的尺寸不一致。', objName);

        % 两种方法采用共同有效的光照观测
        valid = isfinite(E_orth) & isfinite(E_pers);

        if isfield(D, 'Mask')
            valid = valid & logical(D.Mask);
        end

        E_orth(~valid) = NaN;
        E_pers(~valid) = NaN;

        % 每个像素对不同光照取平均
        MAE_orth = mean(E_orth, 3, 'omitnan');
        MAE_pers = mean(E_pers, 3, 'omitnan');

        Mask = any(valid, 3) & validBeta & ...
               isfinite(binMap) & ...
               isfinite(MAE_orth) & isfinite(MAE_pers);

        if ~any(Mask(:))
            continue;
        end

        ids = binMap(Mask);

        sumOrth = sumOrth + accumarray( ...
            ids, MAE_orth(Mask), [numBins, 1], @sum, 0);

        sumPers = sumPers + accumarray( ...
            ids, MAE_pers(Mask), [numBins, 1], @sum, 0);

        count = count + accumarray( ...
            ids, ones(size(ids)), [numBins, 1], @sum, 0);
    end

    %% Mean error for each beta bin
    meanOrth = NaN(numBins, 1);
    meanPers = NaN(numBins, 1);

    keep = count >= minSamples;
    assert(any(keep), '没有满足最少样本数要求的 beta 分组。');

    meanOrth(keep) = sumOrth(keep) ./ count(keep);
    meanPers(keep) = sumPers(keep) ./ count(keep);

    %% Relative MAE reduction
    improveRate = NaN(numBins, 1);

    % Orth. 为零时，改进率无定义
    validRate = keep & meanOrth > 0;
    improveRate(validRate) = ...
        (meanOrth(validRate) - meanPers(validRate)) ...
        ./ meanOrth(validRate) * 100;

    %% Output statistics
    stats.beta = centers;
    stats.edges = edges;
    stats.MAE_Orth = meanOrth;
    stats.MAE_Pers = meanPers;
    stats.improveRate = improveRate;
    stats.count = count;
    stats.validBins = keep;
    stats.validRateBins = validRate;

    %% Plot with two y-axes
    fig = figure('Color', 'w', ...
        'Position', [100, 100, 750, 650]);
    ax = axes('Parent', fig);
    hold(ax, 'on');

    % 曲线颜色
    colorPers = [237, 33, 35] / 255;
    colorOrth = [57, 83, 164] / 255;
    colorRate = [72, 192, 170] / 255;

    % 左轴：平均角度误差
    yyaxis(ax, 'left');

    hOrth = plot(ax, centers, meanOrth, '-o', ...
        'Color', colorOrth, ...
        'LineWidth', 2.5, 'MarkerSize', 8);
    
    hPers = plot(ax, centers, meanPers, '-s', ...
        'Color', colorPers, ...
        'LineWidth', 2.5, 'MarkerSize', 8);
    
    ylabel(ax, 'MAE \Delta \gamma (\circ)');
    
    maxError = max([meanOrth(keep); meanPers(keep)]);
    tickStep = max(5, ceil(1.05 * maxError / (3 * 5)) * 5);
    
    ylim(ax, [0, 3 * tickStep]);
    yticks(ax, 0:tickStep:3*tickStep); 
    % 右轴：相对 MAE 改进率
    yyaxis(ax, 'right');
    
    hRate = plot(ax, centers, improveRate, '--^', ...
        'Color', colorRate, ...
        'LineWidth', 2.5, 'MarkerSize', 8);
    
%     yline(ax, 0, ':', ...
%         'Color', [0.5, 0.5, 0.5], ...
%         'HandleVisibility', 'off');
    
    ylabel(ax, 'MAE reduction (%)');
    
    ax.YAxis(1).Color = 'k';
    ax.YAxis(2).Color = colorRate;

    % 自动设置右轴范围，包含零及负改进率
    rateValues = improveRate(isfinite(improveRate));
    if ~isempty(rateValues)
        rateMin = min([0; rateValues]);
        rateMax = max([0; rateValues]);
        margin = max(1, 0.08 * (rateMax - rateMin));
        ylim(ax, [rateMin - margin, rateMax + margin]);
    end

    %% Appearance
    xlabel(ax, '\beta (\circ)');
    xlim(ax, [0, 30]);
    xticks(ax, [0, 10, 20, 30]);

    grid(ax, 'on');
    box(ax, 'on');

    set(ax, 'FontName', 'Times New Roman', ...
        'FontSize', 40, 'LineWidth', 2.5);

    ax.YAxis(1).Color = 'k';
    ax.YAxis(2).Color = colorRate;

    legend(ax, [hOrth, hPers], ...
        {'Orth.', 'Pers.'}, ...
        'Location', 'northwest');


end

function drawErrorBand(ax, x, mu, sd, keep, color)
    % 寻找连续有效分组
    transitions = diff([false; keep(:); false]);
    starts = find(transitions == 1);
    stops = find(transitions == -1) - 1;

    for k = 1:numel(starts)
        ids = starts(k):stops(k);

        % 单独一个有效分组无法形成有宽度的阴影
        if numel(ids) < 2
            continue;
        end

        xx = x(ids);
        lower = max(0, mu(ids) - sd(ids));
        upper = mu(ids) + sd(ids);

        fill(ax, [xx; flipud(xx)], ...
            [lower; flipud(upper)], color, ...
            'FaceAlpha', 0.15, ...
            'EdgeColor', 'none', ...
            'HandleVisibility', 'off');
    end
end


function fig = plotAllNormalError(Error)
    nameList = "P" + string(1:16);
    [rows, cols, ~] = size(Error.P1.error_Orth);

    sumOrth = zeros(rows, cols);
    sumPers = zeros(rows, cols);
    count = zeros(rows, cols);

    for i = 1:numel(nameList)
        data = Error.(char(nameList(i)));

        E_orth = data.error_Orth;
        E_pers = data.error_Pers;

        % 共同有效的像素—光照观测
        valid = isfinite(E_orth) & isfinite(E_pers);
        if isfield(data, 'Mask')
            valid = valid & logical(data.Mask);
        end

        E_orth(~valid) = NaN;
        E_pers(~valid) = NaN;

        % 当前位置：每个像素在不同光照下的平均误差
        MAE_orth = mean(E_orth, 3, 'omitnan');
        MAE_pers = mean(E_pers, 3, 'omitnan');
        Mask = any(valid, 3);

        sumOrth(Mask) = sumOrth(Mask) + MAE_orth(Mask);
        sumPers(Mask) = sumPers(Mask) + MAE_pers(Mask);
        count(Mask) = count(Mask) + 1;
    end

    % 合并16个位置；重叠区域按位置等权平均
    Mask = count > 0;
    assert(any(Mask(:)), '没有有效误差数据。');

    MAE_orth = NaN(rows, cols);
    MAE_pers = NaN(rows, cols);
    MAE_orth(Mask) = sumOrth(Mask) ./ count(Mask);
    MAE_pers(Mask) = sumPers(Mask) ./ count(Mask);

    % 共用色标
    maxError = max([MAE_orth(Mask); MAE_pers(Mask)]);
    colorLimits = [0, max(maxError, eps)];

    fig(1) = figure('Color', 'w', 'Name', ' Orth.');
    ax = axes(fig(1));
    h = imagesc(ax, MAE_orth);
    set(h, 'AlphaData', double(Mask));
    set(ax, 'Color', 'w');
    axis(ax, 'image');
    set(ax, 'Visible', 'on', ...
    'Box', 'on', ...
    'LineWidth', 1.2, ...
    'XColor', 'k', 'YColor', 'k', ...
    'XTick', [], 'YTick', []);
    colormap(ax, parula);
    caxis(ax, colorLimits);
    cb.FontName = 'Times New Roman';
    cb.FontSize = 23;

    fig(2) = figure('Color', 'w', 'Name', ' Pers.');
    ax = axes(fig(2));
    h = imagesc(ax, MAE_pers);
    set(h, 'AlphaData', double(Mask));
    set(ax, 'Color', 'w');
    axis(ax, 'image');
    set(ax, 'Visible', 'on', ...
    'Box', 'on', ...
    'LineWidth', 1.2, ...
    'XColor', 'k', 'YColor', 'k', ...
    'XTick', [], 'YTick', []);
    colormap(ax, parula);
    caxis(ax, colorLimits);
    cb.FontName = 'Times New Roman';
    cb.FontSize = 23;

    fig(3) = figure('Color', 'w', 'Name', ' Bar');
    ax = axes(fig(3));
    h = imagesc(ax, MAE_pers);
    set(h, 'AlphaData', double(Mask));
    set(ax, 'Color', 'w');
    axis(ax, 'image');
    set(ax, 'Visible', 'on', ...
    'Box', 'on', ...
    'LineWidth', 1.2, ...
    'XColor', 'k', 'YColor', 'k', ...
    'XTick', [], 'YTick', []);
    colormap(ax, parula);
    caxis(ax, colorLimits);
    cb = colorbar(ax, 'southoutside');
    cb.FontName = 'Times New Roman';
    cb.FontSize = 23;
end

function fig = plotNormalErrorNgo(NgoError, objName)
    fig = figure;
    E_orth = NgoError.error_Orth;
    E_pers = NgoError.error_Pers;
    Mask = isfinite(E_orth) & isfinite(E_pers);
    ax = subplot(2,1,1);
    h = imagesc(E_orth); set(h, 'AlphaData', Mask); set(ax, 'Color', 'w'); 
    axis equal; axis([0, 1224, 0, 1024]);  
    title(['Orth. ', objName]);
    colormap(ax, parula);  colorbar(ax); 
    ax = subplot(2,1,2);
    h = imagesc(E_pers); set(h, 'AlphaData', Mask); set(ax, 'Color', 'w'); 
    axis equal; axis([0, 1224, 0, 1024]);
    title(['Pers. ', objName]);
    colormap(ax, parula);  colorbar(ax); 
end

function fig = plotNormalNgo(Ngo, objName)
    N_orth = Ngo.N_Orth;
    N_pers = Ngo.N_Pers;
    N_desired = Ngo.N_Desired;
    Mask = Ngo.maskAll;
    fig = figure;
    subplot(3,1, 1);
    plot3DShape(fig, N_desired, Mask); % , false
    title(['Reference ', objName, '-L']);

    subplot(3,1,2);
    plot3DShape(fig, N_orth, Mask);
    title(['Orth. ', objName, '-L']);

    subplot(3,1,3);
    plot3DShape(fig, N_pers, Mask);
    title(['Pers. ', objName, '-L']);
end

function fig  = plotNormalError(data, objName)
    E_orth = data.error_Orth;
    E_pers = data.error_Pers;

    valid = isfinite(E_orth) & isfinite(E_pers);
    if isfield(data, 'Mask')
        valid = valid & logical(data.Mask);
    end

    E_orth(~valid) = NaN;
    E_pers(~valid) = NaN;

    % 沿第三维（光照）取平均，单位保持为度
    MAE_orth = mean(E_orth, 3, 'omitnan');
    MAE_pers = mean(E_pers, 3, 'omitnan');
    Mask = any(valid, 3);

    assert(any(Mask(:)), '没有有效误差数据。');

    % 两幅图使用相同色标
    maxError = max([MAE_orth(Mask); MAE_pers(Mask)]);
    colorLimits = [0, max(maxError, eps)];

    fig = figure('Color', 'w', 'Name', [char(objName), ' Orth.']);
    ax = axes(fig);
    h = imagesc(ax, MAE_orth);
    set(h, 'AlphaData', double(Mask));
    set(ax, 'Color', 'w');
    axis(ax, 'image');
    axis(ax, 'off');
    colormap(ax, parula);
    caxis(ax, colorLimits);
    cb = colorbar(ax);

    fig = figure('Color', 'w', 'Name', [char(objName), ' Pers.']);
    ax = axes(fig);
    h = imagesc(ax, MAE_pers);
    set(h, 'AlphaData', double(Mask));
    set(ax, 'Color', 'w');
    axis(ax, 'image');
    axis(ax, 'off');
    colormap(ax, parula);
    caxis(ax, colorLimits);
    cb = colorbar(ax);
end

% function fig = plotNormalError(data, objName)
%     fig = figure;
%     for lNum = 1 : 6
%         E_orth = data.error_Orth(:,:,lNum);
%         E_pers = data.error_Pers(:,:,lNum);
%         Mask = isfinite(E_orth) & isfinite(E_pers);
%         ax = subplot(2,6,lNum);
%         h = imagesc(E_orth); set(h, 'AlphaData', Mask); set(ax, 'Color', 'w'); 
%         axis equal; axis([0, 1224, 0, 1024]);
%         title(['Orth. ', objName, '-L', num2str(lNum)]);
%         colormap(ax, parula);  colorbar(ax); 
%         ax = subplot(2,6,lNum + 6);
%         h = imagesc(E_pers); set(h, 'AlphaData', Mask); set(ax, 'Color', 'w'); 
%         axis equal; axis([0, 1224, 0, 1024]);
%         title(['Pers. ', objName, '-L', num2str(lNum)]);
%         colormap(ax, parula);  colorbar(ax); 
%     end
% end

function fig = plotNormal(data, objName)
    fig = figure;
    for lNum = 1 : 6
        N_orth = data.N_Orth(:,:,:,lNum);
        N_pers = data.N_Pers(:,:,:,lNum);
        N_desired = data.N_Desired(:,:,:,lNum);
        Mask = data.maskAll(:,:,lNum);
        subplot(3,6, lNum);
        plot3DShape(fig, N_desired, Mask); % , false
        title(['Reference ', objName, '-L', num2str(lNum)]);

        subplot(3,6,lNum + 6);
        plot3DShape(fig, N_orth, Mask);
        title(['Orth. ', objName, '-L', num2str(lNum)]);

        subplot(3,6,lNum + 12);
        plot3DShape(fig, N_pers, Mask);
        title(['Pers. ', objName, '-L', num2str(lNum)]);
    end
end

function [Atkinson, Smith, Ngo, Beta] = getdata(dataDir)
    nameList = "P" + string(1:16);
    %% Atkinson
    for numObj = 1:numel(nameList)
        objName = char(nameList(numObj));
        fileName = fullfile(dataDir,  ['Data_ExperimentSphereDataset_OursVsAtkinson_mask_', objName, '.mat']);
        Atkinson.(objName) = load(fileName);
    end
    %% Smith
    for numObj = 1:numel(nameList)
        objName = char(nameList(numObj));
        fileName = fullfile(dataDir,  ['Data_ExperimentSphereDataset_OursVsSmith_mask_', objName, '.mat']);
        Smith.(objName) = load(fileName);
    end
    %% Smith
    for numObj = 1:numel(nameList)
        objName = char(nameList(numObj));
        fileName = fullfile(dataDir,  ['Data_ExperimentSphereDataset_OursVsNgo_mask_', objName, '.mat']);
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