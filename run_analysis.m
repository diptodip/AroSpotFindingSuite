function [] = autoMask(filename, output)

run('Aro_parameters.m');

auto_trim_mask_directory();
doEvalFISHStacksForALL;
load([TrainingSetsDir '*RF.mat'])
classifySpotsOnDirectory
collect_stats()
