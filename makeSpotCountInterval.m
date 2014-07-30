function [lbub,distributionSpotCount]=makeSpotCountInterval(spotStats,iWorm,width)
%% ========================================================================
%   Name:       makeSpotCountInterval.m
%   Version:    2.5.1 30 July 2014
%   Author:     Scott Rifkin
%   Command:    makeSpotCountInterval(spotStats,iWorm,width)
%   Description:
%       - Makes a distribution of spotCounts based on calibrated mean leaf
%       probabilities and standard error of this mean
%       - spotStats is from a spotStats file
%       - iWorm is the specimen number in the spotStats file
%       - width is the interval width (0-100, so a 95% interval is 95)
%
%   Files required:     *spotStats.mat file
%                           File name examples: cy5_Pos0_spotStats.mat
%                        A.mat file.  This has the probability calibration curve
%                                           
%   Files generated:    none
%   Output:             2 variables. The first is a vector with the lower and
%                       upper bound of spot counts
%                        The second is the full distribution    
%% ========================================================================
nBoots=1000;
manuallyCurated=spotStats{iWorm}.classification(:,1)~=-1;
meanProbs=mean(spotStats{iWorm}.spotTreeProbs(~manuallyCurated,:),2);
sdProbs=std(spotStats{iWorm}.spotTreeProbs(~manuallyCurated,:),[],2)/sqrt(size(spotStats{iWorm}.spotTreeProbs,2));

meanProbsWithError=normrnd(repmat(meanProbs,1,nBoots),repmat(sdProbs,1,nBoots),length(meanProbs),nBoots);

load A

sigfunc=@(A,x)(1./(1+exp(-x*A(1)+A(2))));

calibratedMeanProbsWithError=sigfunc(A,meanProbsWithError);

distributionSpotCount=sum(binornd(ones(size(calibratedMeanProbsWithError)),calibratedMeanProbsWithError),1)+ sum(spotStats{iWorm}.classification(:,1)==1);
lbub=[prctile(distributionSpotCount,(100-width)/2),prctile(distributionSpotCount,(100-(100-width)/2))];
end

