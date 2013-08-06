function stack=loadStack(stackName,stackFileType,nPlanes)
%  =============================================================
%  Name: loadStack.m   %nameMod
%  Version: 1.0, 9 Nov 2011   %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  =============================================================
%loads the given slice from either a stk or .tiff file

if strcmp(stackFileType,'stk')
    stack=readmm(stackName);
    stack=double(stack.imagedata);
elseif strcmp(stackFileType,'tiff')
    stack=readTiffStack(stackName,nPlanes);
end;
end