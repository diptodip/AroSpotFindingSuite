function worms=matchRNAToNucleus(worms,nucLocations,spotStats)
%For each potential RNA spot, find the nearest nucleus (index in
%nucLocations and location in.  make a new spotDataVectors entry which is
%nucleus location (3D) - both the locations here should be relative to that
%worm's mask
nWorms=length(worms);

%need to load training set to get the IQRt
load(spotStats{1}.trainingSetName);
IQRt=trainingSet.RF.IQRthreshold;
clear('trainingSet');

for iW=1:nWorms
    nucLocs=nucLocations(nucLocations(:,1)==iW,2:4);
    RNALocs=worms{iW}.spotDataVectors.locationStack;
    [distances,I]=pdist2(nucLocs,RNALocs,@scopeDistanceForpdist2,'Smallest',1);
    worms{iW}.spotDataVectors.nucLocation=nucLocs(I,:);
    worms{iW}.spotDataVectors.distanceToNuc=distances';
    %almost the same as prob estimates from spotStats, except ones that
    %aren't counted are set to 0
    %This is how spotNumEstimate is calculated:
    % sum(Probs(IQR<IQRt)>0.5)+sum(Probs(IQR>IQRt));
    worms{iW}.spotDataVectors.ThresholdedProbEstimates=spotStats{iW}.ProbEstimates;
    lessThanThreshold=find(spotStats{iW}.IQR<IQRt);
    lessThanOneHalf=find(worms{iW}.spotDataVectors.ThresholdedProbEstimates<=.5);
    greaterThanOneHalf=find(worms{iW}.spotDataVectors.ThresholdedProbEstimates>.5);
    worms{iW}.spotDataVectors.ThresholdedProbEstimates(intersect(lessThanThreshold,lessThanOneHalf))=0;
    worms{iW}.spotDataVectors.ThresholdedProbEstimates(intersect(lessThanThreshold,greaterThanOneHalf))=1;
    
    worms{iW}.nucDataVectors=struct('nucLocations',nucLocs,'nRNASpots',zeros(size(nucLocs,1),1));
    for iN=1:size(nucLocs,1)
        %iRNAspots=find(I==iN);
        worms{iW}.nucDataVectors.nRNASpots(iN)=sum(worms{iW}.spotDataVectors.ThresholdedProbEstimates(I==iN));
    end;
end;
end



