function spotStatsFound=spotMapAndStats(spotStats,stack,mask,varargin)
%% ========================================================================
%   Name: spotMapAndStats
%   Version: 1.0 30th Apr. 2013
%   Author: Allison Wu
%   Command:
%   spotStatsFound=spotMapAndStats(spotStats,stack,mask,isSegmented*)
%   *Optional Input
%
%   Description: 
%       - Calculate spot statistics with a mask applied to the
%         orignal image analyzed.
%       - Segment the original image with input mask. (default) If it's
%       already segmented, it will just calculate the spot stats.

%
%   Input required:
%       - spotStats: the spotStats of the individual cell to be analyzed.
%       - stack: the original image stack (m-by-n-by-z)    
%       - mask: the mask for the individual cell (m-by-n-by-1)
%       - isSegmented*: optional input specificying whether this image is
%       already segmented.
%
%   Output generated:
%       - Most of the fields of spotStatsFound mean the same as their
%       counterpart in spotStats, except that the statsitics is for this
%       particular cell.
%       - spotStatsFound.mask: saves the cropped mask.
%       - spotStats.Found.stack: saves the segmented image stack.
%       - spotStats.gSpotMapStack: a 3D double matrix (same size as the
%       segmented image stack) with only 1 and 0 which specifies the
%       location of each good spot. 
%       - spotStats.gSpotMapStack: a 3D double matrix (same size as the
%       segmented image stack) with only 1 and 0 which specifies the
%       location of each bad spot.
%% ========================================================================

if isempty(varargin)
    isSegmented=0;
else
    isSegmented=varargin{1};
end

[m n h]=size(stack);

locAndClass=spotStats.locAndClass;
gSpotMapStack=zeros(size(stack));
bSpotMapStack=zeros(size(stack));
spotIndexMap=zeros(size(stack));
for k=1:length(locAndClass)
    loc=locAndClass(k,:);
    if loc(4)==1
        gSpotMapStack(loc(1),loc(2),loc(3))=1; % good spots
    else
        bSpotMapStack(loc(1),loc(2),loc(3))=1;% bad spots
    end
    spotIndexMap(loc(1),loc(2),loc(3))=k;
end

if ~isSegmented
    bb=regionprops(double(mask),'BoundingBox');
    mask=imcrop(mask,bb.BoundingBox);
    stackMasked=zeros([size(mask),h]);
    gSpotMapStackMasked=zeros([size(mask),h]);
    bSpotMapStackMasked=zeros([size(mask),h]);
    spotIndexMapMasked=zeros([size(mask),h]);
    for j=1:h
        stackMasked(:,:,j)=double(imcrop(stack(:,:,j),bb.BoundingBox)).*mask;
        gSpotMapStackMasked(:,:,j)=double(imcrop(gSpotMapStack(:,:,j),bb.BoundingBox)).*mask;
        bSpotMapStackMasked(:,:,j)=double(imcrop(bSpotMapStack(:,:,j),bb.BoundingBox)).*mask;
        spotIndexMapMasked(:,:,j)=double(imcrop(spotIndexMap(:,:,j),bb.BoundingBox)).*mask;
    end
    
end

stack=stackMasked;
gSpotMapStack=gSpotMapStackMasked;
bSpotMapStack=bSpotMapStackMasked;
spotIndexMap=spotIndexMapMasked;
clear stackMasked spotMapStackMasked spotIndexMapMasked gSpotMapStackMasked bSpotMapStackMasked
% Find out how many spots are in this masked image.
spotIndex=spotIndexMap(:);
spotIndex=spotIndex(spotIndex~=0);

IQR=spotStats.IQR(spotIndex);
Probs=spotStats.ProbEstimates(spotIndex);
unreliableSpots=Probs(IQR>0.3);
unreliableGoodSpots=unreliableSpots(unreliableSpots>0.5);
unreliableBadSpots=unreliableSpots(unreliableSpots<0.5);
randG=binornd(1,repmat(unreliableGoodSpots,1,1000),length(unreliableGoodSpots),1000);
randB=binornd(1,repmat(unreliableBadSpots,1,1000),length(unreliableBadSpots),1000);
g2b=prctile(sum(~randG),100-spotStats.quantile);
b2g=prctile(sum(randB), spotStats.quantile);
ub=sum(Probs>0.5)+b2g;
lb=sum(Probs>0.5)-g2b;


spotStatsFound.spotTreeProbs=spotStats.spotTreeProbs(spotIndex,:);
spotStatsFound.UnreliablePortion=mean(IQR>0.3);
spotStatsFound.ProbEstimates=Probs;
spotStatsFound.IQR=IQR;
spotStatsFound.locAndClass=spotStats.locAndClass(spotIndex,:);
spotStatsFound.SpotNumEstimate=sum(spotStatsFound.locAndClass(:,4));
spotStatsFound.SpotNumRange=[lb ub];
spotStatsFound.trainingSetName=spotStats.trainingSetName;
spotStatsFound.mask=mask;   % Cropped mask
spotStatsFound.stack=stack; % Cropped image stack
spotStatsFound.gSpotMapStack=gSpotMapStack; % good spot map
spotStatsFound.bSpotMapStack=bSpotMapStack; % good spot map

visualizeSpotMap(gSpotMapStack,bSpotMapStack,stack);

end