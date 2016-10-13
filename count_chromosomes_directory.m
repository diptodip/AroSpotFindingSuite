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

if isempty(tif_files)
    disp('[ERROR] There appear to be no images in the directory for this dye! Please check your image files.');
    return;
end

ParSegmentationMaskDir = [SegmentationMaskDir];
ParRawImageDir = [RawImageDir];
ParChromosomeFile = [ChromosomeFile];

for i = 1:numel(tif_files)
    name = tif_files{i};
    SegmentationMaskDir = ParSegmentationMaskDir;
    RawImageDir = ParRawImageDir;
    ChromosomeFile = ParChromosomeFile;
    dye_name_length = 3;
    mask_name = strcat('Mask_', name(dye_name_length+1:length(name)-4), '_1.tif');
    mask_full_name [SegmentationMaskDir filesep mask_name];
    count = count_chromosomes([RawImageDir filesep name], [SegmentationMaskDir filesep mask_name]);
    fileID = fopen(ChromosomeFile, 'a');
    fprintf(fileID, [name(dye_name_length+1:length(name)-4) ', ' num2str(count) '\n']);
    fclose(fileID);
end
clear;
return;
