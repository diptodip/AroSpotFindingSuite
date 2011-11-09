function newLocation = translateToNewCoordinates(oldLocation,subImagePosition,direction)
%  =============================================================
%  Name: translateToNewCoordinates.m
%  Version: 1.0, 24 March 2010
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%  License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%  Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu 
%  =============================================================
%takes a location in a larger image and makes new location relative to
%subImage position  note that subImagePosition will come in as a position
%vector so it is in x y coordinates.  so oldLocation and newLocation should
%and will be also in x y coordinates
%direction is either LtoS or StoL (large, small)

if strcmp(direction,'LtoS')
    new_p5X = subImagePosition(1);
    new_p5Y = subImagePosition(2);
    newLocation=[oldLocation(1)-new_p5X+1,oldLocation(2)-new_p5Y+1];
else
    old_p5X=subImagePosition(1);
    old_p5Y=subImagePosition(2);
    %newLocation=[oldLocation(1)+old_p5X-1, oldLocation(2)+old_p5Y-1];
    newLocation=[oldLocation(1)+old_p5X, oldLocation(2)+old_p5Y];%1 May...changed because the above seems to be too small by one
    
end