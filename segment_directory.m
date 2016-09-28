function [] = segment_directory()

run('Aro_parameters.m');

current_files = dir([SegmentationMaskDir filesep '*.tif']);
tif_files = {current_files.name};

for i = 1:numel(tif_files)
    name = tif_files{i};
    pieces = strsplit(name, '_');
    number = pieces{2};
    createSegmenttrans(number);
end