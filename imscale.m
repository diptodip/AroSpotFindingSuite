function [im] = imscale(im1,varargin)
%  =============================================================
%  Name: imscale.m   %nameMod
%  Version: 2.0, 17th July 2012   %nameMod
%  Author: Allison Wu, Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  Command:  [im] = imscale(im1,prtile*,excludeZeros*)
%  Description:scale the images
%       
%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%  License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%  Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%  =============================================================
%This is a utility function to scale an image
%varargin is percentile...if it is present, then scale not to max but to
%percentile

switch length(varargin)
    case 1 
        percentile=varargin{1};
        excludeZeros=1;
    case 2
        percentile=varargin{1};
        excludeZeros=varargin{2};
    otherwise
        percentile=100;
        excludeZeros=1;
end

if excludeZeros==1
    mnIM=min(im1(im1(:)>0));
    mxIM=prctile(im1(im1(:)>0),percentile);
else
    mnIM=min(im1(:));
    mxIM=prctile(im1(:),percentile);
end
rangeIM=mxIM-mnIM;
im=im1;
im(im>0)=(im(im>0)-mnIM)/rangeIM;

end