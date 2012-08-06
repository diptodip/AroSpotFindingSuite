function spotStats=updateSpotStats(spotStats)
%% ========================================================================
%   Name:       updateSpotStats.m
%   Version:    2.0, 11th July 2012
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
spotStats.SpotNumEstimate=sum(Probs(IQR<IQRt)>0.5)+sum(Probs(IQR>IQRt))+sum(spotStats.classification(mCuratedSpots,3));
randSpotNum=binornd(1,spotTreeProbs(IQR>IQRt,:),size(spotTreeProbs(IQR>IQRt,:)));
range=quantile(sum(randSpotNum,1),trainingSet.RF.quantileRange);
spotStats.SpotNumRange=sum(Probs(IQR<IQRt)>0.5)+range+sum(spotStats.classification(mCuratedSpots,3));

end