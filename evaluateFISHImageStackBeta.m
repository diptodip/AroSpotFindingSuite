function evaluateFISHImageStackBeta(stackSuffix,toWrite,varargin)  %nameMod
%  =============================================================
%  Name: evaluateFISHImageStack.m          %nameMod
%  Version: 1.5, 24 Apr 2012     %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%  License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%  Website:
%  http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%  =============================================================
% [worms]= evaluateFISHImageStack(stackName,toWrite,varargin)  %nameMod
% toWrite is flag [0,1] to
% tell to write or not (if doing batch immediately followed by processing
% then no need to write since will pass it in and write after next function
% stackName is the filename of the metamorph image stack (e.g. cy001.stk).
%
% varargin tells the program if your files are in the default file format, especially if you are doing batch processing (say after
% you've corrected a few and are satisfied with your classification scheme and want to do all the stacks in your directory).
% It has 3 possible states.
% 1) 'n'  - this means your files are not in the default format or you aren't sure whether they are or not and want to be prompted
% 2) nothing...don't pass anything in - this means your files are in the default format (whether you are or aren't doing batch processing)
% 3)  arguments in the following order: (1) unique identifier for your image stack, (2) dye, (3) name of your segmentation file,  [optional (4) Number of planes in the stack]} - this option is useful for batch processing because you can just pass in the appropriate information
%
% Do not use spaces in file names.  Use underscores or camelCase.  If you
% are getting file read errors check to make sure you aren't using illegal
% characters.
% The default is for the program to use this stackName to determine the
% unique identifier for this stack and the dye.  It asks whether you want
% this or whether you want to enter this info yourself.
% If default is chosen, the program assumes that this filename will be in the format dyeStacknumber.stk
% Make sure the 'dye' name has no digits in it or modify the stackSuffix assignment below
% Uses readmm to input image stack.
%
% -------------------------------------------------------------------------
% Beta Version: April 27th 2012
%   * Load in segStacks generated by createSegImages
%   * Apply Laplacian Filter and do bleach correction on segmented stacks
%   * Input stackSuffix instead of stackName (e.g. _Pos3)
%   * Can inpute probeName as the first variable in varargin to specify
%   which probe to work with.  Otherwise, it will work through all the
%   channels available in this position.


%shrunkenRsquared=60,.7
%scd=70,.5
%meanrsquare=60,.9

versionName='v1.6beta';

quickAndDirtyStats=0;
if quickAndDirtyStats
    %Then use meanrsquare
    cutoffPercentile=60;%decrease for fewer
    cutoffStatisticValue=.9;
    badSliceCutoffStatisticValue=.9;
    cutoffStat='meanrsquare';
    cutoffStatBackup='meanIntensity';
    disp('Using quickAndDirty gaussian fitting method');
else
    %Then use scd
    %Note that to have it evaluate more spots you either increase the
    %cutoff percentile or decrease the cutoffStatisticValue
    %In other words, if A% have to be below the value X, then this means
    %that A% are already below the value X+1, but you would have to wait
    %longer for A% to be below the value X-1
    %Similarly, if A% are below X, then A-1% are also below X and have
    %been, but you would have to wait longer for A+1% to be below X.
    
    %9/19/11 - changed to 50,0.3...may need to rerun worm file making
    %9/20/11 - changed to 70,0.3...may need to rerun worm file making
    %9/21/11 - changed to 70, .7 using the new 2D gaussian fitting function
    %Note that I will have to evaluate how these are for each
    %dye/probe...70,.7works well for cy/Cel_xol1
    %70.,.7 works just adequately for tmr/Cel_sdc2
    %70,.7 is really close for alexa/Cel_sea2 and Cel_sea1...need to have
    %it take more spots
    %10/21/11 Change to 70 .6 for sex1
    cutoffPercentile=70;
    cutoffStatisticValue=.7;
    badSliceCutoffStatisticValue=.3;
    cutoffStat='scd';
    cutoffStatBackup='intensity';
    %disp('Using non-quickAndDirty 2D gaussian fitting method');
end;

% Omit the process of checking file format

% toWrite=1;
% if size(varargin,2)==1
%     toWrite=varargin{1};
% end;


%getDirectory
directoryName=pwd;
disp('Determine probes to be done:')
d = dir(['*' stackSuffix '_segStacks.mat']);
if nargin >2                                 % Determine probes to be done
        probeName=varargin{1};
    else
        colorCount=1;
        for k=1:length(d)
            prefix=strrep(d(k).name,[stackSuffix '_SegStacks.mat'],'');
            prefix=strrep(prefix,'_','');
            if ~sum(strcmp(prefix,{'trans','dapi','mask'}))
                if ~exist([prefix stackSuffix '_wormGaussianFit.mat'],'file')
                probeName{colorCount}=prefix;
                colorCount=colorCount+1;
                else
                  disp(['All worms in ' prefix ' ' stackSuffix ' are done.' ])
                end
                
            end
            
        end
end

    


totalSpotsTested=0;
if colorCount~=1
    disp(probeName)
for pi=1:length(probeName)
if exist([probeName{pi} '_' stackSuffix '_SegStacks.mat'],'file')
    % segImages have been created.
    stopN=30;%21Oct11 changed back to 30.  20Sep11 changed to 15
    badSliceStopN=5;
    
    spotSize=[7 7];
    offset=floor((spotSize-1)/2);
    %disp(offset);
    % the stack in old version means the whole image
    disp('Loading the segmented stacks...')
    load([probeName{pi} '_' stackSuffix '_SegStacks.mat'])   
    wormNum=length(segStacks);     % Check the number of worms
    stackSize=size(segStacks{1});
    stackH=stackSize(3);
    disp([num2str(wormNum) ' worms in stack. ' num2str(stackH) ' slices']);
    
    
    
    % 9/20/11
    %Image and mask is now read in
    %Correct for bleaching
    %[stack,bleachFactors]=correctForBleach(stack,segments);
    %%%%%%%%%%%%%
    
    % Correct for bleaching and apply laplacian-gaussian filter on it
    disp('Preprocess them for finding regional maxima ....')
    [segStacks,bleachFactors]=correctBleachAndFilter(segStacks)%,wormNum);
    totalTime=0;
    worms=cell(wormNum,1);
            for ci=1:wormNum
                
                
                % Do not load in metaInfo anymore.
                %if ~exist([stackPrefix '_metaInfo.mat'])
                %    worms{ci}.metaInfo{size(stack,3)}=[];
                %else
                %    load([stackPrefix '_metaInfo.mat']);
                %    worms{ci}.metaInfo=metaInfo;
                %end;
                
                worms{ci}.segStackFile=[probeName{pi} stackSuffix '_SegStacks.mat'];
                %worms{ci}.mask=currpolys{ci};
                %worms{ci}.boundingBox=regionprops(double(currpolys{ci}),'BoundingBox');
                worms{ci}.numberOfPlanes=stackH;
                %worms{ci}.stackPrefix=stackPrefix;
                %worms{ci}.stackFileType=stackFileType;
                %These cutoff info were added 9/19/11...I will go back and
                %modify all files made so far to include them
                worms{ci}.cutoffStat=cutoffStat;
                worms{ci}.cutoffStatisticValue=cutoffStatisticValue;
                worms{ci}.cutoffPercentile=cutoffPercentile;
                
                %%%%%%%%%%% 20Sep2011
                worms{ci}.bleachFactors=bleachFactors;
                %%%%%%%%%%%
                
                
                
                % for zi=1:size(stack,3)%just set up the stack
                %parfor crashes here - Alex 8.17.11
                %     currentSlice=imcrop(stack(:,:,zi),bb.BoundingBox).*wormMask;
                %     wormImage(:,:,zi)=currentSlice;
                %currentSlice=imcrop(Lfish(:,:,zi),bb.BoundingBox).*wormMask;
                %wormLfish(:,:,zi)=currentSlice;
                % end;
                
                wormImage=segStacks{ci};
                wormMask=segMasks{ci};
                
                
                %     regMax=wormImage.*imregionalmax(wormImage,26);
                %     disp(['reg maxima' num2str(sum(regMax(:)>0))]);
                worms{ci}.regMaxSpots=[];%4 element vector [r c z value]
                spotInfo={};
                %spotInfo=[];
                %disp('Morphological filtering in 3D');
                [spotRSorted3D,spotCSorted3D,spotZSorted3D,spotVSorted3D,spotVFiltSorted3D]=morphFilterSpotImage3D(wormImage,wormMask);%will this be too long?    %nameMod
                count=1;
                fprintf('%d regional maxima in image %s\n',length(spotRSorted3D),[probeName{pi} stackSuffix ': ' num2str(ci) ]);
                fprintf('# Putative spots evaluated: ');
                
                for zi=1:stackH
                    %fprintf('Doing slice %d: ',zi);
                    spotStatsFilt=[];
                    spotStatsFiltAmp=[];
                    spotRFilt=spotRSorted3D(spotZSorted3D==zi);
                    spotCFilt=spotCSorted3D(spotZSorted3D==zi);
                    spotVSorted=spotVSorted3D(spotZSorted3D==zi);
                    allSpotVSortedFilt=spotVFiltSorted3D(spotZSorted3D==zi);
                    %fprintf('spotRFilt size: %d', size(spotRFilt));
                    
                    %This adds one slice at a time
                    worms{ci}.regMaxSpots=[worms{ci}.regMaxSpots;[spotRFilt,spotCFilt,ones(size(spotRFilt))*zi,spotVSorted,allSpotVSortedFilt]];
                    if ~isempty(spotRFilt)
                        runningTotal=0;
                        tic
                        for si=1:length(spotRFilt)
                            %                 if mod(si,200)==0
                            %                     disp(['Doing spot ' num2str(si)]);
                            %end;
                            %%%%%%%%%%%%%%%%%%%%%
                            NR=max(1,spotRFilt(si)-offset(1));
                            if NR==1
                                %then too close to top
                                SR=spotSize(1);
                            else
                                if spotRFilt(si)+offset(1)>size(wormMask,1)
                                    SR=size(wormMask,1);
                                    NR=size(wormMask,1)-(spotSize(1)-1);
                                else
                                    SR=NR+(spotSize(1)-1);
                                end;
                            end;
                            WC=max(1,spotCFilt(si)-offset(2));
                            if WC==1
                                %then too close to top
                                EC=spotSize(2);
                            else
                                if spotCFilt(si)+offset(2)>size(wormMask,2)
                                    EC=size(wormMask,2);
                                    WC=size(wormMask,2)-(spotSize(2)-1);
                                else
                                    EC=WC+spotSize(2)-1;
                                end;
                            end;
                            dataMat=wormImage(NR:SR,WC:EC,zi);
                            dataColumn=wormImage(NR:SR,WC:EC,:);
                            %adjacentSlices
                            adjacentSlices=[];
                            if zi>1
                                adjacentSlices=wormImage(NR:SR,WC:EC,zi-1);
                            end;
                            if zi<size(wormImage,3)
                                adjacentSlices=cat(3,adjacentSlices,wormImage(NR:SR,WC:EC,zi+1));
                            end;
                            
                            regMaxDataMat=imregionalmax(dataMat(2:6,2:6));
                            %dataMat=wormLfish(NR:SR,WC:EC,zi);
                            %only take if it doesn't overlap the border
                            maskMat=wormMask(NR:SR,WC:EC);
                            %also, sometimes there is a bad pixel and so in the middle
                            %of the spot there is a really bright one and a zero...this
                            %is too often counted as a spot.  so eliminate those
                            [minR,minC]=find(dataMat==min(dataMat(:)));
                            %fprintf('min(maskMat(:)=%f and norm=%f and nRegmax = %d for spot %d\n',min(maskMat(:)),norm([4-minR(1),4-minC(1)]),sum(regMaxDataMat(:)),si);
                            if min(maskMat(:))~=0 && norm([4-minR(1),4-minC(1)])>1.5 && sum(regMaxDataMat(:))<=3%can't be more than 3 regional maxima in the 5x5 box
                                
                                %fprintf('Trying spot %d now\n',si);
                                
                                %%%%%
                                % 24 April 2012
                                %the spot information will now be stored in matrices at the worm level and spotInfo will hold the row number
                                %One vector for each statistic.  Not as compact as a matrix but is robust against adding and deleting statistics
                                %
                                %The upshot is that here, spotInfo needs to change to spotDataVectors which is a struct with the various vectors
                                
                                %If this is the first spot, initialize these dataVectors -
                                %We want to preinitialize so that it isn't growing the vectors by adding one at a time
                                %But this is tricky because we don't want to overdo it and defeat the memory savings.
                                %We can always delete unused space at the end.
                                %So allocate 1/4 the # of regional maxima.
                                %Note that I also split locations from a nested struct to two different matrices.
                                %This way all the fields in spotDataVectors are at the same level making it easier to loop over them
                                nToAllocate=floor(length(spotRSorted3D)/4);
                                
                                if ~exist('spotDataVectors','var')
                                    
                                    spotDataVectors=struct(...
                                        'locationStack',zeros(nToAllocate,3),...
                                        'rawValue',zeros(nToAllocate,1),...
                                        'filteredValue',zeros(nToAllocate,1),...
                                        'spotRank',zeros(nToAllocate,1),...
                                        'dataMat',zeros(nToAllocate,7,7));
                                    
                                end
                                if ~isfield(spotDataVectors,'locationStack')
                                    %spotDataVectors.locationWorm=zeros(nToAllocate,3);
                                    spotDataVectors.locationStack=zeros(nToAllocate,3);
                                    spotDataVectors.rawValue=zeros(nToAllocate,1);
                                    spotDataVectors.filteredValue=zeros(nToAllocate,1);
                                    spotDataVectors.spotRank=zeros(nToAllocate,1);
                                    spotDataVectors.dataMat=zeros(nToAllocate,7,7);
                                end;
                                %Also Have a check to see if these get filled up and then allocate more
                                if count>length(spotDataVectors.rawValue)
                                    %spotDataVectors.locationWorm=[spotDataVectors.locationWorm;zeros(nToAllocate,3)];
                                    spotDataVectors.locationStack=[spotDataVectors.locationStack;zeros(nToAllocate,3)];
                                    spotDataVectors.rawValue=[spotDataVectors.rawValue;zeros(nToAllocate,1)];
                                    spotDataVectors.filteredValue=[spotDataVectors.filteredValue;zeros(nToAllocate,1)];
                                    spotDataVectors.spotRank=[spotDataVectors.spotRank;zeros(nToAllocate,1)];
                                    spotDataVectors.dataMat=[spotDataVectors.dataMat;zeros(nToAllocate,7,7)];
                                    
                                end
                                
                                
                                
                                %Discard the coordination in the whole picture
                                %spotDataVectors.locationWorm(count,:)=[spotRFilt(si) spotCFilt(si) zi];
                                %spotInfo{count}.locations.worm=[spotRFilt(si) spotCFilt(si) zi];
                                
                                %locationWormXY=[colToX(spotCFilt(si)) rowToY(spotRFilt(si))];
                                %newcoords=translateToNewCoordinates(locationWormXY,bb.BoundingBox,'StoL');
                                %spotDataVectors.locationStack(count,:)=[yToRow(newcoords(2)) xToCol(newcoords(1)) zi];
                                spotDataVectors.locationStack(count,:)=[spotRFilt(si) spotCFilt(si) zi];
                                %spotInfo{count}.locations.stack=[yToRow(newcoords(2)) xToCol(newcoords(1)) zi];
                                
                                spotDataVectors.rawValue(count)=spotVSorted(si);
                                %spotInfo{count}.rawValue=spotVSorted(si);
                                
                                spotDataVectors.filteredValue(count)=allSpotVSortedFilt(si);
                                %spotInfo{count}.filteredValue=allSpotVSortedFilt(si);
                                
                                spotDataVectors.spotRank(count)=si;
                                %spotInfo{count}.spotRank=si;
                                
                                spotDataVectors.dataMat(count,:,:)=dataMat;
                                %disp(size(spotDataVectors.dataMat))
                                %spotInfo{count}.dataMat=dataMat;
                                %These following are all redundant with worms
                                %localDir=regexp(regexp(cd,'\\','split'),'/','split');
                                %spotInfo{count}.directory=localDir{end};
                                %spotInfo{count}.dye=dye;
                                %spotInfo{count}.stackSuffix=stackSuffix;
                                %spotInfo{count}.stackName=stackName;
                                %spotInfo{count}.wormNumber=ci;
                                
                                
                                try
                                    
                                    %moved to 1p2
                                    %old way:
                                    %tgs=calculateFISHStatistics(dataMat,spotRFilt(si)-NR+1,spotCFilt(si)-WC+1,adjacentSlices);      %nameMod
                                    tgs=calculateFISHStatistics(dataColumn,spotRFilt(si)-NR+1,spotCFilt(si)-WC+1,zi,quickAndDirtyStats,bleachFactors);       %nameMod
                                    %disp('just got stats from calculateFISHStatistics_1p4 on line 206');
                                    %disp(tgs.statValues);
                                    
                                    
                                    statFields=fieldnames(tgs.statValues);
                                    
                                    %If this is the first spot, initialize these dataVectors -
                                    %We want to preinitialize so that it isn't growing the vectors by adding one at a time
                                    %But this is tricky because we don't want to overdo it and defeat the memory savings.
                                    %We can always delete unused space at the end.
                                    %So allocate 1/4 the # of regional maxima.
                                    if ~isfield(spotDataVectors,statFields{1})
                                        for iFN=1:size(statFields,1)
                                            if ~strcmp(statFields{iFN},'dataFit')%everything else is a single number
                                                spotDataVectors.(statFields{iFN})=zeros(nToAllocate,1);
                                            else
                                                s=size(tgs.statValues.dataFit);
                                                spotDataVectors.(statFields{iFN})=zeros(nToAllocate,7,7);
                                            end;
                                        end;
                                    end;
                                    %Also Have a check to see if these get filled up and then allocate more
                                    if count>length(spotDataVectors.(statFields{1}))
                                        for iFN=1:size(statFields,1)
                                            if ~strcmp(statFields{iFN},'dataFit')%everything else is a single number
                                                spotDataVectors.(statFields{iFN})=[spotDataVectors.(statFields{iFN});zeros(nToAllocate,1)];
                                            else
                                                s=size(tgs.statValues.dataFit);
                                                spotDataVectors.(statFields{iFN})=[spotDataVectors.(statFields{iFN});zeros(nToAllocate,7,7)];
                                            end;
                                        end;
                                    end;
                                    
                                    
                                    
                                    
                                    for iFN=1:size(statFields,1)
                                        if ~strcmp(statFields{iFN},'dataFit')%everything else is a single number
                                            spotDataVectors.(statFields{iFN})(count)=tgs.statValues.(statFields{iFN});
                                        else
                                            spotDataVectors.(statFields{iFN})(count,:,:)=tgs.statValues.(statFields{iFN});
                                        end;
                                    end;
                                    %spotInfo{count}.stat=tgs;
                                    
                                    
                                    
                                    if mod(count,100)==0
                                        fprintf('%d  ',count);
                                    end;
                                    %                           Note that the statistic isn't complete here.  Don't have the trainingSet info, so can't complete the SVD stuff
                                    count=count+1;
                                    %disp(count)
                                    if isfield(tgs,'message')
                                        spotStatsFilt=[spotStatsFilt;0];
                                        spotStatsFiltAmp=[spotStatsFiltAmp;0];
                                        %fprintf('Message at spot %d:  %s\n',si,tgs.message);
                                    else
                                        %spotStatsFilt=[spotStatsFilt;tgs.gof.mean.adjrsquare];
                                        %spotStatsFilt=[spotStatsFilt;tgs.statValues.shrunkenRsquared];
                                        spotStatsFilt=[spotStatsFilt;tgs.statValues.(cutoffStat)];
                                        spotStatsFiltAmp=[spotStatsFiltAmp;tgs.statValues.(cutoffStatBackup)];
                                        %                                      spotStatsFilt=[spotStatsFilt;tgs.statValues.meanrsquare];
                                        %                                      spotStatsFiltAmp=[spotStatsFiltAmp;tgs.statValues.meanIntensity];
                                    end;
                                    clear('tgs');
                                catch ME
                                    %                                          ME
                                    %                                          ME.stack.file
                                    %                                          ME.stack.name
                                    %                                          ME.stack.line
                                    %                                                                     disp(['spot ' num2str(si) ' failed']);
                                    spotStatsFilt=[spotStatsFilt;0];
                                    spotStatsFiltAmp=[spotStatsFiltAmp;0];
                                end;
                                %%%%%%%%%%%%%%%%%%%
                                
                                %stopping criterion%do at least stopN
                                %                 maxPreviousN=max(spotStatsFilt(max(1,si-stopN):si));
                                %                 medianPreviousN=median(spotStatsFilt(max(1,si-stopN):si));
                                
                                %3/15/10 adjusted percentile from 90 to 60.
                                %stopN is 30 so this means that 12 (instead of 3) of the last
                                %30 have to be less than 0.9...no isn't
                                %this backwards?
                                %the thing is that it isn't particularly costly
                                %so run a few more.  so be conservative
                                %9/19/11...seems to be too stringent at (scd,
                                %70%, 0.5)...let more through
                                %20Sep2011 - adjusted to stopN=15.  also, if there aren't any in the first 5 above .5 then it probably isn't a good slice and can quit
                                if length(spotStatsFilt)==badSliceStopN
                                    if sum(spotStatsFilt>badSliceCutoffStatisticValue)==0
                                        break
                                    end;
                                end;
                                prcPreviousN=prctile(spotStatsFilt(max(1,length(spotStatsFilt)-stopN):length(spotStatsFilt)),cutoffPercentile);
                                %3/15/10 adjusted from 10 to stopN
                                if si>=stopN
                                    %fprintf('prcPreviousN = %f at spot
                                    %%d\n',prcPreviousN,si);
                                    
                                    if prcPreviousN<cutoffStatisticValue %e.g. if 70% of the last 15 spots are less than .7, then stop
                                        %disp('Breaking');
                                        break
                                    end;
                                end;
                                %%%%%%%%%%%%%%%%%%%%%%
                                
                            end;
                            
                        end;%end of for si in spotRFilt
                    else
                        %disp('No regional maxima in this slice/worm');
                        
                    end;%if isempty(spotRFilt)
                    %disp(spotStatsFilt);
                    tend=toc;
                    totalTime=totalTime+tend;
                    totalSpotsTested=totalSpotsTested+length(spotStatsFilt);
                    %disp(['Worm ' num2str(ci) ' slice ' num2str(zi) ':' num2str(tend/length(spotStatsFilt)) ' per spot for ' num2str(length(spotStatsFilt)) ' spots done in ' num2str(tend) ' seconds. ' num2str(totalTime) ' total seconds of ' num2str(length(spotRFilt)) ' potential spots in slice']);
                end;%for zi=1:size(stack)
                
                count=count-1;%This needs to be done because of the way count was used and incremented
                %disp(size(spotDataVectors.dataFit))
                %disp(size(spotDataVectors.dataMat))
                
                % Remove all spots or rows that don't have stats evaluated
                spotNum=length(spotDataVectors.rawValue);
                statsToUse=fieldnames(spotDataVectors);                
                testData=zeros(spotNum,length(statsToUse));
                
                for stati=1:length(statsToUse)
                    if ~sum(strcmp(statsToUse{stati},{'dataFit','dataMat'}))
                        width=size(spotDataVectors.(statsToUse{stati}),2);
                        testData(:,stati:(stati+width-1))=spotDataVectors.(statsToUse{stati});
                    end
                end
                
                % Make sure to remove spots that don't have stats evaluated.
                zeroLines=(testData~=0);
                nullStatsIndex=(sum(zeroLines,2)==0); % If all stats equal zero, index=1;
                
                for stati=1:length(statsToUse)
                    if sum(strcmp(statsToUse{stati},{'dataFit','dataMat'}))
                        spotDataVectors.(statsToUse{stati})=spotDataVectors.(statsToUse{stati})(nullStatsIndex~=1,:,:);
                    else
                        spotDataVectors.(statsToUse{stati})=spotDataVectors.(statsToUse{stati})(nullStatsIndex~=1,:);
                    end
                end
                spotNum=length(spotDataVectors.rawValue);
                spotDataVectors.spotInfoNumberInWorm=[1:spotNum]'; %Unique ID for each spots
               
                
                %add to the worm
                worms{ci}.spotDataVectors=spotDataVectors;
                %worms{ci}.spotInfo=spotInfo;
                clear('spotDataVectors');
                
                
                
                
                
                
                worms{ci}.goodWorm=1;
                worms{ci}.quickAndDirtyStats=quickAndDirtyStats;
                %9 July2011.  added mfilename so can know which version generated
                %This no longer works well since it is all named the same thing.  But the date helps
                worms{ci}.functionVersion={mfilename; versionName; datestr(now)};
                disp([num2str(count) ' done']);
                disp([ 'Worm -' num2str(ci) ' Position - ' stackSuffix ' Dye - ' probeName{pi} ':' ])
                disp(['Total elapsed time is ' num2str(totalTime) ' for ' num2str(totalSpotsTested) ' total spots tested  and ' num2str(count) ' total spots in this worm ' num2str(totalTime/totalSpotsTested) ' seconds per spot']);
            end
            if toWrite
                fprintf('Saving worms to:  %s\n',fullfile(directoryName,[probeName{pi} stackSuffix '_wormGaussianFit.mat']));
                save(fullfile(directoryName,[probeName{pi} '_' stackSuffix '_wormGaussianFit']),'worms');
            else
                disp('Will write after processing');
                whos worms
                
            end
            disp(['All worms in ' probeName{pi} ' ' stackSuffix 'are done.' ])

    end
    
   end
end



% figure(200);
% plot(spotInfo(:,2),spotInfo(:,3),'o','MarkerFaceColor','g');
% toc
clear('Lfish');
clear('stack');

end


% CHANGELOG
%
% 26 March 2010
% Changed the arguments used to call the function. Made it easier to run a batch job with files in a nonstandard format
%

%10May2011
%Added fields: stackPrefix,numberOfPlanes,stackFileType, metaInfo, quickAndDirtyStats (1,0) to worm.
%Need to adjust existing wormGaussianFit files


%20 Sept 2011
%Correct for bleaching when image and mask is read in...and add raw and
%bleached as a statistic


%24 April 2012
%Allison suggested memory improvement.
%Structs take up a lot of overhead.
%This becomes a huge problem when there are lots of spots because each spotInfo has a struct to hold all the stat values.  This is really unnecessary since those are all doubles (8 bytes) and could be stored in a vector.  Instead, each struct field has an overhead of 60 bytes
%The stuff that is currently contained in spot info could be stored in matrices at the worm level.  spotInfo could hold the row number of the matrix.
%This becomes a more of a problem when images are LoG filtered first since more spots pass teh cutoffs below
%worm structures take up ~50MB/worm in working memory even though the actual disk space is ~3MB/worm for the compressed .mat file

%30 April 2012
%Revise evaluateFISHImageStackBeta to be able to load in the data format
%created by createSegImages.
