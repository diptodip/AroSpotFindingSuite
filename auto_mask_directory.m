function [] = auto_mask_directory()
run('Aro_parameters.m');

dye = dyesUsed{1};
if ~exist([ImageDir filesep dye], 'dir')
    disp('[ERROR] The images have not been trimmed/placed in the proper folders! Please trim first.');
    return;
end
current_files = dir([ImageDir filesep dye filesep '*.tif']);
tif_files = {current_files.name};
disp(tif_files);

if isempty(tif_files)
    disp('[ERROR] There appear to be no images in the directory for this dye! Please check your image files.');
    return;
end

ParSegmentationMaskDir = [SegmentationMaskDir];
ParImageDir = [ImageDir];
PardyesUsed = dyesUsed;
ParBadMaskList = [BadMaskList];

parfor i = 1:numel(tif_files)
    name = tif_files{i};
    SegmentationMaskDir = ParSegmentationMaskDir;
    ImageDir = ParImageDir;
    dyesUsed = PardyesUsed;
    BadMaskList = ParBadMaskList;
    dye = '';
    for d = 1:length(dyesUsed)
        k = strfind(name, dyesUsed{d});
        if ~isempty(k)
            dye = dyesUsed{d};
            d = length(dyesUsed);
        end
    end
    dye_name_length = length(dye);
    mask_name = strcat('Mask_', name(dye_name_length+1:length(name)-4), '_1.tif');
    isbad = auto_mask([ImageDir filesep dye filesep name], [SegmentationMaskDir filesep mask_name]);
    if isbad
        fileID = fopen(BadMaskList, 'a');
        fprintf(fileID, [mask_name '\n']);
        fclose(fileID);
        disp(['[WARNING] Possible bad mask produced at ' mask_name]);
    end
end
clear;
return;