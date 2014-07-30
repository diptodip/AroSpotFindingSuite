function worms=addStatsToWormGaussian(worms)
%% ========================================================================
%   Name:       addStatsToWormGaussian.m
%   Version:    2.5, 25th Apr. 2013
%   Author:     Allison Wu
%   Command:    worms=addStatsToWormGaussian(worms)
%   Description:
%       - add new stats, such as delta stats, ratioSigmaXY and randStats to
%       an exisiting worms structure from wormGaussianFit.mat
<<<<<<< HEAD
%
%   Attribution: Wu, AC-Y and SA Rifkin. spotFinding Suite version 2.5, 2013 [journal citation TBA]
%   License: Creative Commons Attribution-ShareAlike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%   Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%   Email for comments, questions, bugs, requests:  Allison Wu < dblue0406 at gmail dot com >, Scott Rifkin < sarifkin at ucsd dot edu >
%
%% ========================================================================
for j=1:length(worms)
% Adding the delta stats
=======
%% ========================================================================
for j=1:length(worms)
% Adding the delta stats
if ~isempty(worms{j}.spotDataVectors)
>>>>>>> spotFindingSuite_v2.5.1
deltaStats=calculateDeltaStats(worms{j}.spotDataVectors.dataMat);

% Add the ratioSigmaXY
ratioSigmaXY=worms{j}.spotDataVectors.sigmax./worms{j}.spotDataVectors.sigmay;
I= ratioSigmaXY>1;
ratioSigmaXY(I)=worms{j}.spotDataVectors.sigmay(I)./worms{j}.spotDataVectors.sigmax(I);

% Add the randStats and percentiles of cumulative sum
[randStats,cumSumPrctiles]=calculateRandStats(worms{j}.spotDataVectors.dataMat);



stats2Add=[deltaStats ratioSigmaXY randStats cumSumPrctiles];
statsName={'absDeltaPlusSign','deltaPlusSign','absPlusSignDelta','plusSignPvalue',...
    'absDeltaStarSign','deltaStarSign','absStarSignDelta','starSignPvalue',...
    'absDeltaCenterBox','deltaCenterBox','absCenterBoxDelta','centerBoxPvalue',...
    'ratioSigmaXY','totalAreaRandPvalue','cumSumPrctile90RP','cumSumPrctile70RP','cumSumPrctile50RP','cumSumPrctile30RP',...
    'cumSumPrctile90','cumSumPrctile70','cumSumPrctile50','cumSumPrctile30'};


for k=1:length(statsName)
    worms{j}.spotDataVectors.(statsName{k})=stats2Add(:,k);
end

worms{j}.version='v2.5';
end
<<<<<<< HEAD
=======
end
>>>>>>> spotFindingSuite_v2.5.1

wormFileName=strrep(worms{1}.segStackFile,'_SegStacks.mat','_wormGaussianFit.mat');
save(wormFileName,'worms')
end