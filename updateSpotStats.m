function spotStats=updateSpotStats(spotStats)
%% ========================================================================
%   Name:       updateSpotStats.m
%   Version:    2.5.1, 23rd Jul. 2014
%   Author:     Allison Wu
%   Command:    spotStats=updateSpotStats(spotStats)
%   Description:
%       This code curates the total spot number and range by taking out the manually curated spots first, 
%       calculate the spot number and range and then put the manually curated spots back.
%   Update:
%       2014.7.23 Fixed a bug at line 21 which gives the wrong
%       spotNumEstimates. Use the new prediction interval calculation.
%% ========================================================================

spotStats.spotNumCurated=1;
load(spotStats.trainingSetName)
mCuratedSpots=(spotStats.classification(:,1)~=-1);

Probs=spotStats.ProbEstimates(~mCuratedSpots);

spotTreeProbs=spotStats.spotTreeProbs(~mCuratedSpots,:);
spotStats.SpotNumEstimate=sum(Probs>0.5)+sum(spotStats.classification(mCuratedSpots,1));
randP=binornd(1,repmat(Probs,1,1000),length(Probs),1000);
ub=prctile(sum(randP),97.5)+sum(spotStats.classification(mCuratedSpots,1));
lb=prctile(sum(randP),2.5)+sum(spotStats.classification(mCuratedSpots,1));

spotStats.SpotNumRange=[lb ub];


end