function [worms,wormsChanged]=addNewSpotToWorm(loc,wormNumber,worms)
%  =============================================================
%  Name: addNewSpotToWorm.m   %nameMod
%  Version: 1.4.2, 9 Nov 2011   %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%
%   Attribution: Wu, AC-Y and SA Rifkin. spotFinding Suite version 2.5, 2013 [journal citation TBA]
%   License: Creative Commons Attribution-ShareAlike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%   Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%   Email for comments, questions, bugs, requests:  Allison Wu < dblue0406 at gmail dot com >, Scott Rifkin < sarifkin at ucsd dot edu >
%
%  =============================================================

%Function to add a spot to the spotInfo file in a wormGaussianFit file
%(worms data structure)
%This is called when a trainingSet needs to be updated with spots (rejected
%ones if the program is working correctly) that were local maxima that
%weren't included in new evaluateFISH spot function
%Also should be called if user adds a new spot to the training set in the
%identifySpots GUI that isn't a local maximum.  This should be exceedingly
%unlikely but at least an error won't be thrown.

%Figure out how big the dataMat is so can identify the center and find the
%data column

oldWorms=worms;
disp('loc and wormNumber');
disp(loc);
disp(wormNumber);
dataMatSize=size(worms{wormNumber}.spotInfo{1}.dataMat);
centerR=ceil(dataMatSize(1)/2);
centerC=ceil(dataMatSize(2)/2);

NR=loc(1)-centerR+1;
SR=loc(1)-centerR+dataMatSize(1);
WC=loc(2)-centerC+1;
EC=loc(2)-centerC+dataMatSize(2);

%need to load the stack to get the pixels
if strcmp(worms{wormNumber}.stackFileType,'stk')
    stack=readmm(worms{wormNumber}.stackName);
    stack=double(stack.imagedata);
elseif strcmp(worms{wormNumber}.stackFileType,'tiff') || strcmp(worms{wormNumber}.stackFileType,'tif')
    stackFileType='tiff';
    stack=readTiffStack(worms{wormNumber}.stackName,worms{wormNumber}.numberOfPlanes);
else
    disp('File type not supported');
end;

%Stack is in.  Now extract the data column
dataColumn=stack(NR:SR,WC:EC,:);
%Get statistics
tgs=calculateFISHStatistics(dataColumn,centerR,centerR,loc(3),worms{wormNumber}.quickAndDirtyStats,worms{wormNumber}.bleachFactors);

%As of v. 1p4p1 (10/5/11), this is the info in spotInfo
% worms{1}.spotInfo{1}
% ans =
%         locations: [1x1 struct]
%          rawValue: 1.2370e+03
%     filteredValue: 84.4335
%          spotRank: 1
%           dataMat: [7x7 double]
%         directory: {1x8 cell}
%               dye: 'cy'
%       stackSuffix: '001'
%         stackName: 'cy001.stk'
%        wormNumber: 1
%              stat: [1x1 struct]

newIndex=size(worms{wormNumber}.spotInfo,2)+1;
worms{wormNumber}.spotInfo{newIndex}.locations.stack=loc;
worms{wormNumber}.spotInfo{newIndex}.locations.worm=[loc(1)-floor(worms{wormNumber}.boundingBox.BoundingBox(2)) loc(2)-floor(worms{wormNumber}.boundingBox.BoundingBox(1)) loc(3)];
worms{wormNumber}.spotInfo{newIndex}.rawValue=stack(loc(1),loc(2),loc(3));

%to find its rank, go through regmax spots
worms{wormNumber}.spotInfo{newIndex}.filteredValue=[];
worms{wormNumber}.spotInfo{newIndex}.spotRank=[];
for regi=1:size(worms{wormNumber}.regMaxSpots,1)
    if isequal(loc,worms{wormNumber}.regMaxSpots(regi,1:3))
        worms{wormNumber}.spotInfo{newIndex}.filteredValue=worms{wormNumber}.regMaxSpots(regi,5);
        worms{wormNumber}.spotInfo{newIndex}.spotRank=regi;
        break
    end;
end;
if isempty(worms{wormNumber}.spotInfo{newIndex}.filteredValue)
    %then don't add this one.
    worms=oldWorms;
    wormsChanged=0;
else
    worms{wormNumber}.spotInfo{newIndex}.dataMat=dataColumn(:,:,loc(3));
    worms{wormNumber}.spotInfo{newIndex}.directory=worms{wormNumber}.spotInfo{1}.directory;
    worms{wormNumber}.spotInfo{newIndex}.dye=worms{wormNumber}.spotInfo{1}.dye;
    worms{wormNumber}.spotInfo{newIndex}.wormNumber=wormNumber;
    worms{wormNumber}.spotInfo{newIndex}.stackSuffix=worms{wormNumber}.spotInfo{1}.stackSuffix;
    worms{wormNumber}.spotInfo{newIndex}.stackName=worms{wormNumber}.spotInfo{1}.stackName;
    worms{wormNumber}.spotInfo{newIndex}.stat=tgs;
    wormsChanged=1;
end;
end
