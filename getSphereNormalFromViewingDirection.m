function [N_ref, C, Mask_valid, info] = ...
    getSphereNormalFromViewingDirection(V, Mask)
% 根据视线方向和完整球体轮廓计算参考法向量。
%
% 输入：
%   V          H×W×3，从表面指向相机的视线方向
%   Mask       H×W，单个完整、无遮挡的球体区域
%
% 输出：
%   N_ref      H×W×3，单位外法向量；无效位置为 NaN
%   C          3×1，以球半径为单位的球心坐标
%   Mask_valid H×W，Mask 内具有有效球面交点的位置
%   info       轮廓拟合诊断信息
%
% 要求：
%   1. 所有视线对应同一个相机光心。
%   2. V 与 Mask 使用相同的像素网格。
%   3. 球体轮廓完整，不接触图像边界。
%   4. V 在 Mask 及轮廓插值邻域内有效。
%
% 使用单位球 R=1，整体尺度不影响法向量。
% 需要 Image Processing Toolbox。

    %% 1. 检查输入
    validateattributes(V, {'numeric'}, {'real', 'nonempty'});

    assert(ismatrix(Mask) && all(isfinite(Mask(:))) && ...
        all(Mask(:) == 0 | Mask(:) == 1), ...
        'Mask 必须是二维二值数组。');

    Mask = logical(Mask);
    V = double(V);
    [h, w] = size(Mask);

    assert(ndims(V) == 3 && size(V,3) == 3 && ...
        size(V,1) == h && size(V,2) == w, ...
        'V 必须为 H×W×3，且与 Mask 尺寸一致。');

    assert(any(Mask(:)), 'Mask 不能为空。');

    assert(~any(Mask(1,:)) && ~any(Mask(end,:)) && ...
           ~any(Mask(:,1)) && ~any(Mask(:,end)), ...
        '球体轮廓不能接触图像边界。');

    CC = bwconncomp(Mask);
    assert(CC.NumObjects == 1, ...
        'Mask 应仅包含一个球体。');

    %% 2. 归一化视线
    viewLength = sqrt(sum(V.^2, 3));
    validView = all(isfinite(V), 3) & ...
                isfinite(viewLength) & viewLength > 0;

    assert(all(validView(Mask)), ...
        'Mask 内的视线必须有限且非零。');

    viewLength(~validView) = NaN;
    V = V ./ viewLength;

    %% 3. 提取 Mask 的亚像素外轮廓
    contourData = contourc(double(Mask), [0.5, 0.5]);

    boundary = [];
    k = 1;

    while k < size(contourData, 2)
        count = round(contourData(2,k));
        points = contourData(:, k+1:k+count);

        % 最长轮廓作为外轮廓
        if size(points,2) > size(boundary,2)
            boundary = points;
        end

        k = k + count + 1;
    end

    assert(size(boundary,2) >= 6, ...
        '有效轮廓点不足。');

    % 删除重复的闭合端点
    if norm(boundary(:,1) - boundary(:,end)) < 1e-10
        boundary(:,end) = [];
    end

    uBoundary = boundary(1,:).';
    vBoundary = boundary(2,:).';

    %% 4. 插值轮廓视线，转换为相机指向场景的射线
    boundaryRays = zeros(numel(uBoundary), 3);

    for component = 1:3
        boundaryRays(:,component) = -interp2( ...
            V(:,:,component), ...
            uBoundary, vBoundary, 'linear');
    end

    rayLength = sqrt(sum(boundaryRays.^2, 2));

    assert(all(isfinite(boundaryRays(:))) && ...
           all(isfinite(rayLength) & rayLength > 0), ...
        ['轮廓插值失败：V 在 Mask 外的邻近像素也必须有效。' ...
         '建议生成整幅图像的视线方向。']);

    boundaryRays = boundaryRays ./ rayLength;

    %% 5. 拟合球体切锥
    % 轮廓射线满足：
    % boundaryRays * axisDir = cos(alpha)
    meanRay = mean(boundaryRays, 1);
    centeredRays = boundaryRays - meanRay;

    [~, S, W] = svd(centeredRays, 0);

    assert(S(2,2) > 1e-10, ...
        '轮廓射线退化，无法确定球心。');

    axisDir = W(:,end);

    % 轴线朝向球体
    if dot(axisDir, meanRay.') < 0
        axisDir = -axisDir;
    end

    cosAlpha = mean(boundaryRays * axisDir);

    assert(cosAlpha > 0 && cosAlpha < 1, ...
        '切锥拟合无效，请检查 V 和 Mask。');

    % 单位球：R=1
    sinAlpha = sqrt(1 - cosAlpha^2);
    distance = 1 / sinAlpha;
    C = distance * axisDir;

    %% 6. 获取 Mask 内的射线
    pixelList = find(Mask);

    V_flat = reshape(V, [], 3);
    rays = -V_flat(pixelList,:);       % 每行一个单位射线

    %% 7. 射线与单位球求交
    % ||t*r - C||^2 = 1
    b = rays * C;
    discriminant = b.^2 - (dot(C,C) - 1);

    % 仅容忍浮点舍入误差
    tolerance = 100 * eps(max(dot(C,C), 1));

    good = isfinite(discriminant) & ...
           discriminant >= -tolerance & b > 0;

    t = NaN(size(b));
    t(good) = b(good) - sqrt(max(discriminant(good), 0));
    good = good & isfinite(t) & t > 0;

    %% 8. 计算球面外法向量
    P = rays(good,:) .* t(good);

    % R=1，因此 n=(P-C)/R=P-C
    normals = P - C.';
    normals = normals ./ sqrt(sum(normals.^2, 2));

    N_flat = NaN(h*w, 3);
    N_flat(pixelList(good),:) = normals;
    N_ref = reshape(N_flat, h, w, 3);

    Mask_valid = false(h,w);
    Mask_valid(pixelList(good)) = true;

    %% 9. 诊断信息
    alpha = acos(cosAlpha);
    boundaryAngles = acos(max(-1, min(1, ...
        boundaryRays * axisDir)));

    info.distanceInRadii = distance;
    info.axisDirection = axisDir;
    info.coneHalfAngleDeg = rad2deg(alpha);
    info.boundaryAngularRMSEDeg = rad2deg( ...
        sqrt(mean((boundaryAngles - alpha).^2)));
    info.validFraction = nnz(Mask_valid) / nnz(Mask);
    info.numBoundaryPoints = size(boundaryRays,1);
    info.numInvalidIntersections = nnz(Mask) - nnz(Mask_valid);
end