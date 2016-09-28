function visualizeTrainingSet(trainingSet)
%% ========================================================================
%   Name:       visualizeTrainingSet.m
%   Version:    2.5.1 1 Nov 2014
%   Author:     Scott Rifkin
%   Command:    visualizeTrainingSet(trainingSet)
%   Description:
%       - Makes a plot that depicts a training set
%
%   Files required:     trainingSet*.mat file
%
%   Files generated:    none
%   Output:             A plot
%
%% ========================================================================

% Notes: the plot should a grid that looks like the
% reviewFISHClassification.  Take the 7x7 square from
% trainingSet.stats.dataMat
% and the classification from trainingSet.spotInfo(:,4)

iGoods=vert(find(trainingSet.spotInfo(:,4)==1));
iBads=vert(find(trainingSet.spotInfo(:,4)==0));

allDat=imscale(trainingSet.stats.dataMat([iGoods; iBads],:,:));

% make a grid matrix.
goodColor=[.1,.1,.5];
badColor=[.5,.5,.1];

nGood=length(iGoods);
nBad=length(iBads);
nTotal=nGood+nBad;

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
            if iSpot<=nGood
                rectangle('Position',boxPosition,'EdgeColor',goodColor);
            else
                rectangle('Position',boxPosition,'EdgeColor',badColor);
            end;
        end;
    end;
end;

end



