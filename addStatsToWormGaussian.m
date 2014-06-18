function worms=addStatsToWormGaussian(worms)
%% ========================================================================
%   Name:       addStatsToWormGaussian.m
%   Version:    2.5, 25th Apr. 2013
%   Author:     Allison Wu
%   Command:    worms=addStatsToWormGaussian(worms)
%   Description:
%       - add new stats, such as delta stats, ratioSigmaXY and randStats to
%       an exisiting worms structure from wormGaussianFit.mat
%% ========================================================================
for j=1:length(worms)
% Adding the delta stats
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

wormFileName=strrep(worms{1}.segStackFile,'_SegStacks.mat','_wormGaussianFit.mat');
save(wormFileName,'worms')
end