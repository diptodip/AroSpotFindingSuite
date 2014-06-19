function trainingSet=trainRFClassifier(trainingSet,varargin)
%% ============================================================
%   Name:       traingRFClassifier.m
%   Version:    2.5.2, 25th Apr. 2013
%   Author:     Allison Wu
%   Command: trainingSet=trainRFClassifier(trainingSet,outputSuffix*)
%   Description: train and generate a random forest with the training set of size N.
%       - Needs to load in a trainingSet_{suffix}.mat first.
%       - You can specify the name of the output training set file by specifying the suffix=varargin{1}.  
%         However, by default, it detects the suffix of the file name of the trainingSet mat file where this trainingSet is
%         loaded from and it will overwrite the original trainingSet_{suffix}.mat file.
%       - Each tree in the forest uses "Deviance" as the splitcriterion.
%       - Find and leave out unimportant variables:
%               * All the variables with the VarImp (Variable Importance) 
%                 < VarImpThreshold are left out.
%               * The names of variables that are left out are saved in
%               trainingSet.RF.VarLeftOut.  Those of variables that are
%               used are saved in trainingSet.RF.statsUsed.
%               * trainingSet.RF.dataMatrixUsed is the dataMatrix with
%               unimportant variables left out.
%       - Optimize the number of random features (mBest) to choose at each split
%               * mTryOOBError saves the oob error at each round when
%               looking for the best number of random featurs to choose at
%               each split.
%               * NVarToSampe is the final mBest.
%       - Generate bootstrapped sample of sample size N to generate each tree.
%       - Generate a random forest of ntrees=varargin{2} (1000 by default) trees.
%       - All training statistics are saved in the trainingSet.RF field:
%               * spotTreeProbs: saves the probability estimates generated
%               by each tree for each spot in the training set.
%               * ProbEstimates: the averaged probability estimates among
%               the decision trees.
%               * IQR: interquantile range among probability estimates
%               among trees for each spot.
%               * IQRthreshold: 0.3 by default, any spot with
%               IQR>IQRthreshold is defined as unreliable spots.
%               * UnreliablePortion: the portion of unreliable spots in the
%               data set.
%               * SpotNumEstimate: estimate of the total number of spots
%               (sum over the number of reliable good spots and the
%               probability estimates of unreliable spots.)
%               * SpotNumRange: estimated range of the total number of
%               spots from randomization test with quantile range specified in quantileRange.
%               * ErrorRate: training set error rate
%               * reliableErrorRate: training set error rate among the
%               reliable spots.
%
%       - All the trees are saved in {suffix}_RF.mat
%
%   Files required: trainingSet structure variable loaded from trainingSet_{dye}_{probeName}.mat
%   Files generated: 
%       trainingSet with RF field added
%       trainingSet_{suffix}.mat
%       {suffix}_Train_ProbsIQR.fig - plots the Probability v.s. IQR scatter plot
%       {suffix}_RF.mat
%   Updates:
%       2013 Apr. 17th: 
%           - do not show the Prob_IQR figure so that it won't interfere with reviewFISHClassification
%       2013 Apr. 25th: 
%           - add in the new method to determine the spotNumEstimate and spotNumRange.
%           - built-in version check to add in new stats needed for this version.
%       2013 May 7th:
%           - re-write the way it finds NVarToSample to save some time but
%           it shouldn't change most of the results.
%       2013 May 9th:
%           - use calculateErrorRange.m to calculate error range.
%       2013 May 22nd:
%           - bug fixes to avoid generating trees with only one node.
%       2013 July 16th:
%           - change reliable to concordant, unreliable to discordant
%% =============================================================
tic
parameters
if isempty(varargin)
    ntrees=5000;
    FBoot=1;
    suffix=strrep(trainingSet.FileName,'trainingSet_','');
    suffix=strrep(suffix,'.mat','');
else
    switch length(varargin)
        case 1
            suffix=varargin{1};
            ntrees=1000;
            FBoot=1;
        case 2
            suffix=varargin{1};
            ntrees=varargin{2};
            FBoot=1;
        case 3
            suffix=varargin{1};
            ntrees=varargin{2};
            FBoot=varargin{3};
    end
end

if isfield(trainingSet,'RF')
    trainingSet=rmfield(trainingSet,'RF');
end

% Check if new stats are added.
if ~strfind(trainingSet.version, 'ver. 2.5')
    display('Detect an older version. Update the trainingSet with new stats.')
    trainingSet=addStatsToTrainingSet(trainingSet);
    suffix=strrep(trainingSet.FileName,'trainingSet_','');
    suffix=strrep(suffix,'.mat','');
end


trainingSet.RF.Version='New method of estimating spot numbers, Apr. 2013';
spotNum=length(trainingSet.spotInfo);
trainingSet.RF.nTrees=ntrees;
trainingSet.RF.FBoot=FBoot;
trainSetData.X=trainingSet.dataMatrix.X;
trainSetData.Y=trainingSet.dataMatrix.Y;
% Finding the variables that do not have much predicting power in this
% training set...
disp('Leaving out variables that are not important....')
disp('Variables that are left out:')

testRF=TreeBagger(1000,trainSetData.X,trainSetData.Y,'FBoot',FBoot,'OOBVarImp','on','splitcriterion','deviance');
VarImp=testRF.OOBPermutedVarDeltaError;
threshold=prctile(VarImp,25);
trainSetData.X=trainSetData.X(:,VarImp>threshold);
trainingSet.RF.VarLeftOut=trainingSet.statsUsed(VarImp<threshold);
trainingSet.statsUsed(VarImp<threshold)
trainingSet.RF.statsUsed=trainingSet.statsUsed(VarImp>threshold);
trainingSet.RF.VarImpThreshold=threshold;
trainingSet.RF.VarImp=VarImp;
trainingSet.RF.dataMatrixUsed=trainSetData.X;

% Find the opitmal number of features used to build each tree.
% Modified based on tuneRF in R.
disp('Looking for the optimal number of features to sample....')
nTreeTry=500;
improve=0.01;
stepFactor=1; 
M=sum(VarImp>threshold);
mStart=floor(sqrt(M));
oobErrors=zeros(ceil(M-0.5*mStart)-mStart,2);

m=mStart;
k=1;
errorOld=[];
fprintf('NVarToSample \t OOB Error \t  Improve\n')
while m<ceil(M-0.5*mStart)
    testRF=TreeBagger(nTreeTry,trainSetData.X,trainSetData.Y,'FBoot',FBoot,'oobpred','on','NVarToSample',m,'splitcriterion','deviance');
    errorCurr=oobError(testRF,'mode','ensemble');
    if isempty(errorOld)
        errorOld=errorCurr;
        mBest=m;
        Improve=0;
    else
        Improve=1-errorCurr/errorOld;
        if Improve>=improve
            errorOld=errorCurr;
            mBest=m;
        end        
    end
    
    oobErrors(k,:)=[m,errorCurr];
    fprintf('%g \t %g \t %g \n', m, errorCurr, Improve)
    k=k+1;
    m=m+stepFactor;
end

trainingSet.RF.mTryOOBError=oobErrors((oobErrors(:,1)~=0.*oobErrors(:,2)~=0),:);
trainingSet.RF.NVarToSample=mBest;
fprintf('The best number of variables to sample: %d . \n',mBest)



% Calculate the class probabilities at each leaf node in each decision tree.
fprintf('Generating a random forest with %d trees and NVarToSample = %d.... \n', ntrees, mBest)
%RF=TreeBagger(ntrees,trainSetData.X,trainSetData.Y,'FBoot',FBoot,'oobpred','on','NVarToSample',mBest,'names',trainingSet.RF.statsUsed,'splitcriterion','twoing');
%cRF=compact(RF);
%plot(oobError(RF))
%xlabel('# of Trees')
%ylabel('oob Errors')
%saveas(gcf, [suffix '_oobError.fig'])
trainingSet.RF.ProbEstimates=zeros(spotNum,1);
spotTreeProbs=zeros(spotNum,ntrees);
Trees=cell(ntrees,1);
for n=1:ntrees
    nodeNum=1;
    while nodeNum==1
        BagIndex=randi(spotNum,1,spotNum)';
        X=trainSetData.X(BagIndex,:);
        Y=trainSetData.Y(BagIndex,:);
        t=classregtree(X,Y,'nvartosample',mBest,'method','classification','splitcriterion','deviance');
        nodeNum=numnodes(t); % Avoid generating trees with only one node.
    end
    [~,nodes]=eval(t,trainSetData.X);
    ClassProbs=classprob(t,nodes);
    spotTreeProbs(:,n)=ClassProbs(:,2);
    Trees{n}=t;
end
IQRt=0.3;
IQR=iqr(spotTreeProbs,2);
%spotTreeProbs(IQR>IQRt,:)=spotTreeProbs_corr(IQR>IQRt,:);
trainingSet.RF.spotTreeProbs=spotTreeProbs;
Probs=mean(spotTreeProbs,2);
trainingSet.RF.ProbEstimates=Probs;

save(fullfile(pwd,[suffix '_RF.mat']),'Trees');
trainingSet.RF.RFfileName=[suffix '_RF.mat'];

trainingSet.RF.ErrorRate= mean((trainingSet.RF.ProbEstimates>0.5)~=trainSetData.Y);
trainingSet.RF.MSE=mean((trainingSet.RF.ProbEstimates-trainSetData.Y).^2);
trainingSet.RF.IQR=IQR;
trainingSet.RF.IQRthreshold=IQRt;
trainingSet.RF.discordantPortion=mean(IQR>IQRt);
trainingSet.RF.SpotNumTrue=sum(trainSetData.Y);
trainingSet.RF.SpotNumEstimate=sum(Probs>0.5);
trainingSet.RF.quantile=75; 

[g2b b2g]=calculateErrorRange(Probs, IQR, IQRt,trainingSet.RF.quantile);

ub=sum(Probs>0.5)+b2g;
lb=sum(Probs>0.5)-g2b;

trainingSet.RF.SpotNumRange=[lb ub];
trainingSet.RF.Margin=abs(trainingSet.RF.ProbEstimates*2-1);
trainingSet.RF.FileName=['trainingSet_' suffix '.mat'];
trainingSet.RF.ResponseY=trainingSet.RF.ProbEstimates>0.5;
trainingSet.RF.concordantErrorRate=mean(trainingSet.RF.ResponseY(IQR<0.3)~=trainSetData.Y(IQR<0.3));

% version check
if isfield(trainingSet.RF,'UnreliablePortion')
    rmfield(trainingSet.RF,'UnreliablePortion');
end
if isfield(trainingSet.RF,'reliableErrorRate')
    rmfield(trainingSet.RF,'reliableErrorRate');
end



h=figure('Visible','off');
scatter(Probs(trainSetData.Y~=1),IQR(trainSetData.Y~=1),'.','blue')
hold on
scatter(Probs(trainSetData.Y==1),IQR(trainSetData.Y==1),'.','red')
xlabel('Prob Estimates')
ylabel('IQR of Prob Estimates')
title('Training Set')
saveas(h,fullfile(pwd,[suffix '_Train_ProbsIQR.png']))
close(h)


save(fullfile(pwd,['trainingSet_' suffix '.mat']),'trainingSet')
fprintf('Finished training the random forest in %g minutes.\n', toc/60)

end





