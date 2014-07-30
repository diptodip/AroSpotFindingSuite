function [lbub,distributionSpotCount,spotNumEstimate]=makeSpotCountInterval(spotStatsOrTrainingSetRF,type)
%% ========================================================================
%   Name:       makeSpotCountInterval.m
%   Version:    2.5.1 30 July 2014
%   Author:     Scott Rifkin
%   Command:    makeSpotCountInterval(spotStatsOrTrainingSetRF,type)
%   Description:
%       - Makes a distribution of spotCounts based on calibrated mean leaf
%       probabilities and standard error of this mean
%       - spotStatsOrTrainingSet is either a specimen from a spotStats file
%       or a trainingSet.RF
%       - type is either 'spotStats' or 'trainingSet'
%
%   Files required:     *spotStats.mat file or trainingSet*.mat file
%                           File name examples: cy5_Pos0_spotStats.mat
%                                           
%   Files generated:    none
%   Output:             3 variables. 
%                            - a vector with the lower and upper bound of spot counts
%                            - the full distribution of these counts
%                            - a point estimate of the spot number
%                       
%% ========================================================================
nBoots=1000;
width=spotStatsOrTrainingSetRF.intervalWidth;

%% Deal with manual classification if not making a training set
if strcmp(type,'spotStats')
    manuallyCurated=spotStatsOrTrainingSetRF.classification(:,1)~=-1;
else
    manuallyCurated=zeros(size(spotStatsOrTrainingSetRF.spotTreeProbs,1));
end;

%% Calculate the mean probabilities and the standard deviations
meanProbs=mean(spotStatsOrTrainingSetRF.spotTreeProbs(~manuallyCurated,:),2);
sdProbs=std(spotStatsOrTrainingSetRF.spotTreeProbs(~manuallyCurated,:),[],2)/sqrt(size(spotStatsOrTrainingSetRF.spotTreeProbs,2));

%% Generate the probabilities for bootstrapping
meanProbsWithError=normrnd(repmat(meanProbs,1,nBoots),repmat(sdProbs,1,nBoots),length(meanProbs),nBoots);

%% Calibrate the bootstrap probabilities and also the mean probabilities
calibratedMeanProbsWithError=calibrateProbabilities(meanProbsWithError);
calibratedMeanProbs=calibrateProbabilities(meanProbs);

%% Generate spot count distribution based on the calibrated probabilities
distributionSpotCount=sum(binornd(ones(size(calibratedMeanProbsWithError)),calibratedMeanProbsWithError),1);
if strcmp(type,'spotStats')%then manually classified ones were taken out
    distributionSpotCount=distributionSpotCount+ sum(spotStatsOrTrainingSetRF.classification(:,1)==1);
end;
lbub=[prctile(distributionSpotCount,(100-width)/2),prctile(distributionSpotCount,(100-(100-width)/2))];

%% Calculate the spot number estimate, taking into account manual classification if necessary
spotNumEstimate=sum(calibratedMeanProbs(~manuallyCurated)>.5);
if sum(manuallyCurated)>0
    disp(sum(manuallyCurated));
    spotNumEstimate=spotNumEstimate+sum(spotStatsOrTrainingSetRF.classification(manuallyCurated,1)==1);
end;
end

