function [] = auto_trim_directory()
run('Aro_parameters.m');

current_files = dir(strcat(RawImageDir, filesep, '*.tif'));
tif_files = {current_files.name};

% make dye subfolders in ImageData folder if they don't already exist
for d = 1:length(dyesUsed)
    if ~exist([ImageDir filesep dyesUsed{d}], 'dir')
        mkdir([ImageDir filesep dyesUsed{d}]);
    end
end

ParRawImageDir = [RawImageDir];
ParImageDir = [ImageDir];
PardyesUsed = dyesUsed;

parfor i = 1:numel(tif_files)
    name = tif_files{i};
    RawImageDir = ParRawImageDir;
    ImageDir = ParImageDir;
    dyesUsed = PardyesUsed;
    dye = dyesUsed{1};
    number_extension = strsplit(name, '-');
    number = strsplit(number_extension{2}, '.');
    number = number{1};
    output_name = [dye number '.tif'];
    disp(strcat(RawImageDir, filesep, name));
    disp(strcat(ImageDir, filesep, dye, filesep, name));
    auto_trim(strcat(RawImageDir, filesep, name), strcat(ImageDir, filesep, dye, filesep, output_name));
end
clear;
return;