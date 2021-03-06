%% ============================================================
%   Name:       Aro_parameters.m
%   Version:    2.5.1, 9 Feb 2015
%   Author:     Allison Wu, Scott Rifkin
%   Command: loadParametersForAroSpotFindingSuite
%   Description: The software is relatively parameter free, but does depend on a few.
%                These have now been moved into this script file which should be
%                placed on the MATLAB path - either with the other software
%                files or (and perhaps better) in the data directory from
%                where the software is run so that if changed they can be
%                specifically linked to a set of data.  They are listed
%                below with their default values and under headings of
%                which functions use them.  Each file only reads in the
%                ones it needs based on the value of callingFunction which
%                is set in the calling function and is the function's name
%				 
%				NestedDirectoryStructure
%					tells all functions where to find things
%					assumes that you are running it from the top directory
%					images are in ImageData by dye
%					Analysis in analysis folder
%
%
%	NOTE: This is a template file.  Copy this file into the top directory where
%			the functions will be run from.  Adjust anything that needs adjusting.
%			Name it Aro_parameters.m


%%%%%%%%%%%%%%%%% directory structure %%%%%%%%%%%%%%%%%

% Is the directory file structure flat or nested?  If flat, then everything is in the same directory (the file list gets big)
nestedOrFlatDirectoryStructure = 'nested';  % 'flat' is the other option
% ALWAYS USE NESTED

% What are the dyes that are being used?  This should be a cell array. These will
% be the directory names where the images are and also the names of directories under spotStats, segStacks, wormGaussianFit, etc.
dyesUsed={'par'};
isdapi=''; %or '' if no dapi

if strcmp(nestedOrFlatDirectoryStructure,'nested')
topdir=pwd;
ImageDir='ImageData';
RawImageDir=[ImageDir filesep 'TIFF'];

SegmentationMaskDir= 'SegmentationMasks';
if ~exist(SegmentationMaskDir,'dir')
	mkdir(SegmentationMaskDir);
end;
BadMaskList = [SegmentationMaskDir filesep 'possibly_bad.csv'];


AnalysisDir= 'Analysis';
if ~exist(AnalysisDir,'dir')
	mkdir(AnalysisDir);
end;

PlotDir=[AnalysisDir filesep 'Plots'];
if ~exist(PlotDir,'dir')
	mkdir(PlotDir);
end;

WormGaussianFitDir=[AnalysisDir filesep 'WormGaussianFit'];
if ~exist(WormGaussianFitDir,'dir')
	mkdir(WormGaussianFitDir);
	for i=1:length(dyesUsed)
		mkdir([WormGaussianFitDir filesep dyesUsed{i}]);
	end;
end;

SpotStatsDir=[AnalysisDir filesep 'SpotStats'];
if ~exist(SpotStatsDir,'dir')
	mkdir(SpotStatsDir);
	for i=1:length(dyesUsed)
		mkdir([SpotStatsDir filesep dyesUsed{i}]);
	end;
end;

SegStacksDir=[AnalysisDir filesep 'SegStacks'];
if ~exist(SegStacksDir,'dir')
	mkdir(SegStacksDir);
	for i=1:length(dyesUsed)
		mkdir([SegStacksDir filesep dyesUsed{i}]);
	end;
	if ~isempty(isdapi)
		mkdir([SegStacksDir filesep isdapi]);
	end;
end;

TrainingSetDir=[AnalysisDir filesep 'TrainingSets'];
if ~exist(TrainingSetDir,'dir')
	mkdir(TrainingSetDir);
end;
else
topdir=''; %want relative paths without extra cruff
ImageDir=topdir;
WormGaussianFitDir=topdir;
SpotStatsDir=topdir;
SegStacksDir=topdir;
SegmentationMaskDir=topdir;
TrainingSetDir=topdir;
PlotDir=topdir;
end;



%%%%%%%%%%%%%%%%%%%%%  parameters %%%%%%%%%%%%%%

ST = dbstack(2); %Aro_parameters is called from the calling function by run(fullfile(pwd,'Aro_parameters.m'))
callingFunction=ST(1).name;
disp([callingFunction ': Reading Aro_parameters file in ' pwd '/']);

switch callingFunction
    case 'trainRFClassifier'
        % # of trees in the forest
        ntrees=1000;  % Should be relatively large
        % Fraction of input data to sample with replacement from the input data for growing each new tree. Default value is 1.
        % This is a parameter to pass into TreeBagger
        FBoot=1;  %(0 < Fboot <=1]
        % Whether or not to do a pre-run to choose the best
        % variables/statistics/features for building the tree
        runVarFeatureSel=1;  % 0 or 1
        % TreeBagger determines which variables are important
        % by: A numeric array of size 1-by-Nvars containing a measure of
        % importance for each predictor variable (feature). For any
        % variable, the measure is the increase in prediction error if the
        % values of that variable are permuted across the out-of-bag
        % observations. This measure is computed for every tree, then
        % averaged over the entire ensemble and divided by the standard
        % deviation over the entire ensemble.
        % What percentile threshold should be used to determine which
        % variables have predictive power (>) and which do not (<)
        percentileThresholdForOOBPermutedVarDeltaError=25;  %(0 < <=1]
        %How many trees to use when looking for the optimum number of
        %features to samples?
        nTreeTry=500;  % < ntrees
        % Continue optimizing if the improvement is greater than improve
        improve=0.01;  % a small value
        % How many more variables to try in each optimizing run?
        stepFactor=1;  %1 or more
        %%%%%%%%
        % What should the confidence interval width be?
        intervalWidth=95;   % (0 < < 100] 
        
    case 'classifySpots'
        % What should the confidence interval width be?
        intervalWidth=95;% (0 < < 100] 
        
    case 'evalFISHStacks'
        % This function builds the list of regional maxima in an image
        % stack to even consider
        % it goes through the regional maxima which are sorted by
        % background corrected intensity (by morphFilterSpotImage3D) and
        % decides when the actual spots are long gone
        %
        %%%%%%%%%%
        %What statistic should be used to evaluate whether to keep a local
        %maximum in the running?
        cutoffStat='scd';  %see calculateFISHStatistics for other options
        % what is the minimum cutoff value for this statistic below which
        % it really should not be considered?
        cutoffStatisticValue=0.7;  %depends on the statistic, usually (0 < <=1)
        % How many recent local maxima should be considered?
        stopN=30;
        %What percentile of these have to be over the cutoff to keep going?
        cutoffPercentile=70; % (0 < < 100]
        % If the slice is bad, then lots of spots in a row will be crappy.
        % This usually appears quickly and so there is no need to run
        % through stopN spots before moving on...
        badSliceStopN=5; %how many spots to consider if there get to be a string of bad ones.  this would be less than stopN
        % what is the cutoff value of the statistic to say that the spot
        % definitely is bad
        badSliceCutoffStatisticValue=0.3;
    case 'makeSpotCountInterval'
        %bootstrap repetitions for the interval
        nBoots=1000; %should be a large number
    otherwise
end;



