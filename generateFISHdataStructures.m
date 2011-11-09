%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%  Name: generateFISHdataStructures%nameMod
%  Version: 1.4.2, 9 Nov 2011   %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%
%  License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%  Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu 
%  =============================================================
%a script to extract the data from CSV files generated in the analysis.
%Returns a structure with the data for this directory

dyes={'cy','alexa','tmr'};

if ~isempty(dir('FISHdata*'))
    disp('Deleting previous FISHdata files');
    delete('FISHdata*');
end;
disp('Doing dapi');
fd=extractFISHdataFromCSVs_1p4p2('dapi');
for j=1:3
    if ~isempty(dir([dyes{j} '*wormGaussianFit.mat']))
        disp(['Doing ' dyes{j}]);
        fd=extractFISHdataFromCSVs_1p4p2(dyes{j});
    end;
end;
plotFISHdata_1p4p2(fd);

