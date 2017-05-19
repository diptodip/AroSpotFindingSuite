function [] = produce_mask_thumbnails()
run('Aro_parameters.m');

dye = dyesUsed{1};
if ~exist([ImageDir filesep dye], 'dir')
    disp('[ERROR] The images have not been trimmed/placed in the proper folders! Please trim first.');
    return;
end

current_files = dir([SegmentationMaskDir filesep '*.tif']);
tif_files = {current_files.name};
tif_files = natsortfiles(tif_files);

num_thumbs = round(numel(tif_files)/20);
if num_thumbs < 1
    num_thumbs = 1;
end



for i = 1:num_thumbs;
    image = zeros(400, 500, 1);
    for j = 0:3
        for k = 0:4
            if ((k + 1) +  5 * (j)) <= numel(tif_files)
                disp(['[producing thumbnail] ' tif_files{(k + 1) + 5*j}]);
                original = imread([SegmentationMaskDir filesep tif_files{(k + 1) + 5*j}]);
                thumb = imresize(original, [100, 100]);
                start_x = j * 100 + 1;
                end_x = start_x + 99;
                start_y = k * 100 + 1;
                end_y = start_y + 99;
                image(start_x:end_x, start_y:end_y, 1) = thumb(:,:);
            end
        end
    end
    imwrite(image, [SegmentationMaskDir filesep 'thumbnails' num2str(i) '.bmp']);
end
clear;
return;
