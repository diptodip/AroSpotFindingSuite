function [im] = imscale(im1,varargin)
%  =============================================================
%  Name: imscale.m   %nameMod
%  Version: 1.0, 9 Nov 2011   %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%  License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%  Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%  =============================================================
%This is a utility function to scale an image
%varargin is percentile...if it is present, then scale not to max but to
%percentile
mnIM=min(im1(im1(:)>0));
mxIM=max(im1(im1(:)>0));
if size(varargin,2)>0
    mxIM=prctile(im1(im1(:)>0),varargin{1});
end
rangeIM=mxIM-mnIM;
im=im1;
im(im>0)=(im(im>0)-mnIM)/rangeIM;
end