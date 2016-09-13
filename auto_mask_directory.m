function [] = auto_mask_directory()
tif_files = dir('*.tif');

for i = 1:size(tif_files)
    auto_mask(tif_files(i).name, strcat('mask/',tif_files(i).name));
end
clear;
return;