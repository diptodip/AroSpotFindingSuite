function worms=classifyFISHSpots(dye,stackSuffix,probeName,varargin)  %nameMod
%worms=classifyFISHSpots(dye,stackSuffix,probeName,varargin)   %nameMod
%  =============================================================
%  Name: classifyFISHSpots.m   %nameMod
%  Version: 1.4, 21 July 2011   %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%  License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%  Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%  =============================================================
% This function takes the statistics calculated in evaluateFISHImageStack on
% candidate spots in the stack and applies the random forest of the
% training set on them
%
%dye is the dye name
%stackSuffix is the unique identifier for files associated with this stack
%this is used to find the data file:     worms=load([dye stackSuffix '_wormGaussianFit']);
%
%the data file can be passed in (the output from gaussEvalSpots3D) and then
%it doesn't read in the written file but uses what is passed in
%
% It uses R (http://r-project.org) and the R library randomForest
% (http://cran.r-project.org/web/packages/randomForest/index.html - A. Liaw
% and M. Wiener (2002). Classification and Regression by randomForest. R
% News 2(3), 18--22. )
%
% Follow the installation instructions at the R project site, and modify
% the pathToR information below accordingly.  On Macs and other *NIX based
% systems, the R path should be fine.  On windows systems, you may have to
% modify things, especially the R-version directory
%
%ultimately updates the data structure in [dye stackSuffix '_wormGaussianFit.mat']



if ispc
    %change this to reflect the location or Rterm.exe
    pathToR='C:\\"Program Files"\\R\\R-2.9.0\\bin\\i386\\Rterm.exe';
else
    pathToR='R';
end;

if size(varargin,2)>=1
    worms=varargin{1};
else
    disp('Loading worms');
    wormFile=load([dye stackSuffix '_wormGaussianFit']);
    
    %disp(worms);
    worms=wormFile.worms;%need to change when run again with iSave_worms modification
    disp(['Worms loaded from stack' stackSuffix]);
    
    
    %%Inserted 6 July 11...need to transfer to newly named files
    
    %Check to see if wormGaussianFit has all the fields it is supposed to
    %(if it was made with the latest version).  Version 1p2p2 and beyond should have
    %these fields:
    %
    %              stackName: 'cy001.stk'
    %                   mask: [1024x1024 logical]
    %            boundingBox: [1x1 struct]
    %            regMaxSpots: [90649x5 double]
    %               spotInfo: {1x1761 cell}
    %               goodWorm: 1
    
    %And these additional fields
    %     quickAndDirtyStats: 0
    %          stackFileType: 'stk'
    %            stackPrefix: 'cy001'
    %               metaInfo: []
    %         numberOfPlanes: 40
    %put them in if necessary
    if size(worms,2)==0
        return
    end;
    if ~isfield(worms{1},'quickAndDirtyStats')
        %Then it is a previous version
        load wormGaussianFitUpdater
        for wi=1:size(worms,2)
            worms{wi}.quickAndDirtyStats=updateStruct.quickAndDirtyStats;
            worms{wi}.stackFileType=updateStruct.stackFileType;
            worms{wi}.stackPrefix=updateStruct.stackPrefix;
            worms{wi}.metaInfo=updateStruct.metaInfo;
            worms{wi}.numberOfPlanes=updateStruct.numberOfPlanes;
        end;
        disp('Saving augmented worm file - current version');
        save([dye stackSuffix '_wormGaussianFit'],'worms');
    end;
    
end;
saveAndPrint=1;
if size(varargin,2)==2
    if varargin{2}==0
        saveAndPrint=0;
    end;
end;
%extract data
%will need some nice way of figuring out which variables i used...maybe
%list of all the variables and then choosing only a subset which is
%specified in a file
if ~isempty(worms)%if the stack is bad then it wont run
    %load the training data
    disp('Loading training data');
    curdir=cd;
    %     cd('..');
    %     cd('trainingSets');
    %     trainingDir=cd;
    %   REVISED 2/10/10 so that trainingSets live in the same directory as the
    %   data.  each set of data gets its own trainingSet for now.  need to test
    %   whether they can work cross datasets and then can consolidate into a
    %   single directory
    trainingDir=curdir;
    disp(['trainingDir is ' trainingDir]);
    trainingFile=['trainingSet_' dye '_' probeName '.mat'];
    trainingSet=load(trainingFile);
    disp('Training data loaded');
    trainingSet=trainingSet.trainingSet;
    %disp(trainingSet);
    cd(curdir);
    %linear
    % lw=stats.SVM{1}.w;
    % lgamma=stats.SVM{1}.gamma;
    % nlw=stats.SVM{2}.w;
    % nlgamma=stats.SVM{2}.gamma;
    % lnu=trainingSet.SVM{1}.nu;
    % nlmu=trainingSet.SVM{2}.mu;
    % nlnu=trainingSet.SVM{2}.nu;
    % statsPresent=trainingSet.SVM{1}.statsPresent;
    
    %nu and mu gotten from the initial training file right now
    
    %
    %disp(worms);
    parfor wi=1:size(worms,2)%added parfor here at top level
        if ~isfield(worms{wi},'spotsFixed')
            worms{wi}.spotsFixed=0;%added 12/17/09 so could keep track of which ones have been fixed or not.
        end;
        if 1==1%worms{wi}.spotsFixed==0
            worms{wi}.probeName=probeName;
            
            %16 Sep 2011.  added mfilename for classifier so can know which version generated
            worms{wi}.classifierFunctionVersion={mfilename; datestr(now)};
            
            
            
            if ~isfield(worms{wi},'goodWorm')
                worms{wi}.goodWorm=1;
            end;
            if ~isfield(worms{wi},'spotInfo')
                worms{wi}.goodWorm=0;
            end;
            if worms{wi}.goodWorm
                iSpotsEvaluated=[];
                disp(['Processing worm ' num2str(wi) ' with ' num2str(size(worms{wi}.spotInfo,2)) ' potential spots']);
                %disp(['Processing worm ' num2str(wi)]);
                testData=[];
                locs=[];
                %         worms{wi}.linearNSpots=0;
                %         worms{wi}.svdlinearNSpots=0;
                %         worms{wi}.nlinearNSpots=0;
                worms{wi}.nTestedSpots=0;
                worms{wi}.RFNSpots=0;
                
                for si=1:size(worms{wi}.spotInfo,2)
                    if ~isfield(worms{wi}.spotInfo{si}.stat,'message')
                        %then it has data
                        locs=[locs;worms{wi}.spotInfo{si}.locations.worm];
                        
                        %SVD - need to add the SVD stats in
                        dataInSVDBasis=(worms{wi}.spotInfo{si}.dataMat(:)'-trainingSet.allDataCenter)*trainingSet.svdBasisRightMultiplier;
                        for j=1:5  %take the first five coordinates of in the new basis
                            worms{wi}.spotInfo{si}.stat.statValues.(['sv' num2str(j)])=dataInSVDBasis(j);
                        end;
                        
                        
                        testStat=worms{wi}.spotInfo{si}.stat;
                        dataLine=makeDataLine(testStat.statValues,trainingSet.MachLearn{1}.statsPresentLabels);%is this right?
                        if ~isempty(dataLine)
                            testData=[testData;dataLine];
                            iSpotsEvaluated=[iSpotsEvaluated;si];
                            worms{wi}.spotInfo{si}.data=dataLine;
                        end;
                        
                        
                        
                        %                             Changed to statValues format 19April2011
                        %                             newline=testStat.stats(trainingSet.MachLearn{1}.statsPresent);%do the stats present here - 13 April 2011
                        %                             if max(abs(newline))<2000000 && sum(isnan(newline))==0
                        %                                 testData=[testData;newline];
                        %                                 iSpotsEvaluated=[iSpotsEvaluated;si];
                        %                                 worms{wi}.spotInfo{si}.data=newline;
                        %                             end;
                    end;
                end;
                worms{wi}.trainingFileName=['trainingSet_' dye '_' probeName '.mat'];
                
                
                
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%
                %RANDOM FORESTS
                
                % R
                responseMatrixFileName=['RFtestdataMatrix_' dye stackSuffix '_w' num2str(wi) '.txt'];
                
                
                if ~isempty(testData)
                    programName=['RFtestProgram_' dye stackSuffix '_w' num2str(wi) '.R'];
                    %13 April 2011 - stats present already taken out of
                    %testData
                    dlmwrite(responseMatrixFileName, testData,'delimiter','\t' );%they will come back (0,1)->(1,2)
                    Rfile=fopen(programName,'w');
                    if ispc
                        fprintf(Rfile,'setwd("%s");\n',strrep(cd,'\','\\'));
                        fprintf(Rfile,'library(randomForest);\n');
                        fprintf(Rfile,'teData=read.table("%s");\n',responseMatrixFileName);
                        fprintf(Rfile,'colnames(teData)=c("%s");\n',strjoin(trainingSet.MachLearn{1}.statsPresentLabels,'", "'));
                        
                        %fprintf(Rfile,'load("..\\\\trainingSets\\\\%s");\n',trainingSet.MachLearn{1}.randomForestFile);
                        fprintf(Rfile,'load("%s");\n',trainingSet.MachLearn{1}.randomForestFile);
                    else%POSIX style
                        fprintf(Rfile,'setwd("%s");\n',cd);
                        fprintf(Rfile,'library(randomForest);\n');
                        fprintf(Rfile,'teData=read.table("%s");\n',responseMatrixFileName);
                        fprintf(Rfile,'colnames(teData)=c("%s");\n',strjoin(trainingSet.MachLearn{1}.statsPresentLabels,'", "'));
                        %fprintf(Rfile,'load("../trainingSets/%s");\n',trainingSet.MachLearn{1}.randomForestFile);
                        fprintf(Rfile,'load("%s");\n',trainingSet.MachLearn{1}.randomForestFile);
                    end;
                    
                    %split into data and cateogries
                    fprintf(Rfile,'testRF=predict(object=rf,newdata=teData,type="prob");\n');
                    fprintf(Rfile,'write(t(testRF),file="%s",ncolumns=2);\n',['RFtest' dye stackSuffix '_w' num2str(wi) '_results.txt']);
                    %need to add saveplots
                    fclose(Rfile);
                    fprintf('output going to %s.out.txt\n',programName);
                    
                    
                    %
                    system(sprintf('%s --no-restore --no-save < %s >%s.out.txt 2>&1',pathToR,programName,programName));
                    
                    
                    results=dlmread(['RFtest' dye stackSuffix '_w' num2str(wi) '_results.txt']);
                    
                    [~,classes]=max(results,[],2);
                    %4/13/2011 - added the fuzzy stuff...spot numbers and
                    %variances (for error calculation)
                    if ~isempty(iSpotsEvaluated)
                        for si=1:length(iSpotsEvaluated)
                            worms{wi}.spotInfo{iSpotsEvaluated(si)}.MachLearnResult{1}=results(si,2);%just use the fraction of votes for the good class
                            worms{wi}.spotInfo{iSpotsEvaluated(si)}.classification.MachLearn{1}=classes(si)-1;
                            worms{wi}.spotInfo{iSpotsEvaluated(si)}.classification.final=classes(si)-1;%note that this field will be changed in fixSpotCallsRFOnly() if needed.  but if fixSpot...() is not called, then this field and nSpotsFinal need to be in there for downstream spot tallying to work
                        end;
                        worms{wi}.RFNSpots=sum(classes==2);
                    else
                        worms{wi}.RFNSpots=0;
                    end;
                    %need to adjust to take manual into account
                    
                    %                     worms{wi}.spotProbs=results(:,2);
                    %                     dist=multBinomProbsDist(worms{wi}.spotProbs);
                    %                     quantiles=[.0005,.005,.025,.5,.975,.995,.9995];
                    %                     worms{wi}.RFNSpotsQuantiles=[quantiles;quantile(dist,quantiles)'];
                else
                    worms{wi}.isgood=0;
                    %shouldn't this be goodWorm? 2/10/10
                    worms{wi}.goodWorm=0;
                    worms{wi}.RFNSpots=-1;
                    worms{wi}.nSpotsFinal=worms{wi}.RFNSpots;
                    
                end;
                
                
                %disp([num2str(worms{wi}.linearNSpots) ':' num2str(worms{wi}.nlinearNSpots) ':' num2str(worms{wi}.svdlinearNSpots)  ':' num2str(worms{wi}.RFNSpots) ' in worm ' num2str(wi) ' (' num2str(worms{wi}.nTestedSpots) ' tested)']);
                %disp([num2str(worms{wi}.linearNSpots) ':' num2str(worms{wi}.nlinearNSpots)  ':' num2str(worms{wi}.RFNSpots) ' in worm ' num2str(wi) ' (' num2str(worms{wi}.nTestedSpots) ' tested)']);
            else
                disp(['Worm ' num2str(wi) ' is bad.']);
            end;
        end;%if spotsFixed==0
        
        
        %%%  Need to now go through trainingSet and adjust nSpotsFinal and
        %%%  classification depending on whether it is in there or not
        %%% only have a manual field if it is in trainingSet.  So erase it
        %%% if it does not
        wormSpotClassificationInTraining=zeros(size(worms{wi}.spotInfo,2),1)-1;  %vector of spots.  -1 to start.  fills in with classification if in there
        for tsi=1:size(trainingSet.spotInfo,2)
            if (strcmp(trainingSet.spotInfo{tsi}.stackSuffix,stackSuffix) && trainingSet.spotInfo{tsi}.wormNumber==wi)
                wormSpotClassificationInTraining(trainingSet.spotInfo{tsi}.spotInfoNumberInWorm)=trainingSet.spotInfo{tsi}.classification.manual;
            end;
        end;
        
        %Is this stack in the trainingSet?
        if isempty(find(wormSpotClassificationInTraining~=-1))
            worms{wi}.nSpotsFinal=worms{wi}.RFNSpots;
        else
            worms{wi}.nSpotsFinal=0;
            % first get rid of classification manual for anything that isn't in
            % trainingSet
            iNotInTrainingSet=find(wormSpotClassificationInTraining==-1);
            %These are indices in wormSpotClassificationInTraining which
            %are -1
            for nitsi=1:length(iNotInTrainingSet)
                 worms{wi}.nSpotsFinal=worms{wi}.nSpotsFinal+worms{wi}.spotInfo{iNotInTrainingSet(nitsi)}.classification.final;
                if isfield(worms{wi}.spotInfo{iNotInTrainingSet(nitsi)}.classification,'manual')
                    worms{wi}.spotInfo{iNotInTrainingSet(nitsi)}.classification=rmfield(worms{wi}.spotInfo{iNotInTrainingSet(nitsi)}.classification,'manual');
                end;
            end;

            %Then go through and adjust for being in the trainingSet
            iInTrainingSet=find(wormSpotClassificationInTraining~=-1);
            for switi=1:length(iInTrainingSet)               
                worms{wi}.spotInfo{iInTrainingSet(switi)}.classification.manual=wormSpotClassificationInTraining(iInTrainingSet(switi));
                worms{wi}.spotInfo{iInTrainingSet(switi)}.classification.final=wormSpotClassificationInTraining(iInTrainingSet(switi));              
                worms{wi}.nSpotsFinal=worms{wi}.nSpotsFinal+worms{wi}.spotInfo{iInTrainingSet(switi)}.classification.final;
            end;
        end;
        %Now only those spots in the trainingSet have manual
        %classifications
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end;%end parfor
    
    
    
    
    %Go through and write text file with info
    fileID=fopen([dye stackSuffix '_wormSpotResults.csv'],'w');
    fprintf('nSpots,dye,iWorm,stackSuffix\n');
    for wi=1:size(worms,2)
        fprintf(fileID,'%d,%s,%d,%s\n',worms{wi}.nSpotsFinal,dye,wi,['stack' stackSuffix]);
        disp(sprintf('%d,%s,%d,%s',worms{wi}.nSpotsFinal,dye,wi,['stack' stackSuffix]));
    end;
    fclose(fileID);
    if saveAndPrint
        disp(['Saving ' dye stackSuffix '_wormGaussianFit']);
        save([dye stackSuffix '_wormGaussianFit'],'worms');
        
        
        %saveSpotPictures(dye,stackSuffix,worms);
    else
        disp(['Not saving ' dye stackSuffix '_wormGaussianFit']);
    end;
else
    disp('Stack is bad: worms is empty');
end;
end


