function dataLine=makeDataLine(spotValues,statsToUse)
%  =============================================================
%  Name: makeDataLine.m   %nameMod
%  Version: 1.0, 9 Nov 2011   %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%  License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%  Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%  =============================================================
%goes through a statsValue field and extracts the stats to Use.
%returns [] of there are NaNs

dataLine=zeros(1,length(statsToUse));
for dli=1:length(statsToUse)
    if isfield(spotValues,statsToUse{dli})
        dataLine(dli)= spotValues.(statsToUse{dli});
        if (isnan(dataLine(dli)) || dataLine(dli)>2000000) 
            dataLine=[];
        break
        end;
    else
        dataLine=[];
        break
    end;
end;
end
