    function m=findMedianOfNonMaskedPartOfSlice(slice,mask)
%  =============================================================
%  Name: findMedianOfNonMaskedPartOfSlice.m   %nameMod
%  Version: 1.0, 9 Nov 2011   %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%  License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%  Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%  =============================================================
%A utility function for finding the median of a part of a slice
    slice=slice.*mask;
    slice=slice(:);
    slice=slice(slice>0);
    m=median(slice);
    end