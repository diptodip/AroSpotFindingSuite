function [spotIntensities,wormNumbers,spotInfoNumbersInWorms]=findSpotInfoInWormBasedOnLocation(listOfLocations,worms,currpolys)
%  =============================================================
%  Name: findSpotInfoInWormBasedOnLocation.m   %nameMod
%  Version: 1.0, 9 Nov 2011   %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%
%   Attribution: Wu, AC-Y and SA Rifkin. spotFinding Suite version 2.5, 2013 [journal citation TBA]
%   License: Creative Commons Attribution-ShareAlike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%   Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%   Email for comments, questions, bugs, requests:  Allison Wu < dblue0406 at gmail dot com >, Scott Rifkin < sarifkin at ucsd dot edu >
%
%  =============================================================
%This function takes a list of locations from goldSpots/rejectedSpots
%(actually they will be an n x 4 array since the intensity is also part of
%it) and finds the wormNumber and the spotInfoNumbersInWorms that
%correspond


nSpots=size(listOfLocations,1);
wormNumbers=zeros(nSpots,1);
spotInfoNumbersInWorms=zeros(nSpots,1);
spotIntensities=zeros(nSpots,1);

%This makes a list of all the spotInfoIndices for a worm.  The only reason
%to do this is that when there is a match, that index can be eliminated and
%it saves a little time
for wi=1:size(worms,2)
    spotInfosToTest{wi}=1:(size(worms{wi}.spotInfo,2));
end;

for si=1:nSpots
    spotFound=0;
    %first search the currpolys
    for ci=1:size(currpolys,2)
        if currpolys{ci}(listOfLocations(si,1),listOfLocations(si,2))==1
            wormNumbers(si)=ci;
            %Now search the worms
            for siwi=1:length(spotInfosToTest{ci})
                if isequal(listOfLocations(si,1:3),worms{ci}.spotInfo{spotInfosToTest{ci}(siwi)}.locations.stack)
                    spotInfoNumbersInWorms(si)=spotInfosToTest{ci}(siwi);
                    spotIntensities(si)=worms{ci}.spotInfo{spotInfosToTest{ci}(siwi)}.rawValue;
                    spotFound=1;
                    break
                end;
                if spotFound
                    spotInfosToTest{ci}(siwi)=[];
                end;
            end;
            break
        end;
    end;
    if ~spotFound
        fprintf('Spot %d not found, location %d %d %d\n',si,listOfLocations(si,1),listOfLocations(si,2),listOfLocations(si,3));
    end;
end;

end

