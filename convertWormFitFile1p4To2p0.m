function convertWormFitFile1p4To2p0(old,prefix)

versionName='v2.0';
worms=cell(size(old.worms,2),1);
exactSame={'numberOfPlanes','cutoffStat','cutoffStatisticValue','cutoffPercentile','regMaxSpots','goodWorm'};
wormFitFileName=[prefix '_wormGaussianFit.mat'];
%if ~exist(wormFitFileName,'file')
    for iWorm=1:size(worms,1)
        worms{iWorm}.segStackFile=[prefix '_SegStacks.mat'];
        worms{iWorm}.version=versionName;
        worms{iWorm}.functionVersion={mfilename; versionName; datestr(now)};
        for i=1:length(exactSame)
            worms{iWorm}=mapOldToNew(old.worms{iWorm},worms{iWorm},exactSame{i});%mapOldToNew(old,new,fieldname)
            
            %worms{iWorm}.(exactSame{i})=old.worms{iWorm}.(exactSame{i});
        end;
        worms{iWorm}=mapOldToNew(old.worms{iWorm},worms{iWorm},'bleachFactors');%mapOldToNew(old,new,fieldname)
        %worms{iWorm}.bleachFactors=old.worms{iWorm}.bleachFactors';
        %spotDataVectors
        %First set them up
        nSpots=size(old.worms{iWorm}.spotInfo,2);
        size1s={ 'rawValue',...
            'filteredValue',...
            'spotRank',...
            'spotInfoNumberInWorm',...
            'intensity',...
            'rawIntensity',...
            'totalHeight',...
            'sigmax',...
            'sigmay',...
            'estimatedFloor',...
            'rmse',...
            'shrunkenRsquared',...
            'scmse',...
            'scnmse',...
            'scrmse',...
            'scnrmse',...
            'scmae',...
            'scmare',...
            'scr',...
            'scd',...
            'sce',...
            'prctile_10',...
            'prctile_20',...
            'prctile_30',...
            'prctile_40',...
            'prctile_50',...
            'prctile_60',...
            'prctile_70',...
            'prctile_80',...
            'prctile_90',...
            'threeDness',...
            'raw_center',...
            'fraction_center',...
            'raw_plusSign',...
            'fraction_plusSign',...
            'raw_3box',...
            'fraction_3box',...
            'raw_5star',...
            'fraction_5star',...
            'raw_5box',...
            'fraction_5box',...
            'raw_7star',...
            'fraction_7star',...
            'raw_3ring',...
            'fraction_3ring',...
            'total_area'};
        
        worms{iWorm}.spotDataVectors =struct;
        for iField=1:length(size1s)
            worms{iWorm}.spotDataVectors.(size1s{iField})=zeros(nSpots,1);
        end;
        worms{iWorm}.spotDataVectors.locationStack=zeros(nSpots,3);
        worms{iWorm}.spotDataVectors.dataMat=zeros(nSpots,7,7);
        worms{iWorm}.spotDataVectors.dataFit=zeros(nSpots,7,7);
        
        
        %Now go through and assign them
        for iSpot=1:nSpots
            if isfield(old.worms{iWorm}.spotInfo{iSpot}.stat,'statValues')
                spotInfo=old.worms{iWorm}.spotInfo{iSpot};
                worms{iWorm}.spotDataVectors.locationStack(iSpot,:)=spotInfo.locations.worm;%note that this should be worm not stack because the stacks are now worms
                worms{iWorm}.spotDataVectors.spotInfoNumberInWorm(iSpot)=iSpot;
                worms{iWorm}.spotDataVectors=mapOldToNew2(spotInfo,worms{iWorm}.spotDataVectors,'rawValue',iSpot);%mapOldToNew2(spotInfo,new,fieldname,iSpot)
                worms{iWorm}.spotDataVectors=mapOldToNew2(spotInfo,worms{iWorm}.spotDataVectors,'filteredValue',iSpot);%mapOldToNew2(spotInfo,new,fieldname,iSpot)
                worms{iWorm}.spotDataVectors=mapOldToNew2(spotInfo,worms{iWorm}.spotDataVectors,'spotRank',iSpot);%mapOldToNew2(spotInfo,new,fieldname,iSpot)
                worms{iWorm}.spotDataVectors=mapOldToNew3D(spotInfo.stat.statValues,worms{iWorm}.spotDataVectors,'dataFit',iSpot);%mapOldToNew3D(spotInfo,new,fieldname,iSpot)
                worms{iWorm}.spotDataVectors=mapOldToNew3D(spotInfo,worms{iWorm}.spotDataVectors,'dataMat',iSpot);%mapOldToNew3D(spotInfo,new,fieldname,iSpot)
                for iF=5:length(size1s)
                                    worms{iWorm}.spotDataVectors=mapOldToNew2(spotInfo.stat.statValues,worms{iWorm}.spotDataVectors,size1s{iF},iSpot);%mapOldToNew2(spotInfo,new,fieldname,iSpot)

                    %worms{iWorm}.spotDataVectors.(size1s{iF})=spotInfo.stat.statValues.(size1s{iF});
                end;
            end;
        end;
    end;
    save(wormFitFileName,'worms');
    disp([wormFitFileName ' converted']);
%else
    %disp([wormFitFileName ' already exists']);
%end;




end

function new=mapOldToNew(old,new,fieldname)
if isfield(old,fieldname)
    new.(fieldname)=old.(fieldname);
else
    new.(fieldname)=[];
end;
end

function new=mapOldToNew2(spotInfo,new,fieldname,iSpot)
if isfield(spotInfo,fieldname)
    new.(fieldname)(iSpot)=spotInfo.(fieldname);
end;
end

function new=mapOldToNew3D(spotInfo,new,fieldname,iSpot)
if isfield(spotInfo,fieldname)
    new.(fieldname)(iSpot,:,:)=spotInfo.(fieldname);
end;

end
