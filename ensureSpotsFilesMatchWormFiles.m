function [goldSpotsNew,rejectedSpotsNew]=ensureSpotsFilesMatchWormFiles(goldSpots,rejectedSpots,trainingDir,probeName)
%  =============================================================
%  Name: ensureSpotsFilesMatchWormFiles.m   %nameMod
%  Version: 1.0, 9 Nov 2011   %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%  License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%  Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%  =============================================================
%This function makes sure that the goldSpots and rejectedSpots files have
%the 4-6 columns that match the worm files and that any spots in these
%files are in the worm files.
%This is essentially here for version control
%5Oct2011


goldFieldNames=fieldnames(goldSpots);
for fni=1:size(goldFieldNames,1)%stacks
    stackPrefix=regexp(goldFieldNames{fni},'_','split');
    stackFileType=stackPrefix{2};
    stackPrefix=stackPrefix{1};
    if strcmp(stackFileType,'stk')
        stackSuffix=collectDigits(goldFieldNames{fni},1);
        dye=regexp(goldFieldNames{fni},stackSuffix,'split');
        dye=dye{1};
        segmentsName=['segmenttrans' stackSuffix '.mat'];
    elseif strcmp(stackFileType,'tif') || strcmp(stackFileType,'tiff')
        stackSuffix=regexp(stackPrefix,'_','split');
        dye=stackSuffix{1};
        stackSuffix=stackSuffix{end};
        segmentsName=['segmenttrans' '_' stackSuffix '.mat'];
    end;
    load(segmentsName);
    load([dye stackSuffix '_wormGaussianFit']);
    
    
    
    [spotIntensities,wormNumbers,spotInfoNumbersInWorms]=findSpotInfoInWormBasedOnLocation(goldSpots.(goldFieldNames{fni})(:,1:3),worms,currpolys);
    %immediately here deal with any that are not in the worm files
    newSpotsHaveBeenAddedToWorms=0;
    ToDeleteFromGold=[];
    for regi=1:size(spotInfoNumbersInWorms,1)
        if ~spotInfoNumbersInWorms(regi)
            [worms,wormsChanged]=addNewSpotToWorm(goldSpots.(goldFieldNames{fni})(regi,1:3),wormNumbers(regi),worms);
            if wormsChanged
                newSpotsHaveBeenAddedToWorms=newSpotsHaveBeenAddedToWorms+1;
                spotInfoNumbersInWorms(regi)=size(worms{wormNumbers(regi)}.spotInfo,2);%because it was added at the end
                spotIntensities(regi)=worms{wormNumbers(regi)}.spotInfo{spotInfoNumbersInWorms(regi)}.rawValue;
            else
                ToDeleteFromGold=[ToDeleteFromGold regi];
            end;
        end;
    end;
    tempMat=[goldSpots.(goldFieldNames{fni})(:,1:3),spotIntensities,wormNumbers,spotInfoNumbersInWorms];
    tempMat(ToDeleteFromGold,:)=[];
    if ~isempty(ToDeleteFromGold)
        disp('ToDeleteFromGold');
        disp(ToDeleteFromGold);
    end;
    
    goldSpotsNew.(goldFieldNames{fni})=tempMat;%easier than comparing
    if newSpotsHaveBeenAddedToWorms
        disp(['Saving worms to ' dye stackSuffix '_wormGaussianFit.mat with ' num2str(newSpotsHaveBeenAddedToWorms) ' new spots added']);
        save([dye stackSuffix '_wormGaussianFit'],'worms');
    end;
    
end;




rejectedFieldNames=fieldnames(rejectedSpots);
for fni=1:size(rejectedFieldNames,1)
    
    stackPrefix=regexp(rejectedFieldNames{fni},'_','split');
    disp(stackPrefix);
    stackFileType=stackPrefix{2};
    stackPrefix=stackPrefix{1};
    if strcmp(stackFileType,'stk')
        stackSuffix=collectDigits(rejectedFieldNames{fni},1);
        dye=regexp(rejectedFieldNames{fni},stackSuffix,'split');
        dye=dye{1};
        segmentsName=['segmenttrans' stackSuffix '.mat'];
    elseif strcmp(stackFileType,'tif') || strcmp(stackFileType,'tiff')
        stackSuffix=regexp(stackPrefix,'_','split');
        dye=stackSuffix{1};
        stackSuffix=stackSuffix{end};
        segmentsName=['segmenttrans' '_' stackSuffix '.mat'];
    end;
    load(segmentsName);
    load([dye stackSuffix '_wormGaussianFit']);
    
    
    
    [spotIntensities,wormNumbers,spotInfoNumbersInWorms]=findSpotInfoInWormBasedOnLocation(rejectedSpots.(rejectedFieldNames{fni})(:,1:3),worms,currpolys);
    %immediately here deal with any that are not in the worm files
    newSpotsHaveBeenAddedToWorms=0;
    ToDeleteFromRejected=[];
    for regi=1:size(spotInfoNumbersInWorms,1)
        if ~spotInfoNumbersInWorms(regi)
            [worms,wormsChanged]=addNewSpotToWorm(rejectedSpots.(rejectedFieldNames{fni})(regi,1:3),wormNumbers(regi),worms);
            if wormsChanged
                newSpotsHaveBeenAddedToWorms=newSpotsHaveBeenAddedToWorms+1;
                spotInfoNumbersInWorms(regi)=size(worms{wormNumbers(regi)}.spotInfo,2);%because it was added at the end
                spotIntensities(regi)=worms{wormNumbers(regi)}.spotInfo{spotInfoNumbersInWorms(regi)}.rawValue;
            else
                ToDeleteFromRejected=[ToDeleteFromRejected regi];
                
            end;
        end;
    end;
    if ~isempty(ToDeleteFromRejected)
        disp('ToDeleteFromRejected');
        disp(ToDeleteFromRejected);
    end;
    
    tempMat=[rejectedSpots.(rejectedFieldNames{fni})(:,1:3),spotIntensities,wormNumbers,spotInfoNumbersInWorms];
    tempMat(ToDeleteFromRejected,:)=[];
    rejectedSpotsNew.(rejectedFieldNames{fni})=tempMat;%easier than comparing
    if newSpotsHaveBeenAddedToWorms
        disp(['Saving worms to ' dye stackSuffix '_wormGaussianFit.mat with ' num2str(newSpotsHaveBeenAddedToWorms) ' new spots added']);
        save([dye stackSuffix '_wormGaussianFit'],'worms');
    end;
end;
if ~isequal(goldSpotsNew,goldSpots)
    goldSpots=goldSpotsNew;
    save(fullfile(trainingDir,['goldSpots_' dye '_' probeName '.mat']),'goldSpots');
end;
if ~isequal(rejectedSpotsNew,rejectedSpots)
    rejectedSpots=rejectedSpotsNew;
    save(fullfile(trainingDir,['rejectedSpots_' dye '_' probeName '.mat']),'rejectedSpots');
end;

end
