    function m=findMedianOfNonMaskedPartOfSlice(slice,mask)
%  =============================================================
%  Name: findMedianOfNonMaskedPartOfSlice.m   %nameMod
%  Version: 1.0, 9 Nov 2011   %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  =============================================================
%A utility function for finding the median of a part of a slice
    slice=slice.*mask;
    slice=slice(:);
    slice=slice(slice>0);
    m=median(slice);
    end