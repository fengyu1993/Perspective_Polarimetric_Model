%% Transfer imageData to PolarImage I0 I45 I90 I135
function polarImageRGB = imageDataToPolarImageRGB(folderPath, data)
    num_scenes = length(data.nameList);
    num_polars = length(data.nameImagePolar);
    polarImageRGB = repmat(struct('I0', [], 'I45', [], 'I90', [], 'I135', []), num_scenes, 1);

    for i = 1 : num_scenes
        for j = 1 : num_polars
            name = strcat(data.nameList{i}, data.nameImagePolar{j}, '.png');
            temp_img = imread(fullfile(folderPath, name));
            switch data.nameImagePolar{j}
                case 'I0'
                    polarImageRGB(i).I0 = temp_img;
                case 'I45'
                    polarImageRGB(i).I45 = temp_img;
                case 'I90'
                    polarImageRGB(i).I90 = temp_img;
                case 'I135'
                    polarImageRGB(i).I135 = temp_img; 
            end 
        end
    end    
end