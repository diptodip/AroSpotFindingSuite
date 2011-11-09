function varargout = identifySpots(varargin)     %nameMod
%  =============================================================
%  Name: identifySpots.m        %nameMod
%  Version: 1.4.2, 18 Oct 2011         %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%  License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%  Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%  =============================================================
%IDENTIFYSPOTS M-file for identifySpots.fig
%      IDENTIFYSPOTS, by itself, creates a new IDENTIFYSPOTS or raises the existing
%      singleton*.
%
%      H = IDENTIFYSPOTS returns the handle to a new IDENTIFYSPOTS or the handle to
%      the existing singleton*.
%
%      IDENTIFYSPOTS('Property','Value',...) creates a new IDENTIFYSPOTS using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to identifySpots_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      IDENTIFYSPOTS('CALLBACK') and IDENTIFYSPOTS('CALLBACK',hObject,...) call the
%      local function named CALLBACK in IDENTIFYSPOTS.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
%
% identifySpots is a gui to create a training set.       %nameMod
% The gui consists of three image panes and several buttons
% Regional maxima (=potential spots) are ranked by the function morphFilterSpotImage3D.m
% Then the program goes through the rankings and lets the user decide whether the maxima in the left image pane are spots or not
% The left pane shows a 16x16 square centered on a the focal maxima (there may be others in the image as well).  Maxima are highlighted in blue.  If a maximum has already been accepted, it is highlighted in red.
%   Note also that these are 3D maxima.  So if a clear maximum isn't highlighted in blue in the current slice, it will be in an adjacent slice
% The right pane shows the location of the zoomed left pane area at lower magnification
% The small bottom pane shows the location of the left pane in the whole image
% The 3D plots in the middle are intensity histograms of the 16x16 square in the left image and that same square in neighboring slices
% Possible actions:
%     Click on a square in the left image pane.
%         This toggles the square.  Blue means it is a candidate spot.  Greyscale means it is not under consideration.
%     Click on a the right image pane.
%         This will move the focus to wherever you clicked.
%     Click Next and Nothing button
%         This goes to the next maximum in the list without making any judgments about the maxima (blue squares) in the current left image
%     Click Next and Accept button
%         This accepts all maxima (blue squares) in the current left image as spots and adds them to the positive training set
%     Click Next and Reject button
%         This rejects all maxima (blue squares) in the current left image as spots and adds them to the negative training set
%     Click Next Slice
%         This moves up one slice in the z stack, not doing anything with current maxima in the left image
%     Click Next and Reject button
%         This rejects all maxima (blue squares) in the current left image as spots and adds them to the negative training set
%     Click Undo last button
%         This rolls back the current state one decision (one click on something).  Default is a memory of 6 states, but this can be modified below
%             in the line that reads:  handles.rollbackDepth=6;
%             Each memory state stored can be many MB, so it probably isn't a good idea nor necessary to go much beyond 6
%             This button is useful because there will be times when the user clicks accept and only notices too late that there was a non-spot maximum hiding up there in the corner
%             Or the user might simply press the wrong button
%     Adjust spotRank slider.  This is used to decide where in the ranked spot list to go next.  By default it starts with the top ranked maximum and goes from there.  Ideally you'd want some good examples of borderline spots.  This turns out to be difficult to get at this point, but you can jump around the spot list to try.
%     Click Finished.
%         Self explanatory.  Returns to createFISHTrainingSet
%     Toggle Background spots checkbox
%         When checked, any spots clicked on in the left image pane will be
%         marked as background spots.  This could be useful for image
%         normalization, but isn't really used as the pipeline currently
%         stands.  Spots selected as background will be highlighted in
%         yellow.
%
%   To start, choose around 100 positive and 100 negative spots (this seems to be sufficient to get started but hasn't been tested exhaustively)..  When you
%   correct your first few images (using reviewFISHClassification.m), you'll add
%   to this.  Try to get some borderline examples, but this is easier from
%   reviewFISHClassification because it has already highlighted borderline cases for you.

%Modified 3 May 2011.  evaluateFISHImageStack is run on directory before
%everything.  This creates a wormGaussianFit files.  these have the
%statistics and (important for this function) also have the list of
%relevant maxima...no longer are all maxima in bounds.  so morph function
%is no longer called

%11 May 2011.  Modified so that it only loads one slice at a time to help
%with memory.  Branched off 1p2p2_highMemory when I don't need to deal with
%this
%6 July 2011
%Modified so there is a flag to switch between high and low memory at the
%appropriate spots.  Set the flag in the program for now.

%18Oct2011
%Made spotListSorted into a structure.  Also tried to remove bugs and
%detritus

% Edit the above text to modify the response to help identifySpots

% Last Modified by GUIDE v2.5 09-Nov-2011 11:57:56

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @identifySpots_OpeningFcn, ...
    'gui_OutputFcn',  @identifySpots_OutputFcn, ...
    'gui_LayoutFcn',  [], ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


%NEW WAY OF FINDING BACKGROUND
%MAKE A NEW GUI TO DO CAMERA BACKGROUND - JUST BASED ON WHAT I HAVE BUT NO
%BUTTON SWITCHING
%FOR EMBRYO BACKGROUND (IS THIS NEEDED?) JUST HAVE IT DO IT AUTOMATICALLY
%POSTHOC LIKE I DID IN THE RANDOM FORESTS THING

% --- Executes just before identifySpots is made visible.
function identifySpots_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

%varargin is stack,currpolys,startingSlice,dye

% Choose default command line output for identifySpots
handles.output = hObject;


%EDIT SAR 4/15/09

%%%%% 19Oct2011
%%%The code throws an error where the spotRankSlider Min and Max are not
%%%changed until in the displayImFull function but iCurrentSpot may be
%%%outside this:
% Warning: slider control requires that Min be less than Max
% Control will not be rendered until all of its parameter values are valid
% (Type "warning off MATLAB:hg:uicontrol:ParameterValuesMustBeValid" to suppress
% this warning.) 
% > In uiwait at 73
%   In identifySpots>identifySpots_OpeningFcn at 365
%   In gui_mainfcn at 221
%   In identifySpots at 113
%   In createFISHTrainingSet at 121
% This isn't an issue because the slider is reset in displayImFull, but
% the warning is annoying.  Hence:
warning off MATLAB:hg:uicontrol:ParameterValuesMustBeValid
%%%%%%%%%%%%%

handles.highMemory=1;

global intensityFraction
handles.figure_handle=get(0,'CurrentFigure');
handles.surfPlots={handles.surfMinus2,handles.surfMinus1,handles.surfCurrentZ,handles.surfPlus1,handles.surfPlus2};

%get stuff from varargins
%%
currpolys=varargin{1};
handles.currentZ=varargin{2};%will modify later if need be based on emptiness of maxima in slice
dye=varargin{3};
stackSuffix=varargin{4};
segments=currpolys{1};
outlines=bwperim(currpolys{1});
%%

%# spots per blue slice set in updateBlueSlice2

for i=1:length(currpolys)
    segments=segments+currpolys{i};
    outlines=outlines+bwperim(currpolys{i});
end;
segments=segments>0;
outlines=outlines>0;
%%%Note that this depends on particular file name structure of
%%%wormGaussianFit
load([dye stackSuffix '_wormGaussianFit']);
%%%%%%%%%%%%%%%%%
handles.worms=worms;
stackInfo.stackName=worms{1}.stackName;
stackInfo.stackFileType=worms{1}.stackFileType;
stackInfo.numberOfPlanes=worms{1}.numberOfPlanes;

%%%%%%%%%%% Set up the spot data info
%%

sortedSpotData.rows=[];
sortedSpotData.cols=[];
sortedSpotData.zs=[];
sortedSpotData.values=[];
sortedSpotData.filteredValues=[];
sortedSpotData.wormNumber=[];
sortedSpotData.spotInfoNumberInWorm=[];

for wi=1:size(worms,2)
    for si=1:size(worms{wi}.spotInfo,2)
        sortedSpotData.rows=[sortedSpotData.rows;worms{wi}.spotInfo{si}.locations.stack(1)];
        sortedSpotData.cols=[sortedSpotData.cols;worms{wi}.spotInfo{si}.locations.stack(2)];
        sortedSpotData.zs=[sortedSpotData.zs;worms{wi}.spotInfo{si}.locations.stack(3)];
        sortedSpotData.values=[sortedSpotData.values;worms{wi}.spotInfo{si}.rawValue];
        sortedSpotData.filteredValues=[sortedSpotData.filteredValues;worms{wi}.spotInfo{si}.filteredValue];
        sortedSpotData.wormNumber=[sortedSpotData.wormNumber; wi];%could pull out but clearer here
        sortedSpotData.spotInfoNumberInWorm=[sortedSpotData.spotInfoNumberInWorm; si];
    end;
end;

%Need to sort them
[sortedSpotData.filteredValues,VFiltSortOrder]=sort(sortedSpotData.filteredValues,'descend');
sortedSpotData.rows=sortedSpotData.rows(VFiltSortOrder);
sortedSpotData.cols=sortedSpotData.cols(VFiltSortOrder);
sortedSpotData.zs=sortedSpotData.zs(VFiltSortOrder);
sortedSpotData.values=sortedSpotData.values(VFiltSortOrder);
sortedSpotData.wormNumber=sortedSpotData.wormNumber(VFiltSortOrder);
sortedSpotData.spotInfoNumberInWorm=sortedSpotData.spotInfoNumberInWorm(VFiltSortOrder);

sortedSpotData.scaledValues=sortedSpotData.values;

handles.sortedSpotData=sortedSpotData;
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%

%Count the number in each slice
%%
handles.nMaximaBySlice=zeros(1,stackInfo.numberOfPlanes);
for zi=1:stackInfo.numberOfPlanes;
    handles.nMaximaBySlice(zi)=length(find(handles.sortedSpotData.zs==zi));
end;
%%

%9/17/11 - modify handles.currentZ if nMaxima is empty
%%
zi=handles.currentZ;
while handles.nMaximaBySlice(zi)==0 && zi<=stackInfo.numberOfPlanes
    zi=zi+1;
    handles.currentZ=zi;
end;

if handles.currentZ>stackInfo.numberOfPlanes
    disp('No regional maxima in stack.  This could cause a problem in the program, but there is a bigger problem.');
    return
end;
%%%%%%%%%%%%%%%%%%%%%%

%%

dataStructure.segments=segments;
dataStructure.outlines=outlines;
dataStructure.cameraBackground=[];
dataStructure.stackInfo=stackInfo;

intensityFraction=.8;
if handles.highMemory
    stk=loadStack(worms{1}.stackName,worms{1}.stackFileType,dataStructure.stackInfo.numberOfPlanes);
    for k=1:dataStructure.stackInfo.numberOfPlanes
        slice=stk(:,:,k);
        mnSlice=min(slice(:));
        mxSlice=max(slice(:));
        rangeSlice=mxSlice-mnSlice;
        dataStructure.scaledStack(:,:,k)=(slice-mnSlice)/rangeSlice;
        handles.sortedSpotData.scaledValues(find(handles.sortedSpotData.zs==k))=(handles.sortedSpotData.scaledValues(find(handles.sortedSpotData.zs==k))-mnSlice)/rangeSlice;%All are not scaled yet
    end;
end;
if ~handles.highMemory
    [slice,handles.sortedSpotData.scaledValues]=loadAndScaleSlice(worms{1}.stackName,worms{1}.stackFileType,handles.currentZ,handles);
    dataStructure.scaledSlice=slice;
    clear slice
    
end;

handles.lastHandles={};
handles.rollbackDepth=6;

dataStructure.goodSpots=[];
dataStructure.rejectedSpots=[];
dataStructure.bkgdSpots=[];

handles.dataStructure=dataStructure;
handles.dataStructure.origSize=[size(worms{1}.mask) worms{1}.numberOfPlanes];%size(handles.dataStructure.scaledStack);
%x=1,y=1 is NW,  x runs W-E, y runs N-S

zoom128Size=512;

handles.currentZoom16_width=16;
handles.currentZoom128_width=zoom128Size;
handles.currentZoom16_height=16;
handles.currentZoom128_height=zoom128Size;
%set(handles.zoom128Slider,'Value',log2(zoom128Size));
%these are in axes=spatial coordinates -> NW corner is .5,.5  [x,y]
handles.currentZoom16_x=.5;
handles.currentZoom16_y=.5;
handles.currentZoom128_x=.5;
handles.currentZoom128_y=.5;
handles.currentZoom16_nSpots=0;

c16X=handles.currentZoom16_x;
c16Y=handles.currentZoom16_y;
c16W=handles.currentZoom16_width;
c16H=handles.currentZoom16_height;

c16R=yToRow(c16Y);
c16C=xToCol(c16X);
if handles.highMemory
    currentSlice=handles.dataStructure.scaledStack(:,:,handles.currentZ);
else
    currentSlice=handles.dataStructure.scaledSlice;
end;
[handles.blueSlice,handles.confirmedSlice,handles.blueSpotRankList,handles.blueSpots,handles.bkgd,handles.sliceSortedSpotData]=updateBlueSlice2(handles.sortedSpotData,zeros(size(currentSlice)),handles.currentZ);
%blueSpots is an nx2 matrix of row and column locations

set(handles.spotRankSlider,'Max',handles.nMaximaBySlice(handles.currentZ));
handles.iCurrentSpot=1;%start at 1 get(handles.spotRankSlider,'Value');

%%%%%%%%%%%%%%%
%Current Locations
%%
c16X=handles.currentZoom16_x;
c16Y=handles.currentZoom16_y;
c16W=handles.currentZoom16_width;
c16H=handles.currentZoom16_height;
c128X=handles.currentZoom128_x;
c128Y=handles.currentZoom128_y;
c128W=handles.currentZoom128_width;
c128H=handles.currentZoom128_height;
c16R=yToRow(c16Y);
c16C=xToCol(c16X);
c128R=yToRow(c128Y);
c128C=xToCol(c128X);
%%
%%%%%%%%%%%%%%%%%

[c16X,c16Y,c16R,c16C,handles.blueSlice,handles.confirmedSlice,handles.currentZ,didTopSlice,handles.blueSpots,handles.iCurrentSpot,handles.blueSpotRankList,handles.bkgd,handles.sortedSpotData.scaledValues,handles.sliceSortedSpotData,handles.dataStructure.scaledSlice]=moveZoom16(c16X,c16Y,c16W,c16H,c128X,c128Y,c128W,c128H,handles);
regionalMaxes16=handles.blueSlice(c16R:c16R+c16H-1,c16C:c16C+c16W-1);

handles.currentZoom16_x=c16X;
handles.currentZoom16_y=c16Y;

%%%%%%%%%%%%%%%%%%%%
%always try to keep zoom16 in the middle of zoom128
%but if at the edge, still do a full square
handles.currentZoom128_x=min(colToX(handles.dataStructure.origSize(1))-c128W+1,max(.5,c16X-c128W/2));
handles.currentZoom128_y=min(rowToY(handles.dataStructure.origSize(2))-c128H+1,max(.5,c16Y-c128H/2));
%%%%%%%%%%%%%%%%%%%%%%%

%this is the function that will record the center of the spot
set(handles.zoom16,'ButtonDownFcn',@zoom16_ButtonDownFcn);

%this function will move the focus to a new place
set(handles.zoom128,'ButtonDownFcn',@zoom128_ButtonDownFcn);

%%%%%%%%%%%%%%%%%%%%% Set text data in gui
set(handles.z_pos_txt,'String',outOf('slice', handles.currentZ,handles.dataStructure.stackInfo.numberOfPlanes));
set(handles.x16_txt,'String',['x16: ' num2str(handles.currentZoom16_x)]);
set(handles.y16_txt,'String',['y16: ' num2str(handles.currentZoom16_y)]);
set(handles.x128_txt,'String',['x128: ' num2str(handles.currentZoom128_x)]);
set(handles.y128_txt,'String',['y128: ' num2str(handles.currentZoom128_y)]);
handles.currentZoom16_nSpots=sum(regionalMaxes16(:)>0);
set(handles.nSpots_txt,'String',[num2str(handles.currentZoom16_nSpots) ' spots']);
set(handles.acceptedNSpots_txt,'String','0 accepted spots');
set(handles.rejectedNSpots_txt,'String','0 rejected spots');
set(handles.NregionalMaximaLeftInSlice_txt,'String',[num2str(length(handles.blueSpotRankList)) ' regional maxima left']);
set(handles.spotRankReporter_txt,'String',['Spot Rank: ' num2str(handles.blueSpotRankList(handles.iCurrentSpot))]);
%%%%%%%%%%%%%%%%%%%%%%%%%%

%set(handles.zoom128Slider_txt,'String',num2str(2^get(handles.zoom128Slider,'Value')));
%right now I won't have a scrollbar function

guidata(hObject,handles);
displayImFull(hObject,handles);
%END SAR EDITS

% UIWAIT makes identifySpots wait for user response (see UIRESUME)
uiwait(handles.figure1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  END OPENING_FCN %%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function row=yToRow(y)
row=floor(y+.5);

function col=xToCol(x)
col=floor(x+.5);

function x=colToX(c)
x=c-.5;

function y=rowToY(r)
y=r-.5;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on mouse press over axes background.
function zoom16_ButtonDownFcn(currhandle, eventdata)
% hObject    handle to color_im (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%This function will be invoked when the user clicks on the zoom16 image.
%This happens usually when the user is manually rejecting a spot where
%there are other acceptable spots in the field of view
%The role of this function is to update blueSlice, blueSpots,
%blueSpotRankList, 


data = guidata(currhandle);
data.lastHandles=data;
data=resetLastHandles(data,data.rollbackDepth, 0);

%%% Get the point that was clicked and translate it into rows and columns
pt = get(data.zoom16,'currentpoint');
pixelToChange_c=xToCol(pt(1,1));
pixelToChange_r=yToRow(pt(1,2));
%%%%%%%%%%%%%%%%%


    %%%%%%%%%%%%%%%%%  18 Oct 2011.  I removed the functionality where you
    %%%%%%%%%%%%%%%%%  can click in zoom16 and ADD a spot.  This should not
    %%%%%%%%%%%%%%%%%  happen because all regional maxima are accounted
    %%%%%%%%%%%%%%%%%  for. However, I only comment it out here because it
    %%%%%%%%%%%%%%%%%  might be worthwhile to put it back in at some point
%%% So first check to see if this pixel is nonzero in blueSlice...if it is,
%%% then proceed.  if it isn't then ignore.
if data.blueSlice(pixelToChange_r,pixelToChange_c)


%%%%%% I don't really use the background mode so this first part of the
%%%%%% if-else statement isn't run
if get(data.checkBackground,'Value')==get(data.checkBackground,'Max')%checked
    data.bkgd(pixelToChange_r,pixelToChange_c)=~data.bkgd(pixelToChange_r,pixelToChange_c);
    
    if ~data.bkgd(pixelToChange_r,pixelToChange_c)
        %then it was there and is no longer:  remove and add to rejected list
        [~,~,indexToRemove]=intersect([pixelToChange_r,pixelToChange_c],data.dataStructure.bkgdSpots,'rows');
        data.dataStructure.bkgdSpots(indexToRemove,:)=[];
        set(data.bkgdNSpots_txt,'String',[num2str(size(data.dataStructure.bkgdSpots,1)),' bkgd spots']);
        
    else
        %then add it
        data.dataStructure.bkgdSpots=[data.dataStructure.bkgdSpots;[pixelToChange_r,pixelToChange_c]];
        set(data.bkgdNSpots_txt,'String',[num2str(size(data.dataStructure.bkgdSpots,1)),' bkgd spots']);
        
    end;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else %then not in background mode
    
%     disp(['iCurrentSpot' num2str(data.iCurrentSpot) ' in zoom16ButtonDown']);
%     disp(['currentSpotRank' num2str(data.blueSpotRankList(data.iCurrentSpot)) ' in zoom16ButtonDown']);
%     disp(['blueSpotRankList(end) ' num2str(data.blueSpotRankList(end)) ' in zoom16ButtonDown']);
    
    %%% %%% %%% %% %% 
    %%%%%% If adding a spot, then add 1.  If removing a spot then subtract
    %%%%%% 1 from the count of the number of spots in the 16view
    data.currentZoom16_nSpots=data.currentZoom16_nSpots+(-1)^(data.blueSlice(pixelToChange_r,pixelToChange_c)>0);
    set(data.nSpots_txt,'String',[num2str(data.currentZoom16_nSpots) ' spots']);
    %%%%%%%%%%%%%%

    %%%%%%%%%%%% Change the blueSlice pixel value to 0 or the value of the
    %%%%%%%%%%%% pixel
    if data.highMemory
        data.blueSlice(pixelToChange_r,pixelToChange_c)=(~data.blueSlice(pixelToChange_r,pixelToChange_c)).*data.dataStructure.scaledStack(pixelToChange_r,pixelToChange_c,data.currentZ);
    else
        data.blueSlice(pixelToChange_r,pixelToChange_c)=(~data.blueSlice(pixelToChange_r,pixelToChange_c)).*data.dataStructure.scaledSlice(pixelToChange_r,pixelToChange_c);
    end;
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %disp([num2str(size(data.blueSpots,1)) ' in blueSpots']);
    
    %%% blue spots is an nx2 matrix of rows a columns 
    if ~data.blueSlice(pixelToChange_r,pixelToChange_c)
        %then it was there and is no longer:  remove and add to rejected list
        %%%%%%%%%%%% add or remove from blueSpots and can use same index to
        %%%%%%%%%%%% remove from blueSpotRankList
        [~,~,indexToRemove]=intersect([pixelToChange_r,pixelToChange_c],data.blueSpots,'rows');
        data.blueSpots(indexToRemove,:)=[];
        data.blueSpotRankList(indexToRemove)=[];
        
        %What does this do to iCurrentSpot which is the index of the
        %center of the zoom16?
        if indexToRemove<data.iCurrentSpot
            data.iCurrentSpot=data.iCurrentSpot-1;
        end;
        data.iCurrentSpot=min(max(1,data.iCurrentSpot),length(data.blueSpotRankList));
        %%%%%%%%%%%%%%
        
        data.dataStructure.rejectedSpots=[data.dataStructure.rejectedSpots ;[pixelToChange_r,pixelToChange_c data.currentZ]];
        set(data.rejectedNSpots_txt,'String',[num2str(size(data.dataStructure.rejectedSpots,1)),' rejected spots']);
        %%%%%%%%%%%%% now it is gone from blueSpots and blueSpotRankList
        %%%%%% Don't want to adjust currentSpotRank here because this only
        %%%%%% happens when press Next & something
         
    else
        %%%%%%%%% 18 Oct 2011
        % With the initial if statement, this part of the if-then will
        % never be run....however, I keep it in here if it needs to be
        % added back in the future.  However, would need to make sure the
        % data structures are updated since I didn't finish doing that
        %then add it
        %This is more complicated.  need to add to the various data
        %structures
        %But this should not happen
        %Because later on would also have to add to worms file and do the
        %statistics
        data.blueSpots=[data.blueSpots;[pixelToChange_r,pixelToChange_c]];
        %also check to see if it happens to be in rejectedSpots (say clicked
        %off then clicked back on...if it is, then remove it
        if ~isempty(data.dataStructure.rejectedSpots)
            [~,~,indexOfSpot]=intersect([pixelToChange_r,pixelToChange_c data.currentZ],data.dataStructure.rejectedSpots,'rows');
            if isempty(indexOfSpot)
                
                data.dataStructure.rejectedSpots(indexOfSpot,:)=[];
            end;
        end;
        set(data.rejectedNSpots_txt,'String',[num2str(size(data.dataStructure.rejectedSpots,1)),' rejected spots']);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    end;
    set(data.NregionalMaximaLeftInSlice_txt,'String',[num2str(length(data.blueSpotRankList)) ' regional maxima left']);
end;
%disp([num2str(size(data.blueSpots,1)) ' in blueSpots']);

%%%%%%%%%%%% Was that just the last spot in the slice? %%%%%%%%%%%%%%%%%
%%%%%%%%% Copied from nextSlice_Callback
if isempty(data.blueSpots)
data.lastHandles=data;
data=resetLastHandles(data,data.rollbackDepth,0);
if data.highMemory
    data.lastHandles.dataStructure=rmfield(data.lastHandles.dataStructure,'scaledStack');
else
    data.lastHandles.dataStructure=rmfield(data.lastHandles.dataStructure,'scaledSlice');
end;
if data.currentZ<data.dataStructure.origSize(3)
    disp(['Moving from slice ' num2str(data.currentZ) ' to slice ' num2str(data.currentZ+1)]);
    data.currentZ=data.currentZ+1;
    if ~data.highMemory
        [currentSlice,spotVSortedScaled]=loadAndScaleSlice(data.dataStructure.stackInfo.stackName,data.dataStructure.stackInfo.stackFileType,data.currentZ,data);
        data.dataStructure.scaledSlice=currentSlice;
        data.sortedSpotData.scaledValues=spotVSortedScaled;
    end;
    
    c16X=1;
    c16Y=1;
    c128X=1;
    c128Y=1;
    c16W=data.currentZoom16_width;
    c16H=data.currentZoom16_height;
    c128W=data.currentZoom128_width;
    c128H=data.currentZoom128_height;
    c16R=yToRow(c16Y);
    c16C=xToCol(c16X);
    c128R=yToRow(c128Y);
    c128C=xToCol(c128X);
    
    
    %%%
    %Start new slice from 1
    previousSpotRank=1;
    %update blueSlice and blueSpots
    [data.blueSlice, data.confirmedSlice,data.blueSpotRankList,data.blueSpots,data.bkgd,data.sliceSortedSpotData]=updateBlueSlice2(data.sortedSpotData,data.confirmedSlice,data.currentZ);
    %Now blueSpotRankList is updated for the new slice
    if previousSpotRank>data.blueSpotRankList(end)
        data.iCurrentSpot=length(data.blueSpotRankList);
    else
        data.iCurrentSpot=find(data.blueSpotRankList==previousSpotRank,1,'first');
    end;
    
    data.currentZoom16_x=1;
    data.currentZoom16_y=1;
    data.currentZoom128_x=1;
    data.currentZoom128_y=1;
    
    %moves the 16 square along (with the possibility of going to next
    %slice)
    [c16X,c16Y,c16R,c16C,data.blueSlice,data.confirmedSlice,data.currentZ,didTopSlice,data.blueSpots,data.iCurrentSpot,data.blueSpotRankList,data.bkgd,data.sortedSpotData.scaledValues,data.sliceSortedSpotData,data.dataStructure.scaledSlice]=moveZoom16(c16X,c16Y,c16W,c16H,c128X,c128Y,c128W,c128H,data);
    if didTopSlice==1
        uiresume(gcbf);%this should jump back right after uiwait
    end;
    
    data.currentZoom16_x=c16X;
    data.currentZoom16_y=c16Y;
    %always try to keep zoom16 in the middle of zoom128
    %but if at the edge, still do a full square
    data.currentZoom128_x=min(colToX(data.dataStructure.origSize(2))-c128W+1,max(.5,c16X-c128W/2));
    data.currentZoom128_y=min(rowToY(data.dataStructure.origSize(1))-c128H+1,max(.5,c16Y-c128H/2));
    
    c16R=yToRow(c16Y);
    c16C=xToCol(c16X);
    
    %now redo regional max stuff
    regionalMaxes16=data.blueSlice(c16R:c16R+c16H-1,c16C:c16C+c16W-1);
    data.currentZoom16_nSpots=sum(regionalMaxes16(:)>0);
    set(data.nSpots_txt,'String',[num2str(data.currentZoom16_nSpots) ' spots']);
else%already at top slice
    disp('identifySpots finished');
uiresume(data.figure1);
end;






end;%%if this is the topSlice, then this might cause an error


%Need to deal with the case where I clikc on th elast spot in a slice
%Also seems ot be a problem where sliceSortedSpotData is getting cut by one
%when go to knew slice

guidata(currhandle,data);

displayImFull(currhandle,data,0);

end;%%end if it is a regional maximum - Added 18Oct2011

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on mouse press over axes background.
function zoom128_ButtonDownFcn(currhandle, eventdata)
% hObject    handle to color_im (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%This function is just to move around the zoom128 image.  It doesn't do
%anything to blueSpots or any of the data structures.
%But it could complicate matters in that it escapes from the rank ordering
%and won't necessarily come back exactly...if you move to a zoom16 with
%blueSpotRank less than the previous one, then when these are deleted upon
%Next&, iCurrentSpot will not change but will come back X later than
%previous.


data = guidata(currhandle);

%%%%%%%%%%%%%%%%%%%%%%
c16X=data.currentZoom16_x;
c16Y=data.currentZoom16_y;
c16W=data.currentZoom16_width;
c16H=data.currentZoom16_height;
c128X=data.currentZoom128_x;
c128Y=data.currentZoom128_y;
c128W=data.currentZoom128_width;
c128H=data.currentZoom128_height;
c16R=yToRow(c16Y);
c16C=xToCol(c16X);
c128R=yToRow(c128Y);
c128C=xToCol(c128X);

%%%%%%

pt = get(data.zoom128,'currentpoint');
% xPixelOffset=floor(pt(1,2)-.5);
% yPixelOffset=floor(pt(1,1)-.5);
newC=xToCol(pt(1,1));
newR=yToRow(pt(1,2));


%%%%%%%% I don't know why this is in here.
% [spotR,spotC]=find(data.blueSlice(c16R:c16R+c16H-1,c16C:c16C+c16W-1)>0);
% %need to add z information
% newSpots=[];
% for i=1:size(spotR)
%     newSpots=[newSpots; [spotR(i)+c16R-1 spotC(i)+c16C-1 data.currentZ]];
% end;
% %remove from blueSpots...why?
% if size(newSpots,1)>0 && size(data.blueSpots,1)>0
%     [~,~,blueSpotsToDelete]=intersect(newSpots(:,1:2),data.blueSpots,'rows');
%     data.blueSpots(blueSpotsToDelete,:)=[];
% end;
% set(data.NregionalMaximaLeftInSlice_txt,'String',[num2str(length(data.blueSpotRankList)) ' regional maxima left']);


%move all the axes - move zoom16 to start at the upper corner of zoom128
data.currentZoom16_x=colToX(newC);
data.currentZoom16_y=rowToY(newR);
data.currentZoom128_x=colToX(newC);
data.currentZoom128_y=rowToY(newR);

c16X=data.currentZoom16_x;
c16Y=data.currentZoom16_y;
c16W=data.currentZoom16_width;
c16H=data.currentZoom16_height;
c128X=data.currentZoom128_x;
c128Y=data.currentZoom128_y;
c128W=data.currentZoom128_width;
c128H=data.currentZoom128_height;
c16R=yToRow(c16Y);
c16C=xToCol(c16X);
c128R=yToRow(c128Y);
c128C=xToCol(c128X);



data.currentZoom128_x=min(colToX(data.dataStructure.origSize(1))-c128W+1,max(.5,c16X-c128W/2));
data.currentZoom128_y=min(rowToY(data.dataStructure.origSize(2))-c128H+1,max(.5,c16Y-c128H/2));
regionalMaxes16=data.blueSlice(c16R:c16R+c16H-1,c16C:c16C+c16W-1);
data.currentZoom16_nSpots=sum(regionalMaxes16(:)>0);
set(data.nSpots_txt,'String',[num2str(data.currentZoom16_nSpots) ' spots']);
guidata(currhandle,data);

displayImFull(currhandle,data,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function outstr=outOf(str,i,j)
outstr=[str ' ' num2str(i) '/' num2str(j)];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function displayImFull(hObject,handles,calculateMaxima)
data=guidata(hObject);

%fprintf([num2str(sum((data.blueSlice(:))>0)) ' regional maxima in slice ' num2str(data.currentZ) '\n']);
set(data.z_pos_txt,'String',outOf('slice', data.currentZ,data.dataStructure.origSize(3)));
set(data.x16_txt,'String',['x16: ' num2str(data.currentZoom16_x)]);
set(data.y16_txt,'String',['y16: ' num2str(data.currentZoom16_y)]);
set(data.x128_txt,'String',['x128: ' num2str(data.currentZoom128_x)]);
set(data.y128_txt,'String',['y128: ' num2str(data.currentZoom128_y)]);

iCurrentWorm=data.sliceSortedSpotData.wormNumber(data.blueSpotRankList(data.iCurrentSpot));
iCurrentSpotInWorms=data.sliceSortedSpotData.spotInfoNumberInWorm(data.blueSpotRankList(data.iCurrentSpot));
set(data.iWormiSpot_txt,'String',['Worm:' num2str(iCurrentWorm) ' // Spot:' num2str(iCurrentSpotInWorms)]);
set(data.scdValue_txt,'String',['scd: ' num2str(data.worms{iCurrentWorm}.spotInfo{iCurrentSpotInWorms}.stat.statValues.scd)]);


set(data.NregionalMaximaLeftInSlice_txt,'String',[num2str(length(data.blueSpotRankList)) ' regional maxima left']);

%%
%%%%%%%%%%%%%%%%%%%%%%%%
%check to make sure that currentSpotRank is not greater than the number of
%maxima in the slice
set(data.spotRankSlider,'Min',data.blueSpotRankList(1));
set(data.spotRankSlider,'Max',data.blueSpotRankList(end));
sliderStep=1/(data.blueSpotRankList(end)-data.blueSpotRankList(1));

if ~isinf(sliderStep)
    set(data.spotRankSlider,'SliderStep',[sliderStep 5*sliderStep]);
else
    set(data.spotRankSlider,'SliderStep',[0 1]);
end;
set(data.spotRankSlider,'Value',data.blueSpotRankList(data.iCurrentSpot));
set(data.spotRankReporter_txt,'String',['Spot Rank: ' num2str(data.blueSpotRankList(data.iCurrentSpot))]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%

if data.highMemory
    currentSlice=data.dataStructure.scaledStack(:,:,handles.currentZ);
else
    currentSlice=data.dataStructure.scaledSlice;
end;
c16X=data.currentZoom16_x;
c16Y=data.currentZoom16_y;
c16W=data.currentZoom16_width;
c16H=data.currentZoom16_height;
c128X=data.currentZoom128_x;
c128Y=data.currentZoom128_y;
c128W=data.currentZoom128_width;
c128H=data.currentZoom128_height;

c16R=yToRow(c16Y);
c16C=xToCol(c16X);
c128R=yToRow(c128Y);
c128C=xToCol(c128X);

%i need an argument to tell it whether to recalculate regional maxima or
%not...yes when i move, no when i toggle maxima

if data.highMemory
    set(data.figure_handle,'CurrentAxes',data.fullImage);
    fullColor=cat(3,currentSlice,currentSlice.*(~data.dataStructure.segments),currentSlice.*(~data.dataStructure.segments));
    data.fullImage=imshow(fullColor);
    %note that rectangle x,y is axes (spatial) coordinate.
    %it doesn't work the same way with an axes created by "plot" as an axes
    %created by "imshow"...for imshow, the NW corner is (.5, .5) for plot, SW
    %corner is (0,0)
    rectangle('Position',[c128X, c128Y, c128W,c128H],'EdgeColor','g');
    rectangle('Position',[c16X, c16Y, c16W,c16H],'EdgeColor','y');
end;

set(data.figure_handle,'CurrentAxes',data.zoom16);

rgSlice=currentSlice.*(~data.blueSlice)+.5*data.blueSlice;
color16=cat(3,rgSlice,rgSlice.*(~data.confirmedSlice),(currentSlice).*(~data.confirmedSlice)-data.bkgd);
data.zoom16=imshow(color16);

origXLim=get(gca,'XLim'); origWidth=origXLim(2)-origXLim(1);
origYLim=get(gca,'YLim'); origHeight=origYLim(2)-origYLim(1);
zoomFactorX=origWidth/data.currentZoom16_width;
zoomFactorY=origHeight/data.currentZoom16_height;
zoomFactor=min(zoomFactorX,zoomFactorY);
data.zoom16Factor=zoomFactor;
zoom(data.zoom16Factor);
%the integer is in the middle of the square, so this needs to be -.5
xlim(get(data.figure_handle,'CurrentAxes'),[c16X c16X+c16W]);
ylim([c16Y c16Y+c16H]);

if data.highMemory
    zoom16Column=data.dataStructure.scaledStack(c16R:c16R+c16H-1,c16C:c16C+c16W-1,:);
    for i=1:5
        if data.currentZ+(i-3)<=data.dataStructure.origSize(3) && data.currentZ+(i-3)>=1
            surf(data.surfPlots{i},zoom16Column(:,:,data.currentZ+(i-3)));
        end;
        set(data.surfPlots{i},'YDir','reverse','XTick',[],'ZLim',[0 1],'YTick',[],'ZTick',[],'Visible','off','Color',get(data.figure_handle,'Color'));
    end;
end;

set(data.figure_handle,'CurrentAxes',data.zoom128);

color128=cat(3,currentSlice+.2*data.dataStructure.outlines,currentSlice+.2*data.dataStructure.outlines,currentSlice-data.bkgd*.3);
data.zoom128=imshow(color128);
origXLim=get(gca,'XLim'); origWidth=origXLim(2)-origXLim(1);
origYLim=get(gca,'YLim'); origHeight=origYLim(2)-origYLim(1);
zoomFactorX=origWidth/data.currentZoom128_width;
zoomFactorY=origHeight/data.currentZoom128_height;
zoomFactor=min(zoomFactorX,zoomFactorY);
data.zoom128Factor=zoomFactor;
zoom(data.zoom128Factor);
xlim([data.currentZoom128_x data.currentZoom128_x+data.currentZoom128_width]);
ylim([data.currentZoom128_y data.currentZoom128_y+data.currentZoom128_height]);
rectColor=min(1,3*median(currentSlice(:)));
if get(data.greenBox_checkBox,'Value')
    rectangle('Position',[data.currentZoom16_x, data.currentZoom16_y, data.currentZoom16_width,data.currentZoom16_height],'EdgeColor',[rectColor/3 .8 rectColor/2],'LineWidth',.5);
end;
set(data.rejectedNSpots_txt,'String',[num2str(size(handles.dataStructure.rejectedSpots,1)),' rejected spots']);%handles
set(data.acceptedNSpots_txt,'String',[num2str(size(handles.dataStructure.goodSpots,1)),' accepted spots']);%handles

%this is the function that will record the center of the spot
set(data.zoom16,'ButtonDownFcn',@zoom16_ButtonDownFcn);
%this function will move the focus to a new place
set(data.zoom128,'ButtonDownFcn',@zoom128_ButtonDownFcn);

%guidata(hObject,data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Outputs from this function are returned to the command line.
function varargout = identifySpots_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
%varargout{1} = handles.output;

%Before passing these back, tack on the worms locations using the
% handles.spotIndicesInWormsSorted
% handles.spotListSorted

spotListSorted=[handles.sortedSpotData.rows handles.sortedSpotData.cols handles.sortedSpotData.zs];

[~,ispotListGood,igood]=intersect(spotListSorted,handles.dataStructure.goodSpots,'rows');
[~,ispotListRej,irej]=intersect(spotListSorted,handles.dataStructure.rejectedSpots,'rows');
goodSpotInfoInformation=[handles.sortedSpotData.wormNumber(ispotListGood) handles.sortedSpotData.spotInfoNumberInWorm(ispotListGood)];
rejectedSpotInfoInformation=[handles.sortedSpotData.wormNumber(ispotListRej) handles.sortedSpotData.spotInfoNumberInWorm(ispotListRej)];
goodSpotValueInformation=handles.sortedSpotData.values(ispotListGood);
rejectedSpotValueInformation=handles.sortedSpotData.values(ispotListRej);

%Note that the below works because spots and rejected spots are a proper
%subset of all the candidates in spotListSorted(:,1:3)
handles.dataStructure.goodSpots=[handles.dataStructure.goodSpots(igood,:)  handles.sortedSpotData.values(ispotListGood)  handles.sortedSpotData.wormNumber(ispotListGood) handles.sortedSpotData.spotInfoNumberInWorm(ispotListGood)];   
handles.dataStructure.rejectedSpots=[handles.dataStructure.rejectedSpots(irej,:)  handles.sortedSpotData.values(ispotListRej)  handles.sortedSpotData.wormNumber(ispotListRej) handles.sortedSpotData.spotInfoNumberInWorm(ispotListRej)];   

varargout{1} = handles.dataStructure.goodSpots;
varargout{2} = handles.dataStructure.rejectedSpots;

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes on button press in nextAccept_button.
function nextAccept_button_Callback(hObject, eventdata, handles)
% hObject    handle to nextAccept_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%This function takes the blue pixels in the zoom16 window and adds them to
%good spots and then removes them from blueSlice and blueSpots and
%blueSpotRankList

%data=guidata(handles);
handles.lastHandles=handles;
if handles.highMemory
    handles.lastHandles.dataStructure=rmfield(handles.lastHandles.dataStructure,'scaledStack');
else
    handles.lastHandles.dataStructure=rmfield(handles.lastHandles.dataStructure,'scaledSlice');
end;
handles=resetLastHandles(handles,handles.rollbackDepth,0);
c16X=handles.currentZoom16_x;
c16Y=handles.currentZoom16_y;
c16W=handles.currentZoom16_width;
c16H=handles.currentZoom16_height;
c128X=handles.currentZoom128_x;
c128Y=handles.currentZoom128_y;
c128W=handles.currentZoom128_width;
c128H=handles.currentZoom128_height;

c16R=yToRow(c16Y);
c16C=xToCol(c16X);
c128R=yToRow(c128Y);
c128C=xToCol(c128X);

newSpots=getZoom16Spots(c16R,c16H,c16C,c16W,handles.blueSlice,handles.currentZ);

handles.dataStructure.goodSpots=[handles.dataStructure.goodSpots; newSpots];
set(handles.acceptedNSpots_txt,'String',[num2str(size(handles.dataStructure.goodSpots,1)),' accepted spots']);

%remove from blueSpots
[handles.blueSpots,handles.blueSpotRankList,handles.iCurrentSpot]=removeZoom16SpotsFromBlueSpotsAndUpdateCurrentSpotIndex(newSpots,handles.blueSpots,handles.blueSpotRankList,handles.iCurrentSpot);

%now transfer the spots from blueSlice to confirmedSlice and erase from
%blueSlice - why erase from blueSlice? - so don't go back to it
handles.confirmedSlice(c16R:c16R+c16H-1,c16C:c16C+c16W-1)=handles.blueSlice(c16R:c16R+c16H-1,c16C:c16C+c16W-1);
handles.blueSlice(c16R:c16R+c16H-1,c16C:c16C+c16W-1)=zeros(c16H,c16W);

%moves the 16 square along
[c16X,c16Y,c16R,c16C,handles.blueSlice,handles.confirmedSlice,handles.currentZ,didTopSlice,handles.blueSpots,handles.iCurrentSpot,handles.blueSpotRankList,handles.bkgd,handles.sortedSpotData.scaledValues,handles.sliceSortedSpotData,handles.dataStructure.scaledSlice]=moveZoom16(c16X,c16Y,c16W,c16H,c128X,c128Y,c128W,c128H,handles);
if didTopSlice==1
    uiresume(gcbf);%this should jump back right after uiwait
end;

handles.currentZoom16_x=c16X;
handles.currentZoom16_y=c16Y;
%always try to keep zoom16 in the middle of zoom128
%but if at the edge, still do a full square
handles.currentZoom128_x=min(colToX(handles.dataStructure.origSize(2))-c128W+1,max(.5,c16X-c128W/2));
handles.currentZoom128_y=min(rowToY(handles.dataStructure.origSize(1))-c128H+1,max(.5,c16Y-c128H/2));

c16R=yToRow(c16Y);
c16C=xToCol(c16X);
c128R=yToRow(c128Y);
c128C=xToCol(c128X);

regionalMaxes16=handles.blueSlice(c16R:c16R+c16H-1,c16C:c16C+c16W-1);
handles.currentZoom16_nSpots=sum(regionalMaxes16(:)>0);
set(handles.nSpots_txt,'String',[num2str(handles.currentZoom16_nSpots) ' spots']);
set(handles.NregionalMaximaLeftInSlice_txt,'String',[num2str(length(handles.blueSpotRankList)) ' regional maxima left']);
set(handles.greenBox_checkBox,'Value',1)


guidata(hObject,handles);
displayImFull(hObject,handles,1);
%disp(handles.dataStructure.goodSpots);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes during object creation, after setting all properties.
function x16_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to x16_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes during object creation, after setting all properties.
function nSpots_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nSpots_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes during object creation, after setting all properties.
function z_pos_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to z_pos_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes during object creation, after setting all properties.
function y16_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to y16_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes during object creation, after setting all properties.
function x128_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to x128_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes during object creation, after setting all properties.
function y128_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to y128_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function regMaxes=getImRegionalMax(r16,c16,width16,height16,slice)
fprintf('%d %d %d %d',r16,c16,width16,height16);
sz=size(slice);

smallIm=slice(r16:min(sz(1),r16+height16-1),c16:min(sz(2),c16+width16-1));
%threshold it - it already should have the background subtracted
%off...don't
maxIntensity=max(slice(:));

threshIm=smallIm.*(smallIm>(.5*maxIntensity));
if max(threshIm(:))>0
    regMaxes=imregionalmax(threshIm).*smallIm;
else
    regMaxes=zeros(size(smallIm));
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes on button press in FinishedButton.
function FinishedButton_Callback(hObject, eventdata, handles)
% hObject    handle to FinishedButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('identifySpots finished');
uiresume(handles.figure1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% function [bs,cs]=updateBlueSlice(currentSlice,maxIntensity,previousConfirmedSlice)
% %updates blue slice when currentZ changes
% global intensityFraction
% threshIm=currentSlice.*(currentSlice>(intensityFraction*maxIntensity));
% 
% if max(threshIm(:))>0
%     bs=imregionalmax(threshIm).*currentSlice;
% else
%     bs=zeros(size(currentSlice));
% end;
% fprintf('Blue slice updated with %d regional maxima and threshold %f\n',sum(bs(:)>0),intensityFraction*maxIntensity);
% cs=bs.*previousConfirmedSlice;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [bs,cs,blueSpotRankList,blueSpots,bkgd,sls]=updateBlueSlice2(sortedSpotData,previousConfirmedSlice,currentZ)
%updates blue slice when currentZ changes

bs=zeros(size(previousConfirmedSlice));
currentZIndices=find(sortedSpotData.zs==currentZ);

ssdFieldNames=fieldnames(sortedSpotData);
for fni=1:size(ssdFieldNames,1)
    sls.(ssdFieldNames{fni})=sortedSpotData.(ssdFieldNames{fni})(currentZIndices);
end;

for si=1:length(sls.rows)%should be in order
    bs(sls.rows(si),sls.cols(si))=sls.scaledValues(si);
end;
blueSpots=[sls.rows sls.cols];%%%make sure this is nx2
blueSpotRankList=1:length(sls.rows);


%do neighbors too
bkgd=zeros(size(bs));
cs=zeros(size(bs));


cs(1:end-1,1:end-1)=cs(1:end-1,1:end-1)+bs(1:end-1,1:end-1).*previousConfirmedSlice(2:end,2:end);
cs(1:end-1,1:end)=cs(1:end-1,1:end)+bs(1:end-1,1:end).*previousConfirmedSlice(2:end,1:end);
cs(1:end-1,2:end)=cs(1:end-1,2:end)+bs(1:end-1,2:end).*previousConfirmedSlice(2:end,1:end-1);

cs(1:end,1:end-1)=cs(1:end,1:end-1)+bs(1:end,1:end-1).*previousConfirmedSlice(1:end,2:end);
cs(1:end,1:end)=cs(1:end,1:end)+bs(1:end,1:end).*previousConfirmedSlice(1:end,1:end);
cs(1:end,2:end)=cs(1:end,2:end)+bs(1:end,2:end).*previousConfirmedSlice(1:end,1:end-1);

cs(2:end,1:end-1)=cs(2:end,1:end-1)+bs(2:end,1:end-1).*previousConfirmedSlice(1:end-1,2:end);
cs(2:end,1:end)=cs(2:end,1:end)+bs(2:end,1:end).*previousConfirmedSlice(1:end-1,1:end);
cs(2:end,2:end)=cs(2:end,2:end)+bs(2:end,2:end).*previousConfirmedSlice(1:end-1,1:end-1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function bs=modifyBlueSliceIntensityFraction(currentSlice,maxIntensity)
%updates blue slice when intensityFraction changes
global intensityFraction
threshIm=currentSlice.*(currentSlice>(intensityFraction*maxIntensity));
if max(threshIm(:))>0
    bs=imregionalmax(threshIm).*currentSlice;
else
    bs=zeros(size(currentSlice));
end;
fprintf('Blue slice modified with %d regional maxima and threshold %f\n',sum(bs(:)>0),intensityFraction*maxIntensity);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes on button press in nextSlice.
function nextSlice_Callback(hObject, eventdata, handles)
% hObject    handle to nextSlice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.lastHandles=handles;
handles=resetLastHandles(handles,handles.rollbackDepth,0);
if handles.highMemory
    handles.lastHandles.dataStructure=rmfield(handles.lastHandles.dataStructure,'scaledStack');
else
    handles.lastHandles.dataStructure=rmfield(handles.lastHandles.dataStructure,'scaledSlice');
end;
if handles.currentZ<handles.dataStructure.origSize(3)
    disp(['Moving from slice ' num2str(handles.currentZ) ' to slice ' num2str(handles.currentZ+1)]);
    handles.currentZ=handles.currentZ+1;
    if ~handles.highMemory
        [currentSlice,spotVSortedScaled]=loadAndScaleSlice(handles.dataStructure.stackInfo.stackName,handles.dataStructure.stackInfo.stackFileType,handles.currentZ,handles);
        handles.dataStructure.scaledSlice=currentSlice;
        handles.sortedSpotData.scaledValues=spotVSortedScaled;
    end;
    
    c16X=1;
    c16Y=1;
    c128X=1;
    c128Y=1;
    c16W=handles.currentZoom16_width;
    c16H=handles.currentZoom16_height;
    c128W=handles.currentZoom128_width;
    c128H=handles.currentZoom128_height;
    c16R=yToRow(c16Y);
    c16C=xToCol(c16X);
    c128R=yToRow(c128Y);
    c128C=xToCol(c128X);
    
    
    %%%
    %Need to store the previous slice's spotRank so can continue from there
    previousSpotRank=handles.blueSpotRankList(handles.iCurrentSpot);
    %update blueSlice and blueSpots
    [handles.blueSlice, handles.confirmedSlice,handles.blueSpotRankList,handles.blueSpots,handles.bkgd,handles.sliceSortedSpotData]=updateBlueSlice2(handles.sortedSpotData,handles.confirmedSlice,handles.currentZ);
    %Now blueSpotRankList is updated for teh new slice
    if previousSpotRank>handles.blueSpotRankList(end)
        handles.iCurrentSpot=length(handles.blueSpotRankList);
    else
        handles.iCurrentSpot=find(handles.blueSpotRankList==previousSpotRank,1,'first');
    end;
    
    handles.currentZoom16_x=1;
    handles.currentZoom16_y=1;
    handles.currentZoom128_x=1;
    handles.currentZoom128_y=1;
    
    %moves the 16 square along (with the possibility of going to next
    %slice)
    [c16X,c16Y,c16R,c16C,handles.blueSlice,handles.confirmedSlice,handles.currentZ,didTopSlice,handles.blueSpots,handles.iCurrentSpot,handles.blueSpotRankList,handles.bkgd,handles.sortedSpotData.scaledValues,handles.sliceSortedSpotData,handles.dataStructure.scaledSlice]=moveZoom16(c16X,c16Y,c16W,c16H,c128X,c128Y,c128W,c128H,handles);
    if didTopSlice==1
        uiresume(gcbf);%this should jump back right after uiwait
    end;
    
    handles.currentZoom16_x=c16X;
    handles.currentZoom16_y=c16Y;
    %always try to keep zoom16 in the middle of zoom128
    %but if at the edge, still do a full square
    handles.currentZoom128_x=min(colToX(handles.dataStructure.origSize(2))-c128W+1,max(.5,c16X-c128W/2));
    handles.currentZoom128_y=min(rowToY(handles.dataStructure.origSize(1))-c128H+1,max(.5,c16Y-c128H/2));
    
    c16R=yToRow(c16Y);
    c16C=xToCol(c16X);
    
    %now redo regional max stuff
    regionalMaxes16=handles.blueSlice(c16R:c16R+c16H-1,c16C:c16C+c16W-1);
    handles.currentZoom16_nSpots=sum(regionalMaxes16(:)>0);
    set(handles.nSpots_txt,'String',[num2str(handles.currentZoom16_nSpots) ' spots']);
    set(handles.greenBox_checkBox,'Value',1)

    guidata(hObject,handles);
    displayImFull(hObject,handles,1);
else%already at top slice
    disp('identifySpots finished');
uiresume(handles.figure1);
end;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes on button press in nextReject_button.
function nextReject_button_Callback(hObject, eventdata, handles)
% hObject    handle to nextReject_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%like done with spots but this just rejects all the putative spots in the
%area (doesn't transfer them to confirmed)

handles.lastHandles=handles;
handles=resetLastHandles(handles,handles.rollbackDepth,0);
if handles.highMemory
    handles.lastHandles.dataStructure=rmfield(handles.lastHandles.dataStructure,'scaledStack');
else
    handles.lastHandles.dataStructure=rmfield(handles.lastHandles.dataStructure,'scaledSlice');
end;

c16X=handles.currentZoom16_x;
c16Y=handles.currentZoom16_y;
c16W=handles.currentZoom16_width;
c16H=handles.currentZoom16_height;
c128X=handles.currentZoom128_x;
c128Y=handles.currentZoom128_y;
c128W=handles.currentZoom128_width;
c128H=handles.currentZoom128_height;

c16R=yToRow(c16Y);
c16C=xToCol(c16X);
c128R=yToRow(c128Y);
c128C=xToCol(c128X);

%just have this newSpot stuff here to remove from blueSpots
newSpots=getZoom16Spots(c16R,c16H,c16C,c16W,handles.blueSlice,handles.currentZ);

handles.dataStructure.rejectedSpots=[handles.dataStructure.rejectedSpots ;newSpots];
set(handles.rejectedNSpots_txt,'String',[num2str(size(handles.dataStructure.rejectedSpots,1)),' rejected spots']);

%remove from blueSpots
[handles.blueSpots,handles.blueSpotRankList,handles.iCurrentSpot]=removeZoom16SpotsFromBlueSpotsAndUpdateCurrentSpotIndex(newSpots,handles.blueSpots,handles.blueSpotRankList,handles.iCurrentSpot);

%erase from blueSlice - why erase from blueSlice? - so don't go back to it
handles.blueSlice(c16R:c16R+c16H-1,c16C:c16C+c16W-1)=zeros(c16H,c16W);

[c16X,c16Y,c16R,c16C,handles.blueSlice,handles.confirmedSlice,handles.currentZ,didTopSlice,handles.blueSpots,handles.iCurrentSpot,handles.blueSpotRankList,handles.bkgd,handles.sortedSpotData.scaledValues,handles.sliceSortedSpotData,handles.dataStructure.scaledSlice]=moveZoom16(c16X,c16Y,c16W,c16H,c128X,c128Y,c128W,c128H,handles);

if didTopSlice==1
    uiresume(gcbf);%this should jump back right after uiwait
end;

handles.currentZoom16_x=c16X;
handles.currentZoom16_y=c16Y;
%always try to keep zoom16 in the middle of zoom128
%but if at the edge, still do a full square
handles.currentZoom128_x=min(colToX(handles.dataStructure.origSize(2))-c128W+1,max(.5,c16X-c128W/2));
handles.currentZoom128_y=min(rowToY(handles.dataStructure.origSize(1))-c128H+1,max(.5,c16Y-c128H/2));

c16R=yToRow(c16Y);
c16C=xToCol(c16X);
c128R=yToRow(c128Y);
c128C=xToCol(c128X);

%now redo regional max stuff
regionalMaxes16=handles.blueSlice(c16R:c16R+c16H-1,c16C:c16C+c16W-1);
handles.currentZoom16_nSpots=sum(regionalMaxes16(:)>0);
set(handles.nSpots_txt,'String',[num2str(handles.currentZoom16_nSpots) ' spots']);
set(handles.NregionalMaximaLeftInSlice_txt,'String',[num2str(length(handles.blueSpotRankList)) ' regional maxima left']);
set(handles.greenBox_checkBox,'Value',1)

guidata(hObject,handles);
displayImFull(hObject,handles,1);
%disp(handles.dataStructure.goodSpots);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [c16X,c16Y,c16R,c16C,blueSlice,confirmedSlice,currentZ,didTopSlice,blueSpots,iCurrentSpot,blueSpotRankList,bkgd,scaledValues,sliceSortedSpotData,currentSlice]=moveZoom16(c16X,c16Y,c16W,c16H,c128X,c128Y,c128W,c128H,handles)
%global findGoodIntensity
didTopSlice=0;

origSize_c=handles.dataStructure.origSize(1);
origSize_r=handles.dataStructure.origSize(2);
origSize_h=handles.dataStructure.origSize(3);
blueSlice=handles.blueSlice;
confirmedSlice=handles.confirmedSlice;
currentZ=handles.currentZ;
segments=handles.dataStructure.segments;
%goodIntensity=handles.goodIntensity;
if handles.highMemory
    currentSlice=handles.dataStructure.scaledStack(:,:,handles.currentZ);
else
    currentSlice=handles.dataStructure.scaledSlice;
end;
blueSpots=handles.blueSpots;
blueSpotRankList=handles.blueSpotRankList;
bkgd=handles.bkgd;
iCurrentSpot=handles.iCurrentSpot;

scaledValues=handles.sortedSpotData.scaledValues;
sliceSortedSpotData=handles.sliceSortedSpotData;


%fprintf('Moving zoom16\n');
[c16X,c16Y]=goToBlueSpotRank(blueSpots,iCurrentSpot,c16H,c16W);

while c16X>10000 %this means it is the next slice
    while 1%are there blueSpots in slice
        currentZ=currentZ+1;
        c16X=1;
        c16Y=1;
        if currentZ>origSize_h
            didTopSlice=1;
            break
        end;
        if handles.highMemory
            currentSlice=handles.dataStructure.scaledStack(:,:,currentZ);
        else
            [currentSlice,spotVSortedScaled]=loadAndScaleSlice(handles.dataStructure.stackInfo.stackName,handles.dataStructure.stackInfo.stackFileType,currentZ,handles);
            handles.dataStructure.scaledSlice=currentSlice;
            handles.sortedSpotData.scaledValues=spotVSortedScaled;
        end;
        %if it has gone on to the next slice becaus eit ran out of spots,
        %then make iCurrentSpot 1
        iCurrentSpot=1;
        [blueSlice, confirmedSlice,blueSpotRankList,blueSpots,bkgd,sliceSortedSpotData]=updateBlueSlice2(handles.sortedSpotData,confirmedSlice,currentZ);
        
        %[blueSpotsR,blueSpotsC]=find((blueSlice)>0);%find((blueSlice.*segments)>0);
        %blueSpots=[blueSpotsR blueSpotsC];
        
        if size(blueSpots,1)>0 %| findGoodIntensity
            %blueSpots=sortrows(blueSpots);
            %check to make sure that iCurrentSpot is not beyond the
            %blueSpotRankList
            iCurrentSpot=min(iCurrentSpot,length(blueSpotRankList));
            [c16X,c16Y]=goToBlueSpotRank(blueSpots,iCurrentSpot,c16H,c16W);
            break
        end;
    end;
end;
c16R=yToRow(c16Y);
c16C=xToCol(c16X);


function [c16X,c16Y,c128X,c128Y,blueSlice,confirmedSlice,currentZ,didTopSlice,blueSpotRankList,bkgd]=moveZoom128(c16X,c16Y,c16W,c16H,c128X,c128Y,c128R,c128C,c128W,c128H,handles)
%global findGoodIntensity
origSize_c=handles.dataStructure.origSize(1);
origSize_r=handles.dataStructure.origSize(2);
origSize_h=handles.dataStructure.origSize(3);
blueSlice=handles.blueSlice;
confirmedSlice=handles.confirmedSlice;
currentZ=handles.currentZ;
segments=handles.dataStructure.segments;
%goodIntensity=handles.goodIntensity;

if handles.highMemory
    stk=handles.dataStructure.scaledStack;
end;
blueSpots=handles.blueSpots;
currentSpot=handles.currentSpot;
blueSpotRankList=handles.blueSpotRankList;
bkgd=handles.bkgd;

didTopSlice=0;
fprintf('Moving zoom128\n');
c16R=yToRow(c16Y);
c16C=xToCol(c16X);

while 1%check to see if 128 has any embryos in it
    c128R=yToRow(c128Y);
    c128C=xToCol(c128X);
    %fprintf('16(x,y) (%d,%d)   128(x,y) (%d,%d,%d)\n',c16X,c16Y,c128X,c128Y,currentZ);
    if handles.highMemory
        currentSlice=stk(:,:,currentZ);
    else
        [currentSlice,spotVSortedScaled]=loadAndScaleSlice(handles.dataStructure.stackInfo.stackName,handles.dataStructure.stackInfo.stackFileType,currentZ,handles);        
        handles.dataStructure.scaledSlice=currentSlice;
        handles.sortedSpotData.scaledValues=spotVSortedScaled;
    end;
    
    current128Segment=segments(c128R:min(origSize_r,c128R+c128H-1),c128C:min(origSize_c,c128C+c128W-1));
    currentBlue128Segment=blueSlice(c128R:min(origSize_r,c128R+c128H-1),c128C:min(origSize_c,c128C+c128W-1));
    k=current128Segment.*currentBlue128Segment;
    if max(k(:))>0
        %center the spot
        %         [sr,sc]=find(currentBlue128Segment>0);
        %         c16X=colToX(sc(1)+c16C-1-8);
        %         c16Y=rowToY(sr(1)+c16R-1-8);
        %disp('Found maxima in blue slice 128');
        break
    else
        %advance to the right or down if at the end
        if c128X<colToX(origSize_c)-(c128W-1)
            c128X=c128X+c128W;
        else %at the end of a row of the figure
            if c128Y<rowToY(origSize_r)-(c128H-1)%if i haven't finished the y direction yet
                c128Y=c128Y+c128H;
                c128X=1;
            else %then at the end of the slice
                c128X=1;
                c128Y=1;
                currentZ=currentZ+1;
                if currentZ>origSize_h
                    %then it did all the stacks
                    didTopSlice=1;%this should jump back right after uiwait
                    break
                end;
                %                 if findGoodIntensity
                %                     break
                %end;
                if handles.highMemory
                    currentSlice=handles.dataStructure.scaledStack(:,:,currentZ);
                else
                    [currentSlice,spotVSortedScaled]=loadAndScaleSlice(handles.dataStructure.stackInfo.stackName,handles.dataStructure.stackInfo.stackFileType,currentZ,handles);
                    handles.dataStructure.scaledSlice=currentSlice;
                    handles.sortedSpotData.scaledValues=spotVSortedScaled;
                end;
                
                [blueSlice,confirmedSlice,blueSpotRankList,blueSpots,bkgd,handles.sliceSortedSpotData]=updateBlueSlice2(handles.sortedSpotData,confirmedSlice,handles.currentZ);
                %update confirmed - reset to zero, except for current blues
                %which are in confirmed of previous one.
                %this is the new blue slice times the old confirmed slice
                %note that this leaves previous spots in the blue
                %slice...they will be erased upon confirmation and until
                %then will appear black (which isn't so good)
                
            end;
        end;
    end;
    
    %also reset zoom16
    c16X=c128X;
    c16Y=c128Y;
end;%while

%%%%%%%%%%%%%%%%%%% Commented out 18Oct2011 - goToBlueSpot()
%%
% function [c16X,c16Y,newSpot]=goToBlueSpot(blueSpots,currentSpot,c16H,c16W)
% %after I have looked at each blueSpot, I delete it from blueSpots (in the
% %Next callbacks (accept/reject).  so go to next slice (i.e. newSpot=0) if
% %size(blueSpots,1)==0
% %this also necessitates removing items from blueSpots if I click on
% %zoom128 (but not adding them to rejected spots since they
% %weren't explicitly rejected
% %doesn't matter for nextSlice because blueSpots will get reset anyway
% %18Oct2011...i stopped removing from blueSpots...this is now only done in
% %the Next & buttons.  I suppose I could have it remove from new
% %spots...otherwise it will snap back.
% 
% if size(blueSpots,1)==0
%     c16X=1000000000;
%     c16Y=1000000000;
%     newSpot=0;
% else
%     %otherwise, start at 1 - this always goes back to the one i missed
%     %instead of starting from current one
%     newSpot=1;
%     c16X=colToX(max(1,blueSpots(newSpot,2)-floor(c16W/2)));
%     c16Y=rowToY(max(1,blueSpots(newSpot,1)-floor(c16H/2)));
%     newSpot=currentSpot+1;
%     
% end;
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [c16X,c16Y]=goToBlueSpotRank(blueSpots,iCurrentSpot,c16H,c16W)
%after I have looked at each blueSpot, I delete it from blueSpots (in the
%Next callbacks (accept/reject).  so go to next slice (i.e. newSpot=0) if
%size(blueSpots,1)==0
%this also necessitates removing items from blueSpots if I click on
%zoom128 (but not adding them to rejected spots since they
%weren't explicitly rejected
%doesn't matter for nextSlice because blueSpots will get reset anyway

if isempty(blueSpots) %size(blueSpots,1)
    c16X=1000000000;
    c16Y=1000000000;
else
    %otherwise, start at 1 - this always goes to the next one after the
    %current one
    
    %commented out 18Oct2011
%     if currentSpotRank<blueSpotRankList(end)
%         newSpotRank=blueSpotRankList(find(blueSpotRankList>currentSpotRank,1,'first'));
%     elseif currentSpotRank>=blueSpotRankList(end)
%         newSpotRank=blueSpotRankList(end);
%     else
%         newSpotRank=blueSpotRankList(1);
%     end;
%    newSpotRankIndex=find(blueSpotRankList==newSpotRank,1,'first');
 

    c16X=colToX(max(1,blueSpots(iCurrentSpot,2)-floor(c16W/2)));
    c16Y=rowToY(max(1,blueSpots(iCurrentSpot,1)-floor(c16H/2)));
    
end;

%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes during object creation, after setting all properties.
function rejectedNSpots_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rejectedNSpots_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in nextNothing_button.
function nextNothing_button_Callback(hObject, eventdata, handles)
% hObject    handle to nextNothing_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.lastHandles=handles;
handles=resetLastHandles(handles,handles.rollbackDepth,0);
if handles.highMemory
    handles.lastHandles.dataStructure=rmfield(handles.lastHandles.dataStructure,'scaledStack');
else
    handles.lastHandles.dataStructure=rmfield(handles.lastHandles.dataStructure,'scaledSlice');
end;
c16X=handles.currentZoom16_x;
c16Y=handles.currentZoom16_y;
c16W=handles.currentZoom16_width;
c16H=handles.currentZoom16_height;
c128X=handles.currentZoom128_x;
c128Y=handles.currentZoom128_y;
c128W=handles.currentZoom128_width;
c128H=handles.currentZoom128_height;

c16R=yToRow(c16Y);
c16C=xToCol(c16X);
c128R=yToRow(c128Y);
c128C=xToCol(c128X);

newSpots=getZoom16Spots(c16R,c16H,c16C,c16W,handles.blueSlice,handles.currentZ);

%remove from blueSpots
[handles.blueSpots,handles.blueSpotRankList,handles.iCurrentSpot]=removeZoom16SpotsFromBlueSpotsAndUpdateCurrentSpotIndex(newSpots,handles.blueSpots,handles.blueSpotRankList,handles.iCurrentSpot);


%erase from blueSlice - why erase from blueSlice? - so don't go back to it
handles.blueSlice(c16R:c16R+c16H-1,c16C:c16C+c16W-1)=zeros(c16H,c16W);



%moves the 16 square along
[c16X,c16Y,c16R,c16C,handles.blueSlice,handles.confirmedSlice,handles.currentZ,didTopSlice,handles.blueSpots,handles.iCurrentSpot,handles.blueSpotRankList,handles.bkgd,handles.sortedSpotData.scaledValues,handles.sliceSortedSpotData,handles.dataStructure.scaledSlice]=moveZoom16(c16X,c16Y,c16W,c16H,c128X,c128Y,c128W,c128H,handles);
if didTopSlice==1
    uiresume(gcbf);%this should jump back right after uiwait
end;

handles.currentZoom16_x=c16X;
handles.currentZoom16_y=c16Y;
%always try to keep zoom16 in the middle of zoom128
%but if at the edge, still do a full square
handles.currentZoom128_x=min(colToX(handles.dataStructure.origSize(2))-c128W+1,max(.5,c16X-c128W/2));
handles.currentZoom128_y=min(rowToY(handles.dataStructure.origSize(1))-c128H+1,max(.5,c16Y-c128H/2));

c16R=yToRow(c16Y);
c16C=xToCol(c16X);
c128R=yToRow(c128Y);
c128C=xToCol(c128X);

regionalMaxes16=handles.blueSlice(c16R:c16R+c16H-1,c16C:c16C+c16W-1);
handles.currentZoom16_nSpots=sum(regionalMaxes16(:)>0);
set(handles.nSpots_txt,'String',[num2str(handles.currentZoom16_nSpots) ' spots']);
set(handles.NregionalMaximaLeftInSlice_txt,'String',[num2str(size(handles.blueSpots,1)) ' regional maxima left']);
set(handles.greenBox_checkBox,'Value',1)

guidata(hObject,handles);
displayImFull(hObject,handles,1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes during object creation, after setting all properties.
function NregionalMaximaLeftInSlice_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NregionalMaximaLeftInSlice_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


%
% % --- Executes on slider movement.
% function intensityFractionSlider_Callback(hObject, eventdata, handles)
% % hObject    handle to spotRankSlider (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
%
% % Hints: get(hObject,'Value') returns position of slider
% %        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
% global intensityFraction
% intensityFraction=get(hObject,'Value');
% set(handles.spotRankReporter_txt,'String',num2str(intensityFraction));
% handles.blueSlice=modifyBlueSliceIntensityFraction(handles.dataStructure.scaledStack(:,:,handles.currentZ),handles.goodIntensity(handles.currentZ));
% [blueSpotsR,blueSpotsC]=find(handles.blueSlice>0);

%
% --- Executes during object creation, after setting all properties.
function spotRankSlider_CreateFcn(hObject, ~, handles)
% hObject    handle to spotRankSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end




% --- Executes on slider movement.
function spotRankSlider_Callback(hObject, eventdata, handles)
% hObject    handle to spotRankSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
currValue=get(hObject,'Value');
set(hObject,'Min',handles.blueSpotRankList(1));
set(hObject,'Max',handles.blueSpotRankList(end));
if currValue<=handles.blueSpotRankList(end)
    handles.iCurrentSpot=find(handles.blueSpotRankList>=currValue,1,'first');
else
    handles.iCurrentSpot=length(handles.blueSpotRankList);
end;
set(handles.spotRankReporter_txt,'String',['Spot Rank: ' num2str(handles.blueSpotRankList(handles.iCurrentSpot))]);

guidata(hObject,handles);
displayImFull(hObject,handles,1);

% --- Executes during object creation, after setting all properties.
function spotRankReporter_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to spotRankReporter_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes on button press in checkBackground.
function checkBackground_Callback(hObject, eventdata, handles)
% hObject    handle to checkBackground (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkBackground
handles.identifyingBackground=get(hObject,'Value');
guidata(hObject,handles);


% --- Executes on button press in undoLast_button.
function undoLast_button_Callback(hObject, eventdata, handles)
% hObject    handle to undoLast_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Undo last decision
if isfield(handles,'lastHandles')
    %scaledStack is really big so it isn't part of last handles...need to
    %keep it
    scaledStack=handles.dataStructure.scaledStack;
    handles=handles.lastHandles;
    handles.dataStructure.scaledStack=scaledStack;
    guidata(hObject,handles);
end;
displayImFull(hObject,handles,1);

%---function to recurse handles to reset lastHandles
function h=resetLastHandles(h,rollbackDepth, currentDepth)
%rollbackDepth is the number of rollBacks you want to allow
%currentDepth starts with 0 and goes from there

if isfield(h,'lastHandles')
    if currentDepth==rollbackDepth
        h=rmfield(h,'lastHandles');
    else
        h.lastHandles=resetLastHandles(h.lastHandles,rollbackDepth,currentDepth+1);
    end;
end;

%function to load and scale slice and SpotVs
function [slice,spotVSortedScaled]=loadAndScaleSlice(stackName,stackFileType,iSlice,handles)
disp(stackName);
disp(stackFileType);
disp(iSlice);
spotVSortedScaled=handles.sortedSpotData.scaledValues;
slice=loadSlice(stackName,stackFileType,iSlice);
mnSlice=min(slice(:));
mxSlice=max(slice(:));
rangeSlice=mxSlice-mnSlice;
slice=(slice-mnSlice)/rangeSlice;
spotVSortedScaled(find(handles.sortedSpotData.zs==iSlice))=(spotVSortedScaled(find(handles.sortedSpotData.zs==iSlice))-mnSlice)/rangeSlice;

% --- Executes during object creation, after setting all properties.
function scdValue_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scdValue_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function iWormiSpot_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to iWormiSpot_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

%%%%%%%%%%%%%%%%%%%%%%%%%%
function [blueSpots,blueSpotRankList,iCurrentSpot]=removeZoom16SpotsFromBlueSpotsAndUpdateCurrentSpotIndex(newSpots,blueSpots,blueSpotRankList,iCurrentSpot)
%The Next & functions call this to remove the spots in zoom16 from the
%blueSpotlists and to update iCurrentSpot if need be
%remove from blueSpots
if size(newSpots,1)>0 && size(blueSpots,1)>0
    [~,~,blueSpotsToDelete]=intersect(newSpots(:,1:2),blueSpots,'rows');
    blueSpots(blueSpotsToDelete,:)=[];
    blueSpotRankList(blueSpotsToDelete)=[];
    %handles.blueSpotRankList(blueSpotsToDelete(blueSpotsToDelete<=length(handles.blueSpotRankList)))=[];%this is just so that it doesn't return to it later, right?
end;
%%%However, now that the spot is deleted, handles.iCurrentSpot no longer
%%%points to that particular blueSpot.  it now points to the next one (or a
%%%few later) by default.  this is only a problem if it now points to
%%%something longer than the list.  so take care of that
iCurrentSpot=min(max(iCurrentSpot,1),length(blueSpotRankList));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function newSpots=getZoom16Spots(c16R,c16H,c16C,c16W,blueSlice,currentZ)
%This function takes a zoom16 portion of the blueSlice and gets the rows
%and columns of the spots in it
[spotR,spotC]=find(blueSlice(c16R:c16R+c16H-1,c16C:c16C+c16W-1)>0);
%need to add z information
newSpots=[];
for i=1:size(spotR)
    newSpots=[newSpots; [spotR(i)+c16R-1, spotC(i)+c16C-1, currentZ]];
end;

%%%%%%%%%%%%%%%%%%%%%%%
%% Notes
%9/19/11
%I wanted to display the value of the statistic used as cutoff and also the worm and spot location
%This entailed extracting this info and keeping it (or could just carry worm through the whole thing...but that gets complicated
%Also if someone clicks on a square that isn't a local maximum (and thus
%not in the wormGaussianFit file, then this probably causes all sorts of
%problems because statistics aren't calculated for it.  need to calculate
%these statistics and add them to the wormGaussianFit file if need be
%10/17/11
%in zoom16_ButtonDownFcn when I rejected a spot I was not updating
%currentSpotRank or BlueSpotRankList.  This caused a non-crashing error
%because the blueSpotRankList size got out of sync with blueSpots...this is
%now fixed.


% --- Executes on button press in greenBox_checkBox.
function greenBox_checkBox_Callback(hObject, eventdata, handles)
% hObject    handle to greenBox_checkBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of greenBox_checkBox
guidata(hObject,handles);
displayImFull(hObject,handles,1);
