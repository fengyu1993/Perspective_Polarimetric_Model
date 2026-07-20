%% plot 3D Normal RGB
function plot3DShape(fig, N, Mask)
    Nx = N(:,:,1);
    Ny = N(:,:,2);
    Nz = N(:,:,3);
    R = (Nx + 1) / 2;
    G = (Ny + 1) / 2;
    B = (Nz + 1) / 2; 
    Normal_RGB = cat(3, R, G, B);
    Mask_3D = repmat(Mask, [1, 1, 3]); 
    Normal_RGB(~Mask_3D) = NaN;
    figure(fig);
    imshow(Normal_RGB);
end