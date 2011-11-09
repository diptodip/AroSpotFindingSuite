function stack=readTiffStack(filename,nPlanes,varargin)
%  =============================================================
%  Name: readTiffStack.m   %nameMod
%  Version: 1.0, 9 Nov 2011   %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%  License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%  Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%  =============================================================
%reads tiff stack.  if just two arguments, then 2nd one is the number of
%planes
%if 3 arguments, then the 2nd is the start plane and the 3rd is the end
%plane

if nargin>2
    startPlane=nPlanes;
    endPlane=varargin{1};
else
    startPlane=1;
    endPlane=nPlanes;
end;
stack0=double(imread(filename,startPlane));
stack=zeros(size(stack0,1),size(stack0,2),endPlane-startPlane+1);
stack(:,:,1)=stack0;
for i=startPlane+1:endPlane
    %if there is any problem reading a slice, stop and just return the tiff stack up
    %until that slice.
    try
        stack(:,:,i-startPlane+1)=imread(filename,i);
    catch err 
        break
    end;
end;
end