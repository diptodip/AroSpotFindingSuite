function trainingSet=createSpotTrainingSetFromPreexistingGoldRejectedSpotsFiles(stackName,probeName,varargin)
%% ========================================================================
%   Name: createSpotTrainingSet
%   Version: 2.0 4th July 2012
%   Author: Allison Wu
%   Command:
%   trainingSet=createSpotTrainingSet(stackName,probeName,appendTrainingSet*)
%   *Optional Input
%
%   Description:
%       - Create training set by using identifySpots to identify good spots and bad spots as training set.
%       - Create a data matrix (row: spots, columns:features) ready for Matlab decision trees.
%       - appendTrainingSet=varargin{1}:
%           * appendTrainingSet==1, append spots to existing training set and recalcalculate statistics
%           * appendTrainingSet==0, overwrite any existing training set
%       - Prompts the user about whether to overwrite or to append spots to an existing training set
%         when appendTrainingSet==0 but an exisiting training set is found.
%
%   Files required:     {dye}_{stackSuffix}_SegStacks.mat,  {dye}_{stackSuffix}_wormGaussianFit.mat
%   Files generated:    trainingSet_{dye}_{probeName}.mat.
%% ========================================================================

[dye, stackSuffix, wormGaussianFitName, segStacksName,~]=parseStackNames(stackName);
trainingSetName=['trainingSet_' dye '_' probeName '.mat'];

if isempty(varargin)
    appendTrainingSet=0;
else
    appendTrainingSet=varargin{1};
end

% if exist(trainingSetName, 'file')
%     reply=input('There is an exisiting training set. Do you want to overwrite it? \n(Otherwise, the program will append new spots to the existing training set.) \n Y/N [N]:','s');
%     if isempty(reply)
%         reply='N';
%     end
%
%     if strcmpi(reply,'y')
%         appendTrainingSet=0;
%     else strcmpi(reply,'n')
%         appendTrainingSet=1;
%     end
% else
%     appendTrainingSet=0;
% end
%


%Identify Spots
% posNumber=str2num(cell2mat(regexp(stackSuffix,'\d+','match')));
% disp('Load in spots information...')
% load(wormGaussianFitName);
% wormNum=size(worms);
% stackH=worms{1}.numberOfPlanes;
% w=[1:wormNum];
% spotsInWorm=zeros(wormNum);
% for wi=1:wormNum
%     spotsInWorm(wi)=length(worms{wi}.spotDataVectors.rawValue);
% end
% [~,index]=sort(spotsInWorm,'descend');
% w=w(index);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

oldDir='Version1.4.Analyses';


disp('Load in segmented stacks...')
%load(segStacksName);

disp('Identify spots in worms...')
% for wi=1:wormNum
%
%     [goodSpots,badSpots]=identifySpots(floor(stackH/8),segStacks,segMasks,worms,w(wi));
%     if wi==1
%         goldSpotsData=goodSpots;
%         rejectedSpotsData=badSpots;
%     else
%         if ~isempty(goodSpots)
%             goldSpotsData=[goldSpotsData;goodSpots];
%         end
%         if ~isempty(badSpots)
%             rejectedSpotsData=[rejectedSpotsData;badSpots];
%         end
%     end
% end
% clear segStacks
%%%% Load preexisting spot files
%load([oldDir filesep 'goldSpots_' dye '_' probeName '.mat']);
%load([oldDir filesep 'rejectedSpots_' dye '_' probeName '.mat']);
load([ 'goldSpots_' dye '_' probeName '.mat']);
load([ 'rejectedSpots_' dye '_' probeName '.mat']);
%note that these have locations in whole 1024x1024 stack so need to get
%worm specific locations from these
%also is structure such that fields are the stack name
%gold
trainingSet.FileName=trainingSetName;
trainingSet.spotInfo=[];
spotsNotFound=[0 0];
%gold
gFN=fieldnames(goldSpots);
for iFN=1:size(gFN,1)
    posNumber=collectDigits(gFN{iFN});
    %load the worm file
    old=load(sprintf('%s%s%s%s_wormGaussianFit.mat',oldDir,filesep,dye,posNumber{1}));
    new=load(sprintf('%s_%s_wormGaussianFit.mat',dye,posNumber{1}));
    for iG=1:size(goldSpots.(gFN{iFN}),1)
        
        r=goldSpots.(gFN{iFN})(iG,1);
        c=goldSpots.(gFN{iFN})(iG,2);
        z=goldSpots.(gFN{iFN})(iG,3);
        %        fprintf('%s %d %d %d %d\n',gFN{iG}, iG, r,c,z);
        %which worm is it in?
        wormNum=0;
        for wi=1:length(old.worms)
            if old.worms{wi}.mask(r,c)>0
                wormNum=wi;
                break
            end;
        end;
        if ~wormNum
            disp('Problem, wormNum is 0!! spot not found where it should be');
            %             disp(goldSpots.(gFN{iG})(iG,:));
            %             disp([r c z]);
            %             for iW=1:length(worms)
            %             disp(worms{iW}.boundingBox.BoundingBox);
            %             end;
            spotsNotFound(1)=spotsNotFound(1)+1;
        else
            %what is the spotNumber in that worm?
            toSubtractFromR=floor(old.worms{wormNum}.boundingBox.BoundingBox(2));
            toSubtractFromC=floor(old.worms{wormNum}.boundingBox.BoundingBox(1));
            locationStack=[r-toSubtractFromR,c-toSubtractFromC,z];
            %find it in the worm
            spotIndex=find(ismember(new.worms{wormNum}.spotDataVectors.locationStack,locationStack,'rows'));
            if ~isempty(spotIndex)%if it can't find it for some reason, don't worry about it. This may be a holdover from pre-maxima days, although I don't think so
                classification=1;
                trainingSet.spotInfo=[trainingSet.spotInfo; str2num(posNumber{1}) wormNum spotIndex classification];
            else
                spotsNotFound(1)=spotsNotFound(1)+1;
            end;
        end;
        
    end;
end;
disp('gold done');
%rejected
rFN=fieldnames(rejectedSpots);
for iFN=1:size(rFN,1)
    posNumber=collectDigits(rFN{iFN});
    %load the worm file
    old=load(sprintf('%s%s%s%s_wormGaussianFit.mat',oldDir,filesep,dye,posNumber{1}));
    new=load(sprintf('%s_%s_wormGaussianFit.mat',dye,posNumber{1}));
    for iR=1:size(rejectedSpots.(rFN{iFN}),1)
        r=rejectedSpots.(rFN{iFN})(iR,1);
        c=rejectedSpots.(rFN{iFN})(iR,2);
        z=rejectedSpots.(rFN{iFN})(iR,3);
        
        %which worm is it in?
        wormNum=0;
        for wi=1:length(old.worms)
            if old.worms{wi}.mask(r,c)>0
                wormNum=wi;
                break
            end;
        end;
        if ~wormNum
            disp('Problem, wormNum is 0!! spot not found where it should be');
            spotsNotFound(2)=spotsNotFound(2)+1;
        else
            
            %what is the spotNumber in that worm?
            toSubtractFromR=floor(old.worms{wormNum}.boundingBox.BoundingBox(2));
            toSubtractFromC=floor(old.worms{wormNum}.boundingBox.BoundingBox(1));
            locationStack=[r-toSubtractFromR,c-toSubtractFromC,z];
            %find it in the worm
            spotIndex=find(ismember(new.worms{wormNum}.spotDataVectors.locationStack,locationStack,'rows'));
            if ~isempty(spotIndex)%if it can't find it for some reason, don't worry about it. This may be a holdover from pre-maxima days, although I don't think so
                
                classification=0;
                trainingSet.spotInfo=[trainingSet.spotInfo; str2num(posNumber{1}) wormNum spotIndex classification];
            else
                spotsNotFound(2)=spotsNotFound(2)+1;
            end;
        end;
    end;
end;
worms=new.worms;
clear('old','new');
disp('rejected done');
disp('spotsNotFound')
disp(spotsNotFound);
% goldNum=size(goldSpotsData,1);
% rejNum=size(rejectedSpotsData,1);
% spotNum=goldNum+rejNum;
%
% % [posNumber, wormNumber, spotIndex, classification]
% trainingSet.spotInfo=[ones(goldNum,1)*posNumber goldSpotsData(:,end-1:end) ones(goldNum,1)];
% trainingSet.spotInfo=[trainingSet.spotInfo; ones(rejNum,1)*posNumber rejectedSpotsData(:,end-1:end) zeros(rejNum,1)];
spotNum=size(trainingSet.spotInfo,1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


trainingSet.stats=struct;
% Add stats info to training set
fieldsToAdd=fields(worms{1}.spotDataVectors);


indicesInSpotInfo=1:size(trainingSet.spotInfo,1);
orderIndicesAdded=[];
posNumbers=unique(trainingSet.spotInfo(:,1));
for iP=1:length(posNumbers)
    posNum=posNumbers(iP);
    load(sprintf('%s_%03d_wormGaussianFit.mat',dye,posNum));
    
    for fta=1:length(fieldsToAdd)
        for wi=1:length(worms)
            wormData=worms{wi};
            wormIndex=trainingSet.spotInfo(:,2)==wi;
            posIndex=trainingSet.spotInfo(:,1)==posNum;
            toUseIndex=find(wormIndex&posIndex);
            %             wormIndex=find(trainingSet.spotInfo(:,2)==wi);
            %             posIndex=find(trainingSet.spotInfo(:,1)==posNum);
            %             toUseIndex=intersect(wormIndex,posIndex);
            spotIndex=(trainingSet.spotInfo(toUseIndex,3));
            if fta==1%just do this once
                orderIndicesAdded=[orderIndicesAdded,indicesInSpotInfo(toUseIndex)];
            end;
            
            if ~strcmp(fieldsToAdd{fta},'spotInfoNumberInWorm') && ~strcmp(fieldsToAdd{fta},'nucLocation') && ~strcmp(fieldsToAdd{fta},'distanceToNuc')
                if ~isfield(trainingSet.stats, fieldsToAdd{fta})
                    if ~sum(strcmp(fieldsToAdd{fta},{'dataMat','dataFit'}))
                        trainingSet.stats.(fieldsToAdd{fta})=wormData.spotDataVectors.(fieldsToAdd{fta})(spotIndex);
                    else
                        trainingSet.stats.(fieldsToAdd{fta})=wormData.spotDataVectors.(fieldsToAdd{fta})(spotIndex,:,:);
                    end
                else
                    if ~sum(strcmp(fieldsToAdd{fta},{'dataMat','dataFit'}))
                        trainingSet.stats.(fieldsToAdd{fta})=[trainingSet.stats.(fieldsToAdd{fta});wormData.spotDataVectors.(fieldsToAdd{fta})(spotIndex)];
                    else
                        trainingSet.stats.(fieldsToAdd{fta})=[trainingSet.stats.(fieldsToAdd{fta});wormData.spotDataVectors.(fieldsToAdd{fta})(spotIndex,:,:)];
                    end
                end
            end
        end
        
    end
end
%now rejigger the order to match the spotInfo data
[~,sortInds]=sort(orderIndicesAdded);

for fta=1:length(fieldsToAdd)
            if ~strcmp(fieldsToAdd{fta},'spotInfoNumberInWorm') && ~strcmp(fieldsToAdd{fta},'nucLocation') && ~strcmp(fieldsToAdd{fta},'distanceToNuc')
    if ~sum(strcmp(fieldsToAdd{fta},{'dataMat','dataFit'}))
        trainingSet.stats.(fieldsToAdd{fta})=trainingSet.stats.(fieldsToAdd{fta})(sortInds);
    else
        trainingSet.stats.(fieldsToAdd{fta})=trainingSet.stats.(fieldsToAdd{fta})(sortInds,:,:);
    end
end;
end;
%%%%%%%%%%%%%%%%% end order rejiggering


% Calculate SVD
allDataPixelValues=trainingSet.stats.dataMat(:,:);
%center data
trainingSet.allDataCenter=mean(allDataPixelValues,1);
allDataPixelValuesCentered=allDataPixelValues-repmat(trainingSet.allDataCenter,size(allDataPixelValues,1),1);
[~,~,v]=svd(allDataPixelValuesCentered,0);
trainingSet.svdBasisRightMultiplier=(v')^(-1);
rotatedAllDataPixelValues=allDataPixelValuesCentered*trainingSet.svdBasisRightMultiplier;
%trainingSet.stats.sv=zeros(length(trainingSet.spotInfo),5);
for i=1:5
    %take the first five coordinates of in the new basis
    trainingSet.stats.(['sv' num2str(i)])=rotatedAllDataPixelValues(:,i);
end

% Stores a dataMatrix ready for Matlab random forest.
statsToUse = {'intensity';'rawIntensity';'totalHeight';'sigmax';'sigmay';'estimatedFloor';'scnmse';'scnrmse';'scr';'scd';'sce';
    'prctile_50';    'prctile_60'  ;  'prctile_70'  ;  'prctile_80'  ; 'prctile_90';
    'fraction_center';    'fraction_plusSign'  ;  'fraction_3box'  ;  'fraction_5star'  ;  'fraction_5box';    'fraction_7star' ; 'fraction_3ring';
    'raw_center';    'raw_plusSign'  ;  'raw_3box'  ;  'raw_5star'  ;  'raw_5box';    'raw_7star' ; 'raw_3ring';
    'total_area';'sv1';'sv2';'sv3';'sv4';'sv5'};

trainingSet.statsUsed=statsToUse;

% Create dataMatrix (with predictor X and response Y) for Matlab Random Forest
trainingSet.dataMatrix.X=zeros(spotNum,length(statsToUse));
startj=1;
for j=1:length(statsToUse)
    stat=trainingSet.stats.(statsToUse{j});
    endj=startj-1+size(stat,2);
    trainingSet.dataMatrix.X(:,startj:endj)=stat;
    startj=endj+1;
end
trainingSet.dataMatrix.Y=trainingSet.spotInfo(:,end);

% Append new training set to exisiting training set if necessary.
if appendTrainingSet==0
    trainingSet.version= 'ver. 2.0';
    trainingSet.appended=0;             % 0, if it's a newly created training set. 1, if it's a training set that had been appended with new spots.
    disp('Saving the training set...')
    save(fullfile(pwd,trainingSetName),'trainingSet')
elseif appendTrainingSet==1
    %Should check for duplicates!!
    disp('Append new spot information and stats to existing training set...')
    trainingSetToAppend=trainingSet;
    load(trainingSetName)
    trainingSet.appended=1;
    % Find spots that were not in the training set.
    a=trainingSetToAppend.spotInfo(:,1:3);
    b=trainingSet.spotInfo(:,1:3);
    [~,~,iAppend]=union(b,a,'rows');
    
    % Find duplicated spots.
    disp('Find duplicated spots....')
    [d,iOrigi,iUpdate]=intersect(b,a,'rows');
    
    % Update the classification for duplicated spots if necessary.
    if ~isempty(iUpdate)
        disp('Duplicated spot:')% Print out the spot information for debugging.
        d
        disp('Update the classification...')
        trainingSet.dataMatrix.Y(iOrigi)=trainingSetToAppend.dataMatrix.Y(iUpdate);
        trainingSet.spotInfo(iOrigi,4)=trainingSetToAppend.spotInfo(iUpdate,4);
    end
    
    % Append the rest of the newly picked spots.
    if ~isempty(iAppend)
        disp('Append newly picked spots to the training set...')
        trainingSet.spotInfo=[trainingSet.spotInfo;trainingSetToAppend.spotInfo(iAppend,:)];
        
        for k=1:length(fieldsToAdd)
            if ~strcmp(fieldsToAdd{k},'spotInfoNumberInWorm')
                if ~sum(strcmp(fieldsToAdd{k},{'dataMat','dataFit'}))
                    trainingSet.stats.(fieldsToAdd{k})=[trainingSet.stats.(fieldsToAdd{k});trainingSetToAppend.stats.(fieldsToAdd{k})(iAppend,:)];
                else
                    trainingSet.stats.(fieldsToAdd{k})=[trainingSet.stats.(fieldsToAdd{k});trainingSetToAppend.stats.(fieldsToAdd{k})(iAppend,:,:)];
                end
            end
        end
        trainingSet.dataMatrix.Y=[trainingSet.dataMatrix.Y;trainingSetToAppend.dataMatrix.Y(iAppend,:)];
    end
    
    
    disp('Recalculate SVD...')
    % Recalculate SVD
    allDataPixelValues=trainingSet.stats.dataMat(:,:);
    %center data
    trainingSet.allDataCenter=mean(allDataPixelValues,1);
    allDataPixelValuesCentered=allDataPixelValues-repmat(trainingSet.allDataCenter,size(allDataPixelValues,1),1);
    [~,~,v]=svd(allDataPixelValuesCentered,0);
    trainingSet.svdBasisRightMultiplier=(v')^(-1);
    rotatedAllDataPixelValues=allDataPixelValuesCentered*trainingSet.svdBasisRightMultiplier;
    %trainingSet.stats.sv=zeros(length(trainingSet.spotInfo),5);
    for i=1:5
        %take the first five coordinates in the new basis
        trainingSet.stats.(['sv' num2str(i)])=rotatedAllDataPixelValues(:,i);
    end;
    
    trainingSet.dataMatrix.X=[trainingSet.dataMatrix.X;trainingSetToAppend.dataMatrix.X(iAppend,:)];
    %trainingSet.dataMatrix.X(:,end-4:end)=trainingSet.stats.sv;
    trainingSet.FileName=trainingSetName;
    disp('Saving the training set...')
    save(fullfile(pwd,trainingSetName),'trainingSet')
end

fprintf('There are %d spots in total in the training set.\n', length(trainingSet.dataMatrix.Y))
fprintf('%d good spots and %d bad spots were chosen.\n', sum(trainingSet.dataMatrix.Y),sum(trainingSet.dataMatrix.Y==0));

end
