function result = RNANucVarCalc(ssbn,dyeCol)

%% ========================================================================
%   Name:       RNANucVarCalc.m
%   Version:    0.1, 23 March 2013
%   Author:     Scott Rifkin
%   Command:    RNANucVarCalc(ssbn)
%   Description: calculates the _overall_ dispersion measure for a nucleus
%   trajectory.  [Uses a rlowess filter to determine the mean (span 0.75) and
%   then detemines squared deviation from this mean and rlowess on this to
%   determine the variance at each point. Then sums these variances.] 
%   Takes the 
%   Files required: 
%       - wormData_byNuc**.mat
%   Files generated: 
%% ========================================================================

smoothedMean=smooth(ssbn.spotNum(:,5),ssbn.spotNum(:,dyeCol),0.75,'rlowess');

deviations=ssbn.spotNum(:,dyeCol)-smoothedMean;
squaredDeviations=deviations.^2;
smoothedSqDeviations=smooth(ssbn.spotNum(:,5),squaredDeviations,0.75,'rlowess');
result=sum(smoothedSqDeviations);
figure(100)
[nucs,uniqueInstanceIndices,]=unique(ssbn.spotNum(:,5));
[sortedNucs,sortedUII]=sort(nucs);
plot(sortedNucs,smoothedMean(uniqueInstanceIndices(sortedUII)),'b');
hold on
plot(sortedNucs,smoothedSqDeviations(uniqueInstanceIndices(sortedUII)),'r');

end