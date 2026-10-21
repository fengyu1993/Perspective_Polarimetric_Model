function [N_Ngo, eta_Ngo] = getNormalNgo2022(objData)
    Mask = objData(1).mask;
    [rows, cols] = size(Mask);
    pages = length(objData);
    [rowList, colList] = find(Mask == 1);
    %% Prepare data
    [iList, lList] = getData(objData, rowList, colList, pages);
    %% Initialization
    [N, eta, cfg] = getInit(iList, lList);

        %% Total error
%         getTotalErrorPixel(iList, lList, )
        %% SHADING STEREOSCOPIC CONSTRAINT

end


function [iList, lList] = getData(objData, rowList, colList, pages)
    iList = NaN(pages, 4, length(rowList));
    lList = NaN(pages, 3);
    for page = 1 : pages
        lList(page,:) = objData(page).lightDirection;
        for num = 1 : length(rowList)
            row = rowList(num);
            col = colList(num);
            iList(page,:, num) = [objData(page).polarImage.I0(row, col), objData(page).polarImage.I45(row, col), objData(page).polarImage.I90(row, col), objData(page).polarImage.I135(row, col)];                   
        end
    end
end

function [N, eta, cfg] = getInit(iList, lList)
    cfg.ws = 0.5; cfg.kn = 100; cfg.lambda = 1;  cfg.darkFraction = 0.01;
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














