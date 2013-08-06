function varargout=morphFilterSpotImage3D(im,mask)
%  =============================================================
%  Name: morphFilterSpotImage3D.m
%  Version: 1.2, 19 April 2011
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%
%   Attribution: Wu, AC-Y and SA Rifkin. spotFinding Suite version 2.5, 2013 [journal citation TBA]
%   License: Creative Commons Attribution-ShareAlike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%   Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%   Email for comments, questions, bugs, requests:  Allison Wu < dblue0406 at gmail dot com >, Scott Rifkin < sarifkin at ucsd dot edu >
%
%  =============================================================
% This function is at the heart of the regional maxima ranking.  It finds
% regional maxima in 3D, then goes slice by slice and morphologically opens
% to get a local background and then subtracts this from the original image
% and then ranks the regional maxima by their background corrected
% intensities

%if im is a slice it just does that
%if im is a stack, it does each slice
%imopen image with disk structuring element of radius 7
%subtract this imopened image from the raw image

%varargout is [spotRSorted,spotCSorted,spotVSorted,morphOpenSpotV] for a slice
%varargout is [spotRSorted,spotCSorted,spotZSorted,spotVSorted,morphOpenSpotV] for a stack



sz=size(im);
se=strel('disk',7);

if length(sz)==2
    im3=zeros(sz(1),sz(2),1);
    im3(:,:,1)=im;
else
    im3=im;
end;
clear('im');

%19April2011 added laplace filter of image to gaussianScan2 so doing it
%here would be redundant
%newFISHfilter;
%im3=laplaceFISH(im3,4);

spotRSorted=[];
spotCSorted=[];
spotVSorted=[];
spotVFiltSorted=[];

%imFilt=zeros(size(im3));
spotZSorted=[];
% for zi=1:size(im3,3)
% %     if length(sz)==3
% %         disp(['Processing slice ' num2str(zi)]);
% %     end;
%     %im may be passed in masked, but just in case
%     im3(:,:,zi)=im3(:,:,zi).*mask;
%     
% end;
%disp('Finding regional maxima in 3D');
%tic
regMax=imregionalmax(im3);
%save('regmax','regMax');
%toc
%disp(size(im3));
%disp(size(regMax));
%disp('regmaxcalculated');
for zi=1:size(regMax,3)
   %tic 
    [allSpotR,allSpotC,allSpotV]=find(regMax(:,:,zi).*im3(:,:,zi).*mask);%added masking here rather than above so that don't have edge effects
    %fprintf('%d regional maxima in slice %d\n',length(allSpotR),zi);
    allSpotVFilt=zeros(size(allSpotV));
    imFilt=(im3(:,:,zi)-imopen(im3(:,:,zi),se)).*(~bwperim(mask));
    %sort by value of regional maxima in flitered image
    for si=1:length(allSpotR)
        allSpotVFilt(si)=imFilt(allSpotR(si),allSpotC(si));
    end;
    [morphOpenSpotV,VsortIndexFilt]=sort(allSpotVFilt,'descend');
    spotRSorted=[spotRSorted;allSpotR(VsortIndexFilt)];
    spotCSorted=[spotCSorted;allSpotC(VsortIndexFilt)];
    spotVSorted=[spotVSorted;allSpotV(VsortIndexFilt)];%original value sorted by filtered order
    spotZSorted=[spotZSorted;zi*ones(size(allSpotV))];
    spotVFiltSorted=[spotVFiltSorted;morphOpenSpotV];% new value sorted by filtered order
    %toc
end;

if length(sz)==2
    varargout={spotRSorted,spotCSorted,spotVSorted,spotVFiltSorted};
else
    varargout={spotRSorted,spotCSorted,spotZSorted,spotVSorted,spotVFiltSorted};
end;
end
