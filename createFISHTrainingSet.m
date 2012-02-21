function trainingSet=createFISHTrainingSet(stackName,probeName,varargin)
%  =============================================================
%  Name: createFISHTrainingSet.m  %nameMod
%  Version: 1.4.2, 18 Oct 2011  %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%  License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%  Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%  =============================================================
% trainingSet=createFISHTrainingSet(stackName,probeName)  %nameMod
% stackName is the filename of the metamorph image stack (e.g. cy001.stk).
% probeName is the name of the probe used.  (e.g. C_el_elt2).
%
%Do not use spaces in file names.  Use underscores or camelCase.  If you
%are getting file read errors check to make sure you aren't using illegal
%characters.
%The default is for the program to use this stackName to determine the
%unique identifier for this stack and the dye.  It asks whether you want
%this or whether you want to enter this info yourself.
% If default is chosen, the program assumes that this filename will be in the format dyeStacknumber.stk
% Make sure the 'dye' name has no digits in it or modify the stackSuffix assignment below
% Uses readmm to input image stack.
%
%
% saves trainingSet information in the current directory in several files.
% goldSpots...mat and rejected Spots...mat are the positive and negative
% examples in the training set If these files already exist in the current
% directory, the program just uses them.  So delete or move them if you
% want to create a new training set.
%
% Assumes that there is also a file in the directory called
% segmenttransStacknumber.mat (e.g. segmenttrans001.mat) This file has a
% single variable called currpolys which is a cell array.  currpolys{i} is
% a matrix mask the size of the image (e.g. 1024x1024) with 1 where the
% specimen is and 0 where it is not
%
% Program flow:
%     uses training set or creates a new one (calling identifySpots3.m)
%     note that it passes which slice identifySpots3 will start on. Right
%       now this is set to NumSlices/8 - to change, modify the call to identifySpots (the 3rd argument)
%     calculates statistics of the spots in the training set (calling calculateFISHStatistics.m)%nameMod
%     returns a data structure called trainingSet which collects this information

%21April2011
%Modified so that goldSpot file and rejectedSpotFile can contain data from
%other stacks...for example if they were added in the reviewFISHClassification %nameMod
%function.
%3 May 2011...identifySpots gives goldSpots and rejectedSpots info of the   %nameMod
%value of the spot and also the worm number and spotInfo in worms...this is
%for the new way of making all the worms files first so as to precalculate
%all the statistics
%The fields in goldSpots and rejectedSpots give the actual file name
%including the suffix (.stk or .tif) with '_' instead of '.'
%11May2011
%This function now never loads the stack.  It leaves that to
%identifySpots_1p4
%or not at all.  identifySpots_1p4 just uses info from worms   %nameMod
%20 Sep 2011
%calls identifySpots_1p4p1 which does bleachCorrection
%18Oct2011.
%Cleaned up.  Got rid of detritus and bugs...added in use of dataMatSize info

doAnotherFile=0;
if size(varargin,2)>0
    defaultFileFormat=varargin{1};
    if size(varargin,2)>1
        doAnotherFile=varargin{2};
    end;
else
    defaultFileFormat=input(sprintf('Is the file format the default one? \n\tDefault format is:  \n\tStack Name:   \tdyeStackNumber.stk  \t\te.g.  cy001.stk\n\tSegmentation file name: \tsegmenttransStackNumber.mat,\te.g.  segmenttrans001.mat\ny or n?  [y]    '),'s');
end;
if isempty(defaultFileFormat)
    defaultFileFormat='y';
end;

if strcmp(defaultFileFormat,'n')
    stackSuffix=input('Enter a unique identifier for the files associated with this image stack (e.g. 023).    ','s');
    dye=input('Enter the dye name (e.g. cy).    ','s');
    segmentsName=input('Enter the name of the segmentation/mask file.    ','s');
    stackPrefix=input('Enter the stack prefix (e.g. "cy").    ','s');
    stackFileType= input('Enter the stack file type (e.g. ".stk", ".tiff").   ','s');
else
    [dye, stackSuffix, ~, wormGaussianFitName, segmentsName, metaInfoName]=parseStackName(stackName);
end;
curdir=cd;
trainingDir=curdir;
trainingSetName=['trainingSet_' dye '_' probeName '.mat'];
disp(trainingSetName);
close all;
disp('Identifying spots');
disp(fullfile(trainingDir,['goldSpots_' dye '_' probeName '.mat']));
%returns N x 3 matrix of center points of manually curated spots
if exist(fullfile(trainingDir,trainingSetName),'file')
    disp('Using already existing training set.  Delete file before running if want to redo');
    clear('stack');
    load(fullfile(trainingDir,trainingSetName));
    %trainingSet=trainFISHClassifier(dye,stackSuffix,trainingSet,0);   %nameMod
    trainingSet=trainFISHClassifier(trainingSet,0);%Modified 31March2011   %nameMod
else
    %The only reason to load the wormGaussianFitFile here is to check on
    %the number of planes.  This can be dealt with by loading the metainfo
    %file
    if exist(fullfile(trainingDir,metaInfoName),'file')
        load(metaInfoName);
        sz=size(metaInfo,2);
        clear('metaInfo');
    else
        load(wormGaussianFitName);
        sz=[size(worms{1}.mask) worms{1}.numberOfPlanes];
        clear('worms');
    end;
    %9/17/11 - added possiblity to do another file
    if  ~exist(fullfile(trainingDir,['goldSpots_' dye '_' probeName '.mat']),'file')
        disp('Need to identify spots...');
        %need currpolys
        load(segmentsName);
        
        [goldSpotsData,rejectedSpotsData]=identifySpots(currpolys,floor(sz(3)/8),dye,stackSuffix);%might as well start up in the worm    %nameMod
        goldSpots.(regexprep(stackName,'\.','_'))=goldSpotsData;
        rejectedSpots.(regexprep(stackName,'\.','_'))=rejectedSpotsData;
        save(fullfile(trainingDir,['goldSpots_' dye '_' probeName '.mat']),'goldSpots');
        save(fullfile(trainingDir,['rejectedSpots_' dye '_' probeName '.mat']),'rejectedSpots');
        save(fullfile(trainingDir,['goldSpotsUnamended_' dye '_' probeName '.mat']),'goldSpots');
        save(fullfile(trainingDir,['rejectedSpotsUnamended_' dye '_' probeName '.mat']),'rejectedSpots');
    else
        disp('loading preexisting spot files');
        load(fullfile(trainingDir,['goldSpots_' dye '_' probeName '.mat']));
        load(fullfile(trainingDir,['rejectedSpots_' dye '_' probeName '.mat']));
        if doAnotherFile
            disp('Need to identify spots from another file...');
            %need currpolys
            load(segmentsName);
            
            %NOTE - need to caution if redoing a stack that has already
            %been done...ultimately, will need to integrate this into
            %identifySpots so that these already done ones show up as red
            runGUI=1;
            if isfield(goldSpots,regexprep(stackName,'\.','_')) || isfield(rejectedSpots,regexprep(stackName,'\.','_'))
                contin=input(sprintf('Spots from %s are already part of the manually annotated list.\nThe GUI does not currently look these up, and you will likely select many of the same spots/non-spots again.\nWhile I will make sure that only one copy of each spot is listed, this will waste your time a bit.\nProbably better is just to use a different image stack.\nIf you wish to continue with this stack, press c<Enter>.  If you do not want to continue, press any other key followed by <Enter>:  ',stackName),'s');
                if ~strcmp(contin,'c')
                    runGUI=0;
                end;
            end;
            if runGUI
                if ~isfield(goldSpots,regexprep(stackName,'\.','_'))
                    [goldSpotsData,rejectedSpotsData]=identifySpots(currpolys,floor(sz(3)/8),dye,stackSuffix);%might as well start up in the worm    %nameMod
                    goldSpots.(regexprep(stackName,'\.','_'))=[];
                end;
                
                goldSpots.(regexprep(stackName,'\.','_'))=unique([goldSpots.(regexprep(stackName,'\.','_')); goldSpotsData],'rows');
                
                if ~isfield(rejectedSpots,regexprep(stackName,'\.','_'))
                    rejectedSpots.(regexprep(stackName,'\.','_'))=[];
                end;
                
                rejectedSpots.(regexprep(stackName,'\.','_'))=unique([rejectedSpots.(regexprep(stackName,'\.','_')); rejectedSpotsData],'rows');
                
                % Make sure no spots are both rejected and gold
                inBoth=intersect(rejectedSpots.(regexprep(stackName,'\.','_')),goldSpots.(regexprep(stackName,'\.','_')),'rows');
                if ~isempty(inBoth)
                    %if there are some, remove them from both
                    gd=[]; rd=[];
                    for dbi=1:size(inBoth,1)
                        for gi=1:size(goldSpots.(regexprep(stackName,'\.','_')),1);
                            if isequal(inBoth(dbi,:),goldSpots.(regexprep(stackName,'\.','_'))(gi,:))
                                gd=[gd, dbi];
                            end;
                        end;
                        for ri=1:size(rejectedSpots.(regexprep(stackName,'\.','_')),1);
                            if isequal(inBoth(dbi,:),rejectedSpots.(regexprep(stackName,'\.','_'))(ri,:))
                                rd=[rd, dbi];
                            end;
                        end;
                    end;
                    goldSpots.(regexprep(stackName,'\.','_'))(gd,:)=[];
                    rejectedSpots.(regexprep(stackName,'\.','_'))(rd,:)=[];
                end;
                save(fullfile(trainingDir,['goldSpots_' dye '_' probeName '.mat']),'goldSpots');
                save(fullfile(trainingDir,['rejectedSpots_' dye '_' probeName '.mat']),'rejectedSpots');
            end;
        end;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Go through and make sure that all the goldSpots and rejected spots can be found
        %in the worms files.  This might not be the case if the user has
        %added some non-regional maxima...This should not be necessary any
        %more but it is a check
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [goldSpots,rejectedSpots]=ensureSpotsFilesMatchWormFiles(goldSpots,rejectedSpots,trainingDir,probeName);
    end;%if ~exist goldSpots
    
    
    
    
    stacksInGoldRejectedSpots=sort(union(fieldnames(goldSpots),fieldnames(rejectedSpots)));
    
    trainingSet.categoryVector=[];
    trainingSet.spotInfo={};
    allDataPixelValues=[];
    
    for csi=1:size(stacksInGoldRejectedSpots,1)
        newSpotsHaveBeenAddedToWorms=0;
        stats.gold={};
        stats.rejected={};
        disp(sprintf('Going through stack %s',stacksInGoldRejectedSpots{csi}));
        [dye, stackSuffix, ~, wormGaussianFitName, segmentsName,metaInfoName]=parseStackName(regexprep(stacksInGoldRejectedSpots{csi},'_','\.'));
        load(segmentsName);
        load(wormGaussianFitName);
        dataMatSize=size(worms{1}.spotInfo{1}.dataMat);
        %can't be at the edge of the field of scope image
        if isfield(goldSpots,stacksInGoldRejectedSpots{csi})
            goldSpotsData=goldSpots.(stacksInGoldRejectedSpots{csi});
            goldSpotsData=goldSpotsData(find(goldSpotsData(:,1)>floor(dataMatSize(1)/2) & goldSpotsData(:,2)>floor(dataMatSize(2)/2) & goldSpotsData(:,1)<=sz(1)-floor(dataMatSize(1)/2) & goldSpotsData(:,2)<=sz(2)-floor(dataMatSize(2)/2)),:);
        else
            goldSpotsData=[];
        end;
        if isfield(rejectedSpots,stacksInGoldRejectedSpots{csi})
            rejectedSpotsData=rejectedSpots.(stacksInGoldRejectedSpots{csi});
            rejectedSpotsData=rejectedSpotsData(find(rejectedSpotsData(:,1)>floor(dataMatSize(1)/2) & rejectedSpotsData(:,2)>floor(dataMatSize(2)/2) & rejectedSpotsData(:,1)<=sz(1)-floor(dataMatSize(1)/2) & rejectedSpotsData(:,2)<=sz(2)-floor(dataMatSize(2)/2)),:);
        else
            rejectedSpotsData=[];
        end;
        disp('finding manually curated gold spots' );
        %makes a connectivity matrix (pairwise connections) if they are max 1
        %square apart in 26 connected.  it puts the 1 in the row index of the
        %one with the bigger intensity if they are connected and a -1 in the entry
        %of the one with the smaller intensity.
        %then at the end, go through the rows and only take indices where
        %sum(abs(row))==sum(row) and is not zero
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%18Oct2011...I think this is now redundant since only regional
        %%%maxima are considered
        goldSpotConnMat=zeros(size(goldSpotsData,1));%make pairwise connectMatrix
        for i=1:size(goldSpotsData,1)-1
            for j=i+1:size(goldSpotsData,1)
                if norm(goldSpotsData(i,1:3)-goldSpotsData(j,1:3))<=sqrt(3)
                    if goldSpotsData(i,4)>=goldSpotsData(j,4)
                        goldSpotConnMat(i,j)=1;
                        goldSpotConnMat(j,i)=-1;
                    else
                        goldSpotConnMat(i,j)=-1;
                        goldSpotConnMat(j,i)=1;
                    end;
                end;
            end;
        end;
        [row,col]=find(goldSpotConnMat);
        spotCenters=goldSpotsData;
        rowsToEliminate=[];%row indices are the indices in spotCenters
        
        for ri=1:length(row)%parfor not really useful here
            if sum(goldSpotConnMat(row(ri),:))~=sum(abs(goldSpotConnMat(row(ri),:)))
                rowsToEliminate=[rowsToEliminate row(ri)];
            end;
        end;
        
        spotCenters(rowsToEliminate,:)=[];
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        segments=zeros(size(currpolys{1}));
        for i=1:length(currpolys)%parfor here should work
            currpolys{i}=currpolys{i}>0;
            segments=segments+currpolys{i};
        end;
        %Find the locations in worms 4Oct2011
        [~,wormNumbers,spotInfoNumbersInWorms]=findSpotInfoInWormBasedOnLocation(spotCenters,worms,currpolys);
        for regi=1:size(spotCenters,1)
            loc=spotCenters(regi,1:3);
            %This shouldn't happen anymore%%%%%%%%%%%%%
            if ~spotInfoNumbersInWorms(regi)
                worms=addNewSpotToWorm_1p4p1(loc,wormNumbers(regi),worms);
                newSpotsHaveBeenAddedToWorms=newSpotsHaveBeenAddedToWorms+1;
                spotInfoNumbersInWorms(regi)=size(worms{wormNumbers(regi)}.spotInfo,2);%because it was added at the end
            end;
            %%%%%%%%%%%%%%%%%
            stats.gold{size(stats.gold,2)+1}.wormNumber=wormNumbers(regi);
            stats.gold{size(stats.gold,2)}.spotInfoNumberInWorm=spotInfoNumbersInWorms(regi);
        end;
        %%%%%%%%%%%%%  Rejected Spots ####################################
        disp('finding rejected spots');
        %makes a connectivity matrix (pairwise connections) if they are max 1
        %square apart in 26 connected.  it puts the 1 in the row index of the
        %one with the bigger intensity if they are connected and a -1 in the entry
        %of the one with the smaller intensity.
        %then at the end, go through the rows and only take indices where
        %sum(abs(row))==sum(row) and is not zero
        
        %%%18Oct2011...again, I don't think this is necessary any more
        %%%because all spots are regional maxima since the data is from
        %%%worms
        rejectedSpotConnMat=zeros(size(rejectedSpotsData,1));%make pairwise connectMatrix
        for i=1:size(rejectedSpotsData,1)-1
            for j=i+1:size(rejectedSpotsData,1)
                if norm(rejectedSpotsData(i,1:3)-rejectedSpotsData(j,1:3))<=sqrt(3)
                    if rejectedSpotsData(i,4)>=rejectedSpotsData(j,4)
                        rejectedSpotConnMat(i,j)=1;
                        rejectedSpotConnMat(j,i)=-1;
                    else
                        rejectedSpotConnMat(i,j)=-1;
                        rejectedSpotConnMat(j,i)=1;
                    end;
                end;
            end;
        end;
        %imshow(imscale(rejectedSpotConnMat));
        [row,col]=find(rejectedSpotConnMat);
        spotCenters=rejectedSpotsData;
        rowsToEliminate=[];%row indices are the indices in spotCenters
        
        for ri=1:length(row)
            if sum(rejectedSpotConnMat(row(ri),:))~=sum(abs(rejectedSpotConnMat(row(ri),:)))
                rowsToEliminate=[rowsToEliminate row(ri)];
            end;
        end;
        
        spotCenters(rowsToEliminate,:)=[];
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        clear('segments');
        %Find the locations in worms 4Oct2011
        [~,wormNumbers,spotInfoNumbersInWorms]=findSpotInfoInWormBasedOnLocation(spotCenters,worms,currpolys);
        
        
        for regi=1:size(spotCenters,1)
            loc=spotCenters(regi,1:3);
            if ~spotInfoNumbersInWorms(regi)
                worms=addNewSpotToWorm_1p4p1(loc,wormNumbers(regi),worms);
                newSpotsHaveBeenAddedToWorms=newSpotsHaveBeenAddedToWorms+1;
                spotInfoNumbersInWorms(regi)=size(worms{wormNumbers(regi)}.spotInfo,2);%because it was added at the end
            end;
            stats.rejected{size(stats.rejected,2)+1}.wormNumber=wormNumbers(regi);
            stats.rejected{size(stats.rejected,2)}.spotInfoNumberInWorm=spotInfoNumbersInWorms(regi);
            
        end;
        
        %%%%%%%%%%%%%%%%%  add info to training set %%%%%%%%%%%%%%
        for gi=1:size(stats.gold,2)
            iCurrentlyAdding=size(trainingSet.spotInfo,2)+1;
            spotInfo=worms{stats.gold{gi}.wormNumber}.spotInfo{stats.gold{gi}.spotInfoNumberInWorm};
            trainingSet.spotInfo{iCurrentlyAdding}.classification.manual=1;
            trainingSet.spotInfo{iCurrentlyAdding}.wormNumber=stats.gold{gi}.wormNumber;
            trainingSet.spotInfo{iCurrentlyAdding}.spotInfoNumberInWorm=stats.gold{gi}.spotInfoNumberInWorm;
            fieldsToAdd={'dataMat';'locations';'directory';'dye';'stackName';'stackSuffix';'stat'};
            for ftai=1:size(fieldsToAdd,1)
                trainingSet.spotInfo{iCurrentlyAdding}.(fieldsToAdd{ftai})=spotInfo.(fieldsToAdd{ftai});
                allDataPixelValues=[allDataPixelValues; trainingSet.spotInfo{iCurrentlyAdding}.dataMat(:)'];
            end;
        end;
        %%%%Rejected spots
        for ri=1:size(stats.rejected,2)
            iCurrentlyAdding=size(trainingSet.spotInfo,2)+1;
            spotInfo=worms{stats.rejected{ri}.wormNumber}.spotInfo{stats.rejected{ri}.spotInfoNumberInWorm};
            trainingSet.spotInfo{iCurrentlyAdding}.classification.manual=0;
            trainingSet.spotInfo{iCurrentlyAdding}.wormNumber=stats.rejected{ri}.wormNumber;
            trainingSet.spotInfo{iCurrentlyAdding}.spotInfoNumberInWorm=stats.rejected{ri}.spotInfoNumberInWorm;
            for ftai=1:size(fieldsToAdd,1)
                trainingSet.spotInfo{iCurrentlyAdding}.(fieldsToAdd{ftai})=spotInfo.(fieldsToAdd{ftai});
                allDataPixelValues=[allDataPixelValues; trainingSet.spotInfo{iCurrentlyAdding}.dataMat(:)'];
            end;
        end;
        if newSpotsHaveBeenAddedToWorms
            disp(['Saving worms to ' dye stackSuffix '_wormGaussianFit.mat with ' num2str(newSpotsHaveBeenAddedToWorms) ' new spots added']);
            save([dye stackSuffix '_wormGaussianFit'],'worms');
        end;
        
    end;%go through all the stacks
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SVD %%%%%%%%%%%%%%%
    %center data
    trainingSet.allDataCenter=mean(allDataPixelValues,1);
    allDataPixelValuesCentered=allDataPixelValues-repmat(trainingSet.allDataCenter,size(allDataPixelValues,1),1);
    [~,~,v]=svd(allDataPixelValuesCentered,0);
    trainingSet.svdBasisRightMultiplier=(v')^(-1);
    rotatedAllDataPixelValues=allDataPixelValuesCentered*trainingSet.svdBasisRightMultiplier;
    for i=1:size(trainingSet.spotInfo,2)
        for j=1:5  %take the first five coordinates of in the new basis
            trainingSet.spotInfo{i}.stat.statValues.(['sv' num2str(j)])=rotatedAllDataPixelValues(i,j);
        end;
    end;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    trainingSet.quickAndDirtyStats=worms{1}.quickAndDirtyStats;
    trainingSet.name=trainingSetName;
    %9 July 2011.  add field with function version
    trainingSet.functionVersion=mfilename;
    save(fullfile(trainingDir,trainingSet.name),'trainingSet');
    trainingSet=trainFISHClassifier(trainingSet,0);   %nameMod
end;
close all;
end