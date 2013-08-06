function dataLine=makeDataLine(spotValues,statsToUse)
%  =============================================================
%  Name: makeDataLine.m   %nameMod
%  Version: 1.0, 9 Nov 2011   %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%
%   Attribution: Wu, AC-Y and SA Rifkin. spotFinding Suite version 2.5, 2013 [journal citation TBA]
%   License: Creative Commons Attribution-ShareAlike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%   Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%   Email for comments, questions, bugs, requests:  Allison Wu < dblue0406 at gmail dot com >, Scott Rifkin < sarifkin at ucsd dot edu >
%
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
