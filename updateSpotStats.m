function spotStats=updateSpotStats(spotStats)
%% ========================================================================
%   Name:       updateSpotStats.m
%   Version:    2.5, 25th Apr. 2013
%   Author:     Allison Wu
%   Command:    spotStats=updateSpotStats(spotStats)
%   Description:
%       This code curates the total spot number and range by taking out the manually curated spots first, 
%       calculate the spot number and range and then put the manually curated spots back.
%   Edited 30June14 - SAR - 
%         spotStats.SpotNumEstimate line is adding back the number of the spots that were manually curated - disregarding whether they were good or bad spots
%         this needs to be modified so that it only adds back in the number of "manually curated to be good" spots
%         do this either by:
%             spotStats.SpotNumEstimate=sum(Probs>0.5)+sum(mCuratedSpots*spotStats.classification(:,1));
%             or
%             spotStats.SpotNumEstimate=sum(Probs>0.5)+sum(spotStats.classification(:,1)==1);
%             Choose the second one for now and revise based on consultation with Allison
%             Made a new variable called nManuallyCuratedGoodSpots.
%              Also had to use this for the SpotNumRange
%% ========================================================================

spotStats.spotNumCurated=1;
load(spotStats.trainingSetName)
mCuratedSpots=(spotStats.classification(:,1)~=-1);

Probs=spotStats.ProbEstimates(~mCuratedSpots);
IQR=spotStats.IQR(~mCuratedSpots);
IQRt=trainingSet.RF.IQRthreshold;
spotTreeProbs=spotStats.spotTreeProbs(~mCuratedSpots,:);
nManuallyCuratedGoodSpots=sum(spotStats.classification(:,1)==1);
spotStats.SpotNumEstimate=sum(Probs>0.5)+nManuallyCuratedGoodSpots;
[g2b b2g]=calculateErrorRange(Probs, IQR, IQRt,trainingSet.RF.quantile);
ub=sum(Probs>0.5)+b2g;
lb=sum(Probs>0.5)-g2b;

spotStats.SpotNumRange=[lb++nManuallyCuratedGoodSpots ub+nManuallyCuratedGoodSpots];


end