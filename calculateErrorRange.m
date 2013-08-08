function [g2b b2g]=calculateErrorRange(Probs, IQR, IQRt,quantile)
%% =============================================================
%   Name:       calculateErrorRange.m
%   Version:    2.5.1, 25th Apr. 2013
%   Author:     Allison Wu
%   Command:    calculateErrorRange(Probs, IQR, IQRt,quantile)
%   Description:
%       - bootstrap the spot numbers based on reliable (concordant) and unreliable (discordant) spots
%
%   Attribution: Wu, AC-Y and SA Rifkin. spotFinding Suite version 2.5, 2013 [journal citation TBA]
%   License: Creative Commons Attribution-ShareAlike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%   Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%   Email for comments, questions, bugs, requests:  Allison Wu < dblue0406 at gmail dot com >, Scott Rifkin < sarifkin at ucsd dot edu >
%
%% ========================================================================
unreliableSpots=Probs(IQR>IQRt);
unreliableGoodSpots=unreliableSpots(unreliableSpots>0.5);
unreliableBadSpots=unreliableSpots(unreliableSpots<0.5);
if ~isempty(unreliableGoodSpots)
    randG=binornd(1,repmat(unreliableGoodSpots,1,1000),length(unreliableGoodSpots),1000);
    g2b=prctile(sum(~randG),100-quantile);
else
    g2b=0;
end

if ~isempty(unreliableBadSpots)
    randB=binornd(1,repmat(unreliableBadSpots,1,1000),length(unreliableBadSpots),1000);
    b2g=prctile(sum(randB), quantile);
else 
    b2g=0;
end
end