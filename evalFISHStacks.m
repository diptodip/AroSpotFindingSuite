function evalFISHStacks(stackName,varargin)  %nameMod
%% =============================================================
%   Name:       evalFISHStacks.m
%   Version:    2.5.1, 25th Apr. 2013
%   Author:     Allison Wu, Scott Rifkin
%   Command:    evalFISHStacks(stackName,varargin)
%   Description:
%       - evaluate regional maxima in segmented image stacks in the associated segStack.mat
%       - Use 70% cut off percentile.
%       - stackName:    stack file name (cy_001_SegStacks.mat), can be simplified as {dye}_{stackSuffix}, eg. cy_001
%
%   Files required:     {dye}_{stackSuffix}_SegStacks.mat
%   Files generated:    {dye}_{stackSuffix}_wormGaussianFit.mat

%   Update:
%       2012 Jul. 30th: use try/catch loop to deal with memory problem.  If a
%       memory problem occurs, it will clear out the segStacks variable and
%       re-allocate the memory available in MatLab.
%       2013 Apr. 25th: add in new stats
%       2013 May 7th: fix the edge spot problem

%   Note: Do not use spaces in file names.  Use underscores or camelCase.
%         If you are getting file read errors check to make sure you aren't using illegal characters.
%% ========================================================================


%shrunkenRsquared=60,.7
%scd=70,.5
%meanrsquare=60,.9

versionName='v2.5';

if exist('Aro_parameters.m','file')
   run('Aro_parameters.m');
else
    
    
    cutoffPercentile=90;
    cutoffStatisticValue=.7;
    %cutoffPercentile=90; % for yeast data
    %cutoffStatisticValue=.5;
    badSliceCutoffStatisticValue=.3;
    stopN=30;%21Oct11 changed back to 30.  20Sep11 changed to 15
    badSliceStopN=5;
    cutoffStat='scd';
end;


cutoffStatBackup='intensity';

%getDirectory
stackName=regexprep(stackName,'_','\.');
nameSplit=regexp(stackName,'\.','split');
nameSplit=nameSplit(~cellfun('isempty',nameSplit));
dye=nameSplit{1};
stackSuffix=nameSplit{2};

switch nestedOrFlatDirectoryStructure
    case 'flat'
        segStacksFileName=[dye '_' stackSuffix '_SegStacks.mat'];
        wormFitFileName=[dye '_' stackSuffix '_wormGaussianFit.mat'];
    case 'nested'
        segStacksFileName=fullfile(SegStacksDir,dye,[dye '_' stackSuffix '_SegStacks.mat']);
        wormFitFileName=fullfile(WormGaussianFitDir,dye,[dye '_' stackSuffix '_wormGaussianFit.mat']);
end;



fprintf('segStacks File Name: %s \n', segStacksFileName)
fprintf('wormGaussianFit File Name: %s \n', wormFitFileName)


totalSpotsTested=0;
if exist(segStacksFileName,'file')
    % segImages have been created.
    
    spotSize=[7 7];
    offset=floor((spotSize-1)/2);
    %disp(offset);
    % the stack in old version means the whole image
    disp('Loading the segmented stacks...')
    load(segStacksFileName)
    if ~isempty(segStacks)
        wormNum=length(segStacks);     % Check the number of worms
        stackH=size(segStacks{1},3);
        disp([num2str(wormNum) ' worms in stack. ' num2str(stackH) ' slices']);
        
        
        % Correct for bleaching (and apply laplacian-gaussian filter on it if
        % necessary)....
        disp('Preprocess them for finding regional maxima ....')
        [segStacks,bleachFactors]=correctBleachAndFilter(segStacks);
        totalTime=0;
        worms=cell(wormNum,1);
        
        for ci=1:wormNum
            if ~exist('segStacks','var')
                load segStacks_tmp
            end
            
            %try
            worms{ci}.version=versionName;
            worms{ci}.segStackFile=segStacksFileName;
            worms{ci}.numberOfPlanes=stackH;
            worms{ci}.cutoffStat=cutoffStat;
            worms{ci}.cutoffStatisticValue=cutoffStatisticValue;
            worms{ci}.cutoffPercentile=cutoffPercentile;
            worms{ci}.bleachFactors=bleachFactors(:,ci);
            
            wormImage=segStacks{ci};
            wormMask=segMasks{ci};
            
            worms{ci}.regMaxSpots=[];%4 element vector [r c z value]
            spotInfo={};
            %spotInfo=[];
            %disp('Morphological filtering in 3D');
            [spotRSorted3D,spotCSorted3D,spotZSorted3D,spotVSorted3D,spotVFiltSorted3D]=morphFilterSpotImage3D(wormImage,wormMask);%will this be too long?    %nameMod
            count=1;
            fprintf('%d regional maxima in %s image of worm %d in position %s. \n',length(spotRSorted3D), dye, ci, stackSuffix);
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
                tic
                if ~isempty(spotRFilt)
                    runningTotal=0;
                    
                    for si=1:length(spotRFilt)
                        %                 if mod(si,200)==0
                        %                     disp(['Doing spot ' num2str(si)]);
                        %end;
                        %%%%%%%%%%%%%%%%%%%%%
                        % Check the top border
                        NR=max(1,spotRFilt(si)-offset(1));
                        % Check the bottom border
                        SR=min(size(wormMask,1),spotRFilt(si)+offset(1));
                        % Check the left border
                        WC=max(1,spotCFilt(si)-offset(2));
                        % Check the right border
                        EC=min(size(wormMask,2),spotCFilt(si)+offset(2));
                        
                        dataMat=zeros(spotSize); % fill in the out of border pixels with zeros.
                        dataColumn=zeros(spotSize(1),spotSize(2),stackH);
                        % position the dataMat
                        w=EC-WC;
                        l=SR-NR;
                        if NR==1
                            dataMatRRange=[spotSize(1)-l:spotSize(1)];
                        elseif SR==size(wormMask,1)
                            dataMatRRange=[1:1+l];
                        else
                            dataMatRRange=[1:spotSize(1)];
                        end
                        
                        if WC==1
                            dataMatCRange=[spotSize(2)-w:spotSize(2)];
                        elseif EC==size(wormMask,2)
                            dataMatCRange=[1:1+w];
                        else
                            dataMatCRange=[1:spotSize(2)];
                        end
                        
                        dataMat(dataMatRRange,dataMatCRange)=wormImage(NR:SR,WC:EC,zi);
                        dataColumn(dataMatRRange,dataMatCRange,:)=wormImage(NR:SR,WC:EC,:);
                        regMaxDataMat=imregionalmax(dataMat(2:6,2:6));
                        %dataMat=wormLfish(NR:SR,WC:EC,zi);
                        
                        %also, sometimes there is a bad pixel and so in the middle
                        %of the spot there is a really bright one and a zero...this
                        %is too often counted as a spot.  so eliminate those
                        [minR,minC]=find(dataMat==min(dataMat(dataMat(:)>0)));
                        %fprintf('min(maskMat(:)=%f and norm=%f and nRegmax = %d for spot %d\n',min(maskMat(:)),norm([4-minR(1),4-minC(1)]),sum(regMaxDataMat(:)),si);
                        if  norm([4-minR(1),4-minC(1)])>1.5 && sum(regMaxDataMat(:))<=3%can't be more than 3 regional maxima in the 5x5 box
                            
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
                                tgs=calculateFISHStatistics(dataColumn,spotRFilt(si)-NR+1,spotCFilt(si)-WC+1,zi,0,bleachFactors(:,ci));       %nameMod
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
                                ME
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
            if exist('spotDataVectors','var')
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
            else
                worms{ci}.spotDataVectors=[];
            end
            %worms{ci}.spotInfo=spotInfo;
            clear('spotDataVectors');
            
            
            
            
            
            
            worms{ci}.goodWorm=1;
            %        worms{ci}.quickAndDirtyStats=quickAndDirtyStats;
            %9 July2011.  added mfilename so can know which version generated
            %This no longer works well since it is all named the same thing.  But the date helps
            worms{ci}.functionVersion={mfilename; versionName; datestr(now)};
            disp([num2str(count) ' done']);
            disp([ 'Worm -' num2str(ci) ' Position - ' stackSuffix ' Dye - ' dye ':' ])
            fprintf('Total elapsed time is %g seconds for %d spot, average %g per spots\n', totalTime,totalSpotsTested,totalTime/totalSpotsTested)
            fprintf('%d candidate spots saved. \n',count)
            %catch err
            %    if sum(strcmpi(err.message,'Memory'))~=0
            %        % Try to release more memory....
            %        save segStacks_tmp.mat segStacks
            %        clear segStacks
            %        % Release memory - might not be needed for 64-bit computer
            %        save tmp.mat
            %        clear all
            %        load tmp.mat
            %        rethrow(err)
            %    else
            %        err
            %    end
            %end
        end
        
        % Add in new stats.
        worms=addStatsToWormGaussian(worms);
        
        fprintf('Saving worms to:  %s\n',wormFitFileName);
        save(wormFitFileName,'worms');
        
        disp(['All worms in ' dye ' ' stackSuffix ' are done.' ])
        if exist('tmp.mat','file')
            delete tmp.mat
            delete segStacks_tmp.mat
        end
    else
        disp('This position is bad.')
    end
end


end


