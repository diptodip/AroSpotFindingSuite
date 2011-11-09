function [worms]= evaluateFISHImageStack_(stackName,toWrite,varargin)  %nameMod
%  =============================================================
%  Name: evaluateFISHImageStack.m          %nameMod
%  Version: 1.4.2, 9 Nov 2011     %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%  License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%  Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
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

%10May2011
%Added fields: stackPrefix,numberOfPlanes,stackFileType, metaInfo, quickAndDirtyStats (1,0) to worm.
%Need to adjust existing wormGaussianFit files

%shrunkenRsquared=60,.7
%scd=70,.5
%meanrsquare=60,.9

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


if nargin==2%default file format
    %Decide whether this is .stk default format (cy001.stk) or .tif default
    %format (a594__Pos0.tif)
    stackPrefix=regexp(stackName,'\.','split');
    stackFileType=stackPrefix{2};
    stackPrefix=stackPrefix{1};
    if strcmp(stackFileType,'stk')
        stackSuffix=collectDigits(stackName,1);
        dye=regexp(stackName,stackSuffix,'split');
        dye=dye{1};
        segmentsName=['segmenttrans' stackSuffix '.mat'];
    elseif strcmp(stackFileType,'tif') || strcmp(stackFileType,'tiff')
        stackSuffix=regexp(stackPrefix,'_','split');
        dye=stackSuffix{1};
        stackSuffix=stackSuffix{end};
        segmentsName=['segmenttrans' '_' stackSuffix '.mat'];
        load([stackPrefix '_metaInfo.mat']);
        numberOfPlanes=size(metaInfo,2);
        
    end;
elseif nargin==3%prompt for file format
    defaultFileFormat=input(sprintf('Is the file format the default one? \n\tDefault format is:  \n\tStack Name:   \tdyeStackNumber.stk  \t\te.g.  cy001.stk\n\tSegmentation file name: \tsegmenttransStackNumber.mat,\te.g.  segmenttrans001.mat\ny or n?  [y]    '),'s');
    if isempty(defaultFileFormat)
        defaultFileFormat='y';
    end;
    stackSuffix=input('Enter a unique identifier for the files associated with this image stack (e.g. 023).    ','s');
    dye=input('Enter the dye name (e.g. cy).    ','s');
    segmentsName=input('Enter the name of the segmentation/mask file.    ','s');
    stackPrefix=regexp(stackName,'\.','split');
    stackFileType=stackPrefix{2};
    stackPrefix=stackPrefix{1};
    if ~exist([stackPrefix '_metaInfo.mat'])
        numberOfPlanes=str2num(input('How many planes are there in the stack?','s'));
    else
        load([stackPrefix '_metaInfo.mat']);
        numberOfPlanes=size(metaInfo,2);
    end;
    
elseif nargin==5
    stackSuffix=varargin{1};
    dye=varargin{2};
    segmentsName=varargin{3};
    stackPrefix=regexp(stackName,'\.','split');
    stackFileType=stackPrefix{2};
    stackPrefix=stackPrefix{1};
    load([stackPrefix '_metaInfo.mat']);
    numberOfPlanes=size(metaInfo,2);
elseif nargin==6
    stackSuffix=varargin{1};
    dye=varargin{2};
    segmentsName=varargin{3};
    stackPrefix=regexp(stackName,'\.','split');
    stackFileType=stackPrefix{2};
    stackPrefix=stackPrefix{1};
    numberOfPlanes=varargin{4};
    
else
    error('evaluateFISHImageStack_1p4 called with wrong number of arguments.  There should be 2,3,5 or 6');    %nameMod
end;



% toWrite=1;
% if size(varargin,2)==1
%     toWrite=varargin{1};
% end;
worms={};

%getDirectory
directoryName=pwd;

totalSpotsTested=0;
if exist(segmentsName) %then is stack that wasn't cut off
    %no plotting..see gaussEvalSpotsForShow for that
    stopN=30;%21Oct11 changed back to 30.  20Sep11 changed to 15
    badSliceStopN=5;
    
    spotSize=[7 7];
    offset=floor((spotSize-1)/2);
    %disp(offset);
    load(segmentsName);
    if ~isempty(currpolys)
        segments=zeros(size(currpolys{1}));
        
        parfor i=1:length(currpolys)
            currpolys{i}=currpolys{i}>0;
            segments=segments+currpolys{i};
        end;
        
        
        if strcmp(stackFileType,'stk')
            stack=readmm(stackName);
            stack=double(stack.imagedata);
        elseif strcmp(stackFileType,'tiff') || strcmp(stackFileType,'tif')
            stackFileType='tiff';
            stack=readTiffStack(stackName,numberOfPlanes);
        else
            disp('File type not supported');
        end;
        
        
        % 9/20/11 
        %Image and mask is now read in
        %Correct for bleaching
        [stack,bleachFactors]=correctForBleach_1p4(stack,segments);
        %%%%%%%%%%%%%
        
        
        
        totalTime=0;
        disp([num2str(length(currpolys)) ' worms in stack. ' num2str(size(stack,3)) ' slices']);
        for ci=1:length(currpolys)
            if max(currpolys{ci}(:)>0)
                bb=regionprops(double(currpolys{ci}),'BoundingBox');
                %             disp(max(currpolys{ci}(:)));
                %             disp(bb.BoundingBox);
                wormMask=imcrop(currpolys{ci},bb.BoundingBox);
                wormImage=zeros(size(wormMask,1),size(wormMask,2),size(stack,3));
                %wormLfish=zeros(size(wormMask,1),size(wormMask,2),size(stack,3));
                if ~exist([stackPrefix '_metaInfo.mat'])
                    worms{ci}.metaInfo{size(stack,3)}=[];
                else
                    load([stackPrefix '_metaInfo.mat']);
                    worms{ci}.metaInfo=metaInfo;
                end;
                
                worms{ci}.stackName=stackName;
                worms{ci}.mask=currpolys{ci};
                worms{ci}.boundingBox=regionprops(double(currpolys{ci}),'BoundingBox');
                worms{ci}.numberOfPlanes=size(stack,3);
                worms{ci}.stackPrefix=stackPrefix;
                worms{ci}.stackFileType=stackFileType;
                %These cutoff info were added 9/19/11...I will go back and
                %modify all files made so far to include them
                worms{ci}.cutoffStat=cutoffStat;
                worms{ci}.cutoffStatisticValue=cutoffStatisticValue;
                worms{ci}.cutoffPercentile=cutoffPercentile;
                
                %%%%%%%%%%% 20Sep2011
                worms{ci}.bleachFactors=bleachFactors;
                %%%%%%%%%%%
                
                
                
                for zi=1:size(stack,3)%just set up the stack
                    %parfor crashes here - Alex 8.17.11
                    currentSlice=imcrop(stack(:,:,zi),bb.BoundingBox).*wormMask;
                    wormImage(:,:,zi)=currentSlice;
                    %currentSlice=imcrop(Lfish(:,:,zi),bb.BoundingBox).*wormMask;
                    %wormLfish(:,:,zi)=currentSlice;
                end;
                %     regMax=wormImage.*imregionalmax(wormImage,26);
                %     disp(['reg maxima' num2str(sum(regMax(:)>0))]);
                worms{ci}.regMaxSpots=[];%4 element vector [r c z value]
                spotInfo={};
                %spotInfo=[];
                %disp('Morphological filtering in 3D');
                [spotRSorted3D,spotCSorted3D,spotZSorted3D,spotVSorted3D,spotVFiltSorted3D]=morphFilterSpotImage3D(wormImage,wormMask);%will this be too long?    %nameMod
                count=1;
                fprintf('%d regional maxima in image %s\n',length(spotRSorted3D),[stackName ':' num2str(ci) ]);
                fprintf('# Putative spots evaluated: ');
                
                for zi=1:size(stack,3)
                    %fprintf('Doing slice %d: ',zi);
                    spotStatsFilt=[];
                    spotStatsFiltAmp=[];
                    spotRFilt=spotRSorted3D(find(spotZSorted3D==zi));
                    spotCFilt=spotCSorted3D(find(spotZSorted3D==zi));
                    spotVSorted=spotVSorted3D(find(spotZSorted3D==zi));
                    allSpotVSortedFilt=spotVFiltSorted3D(find(spotZSorted3D==zi));
                    
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
                                spotInfo{count}.locations.worm=[spotRFilt(si) spotCFilt(si) zi];
                                wormLocationXY=[colToX(spotCFilt(si)) rowToY(spotRFilt(si))];
                                newcoords=translateToNewCoordinates(wormLocationXY,bb.BoundingBox,'StoL');
                                spotInfo{count}.locations.stack=[yToRow(newcoords(2)) xToCol(newcoords(1)) zi];
                                spotInfo{count}.rawValue=spotVSorted(si);
                                spotInfo{count}.filteredValue=allSpotVSortedFilt(si);
                                spotInfo{count}.spotRank=si;
                                spotInfo{count}.dataMat=dataMat;
                                localDir=regexp(regexp(cd,'\\','split'),'/','split');
                                spotInfo{count}.directory=localDir{end};
                                spotInfo{count}.dye=dye;
                                spotInfo{count}.stackSuffix=stackSuffix;
                                spotInfo{count}.stackName=stackName;
                                spotInfo{count}.wormNumber=ci;
                                
                                
                                try
                                    %moved to 1p2
                                    %old way:
                                    %tgs=calculateFISHStatistics(dataMat,spotRFilt(si)-NR+1,spotCFilt(si)-WC+1,adjacentSlices);      %nameMod
                                    tgs=calculateFISHStatistics(dataColumn,spotRFilt(si)-NR+1,spotCFilt(si)-WC+1,zi,quickAndDirtyStats,bleachFactors);       %nameMod
                                    % disp('just got stats from calculateFISHStatistics_1p4 on line 206');
                                    %disp(tgs);
                                    spotInfo{count}.stat=tgs;
                                    if mod(count,100)==0
                                        fprintf('%d  ',count);
                                    end;
                                    %                           Note that the statistic isn't complete here.  Don't have the trainingSet info, so can't complete the SVD stuff
                                    count=count+1;
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
                                catch ME
%                                           ME
%                                           ME.stack.file
%                                           ME.stack.name
%                                           ME.stack.line
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
                                    %fprintf('prcPreviousN = %f at spot %d\n',prcPreviousN,si);
                                    
                                    if prcPreviousN<cutoffStatisticValue %e.g. if 70% of the last 15 spots are less than .7, then stop
                                        %disp('Breaking');
                                        break
                                    end;
                                end;
                                %%%%%%%%%%%%%%%%%%%%%%
                            end;
                        end;
                    else
                        %disp('No regional maxima in this slice/worm');
                        
                    end;
                    %disp(spotStatsFilt);
                    tend=toc;
                    totalTime=totalTime+tend;
                    totalSpotsTested=totalSpotsTested+length(spotStatsFilt);
                    %disp(['Worm ' num2str(ci) ' slice ' num2str(zi) ':' num2str(tend/length(spotStatsFilt)) ' per spot for ' num2str(length(spotStatsFilt)) ' spots done in ' num2str(tend) ' seconds. ' num2str(totalTime) ' total seconds of ' num2str(length(spotRFilt)) ' potential spots in slice']);
                end;
                
                worms{ci}.spotInfo=spotInfo;
                worms{ci}.goodWorm=1;
                worms{ci}.quickAndDirtyStats=quickAndDirtyStats;
                %9 July2011.  added mfilename so can know which version generated
                worms{ci}.functionVersion={mfilename; datestr(now)};
                count=count-1;%This needs to be done because of the way count was used and incremented
                disp([num2str(count) ' done']);
                disp([ stackName ':' num2str(ci) ' Total elapsed time is ' num2str(totalTime) ' for ' num2str(totalSpotsTested) ' total spots tested  and ' num2str(count) ' total spots in this worm ' num2str(totalTime/totalSpotsTested) ' seconds per spot']);
            end;
        end;
    end;
    
    if toWrite
        fprintf('Saving worms to:  %s',fullfile(directoryName,[dye stackSuffix '_wormGaussianFit.mat\n']));
        save(fullfile(directoryName,[dye stackSuffix '_wormGaussianFit']),'worms');
    else
        disp('Will write after processing');
        
    end;
    % figure(200);
    % plot(spotInfo(:,2),spotInfo(:,3),'o','MarkerFaceColor','g');
    % toc
    clear('Lfish');
    clear('stack');
    
end;
end

% CHANGELOG
%
% 26 March 2010
% Changed the arguments used to call the function. Made it easier to run a batch job with files in a nonstandard format
%
%20 Sept 2011
%Correct for bleaching when image and mask is read in...and add raw and
%bleached as a statistic
