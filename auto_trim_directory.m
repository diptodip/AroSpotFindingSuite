function [] = auto_trim_directory()
tif_files = dir('*.tif');

for i = 1:size(tif_files)
    auto_trim(tif_files(i).name, strcat('trim/',tif_files(i).name));
end
clear;
return;