function trainingSet=createSpotTrainingSet(stackName,probeName,varargin)
%% ========================================================================
%   Name: createSpotTrainingSet
%   Version: 2.5 25th Apr. 2013
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
%   Updates:
%       - Built-in version check to make sure the new stats are added.
%       - Fix a bug that introduces mismatches of stats and spotInfo.
%       
%
%   Attribution: Wu, AC-Y and SA Rifkin. spotFinding Suite version 2.5, 2013 [journal citation TBA]
%   License: Creative Commons Attribution-ShareAlike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%   Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%   Email for comments, questions, bugs, requests:  Allison Wu < dblue0406 at gmail dot com >, Scott Rifkin < sarifkin at ucsd dot edu >
%
%% ========================================================================

[dye, stackSuffix, wormGaussianFitName, segStacksName,~]=parseStackNames(stackName);
trainingSetName=['trainingSet_' dye '_' probeName '.mat'];

if isempty(varargin)
    appendTrainingSet=0;
else
    appendTrainingSet=varargin{1};
end

if exist(trainingSetName, 'file')
    reply='p';
    while ~strcmpi(reply,'n') && ~strcmpi(reply,'y')
        reply=input('There is an exisiting training set. Do you want to overwrite it? \n(Otherwise, the program will append new spots to the existing training set.) \n Y/N [N]:','s');
        if isempty(reply)
            reply='N';
        end
        
        if strcmpi(reply,'y')
            appendTrainingSet=0;
        else strcmpi(reply,'n')
            appendTrainingSet=1;
        end
    end;
else
    appendTrainingSet=0;
end



%Identify Spots
posNumber=str2num(cell2mat(regexp(stackSuffix,'\d+','match')));

disp('Load in spots information...')
load(wormGaussianFitName);
% Version check
if ~strcmp('v2.5',worms{1}.version)
    display('Detect an older version. Update the wormGaussianFit with new stats.')
    worms=addStatsToWormGaussian(worms);
end
wormNum=size(worms);
stackH=worms{1}.numberOfPlanes;
w=[1:wormNum];
spotsInWorm=zeros(wormNum);
for wi=1:wormNum
    spotsInWorm(wi)=length(worms{wi}.spotDataVectors.rawValue);
end
[~,index]=sort(spotsInWorm,'descend');
w=w(index);

disp('Load in segmented stacks...')
load(segStacksName);

disp('Identify spots in worms...')
for wi=1:wormNum
    [goodSpots,badSpots,doAnotherWorm]=identifySpots(floor(stackH/8),segStacks,segMasks,worms,w(wi));
    if wi==1
        goldSpotsData=goodSpots;
        rejectedSpotsData=badSpots;
    else
        if ~isempty(goodSpots)
            goldSpotsData=[goldSpotsData;goodSpots];
        end
        if ~isempty(badSpots)
            rejectedSpotsData=[rejectedSpotsData;badSpots];
        end
    end
    if ~doAnotherWorm
        break
<<<<<<< HEAD
=======
    else %doAnotherWorm
        disp(['# good spots: ' num2str(length(goodSpots)) ' # bad spots: ' num2str(length(badSpots))]);
        if wi==wormNum
            disp('No more worms to do in this image!');
        end;
>>>>>>> spotFindingSuite_v2.5.1
    end;
end
clear segStacks


goldNum=size(goldSpotsData,1);
rejNum=size(rejectedSpotsData,1);
spotNum=goldNum+rejNum;

% [posNumber, wormNumber, spotIndex, classification]
trainingSet.spotInfo=[ones(goldNum,1)*posNumber goldSpotsData(:,end-1:end) ones(goldNum,1)];
trainingSet.spotInfo=[trainingSet.spotInfo; ones(rejNum,1)*posNumber rejectedSpotsData(:,end-1:end) zeros(rejNum,1)];
trainingSet.stats=struct;
% Add stats info to training set
fieldsToAdd=fields(worms{1}.spotDataVectors);
for fta=1:length(fieldsToAdd)
    for k=1:2
    for wi=1:length(worms)
        wormData=worms{wi};
        if k==1
            wormIndex=(trainingSet.spotInfo(:,2)==wi & trainingSet.spotInfo(:,end)==1);
        else
            wormIndex=(trainingSet.spotInfo(:,2)==wi & trainingSet.spotInfo(:,end)==0);
        end
        spotIndex=(trainingSet.spotInfo(wormIndex,3));
        if ~sum(strcmp(fieldsToAdd{fta},{'spotInfoNumberInWorm','nucLocation','distanceToNuc'}))
            if ~isfield(trainingSet.stats, fieldsToAdd{fta})
                if ~sum(strcmp(fieldsToAdd{fta},{'dataMat','dataFit'}))
                    trainingSet.stats.(fieldsToAdd{fta})=wormData.spotDataVectors.(fieldsToAdd{fta})(spotIndex,:);
                else
                    trainingSet.stats.(fieldsToAdd{fta})=wormData.spotDataVectors.(fieldsToAdd{fta})(spotIndex,:,:);
                end
            else
                if ~sum(strcmp(fieldsToAdd{fta},{'dataMat','dataFit'}))
                    trainingSet.stats.(fieldsToAdd{fta})=[trainingSet.stats.(fieldsToAdd{fta});wormData.spotDataVectors.(fieldsToAdd{fta})(spotIndex,:)];
                else
                    trainingSet.stats.(fieldsToAdd{fta})=[trainingSet.stats.(fieldsToAdd{fta});wormData.spotDataVectors.(fieldsToAdd{fta})(spotIndex,:,:)];
                end
            end
        end
    end
    end
    
end

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
statsToUse = {'intensity';'totalHeight';'estimatedFloor';'scnmse';'scnrmse';'scr';'scd';'sce';...
    'prctile_50';'prctile_60';'prctile_70';'prctile_80';'prctile_90';...
    'fraction_center';'fraction_plusSign';'fraction_3box';'fraction_5star';'fraction_5box';'fraction_7star';'fraction_3ring';...
    'raw_center';'raw_plusSign';'raw_3box';'raw_5star';'raw_5box';'raw_7star';'raw_3ring';'total_area';...
    'sv1';'sv2';'sv3';'sv4';'sv5';...
    'absDeltaPlusSign';'deltaPlusSign';'absPlusSignDelta';'plusSignPvalue';...
    'absDeltaStarSign';'deltaStarSign';'absStarSignDelta';'starSignPvalue';...
    'absDeltaCenterBox';'deltaCenterBox';'absCenterBoxDelta';'centerBoxPvalue';'ratioSigmaXY';...
    'totalAreaRandPvalue';'cumSumPrctile90RP';'cumSumPrctile70RP';'cumSumPrctile50RP';'cumSumPrctile30RP';...
    'cumSumPrctile90';'cumSumPrctile70';'cumSumPrctile50';'cumSumPrctile30'};

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
    trainingSet.version= 'ver. 2.5, new stats added';
    trainingSet.appended=0;             % 0, if it's a newly created training set. 1, if it's a training set that had been appended with new spots.
    disp('Saving the training set...')
    save(fullfile(pwd,trainingSetName),'trainingSet')
elseif appendTrainingSet==1
    %Should check for duplicates!!
    disp('Append new spot information and stats to existing training set...')
    trainingSetToAppend=trainingSet;
    load(trainingSetName)
    % Check if new stats are added.
    if ~strcmp('ver. 2.5, new stats added',trainingSet.version)
        display('Detect an older version. Update the trainingSet with new stats.')
        trainingSet=addStatsToTrainingSet(trainingSet,1);
    end
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
            if ~sum(strcmp(fieldsToAdd{k},{'spotInfoNumberInWorm','nucLocation','distanceToNuc'}))
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

end
trainingSet.FileName=trainingSetName;
disp('Saving the training set...')
save(fullfile(pwd,trainingSetName),'trainingSet')

fprintf('There are %d spots in total in the training set.\n', length(trainingSet.dataMatrix.Y))
fprintf('%d good spots and %d bad spots were chosen.\n', sum(trainingSet.dataMatrix.Y),sum(trainingSet.dataMatrix.Y==0));

end
