p = path;
path(p, '../AroSpotFindingSuite');
p = path;
path(p, '../AroSpotFindingSuite/saveastiff_2.2');
p = path;
path(path, '../AroSpotFindingSuite/mpiv_toolbox');
run('Aro_parameters.m');
doEvalFISHStacksForALL;
load([TrainingSetsDir '*RF.mat'])
classifySpotsOnDirectory
collect_stats()
