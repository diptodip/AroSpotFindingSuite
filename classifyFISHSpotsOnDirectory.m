function classifyFISHSpotsOnDirectory(dye,probeName,varargin)%,parFlag)
%  =============================================================
%  Name: classifyFISHSpotsOnDirectory.m   %nameMod
%  Version: 1.4, 21 July 2011   %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%  License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%  Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%  =============================================================
%This is a utility function to go through a directory and call classifyFISHSpots on all the relevant files for the given dye and probeName


if nargin~=3
    wGFs=dir([dye '*Gaussian*']);
else
    wGFs=varargin{1};
end;
% % if parFlag
% % 
% if ~matlabpool('size')
%     matlabpool open 6
% end;
% 
% disp('Matlabpool started');

%parfor i=1:length(wGFs)
for i=1:length(wGFs)
	nm=collectDigits(wGFs(i).name);
	stackSuffix=nm{1};
	classifyFISHSpots(dye,stackSuffix,probeName);
end;
end