%% Our Sphere Dataset
clc;
% clear; 
close all;
%% Data
% [Atkinson, Smith, Ngo, Beta] = getdata(".\Data");
%% Error
% AtkinsonError = getError(Atkinson);
% SmithError = getError(Smith);
% NgoError = getErrorNgo(Ngo);
%% Normal all plot
figRef = plotAllDesiredNormal(Atkinson);
figAtkinson_ = plotAllNormalError(AtkinsonError);
figSmith_ = plotAllNormalError(SmithError);
figNgo_ = plotAllNormalError(NgoError);
%% Normal plot
nameList = "P" + string(1:16);
for numObj = 1 : 16
    objName = char(nameList(numObj));
    %% Atkinson
%     fig = plotNormal(Atkinson.(objName), objName);
%     fig = plotNormalError(AtkinsonError.(objName), objName);
    %% Smith
%     fig = plotNormal(Smith.(objName), objName);
%     fig = plotNormalError(SmithError.(objName), objName);    
    %% Ngo
%     fig = plotNormalNgo(Ngo.(objName), objName);
%     fig = plotNormalErrorNgo(NgoError.(objName), objName);    
end
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
end

function fig = plotAllNormalError(Error, flag)
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

    fig = figure('Color', 'w', 'Name', ' Orth.');
    ax = axes(fig);
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

    fig = figure('Color', 'w', 'Name', ' Pers.');
    ax = axes(fig);
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

    fig = figure('Color', 'w', 'Name', ' Bar');
    ax = axes(fig);
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
    cb = colorbar(ax);
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