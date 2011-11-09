function [stack,bleachFactors]=correctForBleach(im,mask)
%  =============================================================
%  Name: correctForBleach.m   %nameMod
%  Version: 1.0, 9 Nov 2011   %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%  License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%  Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%  =============================================================
%This is a utility function to adjust for bleaching as the scope goes up a z-stack
%Divides by the median in order to correct for bleaching...not perfect but
%should help wth the randomForesting
%Decent slice should be in the middle of the stack

stack=zeros(size(im));
bleachFactors=zeros(1,size(im,3));
%% Slice as reference
iRefSlice=floor(size(im,3)/2);
medRefSlice=findMedianOfNonMaskedPartOfSlice(im(:,:,iRefSlice),mask);

%% Find the actual pixels
for zi=1:size(im,3)
    medSlice=findMedianOfNonMaskedPartOfSlice(im(:,:,zi),mask);
    bleachFactors(zi)=medSlice/medRefSlice;
    stack(:,:,zi)=im(:,:,zi)/bleachFactors(zi);
end;
end