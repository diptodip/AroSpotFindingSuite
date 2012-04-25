function varargout = reviewFISHClassification(varargin)  %nameMod
%  =============================================================
%  Name: reviewFISHClassification.m   %nameMod
%  Version: 1.4.2  20 Oct 2011    %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/,
%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%  License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%  Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%  =============================================================
% reviewFISHClassification M-file for reviewFISHClassification.fig    %nameMod
%      reviewFISHClassification, by itself, creates a new reviewFISHClassification or    %nameMod
%      raises the existing
%      singleton*.
%
%      H = reviewFISHClassification returns the handle to a new reviewFISHClassification or the handle to     %nameMod
%      the existing singleton*.
%
%      reviewFISHClassification('CALLBACK',hObject,eventData,handles,...) calls the   %nameMod
%      local
%      function named CALLBACK in reviewFISHClassification.M with the given input arguments.   %nameMod
%
%      reviewFISHClassification('Property','Value',...) creates a new reviewFISHClassification or raises the     %nameMod
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before reviewFISHClassification_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property
%      application
%      stop.  All inputs are passed to reviewFISHClassification_OpeningFcn via
%      varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% reviewFISHClassification.m is a gui to browse the results of the spot finding      %nameMod
% algorithm, estimate and/or correct errors, and retrain the machine
% learning algorithm.  It is written to use the results and data structure
% variables from the random forest algorithm as interpreted by
% classifyFISHSpots but can be modified to evaluate any spot    %nameMod
% identification [to be done in future release]
%
%      varargin = {dye, stackSuffix,worms}
% Arguments passed in:
%     dye:                  this is the dye name (e.g. cy)
%     stackSuffix:    this is the unique identifier associated with files from that stack, (e.g. '001')
%     worms:             this is the data structure with the results of the spot finding algorithm
%
% Output is an overwrite of the spot results file from evaluateFISHImageStack    %nameMod
% and classifyFISHSpots (the *wormGaussianFit.mat file)      %nameMod
%
% The program brings up four image panes and several buttons.
%     The big one on the left has the evaluated maxima arranged left to right, top to bottom in order of spotness.
%     The big one on the right has the zoomable image centered around the potential spot.
%     Two smaller ones on the bottom left have zooms of the region around a spot with the raw data with maxima indicated on the left in blue and pink
%         and a scaled version (min subtracted, everything divided by the max) on the right
%      The 7x7 spot context (along with neighboring slices) is shown in the middle (3D intensity histograms).  This is raw data.
%      In the left image pane, maxima that are called spots are bordered by blue.
%         Maxima that were rejected as spots are bordered in yellow.
%         Maxima that were part of the training set have a diagonal slash through them.
%         The current maximum is marked by a red box.
%
% Possible actions:
%     Click on the grey background of the gui.
%         If you are going to use keystrokes, it is necessary to focus the computer's attention on the gui.
%         Clicking on the grey background changes the focus to the gui and makes the program interpret keystrokes as the gui tells it to.
%     Click the Done fixing this worm button.
%         Congratulations!  You like your results
%     Page up/down keys.
%         The left image pane is 25x25 but often more potential spots are evaluated.  Page up and down move you up or down to the next page of potential spots.
%      Left/right/up/down arrow.
%         Used to move around the left image pane.
%     Bad worm toggle button.
%         If you don't like the looks of the specimen, flag it as bad and move on.
%     Good spot button
%         Correct a rejected spot call.  This changes the classification of the currently highlighted spot from bad to good.
%         This spot will be added to the training set, and the spot will be
%         ringed in light blue.
%     Not a spot button
%         Correct a "good" spot call.  This changes the classification of the currently highlighted spot from good to bad.
%         This spot will be added to the training set, and the spot will be ringed in orange.
%     Add to training set button
%         Add the spot to the training set without changing the classification.
%         This is useful to include more cases in the training set, and the spot will be ringed in orange (bad) or light blue (good).
%     Scrollbar under the right image
%         Change the zoom of the right image.  The number under it displays the current zoom
%     Toggle arrow to spot radio button
%         There is a little red arrow that points to the current spot in the right image.  This toggles it on and off if it is disturbing you.
%     Toggle On=Slice;Off=merge radio button
%         Changes the right image to just the slice that includes the spot (On) or a max merge of the stack (Off)
%      Redo gaussianEvalProcessingRFOnly button
%         This redoes the random forest classification based on the newly augmented training set.
%         This is especially useful when you check your first stack and add lots of borderline cases, until you think the classification is working well.
%         Note that if you redoGuassianEvalProcessingRFOnly, it will redo all the specimens in the image based on the new training set and will overwrite previous results
%     Checkbox in the lower right.
%         If checked, this means that the user has gone through and corrected this file and is satisfied with it.

%19April2011 - Removed reliance on stack extent
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help reviewFISHClassification       %nameMod

% Last Modified by GUIDE v2.5 09-Nov-2011 11:55:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @reviewFISHClassification_OpeningFcn, ...       %nameMod
    'gui_OutputFcn',  @reviewFISHClassification_OutputFcn, ...          %nameMod
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end;

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end;
% End initialization code - DO NOT EDIT


% --- Executes just before reviewFISHClassification is made visible.      %nameMod
function reviewFISHClassification_OpeningFcn(hObject, eventdata, handles, varargin)     %nameMod
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to reviewFISHClassification (see VARARGIN)     %nameMod


% Choose default command line output for reviewFISHClassification       %nameMod
handles.output = hObject;
handles.figure_handle=get(0,'CurrentFigure');
set(handles.figure_handle,'KeyPressFcn',@figure1_KeyPressFcn);

%import info and make spot pictures (background subtracted - essentially
%the code from saveSpotPictures
dye = varargin{1};
stackSuffix=varargin{2};
handles.dye=dye;
handles.stackSuffix=stackSuffix;
handles.wormsFileName=[dye stackSuffix '_wormGaussianFit'];
if exist(['nuclearResults' stackSuffix '.mat'])
    handles.nuclearInformation=dlmread(['nuclearResults' stackSuffix '.txt'],'delimiter','\t');
end;
% if ~isempty(dir(['stackExtent' stackSuffix '.csv']))
%     stackExtent=dlmread(['stackExtent' stackSuffix '.csv']);
% else
%     fid=fopen(['stackExtent' stackSuffix '.csv'],'w');
%     fprintf(fid,'%s\t1\t40\n',stackSuffix);
%     fclose(fid);
%     stackExtent=[str2num(stackSuffix) 1 40];
% end;
%
if 0==0
    % if stackExtent(2)==0
    %     disp(['file stackExtent' stackSuffix '.csv  says there is a problem with the stack']);
    %     disp('reviewFISHClassification() exiting');      %nameMod
    %     return
    % else
    %     %just put in 1:40 here
    %     stackExtent=[str2num(stackSuffix) 1 40];
    if size(varargin,2)==3
        worms=varargin{3};
    else
        disp(['Loading ' dye stackSuffix '_wormGaussianFit']);
        load([dye stackSuffix '_wormGaussianFit']);
    end;
    handles.worms=worms;
    set(handles.fileName_button,'String',[dye stackSuffix '_wormGaussianFit']);
    %%temporary kluge...16/July/2011
    if exist(['segmenttrans' stackSuffix '.mat'])
        load(['segmenttrans' stackSuffix]);
    elseif exist(['segmenttrans_' stackSuffix '.mat'])
        load(['segmenttrans_' stackSuffix]);
    else
        disp('segmenttrans files does not exist');
        return
    end;
    %%%%%%%%%%%%%
    disp('currpolys loaded');
    if size(handles.worms,2)>0
        %   REVISED 2/10/10 so that trainingSets live in the same directory as the
        %   data.  each set of data gets its own trainingSet for now.  need to test
        %   whether they can work cross datasets and then can consolidate into a
        %   single directory
        
        curdir=cd;
        %cd('..');
        %cd('trainingSets');
        load(handles.worms{1}.trainingFileName);
        %cd(curdir);
    else
        disp('Breaking execution');
        return%this should break the execution
    end;
    
    disp('training set loaded');
    
    handles.iMachLearnType=6+1;%right now si is in 6 and is the last one in allLocs before results...the idea for this is that if I use diff ML alrogithms to do it, their results would be in this allLocs and then this would say which one to use...column 7,8, or whatever for the sorting and results
    handles.trainingSet=trainingSet;
    if strcmp(worms{1}.stackFileType,'stk')
        stack=readmm(worms{1}.stackName);
        stack=double(stack.imagedata);
    elseif strcmp(worms{1}.stackFileType,'tiff')
        stack=readTiffStack(worms{1}.stackName,worms{1}.numberOfPlanes);
    end;
    
    %19April2011
    %stack=laplaceFISH(stack,4);
    %     stackExtent(3)=min(size(stack,3),stackExtent(3));
    %     stack=stack(:,:,stackExtent(2):stackExtent(3));
    
    % handles.statsPresent=trainingSet.MachLearn{1}.statsPresent;
    handles.wormImage={};
    handles.wormMask={};
    handles.wormImageMaxMerge={};
    for wi=1:size(handles.worms,2)
        bb=regionprops(double(currpolys{wi}),'BoundingBox');
        handles.wormBBs{wi}=bb.BoundingBox;
        handles.wormMask{wi}=imcrop(currpolys{wi},bb.BoundingBox);
        handles.wormImage{wi}=zeros(size(handles.wormMask{wi},1),size(handles.wormMask{wi},2),size(stack,3));
        for zi=1:size(stack,3)
            handles.wormImage{wi}(:,:,zi)=imscale(imcrop(stack(:,:,zi),bb.BoundingBox),99.995);%.*handles.wormMask{wi};%added the scaling here instead of later
        end;
        
        %8/22/2011...max merge sometimes isn't useful because some out of
        %focus slices are just way too bright.  change so that all slices
        %are scaled to have the same prctile and minimum (subtract off
        %minimum and divide by Prctile and max merge)
        
        %just commented to test the laplace
        handles.wormImageMaxMerge{wi}=minPrctileScale(handles.wormImage{wi}(:,:,1));
        for zi=2:size(stack,3)
            handles.wormImageMaxMerge{wi}=max(handles.wormImageMaxMerge{wi},minPrctileScale(handles.wormImage{wi}(:,:,zi)));
        end;
        handles.laplaceWorm{wi}=laplaceFISH(handles.wormImage{wi},1);
        handles.laplaceWormImageMaxMerge{wi}=max(handles.laplaceWorm{wi},[],3);
        
        
        
        %This is the straightforward way to do the max merge
        %handles.wormImageMaxMerge{wi}=imcrop(max(stack,[],3),bb.BoundingBox);%stack(:,:,10:25)
        
        
        %also take care of goodWorms
        if ~isfield(handles.worms{wi},'goodWorm')
            handles.worms{wi}.goodWorm=1;
        end;
        %added nuclear information 3/31/11
        if isfield(handles,'nuclearInformation')
            if eq(handles.nuclearInformation(wi,2),-1)
                handles.worms{wi}.goodWorm=0;
                set(handles.badWorm_button,'Value',1);
                guidata(hObject,handles);
            end;
        end;
    end;
    disp('wormimages constructed');
    clear('stack');
    
    handles.spotSize=[7 7];
    handles.offset=floor((handles.spotSize-1)/2);
    handles.iCurrentWorm=1;
    if ~isfield(handles.worms{handles.iCurrentWorm},'spotsFixed')
        handles.worms{handles.iCurrentWorm}.spotsFixed=0;
    end;
    set(handles.fileName_button,'Value',handles.worms{handles.iCurrentWorm}.spotsFixed);
    
    spotBoxPositions=[];
    spotBoxLocations=[];
    goodLocs=[];
    rejectedLocs=[];
    handles.nGoodToRejected=0;
    handles.nRejectedToGood=0;
    placeholder=-100;
    disp('making good/rejectedLocs');
    
    %%%%%MAKE PART IN HERE TO ONLY DISPLAY IF IT IS A GOOD ONE
    for si=1:size(handles.worms{handles.iCurrentWorm}.spotInfo,2)
        %remember that some of the spots were not classified but were thrown
        %out
        if isfield(handles.worms{handles.iCurrentWorm}.spotInfo{si},'classification')
            if ~isfield(handles.worms{handles.iCurrentWorm}.spotInfo{si}.classification,'manual')
                %disp([num2str(si) ' ' num2str(130)]);
                
                iTrainingSet=isInTrainingSet(handles.trainingSet,handles.worms{handles.iCurrentWorm}.spotInfo{si});
                if iTrainingSet
                    handles.worms{handles.iCurrentWorm}.spotInfo{si}.classification.manual=handles.trainingSet.spotInfo{iTrainingSet}.classification.manual;
                end;
            end;
            MLResults=zeros(1,size(handles.trainingSet.MachLearn,2)+1)-1;
            for mli=1:size(handles.trainingSet.MachLearn,2)
                if ~isempty(handles.worms{handles.iCurrentWorm}.spotInfo{si}.MachLearnResult{mli})
                    MLResults(mli)=handles.worms{handles.iCurrentWorm}.spotInfo{si}.MachLearnResult{mli};
                end;
            end;
            if isfield(handles.worms{handles.iCurrentWorm}.spotInfo{si}.classification,'manual')
                MLResults(end)=handles.worms{handles.iCurrentWorm}.spotInfo{si}.classification.manual;
                if handles.worms{handles.iCurrentWorm}.spotInfo{si}.classification.manual==1
                    goodLocs=[goodLocs;[handles.worms{handles.iCurrentWorm}.spotInfo{si}.locations.worm handles.worms{handles.iCurrentWorm}.spotInfo{si}.filteredValue placeholder si MLResults]];
                else
                    rejectedLocs=[rejectedLocs;[handles.worms{handles.iCurrentWorm}.spotInfo{si}.locations.worm handles.worms{handles.iCurrentWorm}.spotInfo{si}.filteredValue placeholder si MLResults]];
                end;
            else
                if isfield(handles.worms{handles.iCurrentWorm}.spotInfo{si}.classification,'MachLearn')
                    if handles.worms{handles.iCurrentWorm}.spotInfo{si}.classification.MachLearn{1}==1
                        %locations(1-3) filteredValue(4) MachLearnResult(5) si(6)
                        goodLocs=[goodLocs;[handles.worms{handles.iCurrentWorm}.spotInfo{si}.locations.worm handles.worms{handles.iCurrentWorm}.spotInfo{si}.filteredValue placeholder si MLResults]];
                    else
                        rejectedLocs=[rejectedLocs;[handles.worms{handles.iCurrentWorm}.spotInfo{si}.locations.worm handles.worms{handles.iCurrentWorm}.spotInfo{si}.filteredValue placeholder si MLResults]];
                    end;
                end;
            end;
        end;
    end;
    nSpots=size(goodLocs,1)+size(rejectedLocs,1);
    %need next largest multiple of spotSize(1) (assume square)
    %%%6/28/09 - don't want spots to be too small...have it run off the bottom,
    %%%so maximum of, say, 30 spots per horizontal side
    
    handles.spotsPerRow=25;
    
    handles.horizSideSize=min(handles.spotsPerRow,ceil(sqrt(nSpots)));
    handles.vertSideSize=ceil(nSpots/handles.horizSideSize);
    bkgdSubImage=zeros([handles.vertSideSize handles.vertSideSize].*handles.spotSize);
    handles.rejectedOutlines=[];%this is now going to be a list of NW corners (X,Y) for rectangles
    handles.goodOutlines=[];%this is now going to be a list of NW corners (X,Y) for rectangles
    handles.rejectedCurated=[];%this is now going to be a list of NW corners (X,Y) for rectangles
    handles.goodCurated=[];%this is now going to be a list of NW corners (X,Y) for rectangles
    handles.spotIndexImage=zeros(handles.horizSideSize);%size(bkgdSubImage));
    
    %handles.outlines=.5*bwperim(ones(spotSize))+(~bwperim(ones(spotSize)));
    %handles.curated=.5*ones(spotSize);
    handles.outlines=.3*bwperim(ones(handles.spotSize));
    handles.curated=.3*ones(handles.spotSize);
    if size(goodLocs,1)>0
        goodLocs=sortrows(goodLocs,handles.iMachLearnType);%sort rows based on machine learn result in column handles.iMachLearnType
        goodLocs=goodLocs(size(goodLocs,1):-1:1,:);%reverses it?
    end;
    rejectedLocs=sortrows(rejectedLocs,handles.iMachLearnType);
    rejectedLocs=rejectedLocs(size(rejectedLocs,1):-1:1,:);
    allLocs=[goodLocs;rejectedLocs];
    goodIntensities=[];
    disp(['Doing spot box locations for worm #' num2str(handles.iCurrentWorm)]);
    for si=1:size(allLocs,1)
        currentR=1+handles.spotSize(1)*floor((si-1)/handles.horizSideSize);
        currentC=1+handles.spotSize(1)*mod((si-1),handles.horizSideSize);
        NR=max(1,allLocs(si,1)-handles.offset(1));
        if NR==1
            %then too close to top
            SR=handles.spotSize(1);
        else
            if allLocs(si,1)+handles.offset(1)>size(handles.wormMask{handles.iCurrentWorm},1)
                SR=size(handles.wormMask{handles.iCurrentWorm},1);
                NR=size(handles.wormMask{handles.iCurrentWorm},1)-(handles.spotSize(1)-1);
            else
                SR=NR+(handles.spotSize(1)-1);
            end;
        end;
        WC=max(1,allLocs(si,2)-handles.offset(2));
        if WC==1
            %then too close to top
            EC=handles.spotSize(2);
        else
            if allLocs(si,2)+handles.offset(2)>size(handles.wormMask{handles.iCurrentWorm},2)
                EC=size(handles.wormMask{handles.iCurrentWorm},2);
                WC=size(handles.wormMask{handles.iCurrentWorm},2)-(handles.spotSize(2)-1);
            else
                EC=WC+handles.spotSize(2)-1;
            end;
        end;
        dataMat=handles.wormImage{handles.iCurrentWorm}(NR:SR,WC:EC,allLocs(si,3));
        %        rawImage(currentR:currentR+spotSize(1)-1,currentC:currentC+spotSize(2)-1)=dataMat;
        bkgdSubImage(currentR:currentR+handles.spotSize(1)-1,currentC:currentC+handles.spotSize(2)-1)=dataMat-min(dataMat(:));
        handles.spotIndexImage(currentR:currentR+handles.spotSize(1)-1,currentC:currentC+handles.spotSize(2)-1)=zeros(size(dataMat))+si;
        if si<=size(goodLocs,1)
            handles.goodOutlines=[handles.goodOutlines;[colToX(currentC),rowToY(currentR)]];%(currentR:currentR+spotSize(1)-1,currentC:currentC+spotSize(2)-1)=handles.outlines;
            splitPoint=[rowToY(currentR+handles.spotSize(1)-1),colToX(currentC+handles.spotSize(2)-1)];%only really matters for the equality...legacy anyway
            goodIntensities=[goodIntensities dataMat(4,4)];
        else
            handles.rejectedOutlines=[handles.rejectedOutlines;[colToX(currentC),rowToY(currentR)]];%currentR:currentR+spotSize(1)-1,currentC:currentC+spotSize(2)-1)=handles.outlines;
        end;
        spotBoxPositions=[spotBoxPositions;[colToX(WC) rowToY(NR) handles.spotSize(1) handles.spotSize(2)]];%this is for highlighting on context image
        spotBoxLocations=[spotBoxLocations;[colToX(currentC),rowToY(currentR)]];%[currentR,currentR+spotSize(1)-1,currentC,currentC+spotSize(2)-1]];%this is for finding int he spotResults image...it is NW corners in (x,y)
    end;
    
    handles.bkgdSubImage=bkgdSubImage;
    handles.goodLocs=goodLocs;
    handles.rejectedLocs=rejectedLocs;
    handles.allLocs=allLocs;
    handles.spotBoxPositions=spotBoxPositions;
    handles.spotBoxLocations=spotBoxLocations;
    handles.goodIntensities=goodIntensities;
    handles.spotStatus=[ones(size(goodLocs,1),1);zeros(size(rejectedLocs,1),1)];%category vector
    
    handles.iCurrentSpot_allLocs=size(goodLocs,1);%last good spot
    if handles.iCurrentSpot_allLocs==0
        handles.iCurrentSpot_allLocs=1;
    end;
    
    handles.iCurrentSpot_worms=handles.allLocs(handles.iCurrentSpot_allLocs,6);
    %handles.goodCurated(spotBoxLocations(handles.iCurrentSpot_allLocs,1):spotBoxLocations(handles.iCurrentSpot_allLocs,2),spotBoxLocations(handles.iCurrentSpot_allLocs,3):spotBoxLocations(handles.iCurrentSpot_allLocs,4))=handles.curated;
    
    %handles.worms=worms;
    
    
    handles.surfPlots={handles.surfMinus1,handles.surfInFocus,handles.surfPlus1};
    %this is the function that will record the center of the spot
    set(handles.spotResults,'ButtonDownFcn',@spotResults_ButtonDownFcn);
    
    %initialize spotResults figure and get handles to rectangles
    %set(handles.figure_handle,'CurrentAxes',handles.spotResults);
    handles.rectangleHandles={};
    iRH=1;
    handles.spotResultsImage=imshow(handles.bkgdSubImage,'Parent',handles.spotResults);%imshow(fullColor);
    set(handles.spotResultsImage,'HitTest','on');
    set(handles.spotResultsImage,'ButtonDownFcn',@spotResults_ButtonDownFcn);
    %currentSpot
    handles.currentSpotRectangle=rectangle('Position',[handles.spotBoxLocations(handles.iCurrentSpot_allLocs,1)+1,handles.spotBoxLocations(handles.iCurrentSpot_allLocs,2)+1 handles.spotSize-2],'EdgeColor',[1 0 0],'HitTest','off','Parent',handles.spotResults);
    for si=1:size(handles.goodOutlines,1)
        handles.rectangleHandles{iRH}.rect=rectangle('Position',[handles.goodOutlines(si,:) handles.spotSize-.5],'EdgeColor',[.1,.1,.5],'HitTest','off','Parent',handles.spotResults);
        %if isequal, draw a line
        iTrainingSet=isInTrainingSet(handles.trainingSet,handles.worms{handles.iCurrentWorm}.spotInfo{handles.allLocs(si,6)});
        if iTrainingSet
            if handles.trainingSet.categoryVector(handles.trainingSet.spotInfo{iTrainingSet}.iDataMatrix)==1
                tLineColor=[.1 .1 1];
            else
                tLineColor=[.5 .5 .1];
            end;
            handles.rectangleHandles{iRH}.trainingLine=line('Xdata',[handles.goodOutlines(si,1)+1,handles.goodOutlines(si,1)+handles.spotSize(1)-1],'Ydata',[handles.goodOutlines(si,2)+1,handles.goodOutlines(si,2)+handles.spotSize(2)-1],'Color',tLineColor,'LineWidth',2,'HitTest','off','Parent',handles.spotResults);
            set(handles.rectangleHandles{iRH}.trainingLine,'UserData',iTrainingSet);%associate trainingSetIndex
            
        end;
        iRH=iRH+1;
    end;
    %rejected = yellow rectangles
    nGood=size(handles.goodOutlines,1);
    for si=1:size(handles.rejectedOutlines,1)
        handles.rectangleHandles{iRH}.rect=rectangle('Position',[handles.rejectedOutlines(si,:) handles.spotSize-.5],'EdgeColor',[.5,.5,.1],'HitTest','off','Parent',handles.spotResults);
        iTrainingSet=isInTrainingSet(handles.trainingSet,handles.worms{handles.iCurrentWorm}.spotInfo{handles.allLocs(si+nGood,6)});
        if iTrainingSet
            if handles.trainingSet.categoryVector(handles.trainingSet.spotInfo{iTrainingSet}.iDataMatrix)==1
                tLineColor=[.1 .1 1];
                
            else
                tLineColor=[.5 .5 .1];
            end;
            handles.rectangleHandles{iRH}.trainingLine=line('Xdata',[handles.rejectedOutlines(si,1)+1,handles.rejectedOutlines(si,1)+handles.spotSize(1)-1],'YData',[handles.rejectedOutlines(si,2)+1,handles.rejectedOutlines(si,2)+handles.spotSize(2)-1],'Color',tLineColor,'LineWidth',2,'HitTest','off','Parent',handles.spotResults);
            set(handles.rectangleHandles{iRH}.trainingLine,'UserData',iTrainingSet);%associate trainingSetIndex
        end;
        
        iRH=iRH+1;
    end;
    % Update handles structure
    guidata(hObject, handles);
    displayImFull(hObject,handles,0);
    
    % UIWAIT makes reviewFISHClassification wait for user response (see UIRESUME)
    uiwait(handles.figure1);
end;
%%%function lineBox makes xdata and ydata for lines out of rectangle
%%%position - goes clockwise from NW
function [xdata,ydata]=lineBox(position)
NW=position(1:2);
xdata=[NW(1),NW(1)+position(3),NW(1)+position(3),NW(1),NW(1)];
ydata=[NW(2),NW(2),NW(2)+position(4),NW(2)+position(4),NW(2)];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%displayImFull
function displayImFull(hObject,handles,drawSpotResults)

data=guidata(hObject);
% if data.svmType==1%whichever the type is is in allLocs column 5 and the other one is in column 7
%     set(data.LinearMachLearnResult_txt,'String',['Linear MachLearn Result: ' num2str(data.allLocs(data.iCurrentSpot_allLocs,5))]);
%     set(data.NonlinearMachLearnResult_txt,'String',['Nonlinear MachLearn Result: ' num2str(data.allLocs(data.iCurrentSpot_allLocs,7))]);
% else
%     set(data.LinearMachLearnResult_txt,'String',['Linear MachLearn Result: ' num2str(data.allLocs(data.iCurrentSpot_allLocs,7))]);
%     set(data.NonlinearMachLearnResult_txt,'String',['Nonlinear MachLearn Result: ' num2str(data.allLocs(data.iCurrentSpot_allLocs,5))]);
% end;
MachLearnTypes='FilteredRank';
MachLearnResults=num2str(data.allLocs(data.iCurrentSpot_allLocs,4));
for mli=1:size(data.trainingSet.MachLearn,2)
    if isfield(data.trainingSet.MachLearn{mli},'type')
        MachLearnTypes=[MachLearnTypes sprintf('    %s',data.trainingSet.MachLearn{mli}.type)];
        MachLearnResults=[MachLearnResults sprintf('    %0.3f', data.allLocs(data.iCurrentSpot_allLocs,6+mli))];
    else
        MachLearnTypes=[MachLearnTypes sprintf('    %s','')];
        MachLearnResults=[MachLearnResults sprintf('    NA')];
    end;
    
end;
MachLearnTypes=[MachLearnTypes sprintf('    manual')];
MachLearnResults=[MachLearnResults sprintf('    %0.3f', data.allLocs(data.iCurrentSpot_allLocs,end))];

% set(data.LinearMachLearnResult_txt,'String',MachLearnTypes);
% set(data.NonlinearMachLearnResult_txt,'String',MachLearnResults);

%set(data.filteredRank_txt,'String',['Spot Rank: ' num2str(data.allLocs(data.iCurrentSpot_allLocs,4))]);
set(data.spotContextSlider_txt,'String',['Current Zoom: ' num2str(get(data.spotContextSlider,'Value'))]);
set(data.nGoodToRejected_txt,'String',[num2str(data.nGoodToRejected) ' good -> rejected']);
set(data.nRejectedToGood_txt,'String',[num2str(data.nRejectedToGood) ' rejected -> good']);
set(data.nGoodSpots_txt,'String',[num2str(size(data.goodLocs,1)) ' good spots']);
set(data.nRejectedSpots_txt,'String',[num2str(size(data.rejectedLocs,1)) ' rejected spots']);
set(data.iCurrentWorm_txt,'String',['Worm: ' num2str(data.iCurrentWorm) ' of ' num2str(size(data.worms,2))]);
set(data.votes_txt,'String',[num2str(data.worms{data.iCurrentWorm}.spotInfo{data.iCurrentSpot_worms}.MachLearnResult{1}) ' good votes']);
set(data.scdValue_txt,'String',['scd: ' num2str(data.worms{data.iCurrentWorm}.spotInfo{data.iCurrentSpot_worms}.stat.statValues.scd)]);

set(data.iCurrentSpot_worms_txt,'String',['Index in worms: ' num2str(data.iCurrentSpot_worms)]);
set(data.badWorm_button,'Value',abs(data.worms{data.iCurrentWorm}.goodWorm-1));%changes good 1,0 to bad 1,0
currentZ=data.allLocs(data.iCurrentSpot_allLocs,3);
set(data.currentSlice_txt,'String',['Slice ' num2str(currentZ) ' of ' num2str(size(data.wormImage{data.iCurrentWorm},3))]);
currentSlice=data.wormImage{data.iCurrentWorm}(:,:,currentZ);
% mergeStarti=min(10,currentZ);
% mergeEndi=max(25,currentZ);
% maxMerge=scale(double(max(data.wormImage{data.iCurrentWorm}(:,:,mergeStarti:mergeEndi),[],3)));
%set(data.figure_handle,'CurrentAxes',data.spotResults);
%data.spotResults=imshow(data.bkgdSubImage);%imshow(fullColor);
%imshow(data.bkgdSubImage);
zoom(data.spotResultsImage,'factor',data.vertSideSize/(1+data.horizSideSize));

spotBoxesTotalWidth=data.horizSideSize*data.spotSize(1);

xlim(data.spotResults,[colToX(1) colToX(spotBoxesTotalWidth)]);

currentSpotY=data.spotBoxLocations(data.iCurrentSpot_allLocs,2);%N edge of spotBox
spotPage=ceil(currentSpotY/(spotBoxesTotalWidth));
set(data.spotPage_txt,'String',sprintf('Spot page %d of %d',spotPage,ceil(data.vertSideSize/data.horizSideSize)));

ylim(data.spotResults,[rowToY((spotPage-1)*spotBoxesTotalWidth+1) rowToY(spotPage*spotBoxesTotalWidth)]);

if drawSpotResults
    for si=1:size(data.goodOutlines,1)
        rectangle('Position',[data.goodOutlines(si,:) data.spotSize],'EdgeColor',[.1,.1,.5]);
    end;
    %rejected = yellow rectangles
    for si=1:size(data.rejectedOutlines,1)
        rectangle('Position',[data.rejectedOutlines(si,:) data.spotSize],'EdgeColor',[.5,.5,.1]);
    end;
    %goodCurated
    for si=1:size(data.goodCurated,1)
        rectangle('Position',[data.goodCurated(si,:) data.spotSize],'EdgeColor',[0,.7,.7]);
    end;
    %rejectedCurated
    for si=1:size(data.rejectedCurated,1)
        rectangle('Position',[data.rejectedCurated(si,:) data.spotSize],'EdgeColor',[1,.5,0]);
    end;
end;
%currentSpot
set(data.currentSpotRectangle,'Position',[data.spotBoxLocations(data.iCurrentSpot_allLocs,1)+1,data.spotBoxLocations(data.iCurrentSpot_allLocs,2)+1 data.spotSize-2],'EdgeColor',[1 0 0]);
%%%%%%%%%%%%
set(data.figure_handle,'CurrentAxes',data.spotContext);
%equalize the sides (fill in with black)
sz=size(currentSlice);
spotContextIm=zeros(max(sz));
if get(data.sliceMerge_button,'Value')==1
    if get(data.laplaceFilter_button,'Value')==1
        spotContextIm(1:sz(1),1:sz(2))=imscale(data.laplaceWorm{data.iCurrentWorm}(:,:,currentZ),99.995);
    else
        spotContextIm(1:sz(1),1:sz(2))=imscale(currentSlice,99.995);%(currentSlice-min(currentSlice(:)))/getCurrentGoodMax(data);%imscale(currentSlice);
    end;
else%merge
    if get(data.laplaceFilter_button,'Value')==1
        spotContextIm(1:sz(1),1:sz(2))=scale(data.laplaceWormImageMaxMerge{data.iCurrentWorm});
    else
        spotContextIm(1:sz(1),1:sz(2))=scale(data.wormImageMaxMerge{data.iCurrentWorm});
    end;
end;
data.spotContext=imshow(spotContextIm);

%Note that if there is a very bright pixel in this, it will tend to make
%everything else very dark

zoomFactor=get(data.spotContextSlider,'Value');
currentSpotX=data.spotBoxPositions(data.iCurrentSpot_allLocs,1)+data.offset(2);
currentSpotY=data.spotBoxPositions(data.iCurrentSpot_allLocs,2)+data.offset(1);
origXLim=get(gca,'XLim'); origWidth=origXLim(2)-origXLim(1);
origYLim=get(gca,'YLim'); origHeight=origYLim(2)-origYLim(1);
if get(data.arrowSpot_button,'Value')%data.rectangleAroundSpotOnEmbryo
    line('Xdata',[currentSpotX+4, currentSpotX+3, currentSpotX+4, currentSpotX+3,currentSpotX+6],'Ydata',[currentSpotY-1+.5, currentSpotY+.5,currentSpotY+1+.5,currentSpotY+.5,currentSpotY+.5],'color',[.8 .4 0]);
    %rectangle('Position',[currentSpotX-7 currentSpotY-7 15 15],'EdgeColor',[.8 .4 0],'LineStyle','--');
    %Note that the rectangle was intrusive - it focused attention on the
    %putative spot and brought out its spotness even if it was no different from
    %garbage around it.  The arrow visually preserves its context
end;
zoom(zoomFactor);
currContextX=max(1,currentSpotX-floor(.5*origWidth/(zoomFactor)));
currContextX=min(currContextX,origWidth-origWidth/zoomFactor);
currContextY=max(1,currentSpotY-floor(.5*origHeight/(zoomFactor)));
currContextY=min(currContextY,origHeight-origHeight/zoomFactor);
xlim(get(data.figure_handle,'CurrentAxes'),[currContextX currContextX+origWidth/zoomFactor]);
ylim(get(data.figure_handle,'CurrentAxes'),[currContextY currContextY+origHeight/zoomFactor]);

%%%%%%%%%%%%
set(data.figure_handle,'CurrentAxes',data.spotZoomLaplaceFiltered);

%This is from when I had it display the raw data matrix in blue with pink
%marking the maximum
% rc=imregionalmax(currentSlice);
% data.spotZoomRaw=imshow(cat(3,.75*imscale(currentSlice,99.995)+imscale(currentSlice,99.995).*rc,imscale(currentSlice,99.995),imscale(currentSlice,99.995)));
%%%%
data.spotZoomLaplaceFiltered=imshow(imscale(data.laplaceWorm{data.iCurrentWorm}(:,:,currentZ),99.995));
zoomFactorX=origWidth/data.spotSize(2);
zoomFactorY=origHeight/data.spotSize(1);
zoomFactor=max(zoomFactorX,zoomFactorY);
zoom(zoomFactor);
xlim(get(data.figure_handle,'CurrentAxes'),[currentSpotX-data.offset(2) currentSpotX+data.offset(2)+1]);%because want to include that last pixel not have it be the edge
ylim(get(data.figure_handle,'CurrentAxes'),[currentSpotY-data.offset(1) currentSpotY+data.offset(1)+1]);
%%%%%%%%%%%%
set(data.figure_handle,'CurrentAxes',data.spotZoomBkgdSub);
dataMat=currentSlice(yToRow(currentSpotY)-data.offset(2):yToRow(currentSpotY)+data.offset(2),xToCol(currentSpotX)-data.offset(1):xToCol(currentSpotX)+data.offset(1));
minDataMat=min(dataMat(:));
scaledSlice=currentSlice-minDataMat;
scaledSlice=scaledSlice.*(scaledSlice>0);
data.spotZoomBkgdSub=imshow(imscale(scaledSlice,99.995));
zoomFactorX=origWidth/data.spotSize(2);
zoomFactorY=origHeight/data.spotSize(1);
zoomFactor=min(zoomFactorX,zoomFactorY);
zoom(zoomFactor);
xlim(get(data.figure_handle,'CurrentAxes'),[currentSpotX-data.offset(2) currentSpotX+data.offset(2)+1]);
ylim(get(data.figure_handle,'CurrentAxes'),[currentSpotY-data.offset(1) currentSpotY+data.offset(1)+1]);

%%%%%%%%%%%%
surfWidth=15;
surfNR=max(1,yToRow(currentSpotY-floor(surfWidth/2)));
surfWC=max(1,xToCol(currentSpotX-floor(surfWidth/2)));
surfEC=surfWC+surfWidth-1;
surfSR=surfNR+surfWidth-1;
%fprintf('%d %d %d %d\n',surfWC,surfNR,surfEC,surfSR);
surfColumn=data.wormImage{data.iCurrentWorm}(surfNR:surfSR,surfWC:surfEC,:);
%freezeColors;
for i=1:3
    if currentZ+(i-2)<=size(data.wormImage{data.iCurrentWorm},3) && currentZ+(i-2)>=1
        tex=sc(surfColumn(:,:,currentZ+(i-2)),'hsv');
        set(data.figure_handle,'CurrentAxes',data.surfPlots{i});
        surf(surfColumn(:,:,currentZ+(i-2)),tex);
        set(data.surfPlots{i},'YDir','reverse','XTick',[],'ZLim',[0 1],'YTick',[],'ZTick',[],'Visible','off','Color',get(data.figure_handle,'Color'));
        
    end;
    
end;

%this is the function that will record the center of the spot
set(data.spotResults,'ButtonDownFcn',@spotResults_ButtonDownFcn);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%guidata(hObject,data);





% --- Outputs from this function are returned to the command line.
function varargout = reviewFISHClassification_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure

varargout{1} = handles.output;

%rerun the randomForest with the trainingSet as it currently stands after
%review
disp('Rerunning randomForest with the latest amendments');
trainingSet=handles.trainingSet;
save(handles.trainingSet.name,'trainingSet');
handles.trainingSet=trainFISHClassifier(handles.trainingSet,1);  %nameMod

% Get the current position of the GUI from the handles structure
% to pass to the modal dialog.
pos_size = get(handles.figure1,'Position');
% Call modaldlg with the argument 'Position'.
user_response = modaldlg('Title','If you are finished shall I close the GUI window?');
switch user_response
    case {'No'}
        % take no action
    case 'Yes'
        % Prepare to close GUI application window
        %                  .
        %                  .
        %                  .
        delete(handles.figure1)
end


% --- Executes on slider movement.
function spotContextSlider_Callback(hObject, eventdata, handles)
% hObject    handle to spotContextSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of
%        slider


guidata(hObject,handles);
displayImFull(hObject,handles,0);



% --- Executes during object creation, after setting all properties.
function spotContextSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to spotContextSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end;



% --- Executes on button press in goodSpot_button.
function goodSpot_button_Callback(hObject, eventdata, handles)
% hObject    handle to goodSpot_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
currentSpotClassification=handles.worms{handles.iCurrentWorm}.spotInfo{handles.iCurrentSpot_worms}.classification;
if isfield(currentSpotClassification,'manual')
    cla=currentSpotClassification.manual;
else
    if isfield(currentSpotClassification,'MachLearn')
        cla=currentSpotClassification.MachLearn{1};
    end;
end;
if cla~=1
    disp(sprintf('Accepting rejected spot %d',handles.iCurrentSpot_worms));
    
    handles.worms{handles.iCurrentWorm}.spotInfo{handles.iCurrentSpot_worms}.classification.manual=1;
    %modify image
    %compass=handles.spotBoxLocations(handles.iCurrentSpot_allLocs,:);
    %NR=compass(1);SR=compass(2);WC=compass(3);EC=compass(4);
    NW=handles.spotBoxLocations(handles.iCurrentSpot_allLocs,:);
    handles.spotStatus(handles.iCurrentSpot_allLocs)=1;
    rejectedIndex=find(handles.rejectedLocs(:,6)==handles.iCurrentSpot_allLocs);
    handles.goodLocs=[handles.goodLocs;handles.rejectedLocs(rejectedIndex,:)];
    handles.rejectedLocs(rejectedIndex,:)=[];
    %add to training set if not already in it
    if isfield(handles.rectangleHandles{handles.iCurrentSpot_allLocs},'trainingLine')
        disp('This spot already was manually marked as bad and now we are changing it to good');
        disp(sprintf('Its iCurrentSpot is %d and iTrainingSet is %d\n',handles.iCurrentSpot_allLocs,get(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine,'UserData')));
        
        %iTrainingSet=isInTrainingSet(handles.trainingSet,handles.worms{handles.iCurrentWorm}.spotInfo{handles.iCurrentSpot_worms});
        %disp(iTrainingSet);
        %disp('now in trainingset');
        iTrainingSet=get(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine,'UserData');%this doesn't work and above just shunts problem elsewhere
        %error is:
        %        ??? Error using ==> get
        % Invalid handle object.
        %
        % Error in ==>
        % reviewFISHClassification>goodSpot_button_Callback at 584
        %        iTrainingSet=get(handles.rectangleHandles{handles.iCurrent
        %        Spot_allLocs}.trainingLine,'UserData');
        %
        handles.trainingSet.categoryVector(handles.trainingSet.spotInfo{iTrainingSet}.iDataMatrix)=1;
        handles.trainingSet.spotInfo{iTrainingSet}.classification.manual=handles.trainingSet.categoryVector(handles.trainingSet.spotInfo{iTrainingSet}.iDataMatrix);
        set(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine,'Color',[0, .7, .7]);
        
        %Note 25/10/11 - this needs to be propagated to gold/rejectedSpots
        %it also needs to be propagated to the worm file
        
    else
        
        iTrainingSet=size(handles.trainingSet.spotInfo,2)+1;
        handles.trainingSet.dataMatrix=[handles.trainingSet.dataMatrix;handles.worms{handles.iCurrentWorm}.spotInfo{handles.iCurrentSpot_worms}.data];
        handles.trainingSet.categoryVector=[handles.trainingSet.categoryVector;1];
        %specific spot info
        fields={'dataMat','directory','dye','stackSuffix','stackName','wormNumber','stat','classification','locations'};
        for fi=1:length(fields)
            handles.trainingSet.spotInfo{iTrainingSet}.(fields{fi})=handles.worms{handles.iCurrentWorm}.spotInfo{handles.iCurrentSpot_worms}.(fields{fi});
        end;
        handles.trainingSet.spotInfo{iTrainingSet}.spotInfoNumberInWorm=handles.iCurrentSpot_worms;
        
        handles.trainingSet.spotInfo{iTrainingSet}.iDataMatrix=size(handles.trainingSet.dataMatrix,1);
        rectposition=get(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.rect,'Position');
        handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine=line('XData',[rectposition(1),rectposition(1)+handles.spotSize(1)-1],'YData',[rectposition(2),rectposition(2)+handles.spotSize(2)-1],'LineWidth',1,'HitTest','off','Parent',handles.spotResults,'Visible','off');
        set(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine,'UserData',iTrainingSet);
        
    end;
    set(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine,'Color',[0,.7,.7]);
    
    if ~isfield(handles.trainingSet.spotInfo{iTrainingSet}.locations,'stack')
        newLocation=translateToNewCoordinates([colToX(handles.trainingSet.spotInfo{iTrainingSet}.locations.worm(2)) rowToY(handles.trainingSet.spotInfo{iTrainingSet}.locations.worm(1))],handles.wormBBs{handles.iCurrentWorm},'StoL');
        handles.trainingSet.spotInfo{iTrainingSet}.locations.stack=[yToRow(newLocation(2)) xToCol(newLocation(1)) handles.trainingSet.spotInfo{iTrainingSet}.locations.worm(3)];
    end;
    
    [c,ia,ib]=intersect(handles.rejectedOutlines,NW,'rows');
    handles.goodOutlines=[handles.goodOutlines;NW];
    handles.rejectedOutlines(ia,:)=[];
    handles.goodCurated=[handles.goodCurated;NW];
    [c,ia,ib]=intersect(handles.rejectedCurated,NW,'rows');
    handles.rejectedCurated(ia,:)=[];%just in case
    handles.nRejectedToGood=handles.nRejectedToGood+1;
    
    %change the color
    %for lineBox
    %     for rhi=1:length(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.rect)
    %         set(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.rect(rhi),'Color',[0,.7,.7]);
    %     end;
    set(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.rect,'EdgeColor',[0,.7,.7]);
    handles.iCurrentSpot_allLocs=min(size(handles.spotBoxLocations,1),handles.iCurrentSpot_allLocs+1);
    handles.iCurrentSpot_worms=handles.allLocs(handles.iCurrentSpot_allLocs,6);
    
end;
%setfocus(handles.spotResults);
%uicontrol(gcbf);
set(handles.arrowSpot_button,'Value',1)
guidata(hObject,handles);
displayImFull(hObject,handles,0);


% --- Executes on button press in rejectedSpot_button.
function rejectedSpot_button_Callback(hObject, eventdata, handles)
% hObject    handle to rejectedSpot_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

currentSpotClassification=handles.worms{handles.iCurrentWorm}.spotInfo{handles.iCurrentSpot_worms}.classification;
%disp(currentSpotClassification);
%disp(currentSpotClassification.MachLearn{1});
if isfield(currentSpotClassification,'manual')
    cla=currentSpotClassification.manual;
else
    if isfield(currentSpotClassification,'MachLearn')
        cla=currentSpotClassification.MachLearn{1};
    end;
end;
%disp(handles.iCurrentWorm);
%disp(handles.iCurrentSpot_allLocs);
%disp(cla);
if cla==1
    disp(sprintf('Rejecting good spot %d',handles.iCurrentSpot_worms));
    
    handles.worms{handles.iCurrentWorm}.spotInfo{handles.iCurrentSpot_worms}.classification.manual=0;
    %modify image
    %     compass=handles.spotBoxLocations(handles.iCurrentSpot_allLocs,:);
    %     NR=compass(1);SR=compass(2);WC=compass(3);EC=compass(4);
    NW=handles.spotBoxLocations(handles.iCurrentSpot_allLocs,:);
    
    handles.spotStatus(handles.iCurrentSpot_allLocs)=0;
    goodIndex=find(handles.goodLocs(:,6)==handles.iCurrentSpot_allLocs);
    handles.rejectedLocs=[handles.rejectedLocs;handles.goodLocs(goodIndex,:)];
    handles.goodLocs(goodIndex,:)=[];
    %add to training set if not already in it
    if isfield(handles.rectangleHandles{handles.iCurrentSpot_allLocs},'trainingLine')
        disp('This spot already was manually marked as good and now we are changing it to rejected');
        disp(sprintf('Its iCurrentSpot is %d and iTrainingSet is %d\n',handles.iCurrentSpot_allLocs,get(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine,'UserData')));
        iTrainingSet=get(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine,'UserData');
        handles.trainingSet.categoryVector(handles.trainingSet.spotInfo{iTrainingSet}.iDataMatrix)=0;
        handles.trainingSet.spotInfo{iTrainingSet}.classification.manual=handles.trainingSet.categoryVector(handles.trainingSet.spotInfo{iTrainingSet}.iDataMatrix);
        set(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine,'Color',[.7 .4 .1]);
    else
        iTrainingSet=size(handles.trainingSet.spotInfo,2)+1;
        handles.trainingSet.dataMatrix=[handles.trainingSet.dataMatrix;handles.worms{handles.iCurrentWorm}.spotInfo{handles.iCurrentSpot_worms}.data];
        handles.trainingSet.categoryVector=[handles.trainingSet.categoryVector;0];
        %specific spot info
        fields={'dataMat','directory','dye','stackSuffix','stackName','wormNumber','stat','classification','locations'};
        for fi=1:length(fields)
            handles.trainingSet.spotInfo{iTrainingSet}.(fields{fi})=handles.worms{handles.iCurrentWorm}.spotInfo{handles.iCurrentSpot_worms}.(fields{fi});
        end;
        handles.trainingSet.spotInfo{iTrainingSet}.spotInfoNumberInWorm=handles.iCurrentSpot_worms;
        handles.trainingSet.spotInfo{iTrainingSet}.iDataMatrix=size(handles.trainingSet.dataMatrix,1);
        rectposition=get(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.rect,'Position');
        handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine=line('XData',[rectposition(1),rectposition(1)+handles.spotSize(1)-1],'YData',[rectposition(2),rectposition(2)+handles.spotSize(2)-1],'LineWidth',1,'HitTest','off','Parent',handles.spotResults,'Visible','off');
        set(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine,'UserData',iTrainingSet);
    end;
    set(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine,'Color',[.7,.4,.1]);
    if ~isfield(handles.trainingSet.spotInfo{iTrainingSet}.locations,'stack')
        newLocation=translateToNewCoordinates([colToX(handles.trainingSet.spotInfo{iTrainingSet}.locations.worm(2)) rowToY(handles.trainingSet.spotInfo{iTrainingSet}.locations.worm(1))],handles.wormBBs{handles.iCurrentWorm},'StoL');
        handles.trainingSet.spotInfo{iTrainingSet}.locations.stack=[yToRow(newLocation(2)) xToCol(newLocation(1)) handles.trainingSet.spotInfo{iTrainingSet}.locations.worm(3)];
    end;
    
    [c,ia,ib]=intersect(handles.goodOutlines,NW,'rows');
    handles.rejectedOutlines=[handles.rejectedOutlines;NW];
    handles.goodOutlines(ia,:)=[];
    handles.rejectedCurated=[handles.rejectedCurated;NW];
    [c,ia,ib]=intersect(handles.goodCurated,NW,'rows');
    handles.goodCurated(ia,:)=[];%just in case
    handles.nGoodToRejected=handles.nGoodToRejected+1;
    
    %for lineBox
    %     for
    %     rhi=1:length(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.rect)
    %         set(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.rect(rhi),'Color',[.7,.4,.1]);
    %     end;
    set(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.rect,'EdgeColor',[.7,.4,.1]);
    handles.iCurrentSpot_allLocs=min(size(handles.spotBoxLocations,1),handles.iCurrentSpot_allLocs+1);
    handles.iCurrentSpot_worms=handles.allLocs(handles.iCurrentSpot_allLocs,6);
    
end;
%setfocus(handles.spotResults);
%uicontrol(gcbf);
set(handles.arrowSpot_button,'Value',1);
guidata(hObject,handles);
displayImFull(hObject,handles,0);

%--adds final spot information
function worm = recordFinalClassification(worm)
%records the final spot count and adds field 'final' to the classification
worm.nSpotsFinal=0;
for si=1:size(worm.spotInfo,2)
    %remember that some of the spots were not classified but were thrown
    %out
    if isfield(worm.spotInfo{si},'classification')
        if isfield(worm.spotInfo{si}.classification,'manual')
            worm.spotInfo{si}.classification.final=worm.spotInfo{si}.classification.manual;
        else
            worm.spotInfo{si}.classification.final=worm.spotInfo{si}.classification.MachLearn{1};
        end;
        worm.nSpotsFinal=worm.nSpotsFinal+worm.spotInfo{si}.classification.final;
    end;
end;






% --- Executes on button press in done_button.
function done_button_Callback(hObject, eventdata, handles)
% hObject    handle to done_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.worms{handles.iCurrentWorm}=recordFinalClassification(handles.worms{handles.iCurrentWorm});
handles.worms{handles.iCurrentWorm}.spotsFixed=1;

if handles.iCurrentWorm<size(handles.worms,2)
    handles.iCurrentWorm=handles.iCurrentWorm+1;%go to the next worm
    while ~handles.worms{handles.iCurrentWorm}.goodWorm%if the worm is bad
        handles.iCurrentWorm=handles.iCurrentWorm+1;%go to the next worm
    end;
    if ~isfield(handles.worms{handles.iCurrentWorm},'spotsFixed')
        handles.worms{handles.iCurrentWorm}.spotsFixed=0;
    end;
    set(handles.fileName_button,'Value',handles.worms{handles.iCurrentWorm}.spotsFixed);
    
    spotBoxPositions=[];
    spotBoxLocations=[];
    goodLocs=[];
    rejectedLocs=[];
    
    
    placeholder=-100;
    disp('making good/rejectedLocs');
    for si=1:size(handles.worms{handles.iCurrentWorm}.spotInfo,2)
        %remember that some of the spots were not classified but were thrown
        %out
        if isfield(handles.worms{handles.iCurrentWorm}.spotInfo{si},'classification')
            iTrainingSet=isInTrainingSet(handles.trainingSet,handles.worms{handles.iCurrentWorm}.spotInfo{si});
            if iTrainingSet
                handles.worms{handles.iCurrentWorm}.spotInfo{si}.classification.manual=handles.trainingSet.spotInfo{iTrainingSet}.classification.manual;
            end;
            MLResults=zeros(1,size(handles.trainingSet.MachLearn,2)+1)-1;
            for mli=1:size(handles.trainingSet.MachLearn,2)
                if ~isempty(handles.worms{handles.iCurrentWorm}.spotInfo{si}.MachLearnResult{mli})
                    MLResults(mli)=handles.worms{handles.iCurrentWorm}.spotInfo{si}.MachLearnResult{mli};
                end;
            end;
            if isfield(handles.worms{handles.iCurrentWorm}.spotInfo{si}.classification,'manual')
                MLResults(end)=handles.worms{handles.iCurrentWorm}.spotInfo{si}.classification.manual;
                if handles.worms{handles.iCurrentWorm}.spotInfo{si}.classification.manual==1
                    goodLocs=[goodLocs;[handles.worms{handles.iCurrentWorm}.spotInfo{si}.locations.worm handles.worms{handles.iCurrentWorm}.spotInfo{si}.filteredValue placeholder si MLResults]];
                else
                    rejectedLocs=[rejectedLocs;[handles.worms{handles.iCurrentWorm}.spotInfo{si}.locations.worm handles.worms{handles.iCurrentWorm}.spotInfo{si}.filteredValue placeholder si MLResults]];
                end;
            else
                if isfield(handles.worms{handles.iCurrentWorm}.spotInfo{si}.classification,'MachLearn')
                    if handles.worms{handles.iCurrentWorm}.spotInfo{si}.classification.MachLearn{1}==1
                        %locations(1-3) filteredValue(4) MachLearnResult(5) si(6)
                        goodLocs=[goodLocs;[handles.worms{handles.iCurrentWorm}.spotInfo{si}.locations.worm handles.worms{handles.iCurrentWorm}.spotInfo{si}.filteredValue placeholder si MLResults]];
                    else
                        rejectedLocs=[rejectedLocs;[handles.worms{handles.iCurrentWorm}.spotInfo{si}.locations.worm handles.worms{handles.iCurrentWorm}.spotInfo{si}.filteredValue placeholder si MLResults]];
                    end;
                end;
            end;
        end;
    end;
    
    
    
    
    
    
    
    
    
    
    nSpots=size(goodLocs,1)+size(rejectedLocs,1);
    %need next largest multiple of spotSize(1) (assume square)
    
    handles.horizSideSize=min(handles.spotsPerRow,ceil(sqrt(nSpots)));
    handles.vertSideSize=ceil(nSpots/handles.horizSideSize);
    bkgdSubImage=zeros([handles.vertSideSize handles.vertSideSize].*handles.spotSize);
    handles.rejectedOutlines=[];%this is now going to be a list of NW corners (X,Y) for rectangles
    handles.goodOutlines=[];%this is now going to be a list of NW corners (X,Y) for rectangles
    handles.rejectedCurated=[];%this is now going to be a list of NW corners (X,Y) for rectangles
    handles.goodCurated=[];%this is now going to be a list of NW corners (X,Y) for rectangles
    handles.spotIndexImage=zeros(handles.horizSideSize);%size(bkgdSubImage));
    
    %handles.outlines=.5*bwperim(ones(spotSize))+(~bwperim(ones(spotSize)));
    if size(goodLocs,1)>0
        goodLocs=sortrows(goodLocs,handles.iMachLearnType);
        goodLocs=goodLocs(size(goodLocs,1):-1:1,:);
    end;
    rejectedLocs=sortrows(rejectedLocs,handles.iMachLearnType);
    rejectedLocs=rejectedLocs(size(rejectedLocs,1):-1:1,:);
    allLocs=[goodLocs;rejectedLocs];
    for si=1:size(allLocs,1)
        currentR=1+handles.spotSize(1)*floor((si-1)/handles.horizSideSize);
        currentC=1+handles.spotSize(1)*mod((si-1),handles.horizSideSize);
        
        
        
        
        NR=max(1,allLocs(si,1)-handles.offset(1));
        if NR==1
            %then too close to top
            SR=handles.spotSize(1);
        else
            if allLocs(si,1)+handles.offset(1)>size(handles.wormMask{handles.iCurrentWorm},1)
                SR=size(handles.wormMask{handles.iCurrentWorm},1);
                NR=size(handles.wormMask{handles.iCurrentWorm},1)-(handles.spotSize(1)-1);
            else
                SR=NR+(handles.spotSize(1)-1);
            end;
        end;
        WC=max(1,allLocs(si,2)-handles.offset(2));
        if WC==1
            %then too close to top
            EC=handles.spotSize(2);
        else
            if allLocs(si,2)+handles.offset(2)>size(handles.wormMask{handles.iCurrentWorm},2)
                EC=size(handles.wormMask{handles.iCurrentWorm},2);
                WC=size(handles.wormMask{handles.iCurrentWorm},2)-(handles.spotSize(2)-1);
            else
                EC=WC+handles.spotSize(2)-1;
            end;
        end;
        %is this always 7x7?
        dataMat=handles.wormImage{handles.iCurrentWorm}(NR:SR,WC:EC,allLocs(si,3));
        %        rawImage(currentR:currentR+spotSize(1)-1,currentC:currentC+spotSize(2)-1)=dataMat;
        bkgdSubImage(currentR:currentR+handles.spotSize(1)-1,currentC:currentC+handles.spotSize(2)-1)=dataMat-min(dataMat(:));
        handles.spotIndexImage(currentR:currentR+handles.spotSize(1)-1,currentC:currentC+handles.spotSize(2)-1)=zeros(size(dataMat))+si;
        if si<=size(goodLocs,1)
            handles.goodOutlines=[handles.goodOutlines;[colToX(currentC),rowToY(currentR)]];%(currentR:currentR+spotSize(1)-1,currentC:currentC+spotSize(2)-1)=handles.outlines;
            splitPoint=[rowToY(currentR+handles.spotSize(1)-1),colToX(currentC+handles.spotSize(2)-1)];%only really matters for the equality...legacy anyway
        else
            handles.rejectedOutlines=[handles.rejectedOutlines;[colToX(currentC),rowToY(currentR)]];%currentR:currentR+spotSize(1)-1,currentC:currentC+spotSize(2)-1)=handles.outlines;
        end;
        spotBoxPositions=[spotBoxPositions;[colToX(WC) rowToY(NR) handles.spotSize(1) handles.spotSize(2)]];%this is for highlighting on context image
        spotBoxLocations=[spotBoxLocations;[colToX(currentC),rowToY(currentR)]];%[currentR,currentR+spotSize(1)-1,currentC,currentC+spotSize(2)-1]];%this is for finding int he spotResults image...it is NW corners in (x,y)
    end;
    %bkgdSubImage=imscale(bkgdSubImage);wormImage already scaled
    
    handles.bkgdSubImage=bkgdSubImage;
    handles.goodLocs=goodLocs;
    handles.rejectedLocs=rejectedLocs;
    handles.allLocs=allLocs;
    handles.spotBoxPositions=spotBoxPositions;
    handles.spotBoxLocations=spotBoxLocations;
    handles.nGoodToRejected=0;
    handles.nRejectedToGood=0;
    handles.spotStatus=[ones(size(goodLocs,1),1);zeros(size(rejectedLocs,1),1)];%category vector
    handles.iCurrentSpot_allLocs=size(goodLocs,1);%last good spot
    if handles.iCurrentSpot_allLocs==0
        handles.iCurrentSpot_allLocs=1;
    end;
    
    handles.iCurrentSpot_worms=handles.allLocs(handles.iCurrentSpot_allLocs,6);
    %handles.goodCurated(spotBoxLocations(handles.iCurrentSpot_allLocs,1):spotBoxLocations(handles.iCurrentSpot_allLocs,2),spotBoxLocations(handles.iCurrentSpot_allLocs,3):spotBoxLocations(handles.iCurrentSpot_allLocs,4))=handles.curated;
    
    %redo image
    cla(handles.spotResults,'reset');
    handles.spotResultsImage=imshow(handles.bkgdSubImage,'Parent',handles.spotResults);%imshow(fullColor);
    set(handles.spotResultsImage,'HitTest','on');
    set(handles.spotResultsImage,'ButtonDownFcn',@spotResults_ButtonDownFcn);
    
    handles.rectangleHandles={};
    iRH=1;
    %set(handles.spotResultsImage,'CData',handles.bkgdSubImage);
    handles.currentSpotRectangle=rectangle('Position',[handles.spotBoxLocations(handles.iCurrentSpot_allLocs,1)+1,handles.spotBoxLocations(handles.iCurrentSpot_allLocs,2)+1 handles.spotSize-2],'EdgeColor',[1 0 0],'HitTest','off','Parent',handles.spotResults);
    for si=1:size(handles.goodOutlines,1)
        handles.rectangleHandles{iRH}.rect=rectangle('Position',[handles.goodOutlines(si,:) handles.spotSize-.5],'EdgeColor',[.1,.1,.5],'HitTest','off','Parent',handles.spotResults);
        %disp([num2str(si) ' ' num2str(852)]);
        iTrainingSet=isInTrainingSet(handles.trainingSet,handles.worms{handles.iCurrentWorm}.spotInfo{handles.allLocs(si,6)});
        if iTrainingSet
            if handles.trainingSet.categoryVector(handles.trainingSet.spotInfo{iTrainingSet}.iDataMatrix)==1
                tLineColor=[.1 .1 1];
            else
                tLineColor=[.5 .5 .1];
            end;
            %disp([handles.goodOutlines(si,1),handles.goodOutlines(si,1)+handles.spotSize(1)]);
            handles.rectangleHandles{iRH}.trainingLine=line('Xdata',[handles.goodOutlines(si,1)+1,handles.goodOutlines(si,1)+handles.spotSize(1)-1],'Ydata',[handles.goodOutlines(si,2)+1,handles.goodOutlines(si,2)+handles.spotSize(2)-1],'Color',tLineColor,'LineWidth',2,'HitTest','off','Parent',handles.spotResults);
            set(handles.rectangleHandles{iRH}.trainingLine,'UserData',iTrainingSet);%associate trainingSetIndex
            
        end;
        
        
        
        iRH=iRH+1;
    end;
    nGood=size(handles.goodOutlines,1);
    %rejected = yellow rectangles
    for si=1:size(handles.rejectedOutlines,1)
        handles.rectangleHandles{iRH}.rect=rectangle('Position',[handles.rejectedOutlines(si,:) handles.spotSize-.5],'EdgeColor',[.5,.5,.1],'HitTest','off','Parent',handles.spotResults);
        
        
        %disp([num2str(si) ' ' num2str(876)]);
        iTrainingSet=isInTrainingSet(handles.trainingSet,handles.worms{handles.iCurrentWorm}.spotInfo{handles.allLocs(si+nGood,6)});
        if iTrainingSet
            if handles.trainingSet.categoryVector(handles.trainingSet.spotInfo{iTrainingSet}.iDataMatrix)==1
                tLineColor=[.1 .1 1];
            else
                tLineColor=[.5 .5 .1];
            end;
            handles.rectangleHandles{iRH}.trainingLine=line('Xdata',[handles.rejectedOutlines(si,1)+1,handles.rejectedOutlines(si,1)+handles.spotSize(1)-1],'YData',[handles.rejectedOutlines(si,2)+1,handles.rejectedOutlines(si,2)+handles.spotSize(2)-1],'Color',tLineColor,'LineWidth',2,'HitTest','off','Parent',handles.spotResults);
            set(handles.rectangleHandles{iRH}.trainingLine,'UserData',iTrainingSet);%associate trainingSetIndex
        end;
        
        
        iRH=iRH+1;
    end;
else%then completely done-write training set and new spotFile,  21April2011 and goldSpots and rejectedSpots files
    disp('Spot fixing done.  Saving changes');
    trainingSet=handles.trainingSet;
    save(handles.trainingSet.name,'trainingSet');
    
    %%%%%%%%%%%%%%%%%
    %21April2011
    %Also regenerate goldSpots and rejectedSpots files...this takes care of
    %having to find the previous spots in the gold/rejected files
    goldSpots={};
    rejectedSpots={};
    for tsspi=1:size(trainingSet.spotInfo,2)
        if isfield(trainingSet.spotInfo{tsspi}.classification,'manual')
            if trainingSet.spotInfo{tsspi}.classification.manual==1
                if ~isfield(goldSpots,regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'))
                    goldSpots.(regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'))=[];
                end;
                goldSpots.(regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'))=[goldSpots.(regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'));trainingSet.spotInfo{tsspi}.locations.stack];
            else
                if ~isfield(rejectedSpots,regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'))
                    rejectedSpots.(regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'))=[];
                end;
                rejectedSpots.(regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'))=[rejectedSpots.(regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'));trainingSet.spotInfo{tsspi}.locations.stack];
            end;
        end;
    end;
    save(regexprep(handles.trainingSet.name,'trainingSet','goldSpots'),'goldSpots');
    save(regexprep(handles.trainingSet.name,'trainingSet','rejectedSpots'),'rejectedSpots');
    %%%%%%%%%%%%%%%%%%%%
    
    worms=handles.worms;
    save(handles.wormsFileName,'worms');
    
    %Go through and write text file with info
    prefix=regexp(handles.wormsFileName,'_','split');
    prefix=prefix{1};
    fileID=fopen([prefix '_wormSpotResults.csv'],'w');
    fprintf('nSpots,dye,iWorm,stackSuffix\n');
    for wi=1:size(worms,2)
        fprintf(fileID,'%d,%s,%d,%s\n',worms{wi}.nSpotsFinal,handles.dye,wi,['stack' handles.stackSuffix]);
    end;
    fclose(fileID);
    uiresume(gcbf);
end;
set(handles.arrowSpot_button,'Value',1)
guidata(hObject,handles);
displayImFull(hObject,handles,0);

% --- Executes on mouse press over axes background.
function spotResults_ButtonDownFcn(currhandle, eventdata)
% hObject    handle to spotResults (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%get location of mouse click

data=guidata(currhandle);
%disp('Mouse button clicked');
pt = get(data.spotResults,'currentpoint');
pixel_c=xToCol(pt(1,1));
pixel_r=yToRow(pt(1,2));
%disp(pt);
%assign it to some spot
%disp(data.spotIndexImage);
spotIndex=data.spotIndexImage(pixel_r,pixel_c);
if spotIndex>0
    data.iCurrentSpot_allLocs=spotIndex;
    data.iCurrentSpot_worms=data.allLocs(data.iCurrentSpot_allLocs,6);
end;
set(data.arrowSpot_button,'Value',1)
guidata(currhandle,data);
displayImFull(currhandle,data,0);

% --- Executes during object creation, after setting all properties.
function spotResults_CreateFcn(hObject, eventdata, handles)
% hObject    handle to spotResults (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate spotResults

% --- Executes on key press with focus on figure1 and no controls selected.
function figure1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%eventdata.Key
data=guidata(hObject);
if strcmp(eventdata.Key,'leftarrow')
    data.iCurrentSpot_allLocs=max(data.iCurrentSpot_allLocs-1,1);
    data.iCurrentSpot_worms=data.allLocs(data.iCurrentSpot_allLocs,6);
elseif strcmp(eventdata.Key,'rightarrow')
    data.iCurrentSpot_allLocs=min(size(data.spotBoxLocations,1),data.iCurrentSpot_allLocs+1);
    data.iCurrentSpot_worms=data.allLocs(data.iCurrentSpot_allLocs,6);
elseif strcmp(eventdata.Key,'uparrow')
    data.iCurrentSpot_allLocs=max(1,data.iCurrentSpot_allLocs-data.horizSideSize);
    data.iCurrentSpot_worms=data.allLocs(data.iCurrentSpot_allLocs,6);
elseif strcmp(eventdata.Key,'downarrow')
    data.iCurrentSpot_allLocs=min(size(data.spotBoxLocations,1),data.iCurrentSpot_allLocs+data.horizSideSize);
    data.iCurrentSpot_worms=data.allLocs(data.iCurrentSpot_allLocs,6);
elseif strcmp(eventdata.Key,'pagedown')
    data.iCurrentSpot_allLocs=min(size(data.spotBoxLocations,1),data.iCurrentSpot_allLocs+(data.horizSideSize^2)+1);
    data.iCurrentSpot_worms=data.allLocs(data.iCurrentSpot_allLocs,6);
elseif strcmp(eventdata.Key,'pageup')
    data.iCurrentSpot_allLocs=max(1,data.iCurrentSpot_allLocs-(data.horizSideSize^2));
    data.iCurrentSpot_worms=data.allLocs(data.iCurrentSpot_allLocs,6);
end;
set(data.arrowSpot_button,'Value',1)
guidata(hObject,data);
displayImFull(hObject,data,0);

% --- Executes on key press with focus on rejectedSpot_button and none of its controls.
function rejectedSpot_button_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to rejectedSpot_button (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
%keypress = get(handles.figure_handle,'CurrentCharacter');%handles.figure1
figure1_KeyPressFcn(hObject, eventdata, handles);

% --- Executes on key press with focus on goodSpot_button and none of its controls.
function goodSpot_button_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to goodSpot_button (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

figure1_KeyPressFcn(hObject, eventdata, handles);

% --- Executes on key press with focus on done_button and none of its controls.
function done_button_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to done_button (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

figure1_KeyPressFcn(hObject, eventdata, handles);

% --- Executes on key press with focus on redoMachLearn_button and none of its controls.
function redoMachLearn_button_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to rejectedSpot_button (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
%keypress = get(handles.figure_handle,'CurrentCharacter');%handles.figure1
figure1_KeyPressFcn(hObject, eventdata, handles);

% --- Executes on button press in redoMachLearn_button.
function redoMachLearn_button_Callback(hObject, eventdata, handles)
% hObject    handle to redoMachLearn_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%this reruns the classifyFISHSpots machine learning with the new curated
%trainingdata and starts the process of evaluating these spots over
trainingSet=handles.trainingSet;
save(handles.trainingSet.name,'trainingSet');
handles.trainingSet=trainFISHClassifier(handles.trainingSet,1);  %nameMod
handles.worms=classifyFISHSpots(handles.dye,handles.stackSuffix,handles.worms{handles.iCurrentWorm}.probeName,handles.worms,1);   %nameMod%save wormGaussianFitFile
%now redo everyting


handles.iCurrentWorm=1;
spotBoxPositions=[];
spotBoxLocations=[];
goodLocs=[];
rejectedLocs=[];

placeholder=-100;
disp('making good/rejectedLocs');
for si=1:size(handles.worms{handles.iCurrentWorm}.spotInfo,2)
    %remember that some of the spots were not classified but were thrown
    %out
    if isfield(handles.worms{handles.iCurrentWorm}.spotInfo{si},'classification')
        if ~isfield(handles.worms{handles.iCurrentWorm}.spotInfo{si}.classification,'manual')
            %disp([num2str(si) ' ' num2str(1049)]);
            iTrainingSet=isInTrainingSet(handles.trainingSet,handles.worms{handles.iCurrentWorm}.spotInfo{si});
            if iTrainingSet
                handles.worms{handles.iCurrentWorm}.spotInfo{si}.classification.manual=handles.trainingSet.spotInfo{iTrainingSet}.classification.manual;
            end;
        end;
        
        MLResults=zeros(1,size(handles.trainingSet.MachLearn,2)+1)-1;
        for mli=1:size(handles.trainingSet.MachLearn,2)
            if ~isempty(handles.worms{handles.iCurrentWorm}.spotInfo{si}.MachLearnResult{mli})
                MLResults(mli)=handles.worms{handles.iCurrentWorm}.spotInfo{si}.MachLearnResult{mli};
            end;
        end;
        if isfield(handles.worms{handles.iCurrentWorm}.spotInfo{si}.classification,'manual')
            MLResults(end)=handles.worms{handles.iCurrentWorm}.spotInfo{si}.classification.manual;
            if handles.worms{handles.iCurrentWorm}.spotInfo{si}.classification.manual==1
                goodLocs=[goodLocs;[handles.worms{handles.iCurrentWorm}.spotInfo{si}.locations.worm handles.worms{handles.iCurrentWorm}.spotInfo{si}.filteredValue placeholder si MLResults]];
            else
                rejectedLocs=[rejectedLocs;[handles.worms{handles.iCurrentWorm}.spotInfo{si}.locations.worm handles.worms{handles.iCurrentWorm}.spotInfo{si}.filteredValue placeholder si MLResults]];
            end;
        else
            
            if isfield(handles.worms{handles.iCurrentWorm}.spotInfo{si}.classification,'MachLearn')
                if handles.worms{handles.iCurrentWorm}.spotInfo{si}.classification.MachLearn{1}==1
                    %locations(1-3) filteredValue(4) MachLearnResult(5) si(6)
                    goodLocs=[goodLocs;[handles.worms{handles.iCurrentWorm}.spotInfo{si}.locations.worm handles.worms{handles.iCurrentWorm}.spotInfo{si}.filteredValue placeholder si MLResults]];
                else
                    rejectedLocs=[rejectedLocs;[handles.worms{handles.iCurrentWorm}.spotInfo{si}.locations.worm handles.worms{handles.iCurrentWorm}.spotInfo{si}.filteredValue placeholder si MLResults]];
                end;
            end;
        end;
    end;
end;

nSpots=size(goodLocs,1)+size(rejectedLocs,1);
%need next largest multiple of spotSize(1) (assume square)
handles.horizSideSize=min(handles.spotsPerRow,ceil(sqrt(nSpots)));
handles.vertSideSize=ceil(nSpots/handles.horizSideSize);
bkgdSubImage=zeros([handles.vertSideSize handles.vertSideSize].*handles.spotSize);
handles.rejectedOutlines=[];%this is now going to be a list of NW corners (X,Y) for rectangles
handles.goodOutlines=[];%this is now going to be a list of NW corners (X,Y) for rectangles
handles.rejectedCurated=[];%this is now going to be a list of NW corners (X,Y) for rectangles
handles.goodCurated=[];%this is now going to be a list of NW corners (X,Y) for rectangles
handles.spotIndexImage=zeros(handles.horizSideSize);%size(bkgdSubImage));

if size(goodLocs,1)>0
    goodLocs=sortrows(goodLocs,handles.iMachLearnType);
    goodLocs=goodLocs(size(goodLocs,1):-1:1,:);
end;
rejectedLocs=sortrows(rejectedLocs,handles.iMachLearnType);
rejectedLocs=rejectedLocs(size(rejectedLocs,1):-1:1,:);
allLocs=[goodLocs;rejectedLocs];
for si=1:size(allLocs,1)
    currentR=1+handles.spotSize(1)*floor((si-1)/handles.horizSideSize);
    currentC=1+handles.spotSize(1)*mod((si-1),handles.horizSideSize);
    NR=max(1,allLocs(si,1)-handles.offset(1));
    if NR==1
        %then too close to top
        SR=handles.spotSize(1);
    else
        if allLocs(si,1)+handles.offset(1)>size(handles.wormMask{handles.iCurrentWorm},1)
            SR=size(handles.wormMask{handles.iCurrentWorm},1);
            NR=size(handles.wormMask{handles.iCurrentWorm},1)-(handles.spotSize(1)-1);
        else
            SR=NR+(handles.spotSize(1)-1);
        end;
    end;
    WC=max(1,allLocs(si,2)-handles.offset(2));
    if WC==1
        %then too close to top
        EC=handles.spotSize(2);
    else
        if allLocs(si,2)+handles.offset(2)>size(handles.wormMask{handles.iCurrentWorm},2)
            EC=size(handles.wormMask{handles.iCurrentWorm},2);
            WC=size(handles.wormMask{handles.iCurrentWorm},2)-(handles.spotSize(2)-1);
        else
            EC=WC+handles.spotSize(2)-1;
        end;
    end;
    %is this always 7x7?
    dataMat=handles.wormImage{handles.iCurrentWorm}(NR:SR,WC:EC,allLocs(si,3));
    %        rawImage(currentR:currentR+spotSize(1)-1,currentC:currentC+spotSize(2)-1)=dataMat;
    bkgdSubImage(currentR:currentR+handles.spotSize(1)-1,currentC:currentC+handles.spotSize(2)-1)=dataMat-min(dataMat(:));
    handles.spotIndexImage(currentR:currentR+handles.spotSize(1)-1,currentC:currentC+handles.spotSize(2)-1)=zeros(size(dataMat))+si;
    if si<=size(goodLocs,1)
        handles.goodOutlines=[handles.goodOutlines;[colToX(currentC),rowToY(currentR)]];%(currentR:currentR+spotSize(1)-1,currentC:currentC+spotSize(2)-1)=handles.outlines;
        splitPoint=[rowToY(currentR+handles.spotSize(1)-1),colToX(currentC+handles.spotSize(2)-1)];%only really matters for the equality...legacy anyway
    else
        handles.rejectedOutlines=[handles.rejectedOutlines;[colToX(currentC),rowToY(currentR)]];%currentR:currentR+spotSize(1)-1,currentC:currentC+spotSize(2)-1)=handles.outlines;
    end;
    spotBoxPositions=[spotBoxPositions;[colToX(WC) rowToY(NR) handles.spotSize(1) handles.spotSize(2)]];%this is for highlighting on context image
    spotBoxLocations=[spotBoxLocations;[colToX(currentC),rowToY(currentR)]];%[currentR,currentR+spotSize(1)-1,currentC,currentC+spotSize(2)-1]];%this is for finding int he spotResults image...it is NW corners in (x,y)
end;
%bkgdSubImage=imscale(bkgdSubImage);wormImage already scaled

handles.bkgdSubImage=bkgdSubImage;
handles.goodLocs=goodLocs;
handles.rejectedLocs=rejectedLocs;
handles.allLocs=allLocs;
handles.spotBoxPositions=spotBoxPositions;
handles.spotBoxLocations=spotBoxLocations;
handles.nGoodToRejected=0;
handles.nRejectedToGood=0;
handles.spotStatus=[ones(size(goodLocs,1),1);zeros(size(rejectedLocs,1),1)];%category vector
handles.iCurrentSpot_allLocs=size(goodLocs,1);%last good spot
%if there are no good spots then just increase by 1
if handles.iCurrentSpot_allLocs==0
    handles.iCurrentSpot_allLocs=1;
end;
handles.iCurrentSpot_worms=handles.allLocs(handles.iCurrentSpot_allLocs,6);
%handles.goodCurated(spotBoxLocations(handles.iCurrentSpot_allLocs,1):spotBoxLocations(handles.iCurrentSpot_allLocs,2),spotBoxLocations(handles.iCurrentSpot_allLocs,3):spotBoxLocations(handles.iCurrentSpot_allLocs,4))=handles.curated;

%redo image
cla(handles.spotResults,'reset');
handles.spotResultsImage=imshow(handles.bkgdSubImage,'Parent',handles.spotResults);%imshow(fullColor);
set(handles.spotResultsImage,'HitTest','on');
set(handles.spotResultsImage,'ButtonDownFcn',@spotResults_ButtonDownFcn);
handles.rectangleHandles={};
iRH=1;
%set(handles.spotResultsImage,'CData',handles.bkgdSubImage);
handles.currentSpotRectangle=rectangle('Position',[handles.spotBoxLocations(handles.iCurrentSpot_allLocs,1)+1,handles.spotBoxLocations(handles.iCurrentSpot_allLocs,2)+1 handles.spotSize-2],'EdgeColor',[1 0 0],'HitTest','off','Parent',handles.spotResults);
nGood=size(handles.goodOutlines,1);
for si=1:size(handles.goodOutlines,1)
    handles.rectangleHandles{iRH}.rect=rectangle('Position',[handles.goodOutlines(si,:) handles.spotSize-.5],'EdgeColor',[.1,.1,.5],'HitTest','off','Parent',handles.spotResults);
    %disp([num2str(si) ' ' num2str(1170)]);
    iTrainingSet=isInTrainingSet(handles.trainingSet,handles.worms{handles.iCurrentWorm}.spotInfo{handles.allLocs(si,6)});
    if iTrainingSet
        if handles.trainingSet.categoryVector(handles.trainingSet.spotInfo{iTrainingSet}.iDataMatrix)==1
            tLineColor=[.1 .1 1];
        else
            tLineColor=[.5 .5 .1];
        end;
        %disp([handles.goodOutlines(si,1),handles.goodOutlines(si,1)+handles.spotSize(1)]);
        handles.rectangleHandles{iRH}.trainingLine=line('Xdata',[handles.goodOutlines(si,1)+1,handles.goodOutlines(si,1)+handles.spotSize(1)-1],'Ydata',[handles.goodOutlines(si,2)+1,handles.goodOutlines(si,2)+handles.spotSize(2)-1],'Color',tLineColor,'LineWidth',2,'HitTest','off','Parent',handles.spotResults);
        set(handles.rectangleHandles{iRH}.trainingLine,'UserData',iTrainingSet);%associate trainingSetIndex
    end;
    iRH=iRH+1;
end;
%rejected = yellow rectangles
for si=1:size(handles.rejectedOutlines,1)
    handles.rectangleHandles{iRH}.rect=rectangle('Position',[handles.rejectedOutlines(si,:) handles.spotSize-.5],'EdgeColor',[.5,.5,.1],'HitTest','off','Parent',handles.spotResults);
    iTrainingSet=isInTrainingSet(handles.trainingSet,handles.worms{handles.iCurrentWorm}.spotInfo{handles.allLocs(si+nGood,6)});
    if iTrainingSet
        if handles.trainingSet.categoryVector(handles.trainingSet.spotInfo{iTrainingSet}.iDataMatrix)==1
            tLineColor=[.1 .1 1];
        else
            tLineColor=[.5 .5 .1];
        end;
        handles.rectangleHandles{iRH}.trainingLine=line('Xdata',[handles.rejectedOutlines(si,1)+1,handles.rejectedOutlines(si,1)+handles.spotSize(1)-1],'YData',[handles.rejectedOutlines(si,2)+1,handles.rejectedOutlines(si,2)+handles.spotSize(2)-1],'Color',tLineColor,'LineWidth',2,'HitTest','off','Parent',handles.spotResults);
        set(handles.rectangleHandles{iRH}.trainingLine,'UserData',iTrainingSet);%associate trainingSetIndex
    end;
    iRH=iRH+1;
end;

set(handles.arrowSpot_button,'Value',1)
guidata(hObject,handles);
displayImFull(hObject,handles,0);

% --- Executes on button press in badWorm_button.
function badWorm_button_Callback(hObject, eventdata, handles)
% hObject    handle to badWorm_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.worms{handles.iCurrentWorm}.goodWorm=0;
set(handles.badWorm_button,'Value',1)
guidata(hObject,handles);
done_button_Callback(hObject,eventdata,handles);

% --- Executes on key press with focus on badWorm_button and none of its controls.
function badWorm_button_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to badWorm (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
%keypress = get(handles.figure_handle,'CurrentCharacter');%handles.figure1
figure1_KeyPressFcn(hObject, eventdata, handles);

% --- figures out if a spot is already in the training set - this is to
% mark originally and also to return the index if it needs to be changed
%compares the data with the idea that the data will only be completely
%equal if the spots are the same...if this is a problem, I could useother
%fields of spotInfo
function iTrainingSet = isInTrainingSet(trainingSet,spotInfo)
%modified 28April2011 to just look to see if same position in stack (and
%same stackName and directory)...except there is some coordinate mismatch
%somewhere...if trainingSet.stack = [x y z] then worms = [x-1 y-1 z]...so
%allow for this...trainingSet is correct.  worm location info must be
%off...but is it off all the way through?...this may explain why the array
%is always slightly off...note that arrow should also have a 1/2 to it.
%dataMat is equal for both so could use that
iTrainingSet=0;
for si=1:size(trainingSet.spotInfo,2)
    %if isequal(spotInfo.dataMat,trainingSet.spotInfo{si}.dataMat)
    
    if (isequal(spotInfo.directory,trainingSet.spotInfo{si}.directory) && isequal(spotInfo.stackName,trainingSet.spotInfo{si}.stackName) && isequal(spotInfo.locations.stack,trainingSet.spotInfo{si}.locations.stack))
        iTrainingSet=si;
        break;
    end;
end;

function spotPage = currentSpotPage(horizSideSize,spotSize,spotBoxLocations,iCurrentSpot)

spotBoxesTotalWidth=horizSideSize*spotSize;
currentSpotY=spotBoxLocations(iCurrentSpot,2);%N edge of spotBox
spotPage=ceil(currentSpotY/(spotBoxesTotalWidth));

function m=getCurrentGoodMax(handles)
%create vector of goodLoc values
goodIntensities=[];
goodIndices=find(handles.spotStatus==1);
for ai=1:length(goodIndices)
    loc=handles.allLocs(goodIndices(ai),1:3);
    goodIntensities=[goodIntensities handles.wormImage{handles.iCurrentWorm}(loc(1),loc(2),loc(3))];
end;
m=max(goodIntensities);



% --- Executes on button press in arrowSpot_button.
function arrowSpot_button_Callback(hObject, eventdata, handles)
% hObject    handle to arrowSpot_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of arrowSpot_button
%checkboxStatus = 0, if the box is unchecked,
%checkboxStatus = 1, if the box is checked
%handles.rectangleAroundSpotOnEmbryo = get(handles.arrowSpot_button,'Value');
guidata(hObject,handles);
displayImFull(hObject,handles,0);

% --- Executes during object creation, after setting all properties.
function fileName_button_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fileName_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes on button press in fileName_button.
function fileName_button_Callback(hObject, eventdata, handles)
% hObject    handle to fileName_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of fileName_button
%if the user unchecks the handle, then the state of "spotsFixed" changes so
%that user can redo.  the program reads the value of spotsFixed before it
%decides to save/update or not
if handles.worms{handles.iCurrentWorm}.spotsFixed> get(hObject,'Value')
    handles.worms{handles.iCurrentWorm}.spotsFixed=get(hObject,'Value');
end;
guidata(hObject,handles);
displayImFull(hObject,handles,0);

% --- Executes on button press in addToTrainingSet_button.
function addToTrainingSet_button_Callback(hObject, eventdata, handles)
% hObject    handle to addToTrainingSet_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


currentSpotClassification=handles.worms{handles.iCurrentWorm}.spotInfo{handles.iCurrentSpot_worms}.classification;
if isfield(currentSpotClassification,'manual')
    cla=currentSpotClassification.manual;
else
    if isfield(currentSpotClassification,'MachLearn')
        cla=currentSpotClassification.MachLearn{1};
    end;
end;
if isfield(handles.rectangleHandles{handles.iCurrentSpot_allLocs},'trainingLine') %then it is already in the trainingSet...don't need to do anything
    iTrainingSet=get(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine,'UserData');
    %     handles.trainingSet.categoryVector(handles.trainingSet.spotInfo{iTrainingSet}.iDataMatrix)=cla;
    %     set(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine,'Color',trainingLineColor);
    disp(sprintf('Spot already in training set (index: %d) and classified as %d',iTrainingSet,cla));
else
    
    if cla==1
        trainingLineColor=[0, .7, .7];
    else
        trainingLineColor=[.7,.4,.1];
    end;
    
    
    %if cla~=1
    disp(sprintf('Adding spot %d to training set',handles.iCurrentSpot_worms));
    handles.worms{handles.iCurrentWorm}.spotInfo{handles.iCurrentSpot_worms}.classification.manual=cla;
    %modify image
    %compass=handles.spotBoxLocations(handles.iCurrentSpot_allLocs,:);
    %NR=compass(1);SR=compass(2);WC=compass(3);EC=compass(4);
    NW=handles.spotBoxLocations(handles.iCurrentSpot_allLocs,:);
    handles.spotStatus(handles.iCurrentSpot_allLocs)=1;
    %    rejectedIndex=find(handles.rejectedLocs(:,6)==handles.iCurrentSpot_allLocs);
    %    handles.goodLocs=[handles.goodLocs;handles.rejectedLocs(rejectedIndex,:)];
    %    handles.rejectedLocs(rejectedIndex,:)=[];
    %add to training set if not already in it
    
    iTrainingSet=size(handles.trainingSet.spotInfo,2)+1;
    handles.trainingSet.dataMatrix=[handles.trainingSet.dataMatrix;handles.worms{handles.iCurrentWorm}.spotInfo{handles.iCurrentSpot_worms}.data];
    handles.trainingSet.categoryVector=[handles.trainingSet.categoryVector;cla];
    %specific spot info
    fields={'dataMat','directory','dye','stackSuffix','stackName','wormNumber','stat','classification','locations'};
    for fi=1:length(fields)
        handles.trainingSet.spotInfo{iTrainingSet}.(fields{fi})=handles.worms{handles.iCurrentWorm}.spotInfo{handles.iCurrentSpot_worms}.(fields{fi});
    end;
    handles.trainingSet.spotInfo{iTrainingSet}.spotInfoNumberInWorm=handles.iCurrentSpot_worms;
    handles.trainingSet.spotInfo{iTrainingSet}.iDataMatrix=size(handles.trainingSet.dataMatrix,1);
    rectposition=get(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.rect,'Position');
    handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine=line('XData',[rectposition(1),rectposition(1)+handles.spotSize(1)-1],'YData',[rectposition(2),rectposition(2)+handles.spotSize(2)-1],'LineWidth',1,'HitTest','off','Parent',handles.spotResults,'Visible','off');
    set(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine,'UserData',iTrainingSet);
    set(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine,'Color',trainingLineColor);
    
    if ~isfield(handles.trainingSet.spotInfo{iTrainingSet}.locations,'stack')
        newLocation=translateToNewCoordinates([colToX(handles.trainingSet.spotInfo{iTrainingSet}.locations.worm(2)) rowToY(handles.trainingSet.spotInfo{iTrainingSet}.locations.worm(1))],handles.wormBBs{handles.iCurrentWorm},'StoL');
        handles.trainingSet.spotInfo{iTrainingSet}.locations.stack=[yToRow(newLocation(2)) xToCol(newLocation(1)) handles.trainingSet.spotInfo{iTrainingSet}.locations.worm(3)];
    end;
    
    if cla==1
        handles.goodCurated=[handles.goodCurated;NW];
    else
        handles.rejectedCurated=[handles.rejectedCurated;NW];
    end;%is this if then statement necessary?
    
    %change the color
    %for lineBox
    set(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.rect,'EdgeColor',trainingLineColor);
end;
handles.iCurrentSpot_allLocs=min(size(handles.spotBoxLocations,1),handles.iCurrentSpot_allLocs+1);
handles.iCurrentSpot_worms=handles.allLocs(handles.iCurrentSpot_allLocs,6);

%setfocus(handles.spotResults);
%uicontrol(gcbf);
set(handles.arrowSpot_button,'Value',1)
guidata(hObject,handles);
displayImFull(hObject,handles,0);

% --- Executes on key press with focus on addToTrainingSet_button and none
% of its controls. added 2/17/10
function addToTrainingSet_button_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to addToTrainingSet_button (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

figure1_KeyPressFcn(hObject, eventdata, handles);

% --- Executes on button press in sliceMerge_button.
function sliceMerge_button_Callback(hObject, eventdata, handles)
% hObject    handle to sliceMerge_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of sliceMerge_button
guidata(hObject,handles);
displayImFull(hObject,handles,0);

% --- Executes on key press with focus on sliceMerge_button and none of its controls.
function sliceMerge_button_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to sliceMerge_button (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

figure1_KeyPressFcn(hObject, eventdata, handles);


%%%%%%%User defined function
function newIm=minPrctileScale(im)
newIm=im-min(im(:));
newIm=im/prctile(im(:),25);


% --- Executes on button press in laplaceFilter_button.
function laplaceFilter_button_Callback(hObject, eventdata, handles)
% hObject    handle to laplaceFilter_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of laplaceFilter_button
guidata(hObject,handles);
displayImFull(hObject,handles,0);


% --- Executes on key press with focus on laplaceFilter_button and none of its controls.
function laplaceFilter_button_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to laplaceFilter_button (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
figure1_KeyPressFcn(hObject, eventdata, handles);


% --- Executes on button press in saveData_button.
function saveData_button_Callback(hObject, eventdata, handles)
% hObject    handle to saveData_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.worms{handles.iCurrentWorm}=recordFinalClassification(handles.worms{handles.iCurrentWorm});
handles.worms{handles.iCurrentWorm}.spotsFixed=1;

disp('Saving changes');
trainingSet=handles.trainingSet;
save(handles.trainingSet.name,'trainingSet');

%%%%%%%%%%%%%%%%%
%21April2011
%Also regenerate goldSpots and rejectedSpots files...this takes care of
%having to find the previous spots in the gold/rejected files
goldSpots={};
rejectedSpots={};
for tsspi=1:size(trainingSet.spotInfo,2)
    if isfield(trainingSet.spotInfo{tsspi}.classification,'manual')
        if trainingSet.spotInfo{tsspi}.classification.manual==1
            if ~isfield(goldSpots,regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'))
                goldSpots.(regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'))=[];
            end;
            goldSpots.(regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'))=[goldSpots.(regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'));trainingSet.spotInfo{tsspi}.locations.stack];
        else
            if ~isfield(rejectedSpots,regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'))
                rejectedSpots.(regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'))=[];
            end;
            rejectedSpots.(regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'))=[rejectedSpots.(regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'));trainingSet.spotInfo{tsspi}.locations.stack];
        end;
    end;
end;
save(regexprep(handles.trainingSet.name,'trainingSet','goldSpots'),'goldSpots');
save(regexprep(handles.trainingSet.name,'trainingSet','rejectedSpots'),'rejectedSpots');
%%%%%%%%%%%%%%%%%%%%

worms=handles.worms;
save(handles.wormsFileName,'worms');

%Go through and write text file with info
prefix=regexp(handles.wormsFileName,'_','split');
prefix=prefix{1};
fileID=fopen([prefix '_wormSpotResults.csv'],'w');
fprintf('nSpots,dye,iWorm,stackSuffix\n');
for wi=1:size(worms,2)
    fprintf(fileID,'%d,%s,%d,%s\n',worms{wi}.nSpotsFinal,handles.dye,wi,['stack' handles.stackSuffix]);
end;
fclose(fileID);

set(handles.arrowSpot_button,'Value',1)
guidata(hObject,handles);
displayImFull(hObject,handles,0);


% --- Executes on key press with focus on saveData_button and none of its controls.
function saveData_button_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to saveData_button (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
figure1_KeyPressFcn(hObject, eventdata, handles);


% --- Executes on button press in allDone_button.
function allDone_button_Callback(hObject, eventdata, handles)
% hObject    handle to allDone_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.worms{handles.iCurrentWorm}=recordFinalClassification(handles.worms{handles.iCurrentWorm});
handles.worms{handles.iCurrentWorm}.spotsFixed=1;


disp('Spot fixing done.  Saving changes');
trainingSet=handles.trainingSet;
save(handles.trainingSet.name,'trainingSet');

%%%%%%%%%%%%%%%%%
%21April2011
%Also regenerate goldSpots and rejectedSpots files...this takes care of
%having to find the previous spots in the gold/rejected files
goldSpots={};
rejectedSpots={};
for tsspi=1:size(trainingSet.spotInfo,2)
    if isfield(trainingSet.spotInfo{tsspi}.classification,'manual')
        if trainingSet.spotInfo{tsspi}.classification.manual==1
            if ~isfield(goldSpots,regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'))
                goldSpots.(regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'))=[];
            end;
            goldSpots.(regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'))=[goldSpots.(regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'));trainingSet.spotInfo{tsspi}.locations.stack];
        else
            if ~isfield(rejectedSpots,regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'))
                rejectedSpots.(regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'))=[];
            end;
            rejectedSpots.(regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'))=[rejectedSpots.(regexprep(trainingSet.spotInfo{tsspi}.stackName,'\.','_'));trainingSet.spotInfo{tsspi}.locations.stack];
        end;
    end;
end;
save(regexprep(handles.trainingSet.name,'trainingSet','goldSpots'),'goldSpots');
save(regexprep(handles.trainingSet.name,'trainingSet','rejectedSpots'),'rejectedSpots');
%%%%%%%%%%%%%%%%%%%%

worms=handles.worms;
save(handles.wormsFileName,'worms');

%Go through and write text file with info
prefix=regexp(handles.wormsFileName,'_','split');
prefix=prefix{1};
fileID=fopen([prefix '_wormSpotResults.csv'],'w');
fprintf('nSpots,dye,iWorm,stackSuffix\n');
for wi=1:size(worms,2)
    fprintf(fileID,'%d,%s,%d,%s\n',worms{wi}.nSpotsFinal,handles.dye,wi,['stack' handles.stackSuffix]);
end;
fclose(fileID);
uiresume(gcbf);
