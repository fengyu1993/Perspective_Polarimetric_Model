%% Transfer PolarImageRGB to PolarImageGray I0 I45 I90 I135
function polarImageGray = polarImageRGBToPolarImageGray(PolarImageRGB)
    num_imgs = length(PolarImageRGB);
    polarImageGray = repmat(struct('I0', [], 'I45', [], 'I90', [], 'I135', []), num_imgs, 1);
    for i = 1 : num_imgs
        polarImageGray(i).I0 = double(rgb2gray(PolarImageRGB(i).I0));
        polarImageGray(i).I45 = double(rgb2gray(PolarImageRGB(i).I45));
        polarImageGray(i).I90 = double(rgb2gray(PolarImageRGB(i).I90));
        polarImageGray(i).I135 = double(rgb2gray(PolarImageRGB(i).I135));
    end  
end