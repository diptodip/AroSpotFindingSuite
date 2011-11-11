function stack=readTiffStack(filename,nPlanes,varargin)
%  =============================================================
%  Name: readTiffStack.m
%  Version: 1.0, 9 Nov 2011
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%  License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%  Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%  =============================================================
%a wrapper for tiffread.m from Francois Nedelec
if nargin>2
    startPlane=nPlanes;
    endPlane=varargin{1};
else
    startPlane=1;
    endPlane=nPlanes;
end;

stackData=tiffread(filename,startPlace,endPlane);

stack=double(zeros([size(stackData(1).data) size(stackData,2)]));
for si=1:size(stackData,2)
    stack(:,:,si)=double(stackData(si).data);
end;
end