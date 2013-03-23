function [dye, stackSuffix, wormGaussianFitName, segStacksName,spotStatsFileName]=parseStackNames(stackName)
%%  =============================================================
%  Name: parseStackNames.m   %nameMod
%  Version: 2.0, 4th July 2012
%  Author: Allison Wu, Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  Command: [dye, stackSuffix, wormGaussianFitName, segStacksName,spotStatsFileName]=parseStackNames(stackName)
%  Description: 
%       - Take in a stackName or {dye}_{stackSuffix} , e.g. tmr001.stk, tmr_Pos0.tiff or tmr_Pos0
%       - generate the segStack, wormGaussianFitNames
%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%  License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%  Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%%  =============================================================

stackName=regexprep(stackName,'_','\.');
stackPrefix=regexp(stackName,'\.','split');
stackPrefix=stackPrefix(~cellfun('isempty', stackPrefix));
if sum(strcmp('stk',stackPrefix))~=0
    stackSuffix=cell2mat(regexp(stackPrefix{1},'\d+','match'));
    dye=regexprep(stackPrefix{1},stackSuffix,'');
else
    dye=stackPrefix{1};
    stackSuffix=stackPrefix{2};
end

segStacksName=[dye '_' stackSuffix '_SegStacks.mat'];
wormGaussianFitName = [dye '_' stackSuffix '_wormGaussianFit.mat'];
spotStatsFileName=[dye '_Pos' num2str(str2num(cell2mat(regexp(stackSuffix,'\d+','match')))) '_spotStats.mat'];

end