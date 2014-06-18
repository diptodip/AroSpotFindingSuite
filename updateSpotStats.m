function spotStats=updateSpotStats(spotStats)
%% ========================================================================
%   Name:       updateSpotStats.m
%   Version:    2.5, 25th Apr. 2013
%   Author:     Allison Wu
%   Command:    spotStats=updateSpotStats(spotStats)
%   Description:
%       This code curates the total spot number and range by taking out the manually curated spots first, 
%       calculate the spot number and range and then put the manually curated spots back.
%% ========================================================================

spotStats.spotNumCurated=1;
load(spotStats.trainingSetName)
mCuratedSpots=(spotStats.classification(:,1)~=-1);

Probs=spotStats.ProbEstimates(~mCuratedSpots);
IQR=spotStats.IQR(~mCuratedSpots);
IQRt=trainingSet.RF.IQRthreshold;
spotTreeProbs=spotStats.spotTreeProbs(~mCuratedSpots,:);
spotStats.SpotNumEstimate=sum(Probs>0.5)+sum(mCuratedSpots);
[g2b b2g]=calculateErrorRange(Probs, IQR, IQRt,trainingSet.RF.quantile);
ub=sum(Probs>0.5)+b2g;
lb=sum(Probs>0.5)-g2b;

spotStats.SpotNumRange=[lb+sum(mCuratedSpots) ub+sum(mCuratedSpots)];


end