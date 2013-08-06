function slice=loadSlice(stackName,stackFileType,iSlice)
%  =============================================================
%  Name: loadSlice.m   %nameMod
%  Version: 1.0, 9 Nov 2011   %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  =============================================================
%loads the given slice from either a stk or .tiff file

if strcmp(stackFileType,'stk')
    slice=readmm(stackName,iSlice:iSlice);
    slice=double(slice.imagedata);
elseif strcmp(stackFileType,'tiff')
    slice=readTiffStack(stackName,iSlice,iSlice);
end;
end