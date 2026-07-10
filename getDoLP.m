%% Get DoLP
function Rho = getDoLP(PolarImage, Mask)
    Rho = zeros(size(Mask));
    Num = 2*sqrt((PolarImage.I0(Mask) - PolarImage.I90(Mask)).^2 + (PolarImage.I45(Mask) - PolarImage.I135(Mask)).^2);
    Den = PolarImage.I0(Mask) + PolarImage.I45(Mask) + PolarImage.I90(Mask) + PolarImage.I135(Mask) + eps;
    Rho_raw = Num ./ Den;
    Rho(Mask) = min(max(Rho_raw, 0), 1);
end 