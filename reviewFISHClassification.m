function varargout = reviewFISHClassification(varargin)  %nameMod
%% =============================================================
%   Name:    reviewFISHClassification.m
%   Version: 2.5.1, 25th Apr. 2013
%   Authors:  Allison Wu, Scott Rifkin
%   Command:  reviewFISHClassification(stackName*) *Optional Input
%   Description: reviewFISHClassification.m is a gui to browse the results of the spot finding algorithm, estimate and/or correct errors, and retraing the classifier if specified.
%       -  Input Argument:
%               * stackName, or {dye}_{stackSuffix} pair e.g. tmr_Pos1.tif, tmr001.stk, tmr_001, tmr_Pos1
%               * If absent, it will ask you for the stackName.
%       - The program brings up 4 image panes and several buttons:
%               * The big one on the left has the evaluated maxima arranged left to right, top to bottom in order of probability estimates predicted.
%               * The big one on the right has the zoomable image centered around the potential spot.
%               * Two smaller ones on the bottom left have zooms of the region around a spot with the raw data and a laplace filtered image of the same region.
%               * The 7x7 spot context (along with neighboring slices) is shown in the middle (3D intensity histograms).
%               * In the left image pane:
%                       > Maxima that are classified as spots are bordered by blue.
%                       > Maxima that are rejected as spots are bordered in yellow.
%                       > Maxima that are in the training set have a cross on them.
%                       > Maxima that are manually curated but not in the
%                       training set have a single diagnol slash through them.
%                       > The current maximum is marked by a red box.
%                       > Maxima that are curated at this time are marked
%                       with light blue border and cross/slash.
%       - Possible actions:
%               * Click on the grey background of the gui.
%                       > If you are going to use keystrokes, it is necessary to focus the computer's attention on the gui.
%                       > Clicking on the grey background changes the focus to the gui and makes the program interpret keystrokes as the gui tells it to.
%               * Click the 'Done fixing this worm' button.
%                       > Done fixing this worm.
%                       > Saves all the changes and move on to the next worm.
%               * Page up/down keys.  $
%                       > The left image pane is 25x25 but often more potential spots are evaluated.  Page up and down move you up or down to the next page of potential spots.
%               * Left/right/up/down arrow.
%                       > Used to move around the left image pane.
%               * Bad worm toggle button. $
%                       > If you don't like the looks of the specimen, flag it as bad and move on.
%               * Click 'Good Spot' button
%                       > If you're on a good spot:  this spot will be added to the training set. (With a light blue X)
%                       > If you're on a bad spot: this spot will be curated to a good spot but it will not be added to the training set. (With a single light blue slash)
%               * Click 'Not a Spot' button
%                       > If you're on a bad spot:  this spot will be added to the training set. (With a light blue X)
%                       > If you're on a good spot: this spot will be curated to a bad spot but it will not be added to the training set. (With a single light blue slash)
%               * Click 'Add to training set' button
%                       > Add the spot to the training set without changing the classification.
%               * Toggle add corrected spot to trainingSet (On) or Not (off, default)
%                       > Changes the behavior of the 'Good Spot' and 'Not a Spot' buttons to add to training set in addition to correcting (light blue X).             
%               * Scrollbar under the right image $
%                       > Change the zoom of the right image.  The number under it displays the current zoom
%               * Click 'Undo the Last Spot' button:
%                       > undo the action on the last spot you curated
%               * Click 'Undo All' button:
%                       > clear all the unsaved (light blue) spot curation.
%               * Toggle arrow to spot radio button $
%                       > There is a little red arrow that points to the current spot in the right image.  This toggles it on and off if it is disturbing you.
%               * Toggle On=Slice;Off=merge radio button $
%                       > Changes the right image to just the slice that includes the spot (On) or a max merge of the stack (Off)
%               * 'Redo classifySpots' button
%                       > This retrains the random forest classifier with the new training set.
%                       > Redo classifySpots on this worm and output the new results to the GUI.
%               * Checkbox in the lower right. $
%                       > If checked, this means that the user has gone through and corrected this file and is satisfied with it.

%
%   Files required: the corresponding **_segStacks.mat, **_wormGaussianFit.mat, trainingSet_**.mat, **_spotStats.mat
%   Files generated: overwrites all the files mentioned above except for **_segStacks.mat
%
%   Updates:
%       - 2012 Aug 13th, small bug fixes
%       - 2013 Mar 19th, small bug fixes
%       - 2013 May 19th, fix 'index exceeds matrix' problem caused by
%       including 'edge spots'.
%   Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%   License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%   Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%   Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%% =============================================================
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
%



%19April2011 - Removed reliance on stack extent
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help reviewFISHClassification       %nameMod

% Last Modified by GUIDE v2.5 08-Aug-2014 15:03:11

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
handles.spotsCurated=[];

%import info and make spot pictures (background subtracted - essentially
%the code from saveSpotPictures

if isempty(varargin)
    stackName=input('Please enter the stack name (e.g. tmr001.stk, tmr_Pos1.tif, tmr_001):\n','s');
    findTraining=input('Are you using a training set derived from this batch of data? [yes[1]/no[0]]\n ');
elseif length(varargin)==1
    stackName=varargin{1};
    findTraining=1;
else   
    stackName=varargin{1};
    findTraining=varargin{2};
end

if ~findTraining
    trainingSet.sameBatchFlag=zeros(length(trainingSet.spotInfo),1);
end

[dye, stackSuffix, wormGaussianFitName, segStacksName,spotStatsFileName]=parseStackNames(stackName);
handles.findTraining=findTraining;
handles.dye=dye;
handles.stackSuffix=stackSuffix;
handles.posNum=str2num(cell2mat(regexp(stackSuffix,'\d+','match')));
handles.wormsFileName=wormGaussianFitName;
fprintf('Loading %s ... \n',wormGaussianFitName);
load(wormGaussianFitName);
handles.worms=worms;
clear worms
fprintf('Loading %s ... \n', spotStatsFileName)
load(spotStatsFileName)
handles.spotStats=spotStats;
clear spotStats
fprintf('Loading %s ... \n', segStacksName)
load(segStacksName)
handles.segStacks=segStacks;
handles.segMasks=segMasks;
clear segStacks segMasks
set(handles.fileName_button,'String', wormGaussianFitName);

if ~isempty(handles.worms)
    load(handles.spotStats{1}.trainingSetName);
    handles.trainingSet=trainingSet;
    clear trainingSet
else
    disp('Breaking execution');
    return%this should break the execution
end

disp('Training set loaded.');

handles.wormImageMaxMerge={};
for wi=1:size(handles.worms,2)
    %bb=regionprops(double(currpolys{wi}),'BoundingBox');
    %handles.wormBBs{wi}=bb.BoundingBox;
    
    for zi=1:size(handles.segStacks{wi},3)
        handles.segStacks{wi}(:,:,zi)=imscale(handles.segStacks{wi}(:,:,zi),99.995);%.*handles.segMasks{wi};%added the scaling here instead of later
    end;
    
    stackH=size(handles.segStacks{wi},3);
    handles.wormImageMaxMerge{wi}=imscale(max(handles.segStacks{wi}(:,:,floor(stackH/8):ceil(stackH*7/8)),[],3));
    handles.laplaceWorm{wi}=laplaceFISH(handles.segStacks{wi},1);
    handles.laplaceWormImageMaxMerge{wi}=imscale(max(handles.laplaceWorm{wi}(:,:,floor(stackH/8):ceil(stackH*7/8)),[],3));
    
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

handles.spotSize=[7 7];
handles.offset=floor((handles.spotSize-1)/2);
handles.iCurrentWorm=1;
if ~isfield(handles.worms{handles.iCurrentWorm},'spotsFixed')
    handles.worms{handles.iCurrentWorm}.spotsFixed=0;
end;
set(handles.fileName_button,'Value',handles.worms{handles.iCurrentWorm}.spotsFixed);
handles=drawTheLeftPlane(handles);
handles.nGoodToRejected=0;
handles.nRejectedToGood=0;
nGood=sum(handles.allLocs(:,5));
guidata(hObject, handles);
displayImFull(hObject,handles,0);

% UIWAIT makes reviewFISHClassification wait for user response (see UIRESUME)
uiwait(handles.figure1);%%%function lineBox makes xdata and ydata for lines out of rectangle
%%%position - goes clockwise from NW
function [xdata,ydata]=lineBox(position)
NW=position(1:2);
xdata=[NW(1),NW(1)+position(3),NW(1)+position(3),NW(1),NW(1)];
ydata=[NW(2),NW(2),NW(2)+position(4),NW(2)+position(4),NW(2)];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%displayImFull
function displayImFull(hObject,handles,drawSpotResults)

data=guidata(hObject);
set(data.nGoodToRejected_txt,'String',[num2str(data.nGoodToRejected) ' good -> rejected']);
set(data.nRejectedToGood_txt,'String',[num2str(data.nRejectedToGood) ' rejected -> good']);
set(data.nGoodSpots_txt,'String',[num2str(sum(data.allLocs(:,5))) ' good spots']);
set(data.nRejectedSpots_txt,'String',[num2str(sum(data.allLocs(:,5)~=1)) ' rejected spots']);
set(data.iCurrentWorm_txt,'String',['Worm: ' num2str(data.iCurrentWorm) ' of ' num2str(length(data.worms))]);
set(data.RandomForestResult_txt,'String',['Probability Estimate: ' num2str(data.allLocs(data.iCurrentSpot_allLocs,7)*100) '%']);
set(data.scdValue_txt,'String',['scd: ' num2str(data.worms{data.iCurrentWorm}.spotDataVectors.scd(data.iCurrentSpot_worms))]);

set(data.iCurrentSpot_worms_txt,'String',['Index in worms: ' num2str(data.iCurrentSpot_worms)]);
set(data.badWorm_button,'Value',abs(data.worms{data.iCurrentWorm}.goodWorm-1));%changes good 1,0 to bad 1,0
currentZ=data.allLocs(data.iCurrentSpot_allLocs,3);
set(data.currentSlice_txt,'String',['Slice ' num2str(currentZ) ' of ' num2str(size(data.segStacks{data.iCurrentWorm},3))]);
currentSlice=data.segStacks{data.iCurrentWorm}(:,:,currentZ);

zoom(data.spotResultsImage,'factor',data.vertSideSize/(1+data.horizSideSize));

spotBoxesTotalWidth=data.horizSideSize*data.spotSize(1);

xlim(data.spotResults,[colToX(1) colToX(spotBoxesTotalWidth)]);

currentSpotY=data.spotBoxLocations(data.iCurrentSpot_allLocs,2);%N edge of spotBox
spotPage=ceil(currentSpotY/(spotBoxesTotalWidth));
set(data.spotPage_txt,'String',sprintf('Spot page %d of %d',spotPage,ceil(data.vertSideSize/data.horizSideSize)));

ylim(data.spotResults,[rowToY((spotPage-1)*spotBoxesTotalWidth+1) rowToY(spotPage*spotBoxesTotalWidth)]);

if drawSpotResults
    
    for si=1:size(data.allLocs,1)
        if data.allLocs(si,5)==1 %good spots
            edgeColor=[.1,.1,.5];
        else %bad spots
            edgeColor=[.5,.5,.1];
        end
        
        
    end
    rectangle('Position',[data.outLines(si,:) data.spotSize],'EdgeColor',edgeColor);
    
    %for si=1:size(data.goodOutlines,1)
    %    rectangle('Position',[data.goodOutlines(si,:) data.spotSize],'EdgeColor',[.1,.1,.5]);
    %end;
    %rejected = yellow rectangles
    %for si=1:size(data.rejectedOutlines,1)
    %    rectangle('Position',[data.rejectedOutlines(si,:) data.spotSize],'EdgeColor',[.5,.5,.1]);
    %end;
    
    if data.Curated(:,3)==1 % Curated to good spot
        rectangle('Position',[data.Curated(si,1:2) data.spotSize],'EdgeColor',[0,.7,.7]);
    elseif data.Curated(:,3)==0 % Curated to bad spot
        rectangle('Position',[data.Curated(si,1:2) data.spotSize],'EdgeColor',[1,.5,0]);
    end
    
end
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
%data.spotZoomLaplaceFiltered=imshow(imscale(data.laplaceWorm{data.iCurrentWorm}(:,:,currentZ),99.995));
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
surfColumn=data.segStacks{data.iCurrentWorm}(surfNR:surfSR,surfWC:surfEC,:);
%freezeColors;
for i=1:3
    if currentZ+(i-2)<=size(data.segStacks{data.iCurrentWorm},3) && currentZ+(i-2)>=1
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

%disp('in OutputFcn');

% Get default command line output from handles structure

varargout{1} = handles.output;

%rerun the randomForest with the trainingSet as it currently stands after
%review

disp('Spot fixing done.  Saving changes');
button = questdlg('Do you want to re-train the classifier now?','Re-train?','No');
switch button
    case {'No'}
        
        button = questdlg('Do you want to save the training set and updated spot data when exiting?','Save when exiting?','Yes');
        switch button
            case {'No'}
                delete(handles.figure1)
            case {'Yes'}
                disp('Saving the training set and updated spot stats....')
                trainingSet=handles.trainingSet;
                save(handles.trainingSet.FileName,'trainingSet');
                [~, ~, wormGaussianFitName, ~,spotStatsFileName]=parseStackNames(handles.worms{1}.segStackFile);
                worms=handles.worms;
                save(wormGaussianFitName,'worms');
                spotStats=handles.spotStats;
                save(spotStatsFileName,'spotStats');
                disp(spotStats{1});
                disp(spotStatsFileName);
                delete(handles.figure1)
        end
        
    case {'Yes'}
        disp('Saving the training set and updated spot stats....')
        trainingSet=handles.trainingSet;
        save(handles.trainingSet.FileName,'trainingSet');
        [~, ~, wormGaussianFitName, ~,spotStatsFileName]=parseStackNames(handles.worms{1}.segStackFile);
        worms=handles.worms;
        save(wormGaussianFitName,'worms');
        spotStats=handles.spotStats;
        %disp(spotStats{1});
        save(spotStatsFileName,'spotStats');
        delete(handles.figure1)
        disp('Rerunning randomForest with the latest amendments');
        handles.trainingSet=trainRFClassifier(handles.trainingSet);  %nameMod
        disp('Redo classification of the spots for this stack...')
        handles.spotStats=classifySpots(handles.worms,handles.trainingSet);
        
end
disp('output fcn done');
%pos_size = get(handles.figure1,'Position');




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
currentSpotClassification=handles.spotStats{handles.iCurrentWorm}.classification(handles.iCurrentSpot_worms,:);
handles.spotStats{handles.iCurrentWorm}.classification(handles.iCurrentSpot_worms,3)=1;
handles.spotStats{handles.iCurrentWorm}.classification(handles.iCurrentSpot_worms,1)=1;
handles.allLocs(handles.iCurrentSpot_allLocs,4)=1;
handles.allLocs(handles.iCurrentSpot_allLocs,5)=1;
rectposition=get(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.rect,'Position');
newSpotRow=[handles.posNum handles.iCurrentWorm handles.iCurrentSpot_worms 1];
handles.spotsCurated=[handles.spotsCurated;[newSpotRow currentSpotClassification(3)]];
if currentSpotClassification(3)~=1%it was not manually marked as good
    disp(sprintf('Accepting rejected spot %d',handles.iCurrentSpot_worms));
    handles.nRejectedToGood=handles.nRejectedToGood+1;
    %modify image
    NW=handles.spotBoxLocations(handles.iCurrentSpot_allLocs,:);
    
    if currentSpotClassification(1)~=-1
        disp('This spot already was manually marked as bad and now we are changing it to good');
        handles.allLocs(handles.iCurrentSpot_allLocs,4)=1;
        if handles.findTraining
            [~,~,iCurrentSpot_trainingSet]=intersect(newSpotRow(1:3),handles.trainingSet.spotInfo(:,1:3),'rows'); %Check to see if the spot is in the training set
        else
            iCurrentSpot_trainingSet=[];
        end
        if isempty(iCurrentSpot_trainingSet) % not in the training set
            disp('This spot is not in the training set.  It is manually curated but not added to the training set.')
        else
            handles.trainingSet=updateTrainingSet(handles.trainingSet,handles.worms,newSpotRow);
            handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine=line('Xdata',[rectposition(1)+handles.spotSize(1)-1,rectposition(1)+1],'Ydata',[rectposition(2)+1,rectposition(2)+handles.spotSize(2)-1],'Color',[0,.7,.7],'LineWidth',2,'HitTest','off','Parent',handles.spotResults);
            
        end
        
    elseif get(handles.addCorrToTS_button,'Value') %it is a bad spot but was not manually marked as good and add corrections to training set button is on
        handles.trainingSet=updateTrainingSet(handles.trainingSet,handles.worms,newSpotRow);
        disp('This spot is added into the training set.')
        handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine=line('Xdata',[rectposition(1)+handles.spotSize(1)-1,rectposition(1)+1],'Ydata',[rectposition(2)+1,rectposition(2)+handles.spotSize(2)-1],'Color',[0,.7,.7],'LineWidth',2,'HitTest','off','Parent',handles.spotResults);
    end;
else % It is already a good spot. Add to training set.
    disp('This spot is already classified as good spot.  Adding this spot into the training set....')
    handles.allLocs(handles.iCurrentSpot_allLocs,4)=1;
    
    handles.trainingSet=updateTrainingSet(handles.trainingSet,handles.worms,newSpotRow);
    disp('This spot is added into the training set.')
    handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine=line('Xdata',[rectposition(1)+handles.spotSize(1)-1,rectposition(1)+1],'Ydata',[rectposition(2)+1,rectposition(2)+handles.spotSize(2)-1],'Color',[0,.7,.7],'LineWidth',2,'HitTest','off','Parent',handles.spotResults);
end
handles.rectangleHandles{handles.iCurrentSpot_allLocs}.curationLine=line('Xdata',[rectposition(1)+1,rectposition(1)+handles.spotSize(1)-1],'Ydata',[rectposition(2)+1,rectposition(2)+handles.spotSize(2)-1],'Color',[0,.7,.7],'LineWidth',2,'HitTest','off','Parent',handles.spotResults);
set(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.rect,'EdgeColor',[0,.7,.7]);
handles.iCurrentSpot_allLocs=min(size(handles.spotBoxLocations,1),handles.iCurrentSpot_allLocs+1);
handles.iCurrentSpot_worms=handles.allLocs(handles.iCurrentSpot_allLocs,6);
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
currentSpotClassification=handles.spotStats{handles.iCurrentWorm}.classification(handles.iCurrentSpot_worms,:);
handles.spotStats{handles.iCurrentWorm}.classification(handles.iCurrentSpot_worms,3)=0;
handles.spotStats{handles.iCurrentWorm}.classification(handles.iCurrentSpot_worms,1)=0;
handles.allLocs(handles.iCurrentSpot_allLocs,5)=0;
handles.allLocs(handles.iCurrentSpot_allLocs,4)=0;
rectposition=get(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.rect,'Position');
newSpotRow=[handles.posNum handles.iCurrentWorm handles.iCurrentSpot_worms 0];
handles.spotsCurated=[handles.spotsCurated;[newSpotRow currentSpotClassification(3)]];
if currentSpotClassification(3)~=0
    disp(sprintf('Rejected an accepted spot %d',handles.iCurrentSpot_worms));
    handles.nGoodToRejected=handles.nGoodToRejected+1;
    %modify image
    NW=handles.spotBoxLocations(handles.iCurrentSpot_allLocs,:);
    
    if currentSpotClassification(1)~=-1
        disp('This spot already was manually marked as bad and now we are changing it to good');
        if handles.findTraining
            [~,~,iCurrentSpot_trainingSet]=intersect(newSpotRow(1:3),handles.trainingSet.spotInfo(:,1:3),'rows'); %Check to see if the spot is in the training set
        else
            iCurrentSpot_trainingSet=[];
        end
        if isempty(iCurrentSpot_trainingSet) % not in the training set
            disp('This spot is not in the training set.  It is manually curated but not added to the training set.')
        else
            handles.trainingSet=updateTrainingSet(handles.trainingSet,handles.worms,newSpotRow);
            handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine=line('Xdata',[rectposition(1)+handles.spotSize(1)-1,rectposition(1)+1],'Ydata',[rectposition(2)+1,rectposition(2)+handles.spotSize(2)-1],'Color',[0,.7,.7],'LineWidth',2,'HitTest','off','Parent',handles.spotResults);
            
        end
        
    elseif get(handles.addCorrToTS_button,'Value') %it is a bad spot but was not manually marked as good and add corrections to training set button is on
        handles.trainingSet=updateTrainingSet(handles.trainingSet,handles.worms,newSpotRow);
        disp('This spot is added into the training set.')
        handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine=line('Xdata',[rectposition(1)+handles.spotSize(1)-1,rectposition(1)+1],'Ydata',[rectposition(2)+1,rectposition(2)+handles.spotSize(2)-1],'Color',[0,.7,.7],'LineWidth',2,'HitTest','off','Parent',handles.spotResults);
    end;
    
else % It is already a bad spot. Add to training set.
    disp('This spot is already classified as bad spot.  Adding this spot into the training set....')
    handles.allLocs(handles.iCurrentSpot_allLocs,4)=0;
    handles.trainingSet=updateTrainingSet(handles.trainingSet,handles.worms,newSpotRow);
    disp('This spot is added into the training set.')
    handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine=line('Xdata',[rectposition(1)+handles.spotSize(1)-1,rectposition(1)+1],'Ydata',[rectposition(2)+1,rectposition(2)+handles.spotSize(2)-1],'Color',[0,.7,.7],'LineWidth',2,'HitTest','off','Parent',handles.spotResults);
end
handles.rectangleHandles{handles.iCurrentSpot_allLocs}.curationLine=line('Xdata',[rectposition(1)+1,rectposition(1)+handles.spotSize(1)-1],'Ydata',[rectposition(2)+1,rectposition(2)+handles.spotSize(2)-1],'Color',[0,.7,.7],'LineWidth',2,'HitTest','off','Parent',handles.spotResults);
set(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.rect,'EdgeColor',[0,.7,.7]);
handles.iCurrentSpot_allLocs=min(size(handles.spotBoxLocations,1),handles.iCurrentSpot_allLocs+1);
handles.iCurrentSpot_worms=handles.allLocs(handles.iCurrentSpot_allLocs,6);

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

data=guidata(hObject);

data.spotStats{data.iCurrentWorm}.spotsFixed=1;
data.spotStats{data.iCurrentWorm}=updateSpotStats(data.spotStats{data.iCurrentWorm});
set(data.arrowSpot_button,'Value',1)
guidata(hObject,data);
if data.iCurrentWorm<length(data.worms)
    data.iCurrentWorm=data.iCurrentWorm+1;%go to the next worm
    while ~data.worms{data.iCurrentWorm}.goodWorm%if the worm is bad
        data.iCurrentWorm=data.iCurrentWorm+1;%go to the next worm
    end
    if ~isfield(data.worms{data.iCurrentWorm},'spotsFixed')
        data.worms{data.iCurrentWorm}.spotsFixed=0;
    end
    set(data.fileName_button,'Value',data.worms{data.iCurrentWorm}.spotsFixed);
    
    data=drawTheLeftPlane(data);
    
    nGood=sum(data.allLocs(:,5));
    guidata(hObject, data);
    
else%then completely done-write training set and new spotFile,  21April2011 and goldSpots and rejectedSpots files
    
    uiresume(gcbf);
end
displayImFull(hObject,data,0);

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
% %	Character: characte interpretation of the key(s) that was pressed
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

handles.trainingSet=trainRFClassifier(handles.trainingSet);  %nameMod
handles.spotStats=classifySpots(handles.worms,handles.trainingSet);
handles.iCurrentWorm=1;

handles=drawTheLeftPlane(handles);

nGood=sum(handles.allLocs(:,5));
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
    goodIntensities=[goodIntensities handles.segStacks{handles.iCurrentWorm}(loc(1),loc(2),loc(3))];
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
disp('Adding this spot into the training set....')
currentSpotClassification=handles.spotStats{handles.iCurrentWorm}.classification(handles.iCurrentSpot_worms,:);
handles.spotStats{handles.iCurrentWorm}.classification(handles.iCurrentSpot_worms,1)=currentSpotClassification(3);
handles.allLocs(handles.iCurrentSpot_allLocs,4)=currentSpotClassification(3);
spotIndex=[handles.posNum handles.iCurrentWorm handles.iCurrentSpot_worms];
newSpotRow=[spotIndex currentSpotClassification(3)];
handles.spotsCurated=[handles.spotsCurated;[newSpotRow currentSpotClassification(3)]];
handles.trainingSet=updateTrainingSet(handles.trainingSet,handles.worms,newSpotRow);
rectposition=get(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.rect,'Position');
handles.rectangleHandles{handles.iCurrentSpot_allLocs}.trainingLine=line('Xdata',[rectposition(1)+handles.spotSize(1)-1,rectposition(1)+1],'Ydata',[rectposition(2)+1,rectposition(2)+handles.spotSize(2)-1],'Color',[0,.7,.7],'LineWidth',2,'HitTest','off','Parent',handles.spotResults);
handles.rectangleHandles{handles.iCurrentSpot_allLocs}.curationLine=line('Xdata',[rectposition(1)+1,rectposition(1)+handles.spotSize(1)-1],'Ydata',[rectposition(2)+1,rectposition(2)+handles.spotSize(2)-1],'Color',[0,.7,.7],'LineWidth',2,'HitTest','off','Parent',handles.spotResults);

set(handles.rectangleHandles{handles.iCurrentSpot_allLocs}.rect,'EdgeColor',[0,.7,.7]);
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
handles.worms{handles.iCurrentWorm}.spotsFixed=1;

disp('Saving changes');
trainingSet=handles.trainingSet;
save(handles.trainingSet.FileName,'trainingSet');
%%%%%%%%%%%%%%%%%%%%
[~, ~, wormGaussianFitName, ~,spotStatsFileName]=parseStackNames(handles.worms{1}.segStackFile);
worms=handles.worms;
save(wormGaussianFitName,'worms');
spotStats=handles.spotStats;
save(spotStatsFileName,'spotStats');
disp('Data saved.')
set(handles.arrowSpot_button,'Value',1)
handles=drawTheLeftPlane(handles);
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

handles.spotStats{handles.iCurrentWorm}.spotsFixed=1;
handles.spotStats{handles.iCurrentWorm}=updateSpotStats(handles.spotStats{handles.iCurrentWorm});
%SAR - 30June2014 Added the following line
guidata(hObject,handles);
uiresume(gcbf);


% --- Executes on button press in undoTheLast.
function undoTheLast_Callback(hObject, eventdata, handles)
% hObject    handle to undoTheLast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

spotBeingRemoved=handles.spotsCurated(end,:);
handles.spotStats{handles.iCurrentWorm}.classification(spotBeingRemoved(3),3)=handles.spotsCurated(end,end); % adjust back to the original state
handles.spotStats{handles.iCurrentWorm}.classification(spotBeingRemoved(3),1)=-1;
handles.trainingSet=updateTrainingSet(handles.trainingSet,handles.worms,spotBeingRemoved([1 2 3 5]),1); % update the training set.

iSpotBeingRemoved_allLocs=find(handles.allLocs(:,6)==spotBeingRemoved(3));
handles.spotsCurated=handles.spotsCurated(1:end-1,:);
disp('The Spot is removed.')

if isfield(handles.rectangleHandles{iSpotBeingRemoved_allLocs},'trainingLine')
    delete(handles.rectangleHandles{iSpotBeingRemoved_allLocs}.trainingLine);
end

if isfield(handles.rectangleHandles{iSpotBeingRemoved_allLocs},'curationLine')
    delete(handles.rectangleHandles{iSpotBeingRemoved_allLocs}.curationLine);
end

%delete(handles.rectangleHandles{iSpotBeingRemoved_allLocs}.rect);
if spotBeingRemoved(end)== 1 % origianlly a good spot
    set(handles.rectangleHandles{iSpotBeingRemoved_allLocs}.rect,'EdgeColor',[0.1,0.1,0.5]);
elseif spotBeingRemoved(end)==0
    disp('hello')
    set(handles.rectangleHandles{iSpotBeingRemoved_allLocs}.rect,'EdgeColor',[0.5,0.5,0.1]);
end

handles.nGoodToRejected=sum((handles.spotsCurated(:,5)==1).*(handles.spotsCurated(:,4)==0));
handles.nRejectedToGood=sum((handles.spotsCurated(:,5)==0).*(handles.spotsCurated(:,4)==1));


guidata(hObject,handles);
displayImFull(hObject,handles,0);


% --- Executes on button press in undoAll.
function undoAll_Callback(hObject, eventdata, handles)
% hObject    handle to undoAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

load(handles.trainingSet.FileName);
handles.trainingSet=trainingSet;
clear trainingSet

[~,~ , wormGaussianFitName, ~,spotStatsFileName]=parseStackNames(handles.worms{handles.iCurrentWorm}.segStackFile);
load(wormGaussianFitName)
handles.worms{handles.iCurrentWorm}=worms{handles.iCurrentWorm};
clear worms

load(spotStatsFileName)
handles.spotStats{handles.iCurrentWorm}=spotStats{handles.iCurrentWorm};
clear spotStats

handles=drawTheLeftPlane(handles);
guidata(hObject,handles);
displayImFull(hObject,handles,0);

function handles=drawTheLeftPlane(handles)
spotBoxPositions=[];
spotBoxLocations=[];
placeholder=-100;
allLocs=[];

placeholder=-100;
disp('making good/rejectedLocs')
% [Location, classification (manual), classification (final), spot index, Prob Estimates]
allLocs=[handles.worms{handles.iCurrentWorm}.spotDataVectors.locationStack handles.spotStats{handles.iCurrentWorm}.classification(:,1) handles.spotStats{handles.iCurrentWorm}.classification(:,3), handles.worms{handles.iCurrentWorm}.spotDataVectors.spotInfoNumberInWorm handles.spotStats{handles.iCurrentWorm}.ProbEstimates];
[allLocs,I]=sortrows(allLocs,-7); % sort the spots based on probability estimates
allDataMat=handles.worms{handles.iCurrentWorm}.spotDataVectors.dataMat(I,:,:);
nSpots=size(allLocs,1);
%need next largest multiple of spotSize(1) (assume square)
%%%6/28/09 - don't want spots to be too small...have it run off the bottom,
%%%so maximum of, say, 30 spots per horizontal side

handles.spotsPerRow=25;

handles.horizSideSize=min(handles.spotsPerRow,ceil(sqrt(nSpots)));
handles.vertSideSize=ceil(nSpots/handles.horizSideSize);
bkgdSubImage=zeros([handles.vertSideSize handles.vertSideSize].*handles.spotSize);
%handles.rejectedOutlines=[];%this is now going to be a list of NW corners (X,Y) for rectangles
%handles.goodOutlines=[];%this is now going to be a list of NW corners (X,Y) for rectangles
handles.outLines=zeros(nSpots,2);
handles.spotIndexImage=zeros(handles.horizSideSize);%size(bkgdSubImage));
handles.traingSetIndex=zeros(nSpots,1); % it will be zero if it's not in the training set.

%handles.outlines=.5*bwperim(ones(spotSize))+(~bwperim(ones(spotSize)));
%handles.curated=.5*ones(spotSize);
%handles.outlines=.3*bwperim(ones(handles.spotSize));
%handles.curated=.3*ones(handles.spotSize);
goodIntensities=[];
disp(['Doing spot box locations for worm #' num2str(handles.iCurrentWorm)]);
for si=1:nSpots
    currentR=1+handles.spotSize(1)*floor((si-1)/handles.horizSideSize);
    currentC=1+handles.spotSize(1)*mod((si-1),handles.horizSideSize);
    % 20130518: use dataMat stored directly.  Do not use the location to
    % find the dataMat to show to avoid "index exceeds matrix" problems
    % casused by edge spots.
    
    NR=max(1,allLocs(si,1)-handles.offset(1));
    %if NR==1
        %then too close to top
    %    SR=handles.spotSize(1);
    %else
    %    if allLocs(si,1)+handles.offset(1)>size(handles.segMasks{handles.iCurrentWorm},1)
    %        SR=size(handles.segMasks{handles.iCurrentWorm},1);
    %        NR=size(handles.segMasks{handles.iCurrentWorm},1)-(handles.spotSize(1)-1);
    %    else
    %        SR=NR+(handles.spotSize(1)-1);
    %    end;
    %end;
    WC=max(1,allLocs(si,2)-handles.offset(2));
    %if WC==1
        %then too close to top
    %    EC=handles.spotSize(2);
    %else
    %    if allLocs(si,2)+handles.offset(2)>size(handles.segMasks{handles.iCurrentWorm},2)
    %        EC=size(handles.segMasks{handles.iCurrentWorm},2);
    %        WC=size(handles.segMasks{handles.iCurrentWorm},2)-(handles.spotSize(2)-1);
    %    else
    %        EC=WC+handles.spotSize(2)-1;
    %    end;
    %end;
      
    %dataMat=handles.segStacks{handles.iCurrentWorm}(NR:SR,WC:EC,allLocs(si,3));
    dataMat=permute(allDataMat(si,:,:),[2,3,1]);
    if min(dataMat(:))==0 % edge spot
        dataMat=imscale(dataMat,90); 
    end
    %        rawImage(currentR:currentR+spotSize(1)-1,currentC:currentC+spotSize(2)-1)=dataMat;
    bkgdSubImage(currentR:currentR+handles.spotSize(1)-1,currentC:currentC+handles.spotSize(2)-1)=dataMat-min(dataMat(:));
    handles.spotIndexImage(currentR:currentR+handles.spotSize(1)-1,currentC:currentC+handles.spotSize(2)-1)=zeros(size(dataMat))+si;
    handles.outLines(si,:)=[colToX(currentC),rowToY(currentR)];
    if allLocs(si,5)==1  %good spot
        splitPoint=[rowToY(currentR+handles.spotSize(1)-1),colToX(currentC+handles.spotSize(2)-1)];%only really matters for the equality...legacy anyway
        goodIntensities=[goodIntensities dataMat(4,4)];
    end;
    spotBoxPositions=[spotBoxPositions;[colToX(WC) rowToY(NR) handles.spotSize(1) handles.spotSize(2)]];%this is for highlighting on context image
    spotBoxLocations=[spotBoxLocations;[colToX(currentC),rowToY(currentR)]];%[currentR,currentR+spotSize(1)-1,currentC,currentC+spotSize(2)-1]];%this is for finding int he spotResults image...it is NW corners in (x,y)
end;

handles.bkgdSubImage=bkgdSubImage;
%handles.goodLocs=allLocs(allLocs(:,5)==1,:);
%handles.rejectedLocs=allLocs(allLocs(:,5)==0,:);
handles.allLocs=allLocs;
handles.spotBoxPositions=spotBoxPositions;
handles.spotBoxLocations=spotBoxLocations;
handles.goodIntensities=goodIntensities;

%handles.spotStatus=[ones(size(goodLocs,1),1);zeros(size(rejectedLocs,1),1)];%category vector

handles.iCurrentSpot_allLocs=sum(allLocs(:,5));%last good spot
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
for si=1:nSpots%size(handles.goodOutlines,1)
    %handles.rectangleHandles{iRH}.rect=rectangle('Position',[handles.goodOutlines(si,:) handles.spotSize-.5],'EdgeColor',[.1,.1,.5],'HitTest','off','Parent',handles.spotResults);
    if allLocs(si,5)==1
        edgeColor=[.1,.1,.5];
    else
        edgeColor=[.5,.5,.1];
    end
    handles.rectangleHandles{iRH}.rect=rectangle('Position',[handles.outLines(si,:) handles.spotSize-.5],'EdgeColor',edgeColor,'HitTest','off','Parent',handles.spotResults);
    
    %if isequal, draw a line
    if handles.allLocs(si,4)~=-1 % manually curated
        if handles.allLocs(si,5) ==1 % manually curated as a good spot
            tLineColor=[.1 .1 .5];
        else
            tLineColor=[.5 .5 .1];
        end
        %handles.rectangleHandles{iRH}.trainingLine=line('Xdata',[handles.goodOutlines(si,1)+1,handles.goodOutlines(si,1)+handles.spotSize(1)-1],'Ydata',[handles.goodOutlines(si,2)+1,handles.goodOutlines(si,2)+handles.spotSize(2)-1],'Color',tLineColor,'LineWidth',2,'HitTest','off','Parent',handles.spotResults);
        handles.rectangleHandles{iRH}.curationLine=line('Xdata',[handles.outLines(si,1)+1,handles.outLines(si,1)+handles.spotSize(1)-1],'Ydata',[handles.outLines(si,2)+1,handles.outLines(si,2)+handles.spotSize(2)-1],'Color',tLineColor,'LineWidth',2,'HitTest','off','Parent',handles.spotResults);
        %set(handles.rectangleHandles{iRH}.trainingLine,'UserData',iTrainingSet);%associate trainingSetIndex
        % Check and see if the spot is in the training set. If it's in the
        % trainingSet, draw a cross
        spotInfo=[handles.posNum, handles.iCurrentWorm, handles.allLocs(si,6)];
        if handles.findTraining
            [~,~,trainingSetIndex]=intersect(spotInfo, handles.trainingSet.spotInfo(:,1:3),'rows');
        else
            trainingSetIndex=[];
        end
        if ~isempty(trainingSetIndex) % order is the same as allLocs
            handles.trainingSetIndex(si)=trainingSetIndex;
            if handles.allLocs(si,5) ==1 % good spot in training set
                tLineColor=[.1 .1 .5];
            else
                tLineColor=[.5 .5 .1];
            end
            %handles.rectangleHandles{iRH}.trainingLine=line('Xdata',[handles.goodOutlines(si,1)+1,handles.goodOutlines(si,1)+handles.spotSize(1)-1],'Ydata',[handles.goodOutlines(si,2)+1,handles.goodOutlines(si,2)+handles.spotSize(2)-1],'Color',tLineColor,'LineWidth',2,'HitTest','off','Parent',handles.spotResults);
            handles.rectangleHandles{iRH}.trainingLine=line('Xdata',[handles.outLines(si,1)+handles.spotSize(1)-1,handles.outLines(si,1)+1],'Ydata',[handles.outLines(si,2)+1,handles.outLines(si,2)+handles.spotSize(2)-1],'Color',tLineColor,'LineWidth',2,'HitTest','off','Parent',handles.spotResults);
            
        end 
     end
    iRH=iRH+1;
end


% --- Executes on button press in addCorrToTS_button.
function addCorrToTS_button_Callback(hObject, eventdata, handles)
% hObject    handle to addCorrToTS_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of addCorrToTS_button
