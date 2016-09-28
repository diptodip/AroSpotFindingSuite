function [] = auto_trim_mask_directory()
run('Aro_parameters.m');

auto_trim_directory();
auto_mask_directory();

current_files = dir([SegmentationMaskDir filesep '*.tif']);
tif_files = {current_files.name};
disp(tif_files);

for i = 1:numel(tif_files)
    name = tif_files{i};
    createSegmenttrans([SegmentationMaskDir filesep name]);
end

createSegImages('tif');