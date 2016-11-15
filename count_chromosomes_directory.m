function [] = count_chromosomes_directory()
run('Aro_parameters.m');

dye = dyesUsed{1};
if ~exist([ImageDir filesep dye], 'dir')
    disp('[ERROR] The images have not been trimmed/placed in the proper folders! Please trim first.');
    return;
end
current_files = dir([RawImageDir filesep '*.tif']);
tif_files = {current_files.name};
disp(tif_files);

mask_files = dir([SegmentationMaskDir filesep 'Mask*.tif']);
mask_files = {mask_files.name};
disp(mask_files);

masks_exist = (numel(mask_files) == numel(tif_files));

if isempty(tif_files)
    disp('[ERROR] There appear to be no images in the directory for this dye! Please check your image files.');
    return;
else

    for i = 1:numel(tif_files)
        name = tif_files{i};
        if masks_exist
            mask_name = [SegmentationMaskDir filesep mask_files{i}];
        else
            mask_name = '0';
        end
        count = count_chromosomes([RawImageDir filesep name], mask_name);
        fileID = fopen(ChromosomeFile, 'a');
        fprintf(fileID, [name ', ' num2str(count) '\n']);
        fclose(fileID);
    end
end
clear;
return;
