%% Transfer imageGrayRaw to I0 I45 I90 I135
% 90  45
% 135 0
function PolarImage = imageGrayRawToPolarImage(imageGray)
    PolarImage.I90  = double(imageGray(1:2:end, 1:2:end)); 
    PolarImage.I45  = double(imageGray(1:2:end, 2:2:end)); 
    PolarImage.I135 = double(imageGray(2:2:end, 1:2:end)); 
    PolarImage.I0   = double(imageGray(2:2:end, 2:2:end));
end