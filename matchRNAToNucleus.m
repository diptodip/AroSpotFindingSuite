function worms=matchRNAToNucleus(worms,varargin)
%% ========================================================================
%   Name:       matchRNAToNucleus.m
%   Version:    2.1, 23 March 2013
%   Author:     Scott Rifkin
%   Command:    worms=matchRNAToNucleus(worms,overwrite*) *Optional
%   Description: Assigns RNA spots to nuclei
%                 - overwrite (varargin) flag [0,1]: 0 don't overwrite if nucLocation is already a field (default=1)
%                 - adds some fields to the worms data structure (**_wormGaussianFit.mat)
%                 - reads in RNA location from worms data structure
%                   accessed by worms{x}.spotDataVectors.locationStack which is [row, col, z]
%                 - reads nuc location data currently from the singleton files
%                   so there is a bit of a hack to get these to match up
%                   and to decide which file to read because of incomplete state
%                   of curation
%
%   Files required:
%       - **_spotStats.mat
%       - curated_nuclei**.mat or autoNucLocsEqualized**.mat
%         - **_wormGaussianFit.mat file so that it has spot Locations
%         accessed by
%   Files generated:
%         - **_wormGaussianFit.mat updates with nucLocation, distnaceToNuc,
%         ThresholdProbEstimates, nucIndex
%% ========================================================================


p = inputParser;
%nucLocationInfo is struct with fields: nucLocations, nucLocationSource (where
%it comes from)
% add optional needs the name, default value, and validator
p.addParamValue('nucLocationInfo',{},@(x) isa(x,'struct'));
p.addParamValue('spotStats',{},@(x) isa(x,'cell'));
p.addParamValue('overwrite',1,@isscalar);
p.parse(varargin{:});


nWorms=length(worms);

stackName=regexprep(worms{1}.segStackFile,'_','\.');
stackPrefix=regexp(stackName,'\.','split');
dye=stackPrefix{1};
posNum=stackPrefix{2};
posNum=str2num(cell2mat(regexp(posNum,'\d+','match')));

%need to load spotStats
if isempty(p.Results.spotStats)
    sps=load([dye '_Pos' num2str(posNum) '_spotStats.mat']);
    spotStats=sps.spotStats;
    clear sps
else
    spotStats=p.Results.spotStats;
end;

%need to load training set to get the IQRt and quantileRange
ts=load(spotStats{1}.trainingSetName);
trainingSet=ts.trainingSet;
clear ts
IQRt=trainingSet.RF.IQRthreshold;
quantileRange=trainingSet.RF.quantileRange;
clear('trainingSet');
wormsChanged=0;
for iW=1:nWorms
    
    if isempty(p.Results.nucLocationInfo)
        
        %Need to get nucLocations
        %%%%%%%%%%%%%%%
        %This section is just for the separated embryos with adjustedManualInfo
        [~,curdirName]=fileparts(pwd);
        separatedBase='/Volumes/rifkinlab/SharedData/SexDeterminationData';
        singletonNucleiDir=fullfile(separatedBase,curdirName);
        
        singletonFileNum=num2str(100*(iW+1)+posNum);
        curs=dir(fullfile(singletonNucleiDir,['curated_nuclei' singletonFileNum '*.mat']));
        autos=dir(fullfile(singletonNucleiDir,['autoNucLocsEq*' singletonFileNum '*.mat']));
        abandoned=dir(fullfile(singletonNucleiDir,['abandoned*' singletonFileNum '*.mat']));
        if ~isempty(abandoned)
            disp(['abandoned*' singletonFileNum '*.mat']);
            nucLocations=[];
        elseif ~isempty(curs)
            disp(['Loading ' curs(1).name]);
            ae=load(fullfile(singletonNucleiDir,curs(1).name));
            allembryos=ae.allembryos;
            clear ae
            if isfield(allembryos{1}.dapistr,'curatedPts')
                nucLocations=allembryos{1}.dapistr.curatedPts;
                nucLocationSource=[curs(1).name '.field.curatedPts'];
            else
                if isfield(allembryos{1}.dapistr,'adjustedManualNucLocs')
                    nucLocations=allembryos{1}.dapistr.adjustedManualNucLocs{1};
                    nucLocationSource=[curs(1).name '.field.adjustedManualNucLocs{1}'];
                    
                else
                    nucLocations=[];
                end;
            end;
        elseif ~isempty(autos)
            ae=load(fullfile(singletonNucleiDir,autos(1).name));
            allembryos=ae.allembryos;
            clear ae
            disp(['Loading ' autos(1).name]);
            if isfield(allembryos{1}.dapistr,'adjustedManualNucLocs')
                nucLocations=allembryos{1}.dapistr.adjustedManualNucLocs;
                nucLocationSource=[autos(1).name '.field.adjustedManualNucLocs'];
                
            else
                nucLocations=[];
            end;
        elseif isfield(worms{iW},'nucDataVectors')
            nucLocations=worms{iW}.nucDataVectors.nucLocations;
        else
            nucLocations=[];
        end;
        clear allembryos 
    else
        nucLocations=p.Results.nucLocationInfo.nucLocations;
        nucLocationSource=p.Results.nucLocationInfo.nucLocationSource;
    end;
    %%%%%%%%%%%%%%%%%%
    if ~isempty(nucLocations)
        RNALocs=worms{iW}.spotDataVectors.locationStack;
        [distances,nucIndices]=pdist2(nucLocations,RNALocs,@scopeDistanceForpdist2,'Smallest',1);%3/26/13: This is probably the wrong distance measure.  Should use XY_ZBtwvectorListsForCombining
        worms{iW}.spotDataVectors.nucLocation=nucLocations(nucIndices,:);
        worms{iW}.spotDataVectors.distanceToNuc=distances';
        worms{iW}.spotDataVectors.nucIndices=nucIndices';
        %   From classifySpots (23 March 2013)
        %         spotStats{wi}.spotTreeProbs=spotTreeProbs;
        %         Probs=mean(spotTreeProbs,2);
        %         IQR=iqr(spotTreeProbs,2);
        %         IQRt=trainingSet.RF.IQRthreshold;
        %         spotStats{wi}.ProbEstimates=Probs;
        %         spotStats{wi}.SpotNumEstimate=sum(Probs(IQR<IQRt)>0.5)+sum(Probs(IQR>IQRt));
        %         randSpotNum=binornd(1,spotTreeProbs(IQR>IQRt,:),size(spotTreeProbs(IQR>IQRt,:)));
        %         range=quantile(sum(randSpotNum,1),trainingSet.RF.quantileRange);
        %         spotStats{wi}.SpotNumRange=sum(Probs(IQR<IQRt)>0.5)+range;
        %         spotStats{wi}.quantileRange=trainingSet.RF.quantileRange;
        %         spotStats{wi}.Margin=abs(Probs*2-1);
        %         spotStats{wi}.IQR=IQR;
        %         spotStats{wi}.UnreliablePortion=mean(IQR>IQRt);
        
        %   I only re-store data here that could change begin nucleus
        %   specific.  So spot-specific info won't change but estimates of
        %   #RNA in nucleus will.  I keep quantileRange here just so I know
        %   what it is conveniently
        
        nNucs=size(nucLocations,1);
        worms{iW}.nucDataStats.quantileRange=quantileRange;
        worms{iW}.nucDataStats.nucLocations=nucLocations;
        worms{iW}.nucDataStats.nucLocationSource=nucLocationSource;
        worms{iW}.nucDataStats.SpotIndices=cell(nNucs,1);
        worms{iW}.nucDataStats.SpotNumEstimate=zeros(nNucs,1);
        worms{iW}.nucDataStats.SpotNumRange=zeros(nNucs,2);
        worms{iW}.nucDataStats.UnreliablePortion=zeros(nNucs,1);
        for iNuc=1:nNucs
            spotIndicesForThisNucleus=find(nucIndices==iNuc);
            worms{iW}.nucDataStats.SpotIndices{iNuc}=spotIndicesForThisNucleus;
            if ~isempty(spotIndicesForThisNucleus)
                spotTreeProbs=spotStats{iW}.spotTreeProbs(spotIndicesForThisNucleus,:);
                Probs=mean(spotTreeProbs,2);
                IQR=iqr(spotTreeProbs,2);
                randSpotNum=binornd(1,spotTreeProbs(IQR>IQRt,:),size(spotTreeProbs(IQR>IQRt,:)));
                range=quantile(sum(randSpotNum,1),quantileRange);
                worms{iW}.nucDataStats.SpotNumEstimate(iNuc)=sum(Probs(IQR<IQRt)>0.5)+sum(Probs(IQR>IQRt));
                worms{iW}.nucDataStats.SpotNumRange(iNuc,:)=sum(Probs(IQR<IQRt)>0.5)+range;
                worms{iW}.nucDataStats.UnreliablePortion(iNuc)=mean(IQR>IQRt);
            else
                worms{iW}.nucDataStats.SpotNumEstimate(iNuc)=0;
                worms{iW}.nucDataStats.SpotNumRange(iNuc,:)=[0 0];
                worms{iW}.nucDataStats.UnreliablePortion(iNuc)=0;
            end;
            
            
            %
            %     worms{iW}.spotDataVectors.ThresholdedProbEstimates=spotStats{iW}.ProbEstimates;
            %     lessThanThreshold=find(spotStats{iW}.IQR<IQRt);
            %     lessThanOneHalf=find(worms{iW}.spotDataVectors.ThresholdedProbEstimates<=.5);
            %     greaterThanOneHalf=find(worms{iW}.spotDataVectors.ThresholdedProbEstimates>.5);
            %     worms{iW}.spotDataVectors.ThresholdedProbEstimates(intersect(lessThanThreshold,lessThanOneHalf))=0;
            %     worms{iW}.spotDataVectors.ThresholdedProbEstimates(intersect(lessThanThreshold,greaterThanOneHalf))=1;
            %
            %     worms{iW}.nucDataVectors=struct('nucLocations',nucLocations,'nRNASpots',zeros(size(nucLocations,1),1));
            %     for iN=1:size(nucLocations,1)
            %         %iRNAspots=find(I==iN);
            %         worms{iW}.nucDataVectors.nRNASpots(iN)=sum(worms{iW}.spotDataVectors.ThresholdedProbEstimates(I==iN));
            %     end;
        end;%for iNucs
    end;%if ~isempty nucLocations
    worms{iW}.date_RNAToNucleusMatched=datestr(now);
end;%for worms

if p.Results.overwrite
    disp(['Saving: ' stackPrefix{1} '_' stackPrefix{2} '_wormGaussianFit.mat']);
    parsave_worms([stackPrefix{1} '_' stackPrefix{2} '_wormGaussianFit.mat'],worms);
end;


    function parsave_worms(fileName,worms)
        save(fileName,'worms');
    end

end





