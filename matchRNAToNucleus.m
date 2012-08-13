function worms=matchRNAToNucleus(worms,nucLocations)
%For each potential RNA spot, find the nearest nucleus (index in
%nucLocations and location in.  make a new spotDataVectors entry which is
%nucleus location (3D) - both the locations here should be relative to that
%worm's mask
nWorms=length(worms);

for iW=1:nWorms
    nucLocs=nucLocations(nucLocations(:,1)==iW,2:4);
    RNALocs=worms{iW}.spotDataVectors.locationStack;
    [distances,I]=pdist2(nucLocs,RNALocs,@scopeDistanceForpdist2,'Smallest',1);
    worms{iW}.spotDataVectors.nucLocation=nucLocs(I,:);
    worms{iW}.spotDataVectors.distanceToNuc=distances';
    worms{iW}.nucDataVectors=struct('nucLocations',nucLocs,'nRNASpots',zeros(size(nucLocs,1),1));
    for iN=1:size(nucLocs,1)
        worms{iW}.nucDataVectors.nRNASpots(iN)=sum(I==iN);
    end;
end;
end




