function spotStats=updateSpotStats(spotStats)
%% ========================================================================
%   Name:       updateSpotStats.m
%   Version:    2.5, 25th Apr. 2013
%   Author:     Allison Wu
%   Command:    spotStats=updateSpotStats(spotStats)
%   Description:
%       This code curates the total spot number and range by taking out the manually curated spots first, 
%       calculate the spot number and range and then put the manually curated spots back.
%
%   Attribution: Wu, AC-Y and SA Rifkin. spotFinding Suite version 2.5, 2013 [journal citation TBA]
%   License: Creative Commons Attribution-ShareAlike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%   Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%   Email for comments, questions, bugs, requests:  Allison Wu < dblue0406 at gmail dot com >, Scott Rifkin < sarifkin at ucsd dot edu >
%
%% ========================================================================

spotStats.spotNumCurated=1;
load(spotStats.trainingSetName)
mCuratedSpots=(spotStats.classification(:,1)~=-1);

Probs=spotStats.ProbEstimates(~mCuratedSpots);
IQR=spotStats.IQR(~mCuratedSpots);
IQRt=trainingSet.RF.IQRthreshold;
spotTreeProbs=spotStats.spotTreeProbs(~mCuratedSpots,:);
spotStats.SpotNumEstimate=sum(Probs>0.5)+sum(mCuratedSpots);

unreliableSpots=Probs(IQR>trainingSet.RF.IQRthreshold);
unreliableGoodSpots=unreliableSpots(unreliableSpots>0.5);
unreliableBadSpots=unreliableSpots(unreliableSpots<0.5);
randG=binornd(1,repmat(unreliableGoodSpots,1,1000),length(unreliableGoodSpots),1000);
randB=binornd(1,repmat(unreliableBadSpots,1,1000),length(unreliableBadSpots),1000);
g2b=prctile(sum(~randG),trainingSet.RF.quantile);
b2g=prctile(sum(randB), 100-trainingSet.RF.quantile);
ub=sum(Probs>0.5)+b2g;
lb=sum(Probs>0.5)-g2b;

spotStats.SpotNumRange=[lb+sum(mCuratedSpots) ub+sum(mCuratedSpots)];


end