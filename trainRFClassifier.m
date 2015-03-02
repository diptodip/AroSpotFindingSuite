function trainingSet=trainRFClassifier(trainingSet,varargin)
%% ============================================================
%   Name:       trainRFClassifier.m
%   Version:    2.5.4, 9 Aug. 2014
%   Author:     Allison Wu
%   Command: trainingSet=trainRFClassifier(trainingSet,suffix*,ntrees*,FBoot*,runVarFeatureSel*)
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
%               * SpotNumEstimate: estimate of the total number of spots
%               (sum over the number of reliable good spots and the
%               probability estimates of unreliable spots.)
%               * SpotNumRange: estimated range of the total number of
%               spots from randomization test with quantile range specified in quantileRange.
%               * ErrorRate: training set error rate
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
%       2014 July 29th:
%           - use calibrated probability estimates for prediction interval
%           estimation.
%		2014 Aug 9th:
%			- Changed input to param-value pairs. Added option to skip the variable and
%			feature selection to save time when in the middle of reviewFISHClassification
%% =============================================================
tic
RFparameters
p=inputParser;
p.addRequired('trainingSet',@isstruct);
p.addParamValue('suffix',[],@isstr);
p.addParamValue('ntrees',1000,@isscalar);
p.addParamValue('FBoot',1,@isscalar);
p.addParamValue('runVarFeatureSel',true,@islogical);
p.addParamValue('readParameterFile',true,@islogical);
p.addParamValue('nTreeTry',500,@isscalar);
p.addParamValue('improve',.01,@isscalar);
p.addParamValue('stepFactor',1,@isscalar);
p.addParamValue('intervalWidth',95,@isscalar);
p.addParamValue('percentileThresholdForOOBPermutedVarDeltaError',25,@isscalar);
p.parse(trainingSet,varargin{:});
trainingSet=p.Results.trainingSet;

if isempty(p.Results.suffix)
    [~,suffix,~]=fileparts(trainingSet.FileName);
    suffix=strrep(suffix,'trainingSet_','');
else
	suffix=p.Results.suffix;
end;
if p.Results.readParameterFile && exist('Aro_parameters.m','file')
   run('Aro_parameters.m');
else
    ntrees=p.Results.ntrees;
    FBoot=p.Results.FBoot;
    nTreeTry=p.Results.nTreeTry;
    improve=p.Results.improve;
    stepFactor=p.Results.stepFactor;
    intervalWidth=p.Results.intervalWidth;
    percentileThresholdForOOBPermutedVarDeltaError=p.Results.percentileThresholdForOOBPermutedVarDeltaError;
end;
runVarFeatureSel=p.Results.runVarFeatureSel;


if isfield(trainingSet,'RF') && runVarFeatureSel
    trainingSet=rmfield(trainingSet,'RF');
end

% Check if new stats are added.
updateTrainingSet=false;
statsToAddIn2_5Version={'absDeltaPlusSign','deltaPlusSign','absPlusSignDelta','plusSignPvalue',...
    'absDeltaStarSign','deltaStarSign','absStarSignDelta','starSignPvalue',...
    'absDeltaCenterBox','deltaCenterBox','absCenterBoxDelta','centerBoxPvalue',...
    'ratioSigmaXY','totalAreaRandPvalue','cumSumPrctile90RP','cumSumPrctile70RP','cumSumPrctile50RP','cumSumPrctile30RP',...
    'cumSumPrctile90','cumSumPrctile70','cumSumPrctile50','cumSumPrctile30'};

if length(intersect(statsToAddIn2_5Version,trainingSet.statsUsed))~=length(statsToAddIn2_5Version)
    updateTrainingSet=true;
end;
% 
% if ~isfield(trainingSet,'version')
%     updateTrainingSet=true;
% elseif isempty(strfind(trainingSet.version, 'ver. 2.5'))
%     updateTrainingSet=true;
% end;
if updateTrainingSet
    display('Detect an older version. Update the trainingSet with new stats.')
    trainingSet=addStatsToTrainingSet(trainingSet);
end

disp(['Suffix is: ' suffix]);

trainingSet.RF.Version='New method of estimating spot numbers, Apr. 2013';
spotNum=length(trainingSet.spotInfo);
trainingSet.RF.nTrees=ntrees;
trainingSet.RF.FBoot=FBoot;
trainSetData.X=trainingSet.dataMatrix.X;
trainSetData.Y=trainingSet.dataMatrix.Y;

if runVarFeatureSel %if 0 this saves time (e.g. in the middle of reviewFISHClassification)
	%% Variable selection
	% Finding the variables that do not have much predicting power in this
	% training set...
	disp('Leaving out variables that are not important....')
	disp('Variables that are left out:')

	testRF=TreeBagger(1000,trainSetData.X,trainSetData.Y,'FBoot',FBoot,'OOBVarImp','on','splitcriterion','deviance');
	VarImp=testRF.OOBPermutedVarDeltaError;
	threshold=prctile(VarImp,percentileThresholdForOOBPermutedVarDeltaError);
	trainSetData.X=trainSetData.X(:,VarImp>threshold);
	trainingSet.RF.VarLeftOut=trainingSet.statsUsed(VarImp<threshold);
	trainingSet.statsUsed(VarImp<threshold)
	trainingSet.RF.statsUsed=trainingSet.statsUsed(VarImp>threshold);
	trainingSet.RF.VarImpThreshold=threshold;
	trainingSet.RF.VarImp=VarImp;
	trainingSet.RF.dataMatrixUsed=trainSetData.X;

	%% Choose the number of features
	% Find the opitmal number of features used to build each tree.
	% Modified based on tuneRF in R.
	disp('Looking for the optimal number of features to sample....')
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
		% 2014.05.18 test
		%errorCurr
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
else%runVarFeatureSel==0
	%Need to adjust the X data so that it just has the correct variables
	trainSetData.X=trainSetData.X(:,trainingSet.RF.VarImp>trainingSet.RF.VarImpThreshold);
end;
%% Build the forest

%% Calculate the class probabilities at each leaf node in each decision tree.
fprintf('Generating a random forest with %d trees and NVarToSample = %d.... \n', ntrees,trainingSet.RF.NVarToSample)
%RF=TreeBagger(ntrees,trainSetData.X,trainSetData.Y,'FBoot',FBoot,'oobpred','on','NVarToSample',trainingSet.RF.NVarToSample,'names',trainingSet.RF.statsUsed,'splitcriterion','twoing');
%cRF=compact(RF);
%plot(oobError(RF))
%xlabel('# of Trees')
%ylabel('oob Errors')
%saveas(gcf, [suffix '_oobError.fig'])
trainingSet.RF.ProbEstimates=zeros(spotNum,1);
spotTreeProbs=zeros(spotNum,ntrees);
Trees=cell(ntrees,1);
BagIndices=cell(ntrees,1);
for n=1:ntrees
    nodeNum=1;
    while nodeNum==1
        BagIndex=randi(spotNum,1,spotNum)';
        X=trainSetData.X(BagIndex,:);
        Y=trainSetData.Y(BagIndex,:);
        t=classregtree(X,Y,'nvartosample',trainingSet.RF.NVarToSample,'method','classification','splitcriterion','deviance');
        nodeNum=numnodes(t); % Avoid generating trees with only one node.
    end
    [~,nodes]=eval(t,trainSetData.X);
    ClassProbs=classprob(t,nodes);
    spotTreeProbs(:,n)=ClassProbs(:,2);
    BagIndices{n}=BagIndex;
    Trees{n}=t;
end


%% Calibrate the probabilities

trainingSet.RF.spotTreeProbs=spotTreeProbs;
Probs=calibrateProbabilities(mean(spotTreeProbs,2));
trainingSet.RF.ProbEstimates=Probs;
trainingSet.RF.RFfileName=fullfile(TrainingSetDir,[suffix '_RF.mat']);
save(trainingSet.RF.RFfileName,'Trees','BagIndices','-v7.3');
trainingSet.RF.ErrorRate= mean((trainingSet.RF.ProbEstimates>0.5)~=trainSetData.Y);
trainingSet.RF.SpotNumTrue=sum(trainSetData.Y);
trainingSet.RF.SpotNumEstimate=sum(Probs>0.5);


%% Make interval estimate
trainingSet.RF.intervalWidth=intervalWidth;
[lbub,dist,~]=makeSpotCountInterval(trainingSet.RF,'trainingSet');
trainingSet.RF.SpotNumRange=lbub;
trainingSet.RF.SpotNumDistribution=dist;

%% Include other fields
trainingSet.RF.Margin=abs(trainingSet.RF.ProbEstimates*2-1);
trainingSet.RF.FileName=fullfile(TrainingSetDir,['trainingSet_' suffix '.mat']);
trainingSet.RF.ResponseY=trainingSet.RF.ProbEstimates>0.5;

%% version check
if isfield(trainingSet.RF,'UnreliablePortion')
    trainingSet.RF=rmfield(trainingSet.RF,'UnreliablePortion');
end
if isfield(trainingSet.RF,'reliableErrorRate')
    trainingSet.RF=rmfield(trainingSet.RF,'reliableErrorRate');
end


%% Save the training set
save(fullfile(TrainingSetDir,['trainingSet_' suffix '.mat']),'trainingSet','-v7.3')
fprintf('Finished training the random forest in %g minutes.\n', toc/60)

end
