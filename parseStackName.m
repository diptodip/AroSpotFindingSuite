function [dye, stackSuffix, stackFileType, wormGaussianFitName, segmentsName,metaInfoName]=parseStackName(stackName)
%  =============================================================
%  Name: parseStackName.m   %nameMod
%  Version: 1.0, 9 Nov 2011   %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%  License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%  Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%  =============================================================
%a stackName is passed in (e.g. tmr001.stk, tmr_Pos0.tiff) and this
%function parses it and passes back the info
%useful to have this information all in this function because it is used so
%much

stackPrefix=regexp(stackName,'\.','split');
stackFileType=stackPrefix{2};
stackPrefix=stackPrefix{1};
if strcmp(stackFileType,'stk')
    stackSuffix=collectDigits(stackName,1);
    dye=regexp(stackName,stackSuffix,'split');
    dye=dye{1};
    segmentsName=['segmenttrans' stackSuffix '.mat'];
    wormGaussianFitName = [dye stackSuffix '_wormGaussianFit.mat'];
    metaInfoName=[dye stackSuffix '_metaInfo.mat'];
elseif strcmp(stackFileType,'tif') || strcmp(stackFileType,'tiff')
    stackSuffix=regexp(stackPrefix,'_','split');
    dye=stackSuffix{1};
    stackSuffix=stackSuffix{end};
    segmentsName=['segmenttrans' '_' stackSuffix '.mat'];
    wormGaussianFitName = [dye stackSuffix '_wormGaussianFit.mat'];
    metaInfoName=[dye '_' stackSuffix '_metaInfo.mat'];
end;
end