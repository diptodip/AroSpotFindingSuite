function stack=loadStack(stackName,stackFileType,nPlanes)
%  =============================================================
%  Name: loadStack.m   %nameMod
%  Version: 1.0, 9 Nov 2011   %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%  License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%  Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%  =============================================================
%loads the given slice from either a stk or .tiff file

if strcmp(stackFileType,'stk')
    stack=readmm(stackName);
    stack=double(stack.imagedata);
elseif strcmp(stackFileType,'tiff')
    stack=readTiffStack(stackName,nPlanes);
end;
end