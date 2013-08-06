function trainingSet=addStatsToTrainingSet(trainingSet,varargin)
%% ========================================================================
%   Name:       addStatsToTrainingSet.m
%   Version:    2.5, 25th Apr. 2013
%   Author:     Allison Wu
%   Command:    trainingSet=addStatsToTrainingSet(trainingSet)
%   Description:
%       - add new stats, such as delta stats, ratioSigmaXY and randStats to
%       an exisiting trainingSet.
%
%   Attribution: Wu, AC-Y and SA Rifkin. spotFinding Suite version 2.5, 2013 [journal citation TBA]
%   License: Creative Commons Attribution-ShareAlike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%   Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%   Email for comments, questions, bugs, requests:  Allison Wu < dblue0406 at gmail dot com >, Scott Rifkin < sarifkin at ucsd dot edu >
%
%% ========================================================================
% Adding the delta stats
deltaStats=calculateDeltaStats(trainingSet.stats.dataMat);

% Add the ratioSigmaXY
ratioSigmaXY=trainingSet.stats.sigmax./trainingSet.stats.sigmay;
I= ratioSigmaXY>1;
ratioSigmaXY(I)=trainingSet.stats.sigmay(I)./trainingSet.stats.sigmax(I);

% Add the randStats and percentiles of cumulative sum
[randStats,cumSumPrctiles]=calculateRandStats(trainingSet.stats.dataMat);

% Remove some stats
stats2Remove={'sigmax','sigmay','rawIntensity'};
for k=1:length(stats2Remove)
    I=strcmp(stats2Remove{k},trainingSet.statsUsed);
    trainingSet.dataMatrix.X(:,I)=[];
    trainingSet.statsUsed(I)=[];
    
end

stats2Add=[deltaStats ratioSigmaXY randStats cumSumPrctiles];
statsName={'absDeltaPlusSign','deltaPlusSign','absPlusSignDelta','plusSignPvalue',...
    'absDeltaStarSign','deltaStarSign','absStarSignDelta','starSignPvalue',...
    'absDeltaCenterBox','deltaCenterBox','absCenterBoxDelta','centerBoxPvalue',...
    'ratioSigmaXY','totalAreaRandPvalue','cumSumPrctile90RP','cumSumPrctile70RP','cumSumPrctile50RP','cumSumPrctile30RP',...
    'cumSumPrctile90','cumSumPrctile70','cumSumPrctile50','cumSumPrctile30'};
for k=1:length(statsName)
    trainingSet.stats.(statsName{k})=stats2Add(:,k);
    if sum(strcmp(statsName{k},trainingSet.statsUsed))==0
         trainingSet.statsUsed=[trainingSet.statsUsed;statsName(k)];
    end
    if isfield(trainingSet.stats,statsName{k})
        I=strcmp(statsName{k},trainingSet.statsUsed);
        trainingSet.dataMatrix.X(:,I)=stats2Add(:,k);
        
    else
        trainingSet.dataMatrix.X=[trainingSet.dataMatrix.X stats2Add(:,k)];
        
    end
    

    
end

trainingSet.version='ver. 2.5, new stats added';
if isempty(varargin)
    FileName=regexp(trainingSet.FileName,'\.','split');
    trainingSet.FileName=[FileName{1} '_v2p5.mat'];
   
end
save(trainingSet.FileName,'trainingSet')
end