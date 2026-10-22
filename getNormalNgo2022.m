function [N_Ngo, eta_Ngo] = getNormalNgo2022(objData)
    Mask = objData(1).mask;
    [rows, cols] = size(Mask);
    pages = length(objData);
    [rowList, colList] = find(Mask);
    pixelList = find(Mask);
    numPixels = numel(pixelList);
    %% Prepare data
    [iList, lList] = getData(objData, rowList, colList, pages);
    %% Initialization
    [N_init, eta_init, cfg] = getInit(iList, lList);
    xInit = [acos(max(-1, min(1, N_init(:,3)))), atan2(N_init(:,2), N_init(:,1)), eta_init];
    %% Allocate outputs
    N_list = NaN(numPixels, 3);
    eta_list = NaN(numPixels, 1);
    %% Optimize each pixel
    for num = 1 : numPixels
        x0 = xInit(num,:).';
        I = iList(:,:,num);  
        % 构建与优化变量无关的数据，例如观测配对和权重
        c = preparePixelData(I, lList, cfg);
        % 总残差函数：输入 [theta; phi; eta]
        residualFun = @(x) getTotalResidual(x, c, cfg);
        % 非线性优化
        xOpt = optimizePixel(residualFun, x0);
        % 将优化后的角度转换为单位法向量
        theta = xOpt(1); phi   = xOpt(2);
        N_list(num,:) = [sin(theta)*cos(phi), sin(theta)*sin(phi), cos(theta)];
        eta_list(num) = xOpt(3);
    end
    %% Restore image-shaped outputs
    N_flat = NaN(rows*cols, 3);
    N_flat(pixelList,:) = N_list;
    N_Ngo = reshape(N_flat, rows, cols, 3);
    eta_Ngo = NaN(rows, cols);
    eta_Ngo(pixelList) = eta_list;
end

%%
function c = preparePixelData(I, L, cfg)
    c.L = L;
    c.I = I;
    c.angles = [0; pi/4; pi/2; 3*pi/4];
    c.o = [0; 0; 1];
    c.alpha = double(all(I >= cfg.darkThreshold, 2));
    c.lightIds = find(c.alpha > 0);
    if numel(c.lightIds) >= 2
        c.lightPairs = nchoosek(c.lightIds, 2);
    else
        c.lightPairs = zeros(0, 2);
    end
    c.anglePairs = nchoosek(1:4, 2);
end

function r = getTotalResidual(x, c, cfg)

    % 光度立体约束
    r_s = getShadingResidual(x, c);

    % 偏振约束
    r_p = getPolarizationResidual(x, c);

    % 附加约束或惩罚项
    r_c = getConstraintResidual(x, c, cfg.kn);

    r = [sqrt(cfg.ws)     * r_s(:); ...
         sqrt(1-cfg.ws)   * r_p(:); ...
         sqrt(cfg.lambda) * r_c(:)];
end

function r_s = getShadingResidual(x, c)
    li = c.lightPairs(:,1); lj = c.lightPairs(:,2); 
    I1 = c.I(li,:);         I2 = c.I(lj,:);
    normS1 = hypot(I1, I2);
    %%
    theta = x(1); phi = x(2); eta = x(3);
    n = [sin(theta)*cos(phi); sin(theta)*sin(phi); cos(theta)];
    lightIds = unique([li; lj]);
    %%
    cosThetaI = c.L(lightIds,:) * n;
    cosThetaI = max(-1, min(1, cosThetaI));
    thetaI = acos(cosThetaI);
    sinThetaT = sin(thetaI) ./ eta;
    cosThetaT = sqrt(1 - sinThetaT.^2);
    r_perp = (cosThetaI - eta*cosThetaT) ./ (cosThetaI + eta*cosThetaT);
    r_para = (eta*cosThetaI - cosThetaT) ./ (eta*cosThetaI + cosThetaT);
    F = r_perp.^2 + r_para.^2;
    %%
    t = NaN(size(c.L,1), 1);
    t(lightIds) = (1 - F) .* cosThetaI;
    t1 = t(li); t2 = t(lj); 
    normS2 = hypot(t1, t2);
    %%
    cosAngle = (I1 .* t1 + I2 .* t2) ./ (normS1 .* normS2);
    cosAngle = max(-1, min(1, cosAngle));
    r_s = acos(cosAngle(:));
end

function r_p = getPolarizationResidual(x, c)
    ai = c.anglePairs(:,1);     aj = c.anglePairs(:,2);
    I1 = c.I(c.lightIds, ai);   I2 = c.I(c.lightIds, aj);
    normP1 = hypot(I1, I2);
    %%
    theta = x(1); phi = x(2); eta = x(3);
    sin2Theta = sin(theta)^2;
    numerator = (eta - 1/eta)^2 * sin2Theta;
    denominator = 2 + 2*eta^2 - (eta + 1/eta)^2 * sin2Theta + 4*cos(theta)*sqrt(eta^2 - sin2Theta);
    rho = numerator / denominator;
    %%
    p = 1 + rho*cos(2*c.angles - 2*phi);
    p1 = p(ai).'; p2 = p(aj).';
    normP2 = hypot(p1, p2);
    %%
    cosAngle = (I1.*p1 + I2.*p2) ./ (normP1.*normP2);
    cosAngle = max(-1, min(1, cosAngle));
    r_p = acos(cosAngle(:));
end

function r_c = getConstraintResidual(x, c, kn)
    theta = x(1);   phi = x(2);
    n = [sin(theta)*cos(phi); sin(theta)*sin(phi); cos(theta)];
    cosView = n.' * c.o(:); cosView = max(-1, min(1, cosView));
    g = (1 - cosView) / (1 + exp(kn*cosView));
    r_c = sqrt(g);
end

function [xOpt, info] = optimizePixel(residualFun, x0)
    x0 = x0(:);
    %% Solver options
    options = optimoptions('lsqnonlin', ...
            'Display', 'off', ...
            'MaxIterations', 200, ...
            'MaxFunctionEvaluations', 2000, ...
            'FunctionTolerance', 1e-8, ...
            'StepTolerance', 1e-8, ...
            'FiniteDifferenceType', 'forward');
    options.Algorithm = 'levenberg-marquardt';
    %% Unconstrained L-M optimization
    [xOpt, resnorm, residual, exitflag, output] = lsqnonlin(residualFun, x0, [], [], options);
    info.resnorm  = resnorm;       % 最终残差平方和
    info.residual = residual;      % 最终残差向量
    info.exitflag = exitflag;      % 停止原因
    info.output   = output;        % 迭代次数、停止信息等
end

function [iList, lList] = getData(objData, rowList, colList, pages)
    iList = NaN(pages, 4, length(rowList));
    lList = NaN(pages, 3);
    for page = 1 : pages
        lList(page,:) = objData(page).lightDirection;
        E = double(objData(page).intensity);
        for num = 1 : length(rowList)
            row = rowList(num);
            col = colList(num);
            iList(page,:, num) = [objData(page).polarImage.I0(row, col), objData(page).polarImage.I45(row, col), objData(page).polarImage.I90(row, col), objData(page).polarImage.I135(row, col)];                   
        end
        iList(page,:, :) = iList(page,:, :) ./ E;
    end
end

function [N, eta, cfg] = getInit(iList, lList)
    cfg.ws = 0.5; cfg.kn = 100; cfg.lambda = 1;  cfg.darkThreshold = 0.01;
    N = NaN(size(iList, 3), 3);
    eta = NaN(size(iList, 3), 1);
    LInv = pinv(lList);
    for num = 1 : size(iList, 3)
        eta(num,1) = 1;
        i = iList(:,:,num);
        iMean = mean(i, 2);
        g = LInv * iMean;
        gLength = norm(g);
        if ~isfinite(gLength) || gLength == 0
            continue;
        end
        N(num, :) = (g / gLength).';
    end

end














