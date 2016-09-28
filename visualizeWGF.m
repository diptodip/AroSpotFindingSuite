function visualizeWGF(worms,wi)
%% ========================================================================
%   Name:       visualizeWGF.m
%   Version:    2.5.1 1 Nov 2014
%   Author:     Scott Rifkin
%   Command:    visualizeTrainingSet(trainingSet)
%   Description:
%       - Makes a plot that depicts the local maxima in a wormGaussianFit file
%
%   Files required:     WGF
%
%   Files generated:    none
%   Output:             A plot
%
%% ========================================================================

% Notes: the plot should a grid that looks like the
% reviewFISHClassification.  Take the 7x7 square from
% worms{wi}.spotDataVectors.dataMat



allDat=imscale(worms{wi}.spotDataVectors.dataMat);

% make a grid matrix.
allColor=[.1,.1,.5];

nTotal=size(allDat,1);

widthInSpots=40;
heightInSpots=ceil(nTotal/widthInSpots);
spotSize=size(allDat);
spotSize=spotSize(2:3);
gridVStep=spotSize(1)+1;
gridHStep=spotSize(2)+1;
grid=zeros(heightInSpots*gridVStep+1,widthInSpots*gridHStep+1);

for i=1:widthInSpots
    for j=0:heightInSpots-1
        iSpot=i+widthInSpots*j;
        if iSpot<=nTotal
            grid(1+1+j*gridVStep:(j+1)*gridVStep,1+1+(i-1)*gridHStep:i*gridHStep)=squeeze(allDat(iSpot,:,:));
        end;
    end;
end;
imshow(grid);
for i=1:widthInSpots
    for j=0:heightInSpots-1
        iSpot=i+widthInSpots*j;
        if iSpot<=nTotal
            boxPosition=[colToX(1+(i-1)*gridHStep)+.5,rowToY(1+j*gridVStep)+.5, gridHStep, gridVStep];
            rectangle('Position',boxPosition,'EdgeColor',allColor);
        end;
    end;
end;

end



