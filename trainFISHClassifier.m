function trainingSet=trainFISHClassifier(trainingSet,fromFixSpotCalls)  %nameMod
%  =============================================================
%  Name: trainFISHClassifier.m%nameMod
%  Version: 1.4.1, 22 Sep 2011   %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%  License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%  Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu 
%  =============================================================
% This function takes the spots in the training set from
% createFISHTrainingSet and trains a random forest with them
%
%trainingSet=trainFISHClassifier(trainingSet,fromFixSpotCalls)
%trainingSet is a trainingSet output by createFISHTrainingSet
%fromFixSpotCalls is 0 or 1.  Should be set to 0 if this function is not
%   being called from fixSpotCallsRFOnly.m
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
% The program prints the confusion matrix to the screen and rewrites the
% training set data to the file.  It also outputs various measures of how
% it did under trainingSet* in the current directory.
%
% The training set data structure can use other machine learning algorithms
% in addition or instead of random forests.  You'll see commented out below
% a suport vector machines one.
%
% As currently written the data structure and the following programs that
% evaluate other images are set up to use random forests and the variables
% it produces.  But with modification of the data structure, there is no
% reason why others couldn't be plugged in.

%stat now only has statValues
%9/22/11
%stat also has the dataFit.  and new stat values for 2D gaussian fit
%compatible with the other 1p4p1 series

if ispc
    %change this to point to Rterm.exe in your R distribution
    pathToR='C:\\"Program Files"\\R\\R-2.9.0\\bin\\Rterm.exe';
else
    pathToR='R';
end;


curdir=cd;

trainingDir=curdir;

if trainingSet.quickAndDirtyStats
  %'Vx';'intensity';'rmse';'nmse'  ;'shrunkenRsquared';'estimatedFloor';'scnmse';'scnrmse';'scr';'scd';'sce';
 
   statsToUse = {  'prctile_50';    'prctile_60'  ;  'prctile_70'  ;  'prctile_80'  ; 'prctile_90';
    'fraction_center';    'fraction_plusSign'  ;  'fraction_3box'  ;  'fraction_5star'  ;  'fraction_5box';    'fraction_7star' ; 'fraction_3ring';
    'raw_center';    'raw_plusSign'  ;  'raw_3box'  ;  'raw_5star'  ;  'raw_5box';    'raw_7star' ; 'raw_3ring';
    'total_area';
     'sv1';'sv2';'sv3';'sv4';'sv5';
     'horizIntensity';'vertIntensity';'meanIntensity';'horizrsquare';'vertrsquare';'meanrsquare'};
else

    statsToUse = {'intensity';'rawIntensity';'totalHeight';'sigmax';'sigmay';'estimatedFloor';'scnmse';'scnrmse';'scr';'scd';'sce';
 
    'prctile_50';    'prctile_60'  ;  'prctile_70'  ;  'prctile_80'  ; 'prctile_90';
    'fraction_center';    'fraction_plusSign'  ;  'fraction_3box'  ;  'fraction_5star'  ;  'fraction_5box';    'fraction_7star' ; 'fraction_3ring';
    'raw_center';    'raw_plusSign'  ;  'raw_3box'  ;  'raw_5star'  ;  'raw_5box';    'raw_7star' ; 'raw_3ring';
    'total_area';
     'sv1';'sv2';'sv3';'sv4';'sv5'};

    %'horizIntensity';'vertIntensity';'meanIntensity';'horizrsquare';'vertrsquare';'meanrsquare';
end;

% statsPresent=[];
% for sti=1:length(trainingSet.spotInfo{1}.stat.statLabels)
%     for sli=1:length(statsToUse) %does extra but useful in case order changes
%         if strcmp(trainingSet.spotInfo{1}.stat.statLabels(sti),statsToUse{sli})
%             statsPresent=[statsPresent sti];
%         end;
%     end;
% end;


if ~fromFixSpotCalls%reviewFISHClassification already adds to dataMatrix
%     fileName=trainingSet.name;
%     load(fileName);
    %make plots of amplitude and adjrsquared
    data.gold=[];
    data.rejected=[];
    %data.bkgd=[];

    trainingSet.dataMatrix=[];
    trainingSet.categoryVector=[];
    trainingSet.dataHeader=[];
    trainingSet.notInDataMatrix=[];
    %can't parfor this loop - because initial size not fixed - appending
    for si=1:size(trainingSet.spotInfo,2)
        if isfield(trainingSet.spotInfo{si},'stat')
            if ~isfield(trainingSet.spotInfo{si}.stat,'message')
                
                %19 April 2011 - this is replaced with a fieldnames call to
                %makeDataLine function below
                %newline=[trainingSet.spotInfo{si}.stat.stats(statsPresent) trainingSet.spotInfo{si}.classification.manual];
                %statLabels=trainingSet.spotInfo{si}.stat.statLabels(statsPresent);
%                 if max(abs(newline))<20000000 && sum(isnan(newline))==0                    
%                     trainingSet.dataMatrix=[trainingSet.dataMatrix;newline(1:end-1)];
%                     trainingSet.categoryVector=[trainingSet.categoryVecto
%                     r;trainingSet.spotInfo{si}.classification.manual];
%                     trainingSet.spotInfo{si}.iDataMatrix=size(trainingSet.dataMatrix,1);
%                 else
%                     trainingSet.spotInfo{si}.iDataMatrix=0;
%                 end;

                dataLine=makeDataLine(trainingSet.spotInfo{si}.stat.statValues,statsToUse);
%                 if sum(isnan(dataLine))>0
%                     disp(si);
%                     disp(trainingSet.spotInfo{si}.stat.statValues);
%                     pause();
%                 end;
                    
                if ~isempty(dataLine)%there is a datalineProblem!!!
                    trainingSet.dataMatrix=[trainingSet.dataMatrix;dataLine];
                    trainingSet.categoryVector=[trainingSet.categoryVector;trainingSet.spotInfo{si}.classification.manual];
                    trainingSet.spotInfo{si}.iDataMatrix=size(trainingSet.dataMatrix,1);
                else
                    trainingSet.spotInfo{si}.iDataMatrix=0;
                 trainingSet.notInDataMatrix=[trainingSet.notInDataMatrix si];
               end;
                    
            else
                trainingSet.spotInfo{si}.iDataMatrix=0;
                trainingSet.notInDataMatrix=[trainingSet.notInDataMatrix si];
            end;
        else
            trainingSet.spotInfo{si}.iDataMatrix=0;
        end;
    end;
%     plot(trainingSet.categoryVector,trainingSet.dataMatrix(:,14),'o');
%     pause;
    close all;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %SVM - uses SSVM from http://www.cs.wisc.edu/dmi/svm/
%     stats.SVM={};
% 
%     %dlmwrite([filename '.tsv'],[trainingSet.dataMatrix trainingSet.categoryVector], 'Delimiter','\t');
% 
%     %ssvm and n_ssvm expect 1s and -1s...so need to translate category vector
%     %into those from 1,0
%     categoryVector=2*trainingSet.categoryVector-1;
% 
%     [w gamma trainCorr testCorr cpu_time nu trainStats testStats,trainClassMat, testClassMat]=ssvmMod(trainingSet.dataMatrix(:,statsPresent),categoryVector,1);
%     fprintf('Linear SVM has training correctness of %f\n',trainCorr);
% 
%     trainingSet.SVM{1}.w=w;
%     trainingSet.SVM{1}.gamma=gamma;
%     trainingSet.SVM{1}.corr=trainCorr;
%     trainingSet.SVM{1}.nu=nu;
%     trainingSet.SVM{1}.statsPresent=statsPresent;
%     trainingSet.SVM{1}.statsPresentLabels=[statLabels{statsPresent}];
%     trainingSet.SVM{1}.trainStats=trainStats;
%     trainingSet.SVM{1}.trainClassMat=trainClassMat;
%     trainingSet.SVM{1}.type='linear';
% 
% 
% 
%     % %need to mean center points and normalize features
%     % meanNormDataMatrix=trainingSet.dataMatrix;
%     % mn=[];
%     % for ci=1:size(meanNormDataMatrix,2)
%     %     mn=[mn norm(meanNormDataMatrix(:,ci))];
%     %     meanNormDataMatrix(:,ci)=(meanNormDataMatrix(:,ci)-mean(meanNormDataMatrix(:,ci)))/mn(end);
%     %
%     % end;
%     %
%     % [U,S,V]=svd(meanNormDataMatrix,0);%just svd all stats
%     % svdData=U*S;
%     %
%     % svdResults=[];
%     % for svd_dimensions=1:size(trainingSet.dataMatrix,2)
%     % [w gamma trainCorr testCorr cpu_time nu trainStats testStats,trainClassMat, testClassMat]=ssvmMod(svdData(:,1:svd_dimensions),categoryVector,1);
%     % fprintf('Linear SVM_SVD has training correctness of %f\n',trainCorr);
%     % svdResults=[svdResults trainCorr];
%     % end;
%     % [c,svd_dimensions]=max(svdResults);
%     % disp(['SVD dimensions = ' num2str(svd_dimensions)]);
%     %
%     % trainingSet.SVM{3}.w=w;
%     % trainingSet.SVM{3}.gamma=gamma;
%     % trainingSet.SVM{3}.corr=trainCorr;
%     % trainingSet.SVM{3}.nu=nu;
%     % trainingSet.SVM{3}.statsPresent=statsPresent;
%     % trainingSet.SVM{3}.statsPresentLabels=[statLabels{statsPresent}];
%     % trainingSet.SVM{3}.trainStats=trainStats;
%     % trainingSet.SVM{3}.trainClassMat=trainClassMat;
%     % trainingSet.SVM{3}.type='linearSVD';
%     % trainingSet.SVM{3}.SVD={U,S,V};
%     % trainingSet.SVM{3}.SVD_dimensions=svd_dimensions;
%     % trainingSet.SVM{3}.meanDataMatrix=mean(trainingSet.dataMatrix,1);
%     % trainingSet.SVM{3}.normDataMatrix=mn;
%     % plot(diag(S));
% 
% 
%     %gaussian kernel
%     rr=1;
%     k=1;
%     nu=0;
%     mu=.001;
%     [w gamma trainCorr testCorr cpu_time nu mu trainStats testStats,trainClassMat, testClassMat]=n_ssvmMod(trainingSet.dataMatrix(:,statsPresent),categoryVector,rr,k,nu,mu);
% 
%     trainingSet.SVM{2}.w=w;
%     trainingSet.SVM{2}.gamma=gamma;
%     trainingSet.SVM{2}.corr=trainCorr;
%     trainingSet.SVM{2}.nu=nu;
%     trainingSet.SVM{2}.mu=mu;
%     trainingSet.SVM{2}.statsPresent=statsPresent;
%     trainingSet.SVM{2}.statsPresentLabels=[statLabels{statsPresent}];
%     trainingSet.SVM{2}.trainStats=trainStats;
%     trainingSet.SVM{2}.trainClassMat=trainClassMat;
% 
%     trainingSet.SVM{2}.type=['gaussian_mu=' num2str(mu)];
% else % 27 April commented out...what does this do?
%     %just run random forests from fixSpotCalls2
%     %trainingSet=varargin{1};
%     %fileName=['trainingSet_' dye stackSuffix];
%     for si=1:size(trainingSet.spotInfo,2)
%         if isfield(trainingSet.spotInfo{si},'stat')
%             if ~isfield(trainingSet.spotInfo{si}.stat,'message')
%                 statLabels=trainingSet.spotInfo{si}.stat.statLabels;
%                 break
%             end;
%         end;
%     end;
end;
%train RandomForests
%%%%%%%%%%%%%%%%%%%%%%%%%%
%RANDOM FORESTS
%statsPresent=1:size(trainingSet.dataMatrix,2);


% R
responseMatrixFileName=regexprep(trainingSet.name,'.mat','_dataMatrix.txt');
ntree=10000;%25Oct2011 changed to 5000
programName=regexprep(trainingSet.name,'.mat','_trainingProgram.R');
dlmwrite( responseMatrixFileName, [ trainingSet.dataMatrix trainingSet.categoryVector+1],'delimiter','\t','precision',10 );%(0,1)->(1,2) since this is the way they will come back
Rfile=fopen(programName,'w');
fprintf(Rfile,'setwd("%s");\n',strrep(cd,'\','\\'));
fprintf(Rfile,'library(randomForest);\n');
fprintf(Rfile,'train=read.table("%s");\n',responseMatrixFileName);
%rename columns with statLabels
fprintf(Rfile,'colnames(train)=c("%s");\n',[strjoin(statsToUse,'", "') '", "manualClass']);
%split into data and cateogries
fprintf(Rfile,'dimTrain=dim(train);\n');
fprintf(Rfile,'trData=train[,-dimTrain[2]];\n');
fprintf(Rfile,'trCats=factor(train[,dimTrain[2]]);\n');
fprintf(Rfile,'rf=tuneRF(x=trData,y=trCats,mtryStart=floor(2*sqrt(dimTrain[2]-1)),stepFactor=1.1,improve=0.01,ntree=%d,importance=TRUE,doBest=TRUE, proximity=TRUE);\n',ntree);%25Oct2011 changed to 2*sqrt...
fprintf(Rfile,'save(rf,file="%s");\n',regexprep(trainingSet.name,'.mat','.randomForest'));
fprintf(Rfile,'write(rf$mtry,file="%s");\n',regexprep(trainingSet.name,'.mat','_mtry.txt'));
fprintf(Rfile,'write(t(rf$confusion),file="%s",ncolumns=3);\n',regexprep(trainingSet.name,'.mat','_confusion.txt'));
fprintf(Rfile,'write(t(rf$votes),file="%s",ncolumns=2);\n',regexprep(trainingSet.name,'.mat','_votes.txt'));
fprintf(Rfile,'write(t(rf$importance),file="%s",ncolumns=4);\n',regexprep(trainingSet.name,'.mat','_importance.txt'));
fprintf(Rfile,'x=margin(rf,observed=trCats);\npdf("%s");\nplot(x,sort=FALSE,main="Training Set Margin");\ndev.off();\n',regexprep(trainingSet.name,'.mat','_margin.pdf'));
fprintf(Rfile,'\npdf("%s",width=12,height=12);varImpPlot(rf,sort=FALSE, n.var=%d);\ndev.off();\n',regexprep(trainingSet.name,'.mat','_varImp.pdf'),length(statsToUse));
fprintf(Rfile,'\npdf("%s");MDSplot(rf,trCats,k=2);\ndev.off();\n',regexprep(trainingSet.name,'.mat','_MDS.pdf'));
fprintf(Rfile,'\npdf("%s");plot(rf);\ndev.off();\n',regexprep(trainingSet.name,'.mat','_rfPlot.pdf'));

%need to add saveplots
fclose(Rfile);
fprintf('output going to %s.out.txt\n',programName);
callToR=tic;
system(sprintf('%s --no-restore --no-save < %s >%s.out.txt 2>&1',pathToR,programName,programName));
disp(['Took ' num2str(toc(callToR)) ' to run']);
trainingSet.MachLearn{1}.params.mtry=dlmread(regexprep(trainingSet.name,'.mat','_mtry.txt'));
trainingSet.MachLearn{1}.results.confusion=dlmread(regexprep(trainingSet.name,'.mat','_confusion.txt'));
trainingSet.MachLearn{1}.results.votes=dlmread(regexprep(trainingSet.name,'.mat','_votes.txt'));
trainingSet.MachLearn{1}.results.importance=dlmread(regexprep(trainingSet.name,'.mat','_importance.txt'));
trainingSet.MachLearn{1}.randomForestFile=regexprep(trainingSet.name,'.mat','.randomForest');
trainingSet.MachLearn{1}.params.ntree=ntree;

disp(trainingSet.MachLearn{1}.results.confusion);
trainingSet.MachLearn{1}.params.NTRAIN=size(trainingSet.dataMatrix,1);
trainingSet.MachLearn{1}.params.TRAINDATAFILE= responseMatrixFileName;
trainingSet.MachLearn{1}.params.programFileName= programName;
%trainingSet.MachLearn{1}.statsPresent=statsPresent;
%trainingSet.MachLearn{1}.statsPresentLabels=[statLabels{statsPresent}];
trainingSet.MachLearn{1}.statsPresentLabels=[statsToUse];
trainingSet.MachLearn{1}.type='RandomForest';
trainingSet.MachLearn{1}.params.MDIM=length(statsToUse);
trainingSet.MachLearn{1}.version='trainFISHClassifier_1p4.m';%nameMod
trainingSet.MachLearn{1}.date=date;


%%%%%%%%%%%%%%%%%%%%%%%%%%





save(trainingSet.name,'trainingSet');


cd(curdir);




end