function spotStats=classifySpots(worms,varargin)
%% ========================================================================
%   Name:       classifySpots.m
%   Version:    2.0, 5th July 2012
%   Author:     Allison Wu
%   Command:    spotStats=classifySpots(worms,trainingSet*) *Optional Input
%   Description: classify the spots using the trained classifier
%       - take in the loaded worms cell array from {dye}_{posNum}_wormGaussianFit.mat
%       - spotStats=classifySpots(worms)
%         It will automatically try to find the trainingSet_{dye}_**.mat.
%         If no files found, it will ask the user to input the file name directly.
%         If multiple files are found, it will ask the user to choose one
%         of the files.
%         After the trainingSet.mat file is specified, it will find the
%         related RF.mat file.
%       - spotStats=classifySpots(worms,trainingSet) 
%         It specifies a particular training set and its related trained 
%         Random Forest to use.  You need to load in the trainingSet 
%         stucture variable first.  
%       - All the statistics for the spots within each worm is saved in the 
%         spotStats.mat file. (All the fields are the same as in the trainingSet.)
%       - spotStats{}.classification is a spotNumber*3 matrix which saves [manual, auto, final] classification:
%               * Manual classification (0, bad spots; 1, good spots; -1, not manually curated)
%               * Auto classification by random forest
%               * Final classification: auto classification curated by manual classification
%       
%   Files required: 
%       - 'worms' loaded from {dye}_{posNum}_wormGaussianFit.mat,
%       - trainingSet_**.mat, **_RF.mat
%   Files generated: {dye}_{stackSuffix}_spotStats.mat    
%   
%% ========================================================================
if ~isempty(worms)

    % Find the dye and posNumber.
    segStackName=worms{1}.segStackFile;
    prefix=regexprep(segStackName,'_SegStacks.mat','');
    prefix=regexp(prefix,'_','split');
    dye=prefix{1};
    posNumber=prefix{2};
    posNumber=regexprep(posNumber,'Pos','');
    posNumber=regexprep(posNumber,'_','');
    posNumber=str2num(posNumber);
    
    fprintf('dye: %s , position: %d \n', dye, posNumber)
    
    spotStats=cell(size(worms));
    wormNum=size(worms);
    
    
    
    % Load in the compact random forests.
    disp('Load in the random forests...')
    if ~isempty(varargin)&&~isempty(varargin{1})
        fprintf('Using trained classifier linked to %s \n', trainingSet.FileName)
        trainingSet=varargin{1};
        load(trainingSet.RF.RFfileName);
    else
        t=dir(['trainingSet_' dye '**.mat']);
        switch length(t)
            case 0
                fprintf('Cannot find a trained classifier corresponding to this dye.')
                name=input('Please specify the correct training set file (full file name): ','s');
                load(name)
            case 1
                fprintf('Using trained classifier linked to %s \n', t.name)
                load(t.name);
            otherwise
                disp('There are multiple trained classifiers found for this dye:')
                for k=1:length(t)
                    disp([num2str(k) '): ' t(k).name])
                end
                ttNum=input('Which one do you want to use? Enter NUMBER: ');
                load(t(ttNum).name)
        end
        load(trainingSet.RF.RFfileName);
    end
    
    statsToUse=trainingSet.RF.statsUsed;
    
    for wi=1:wormNum
        tic
        fprintf('Doing worm %d ...\n',wi)
        spotNum=length(worms{wi}.spotDataVectors.rawValue);
        allDataCenter=repmat(trainingSet.allDataCenter,[spotNum,1]);
        % Need to add in SVD stats.
        dataInSVDBasis=(worms{wi}.spotDataVectors.dataMat(:,:)-allDataCenter)*trainingSet.svdBasisRightMultiplier;
        for k=1:5
            worms{wi}.spotDataVectors.(['sv' num2str(k)])=dataInSVDBasis(:,k);
        end
        
        % Generate a data matrix ready for MatLab random forest.
        % Create dataMatrix (with predictor X and response Y) for Matlab Random Forest
        dataMatrix=zeros(spotNum,length(statsToUse));
        for j=1:length(statsToUse)
            dataMatrix(:,j)=worms{wi}.spotDataVectors.(statsToUse{j});
        end
        spotStats{wi}.dataMatrix=dataMatrix;
        % Classify spots
        disp('Running each spot through each tree and calculate the probabilities...')
        spotTreeProbs=zeros(spotNum,length(Trees));
        for n=1:length(Trees)
            [~,nodes]=eval(Trees{n},dataMatrix);
            ClassProbs=classprob(Trees{n},nodes);
             spotTreeProbs(:,n)=ClassProbs(:,2);
        end
        
        spotStats{wi}.spotTreeProbs=spotTreeProbs;
        Probs=mean(spotTreeProbs,2);
        IQR=iqr(spotTreeProbs,2);
        IQRt=trainingSet.RF.IQRthreshold;
        spotStats{wi}.ProbEstimates=Probs;
        %spotStats{wi}.wSpotTreeProbs=wSpotTreeProbs;
        spotStats{wi}.SpotNumEstimate=sum(Probs(IQR<IQRt)>0.5)+sum(Probs(IQR>IQRt));
        randSpotNum=binornd(1,spotTreeProbs(IQR>IQRt,:),size(spotTreeProbs(IQR>IQRt,:)));
        range=quantile(sum(randSpotNum,1),trainingSet.RF.quantileRange);
        spotStats{wi}.SpotNumRange=sum(Probs(IQR<IQRt)>0.5)+range;
        spotStats{wi}.quantileRange=trainingSet.RF.quantileRange;
        spotStats{wi}.Margin=abs(Probs*2-1);
        spotStats{wi}.IQR=IQR;
        spotStats{wi}.UnreliablePortion=mean(IQR>IQRt);

        %spotStats{wi}.classification=[manual,auto,final]
        spotStats{wi}.classification=zeros(spotNum,3); 
        spotStats{wi}.classification(:,1)=-1; % won't be -1 if manually corrected.
        spotStats{wi}.classification(:,2)=Probs>0.5;
        
                
        % Check if the spot is already in the training set.
        disp('Check if the spot is already in the training set...')
        spotInfo=[ones(spotNum,1)*posNumber ones(spotNum,1)*wi worms{wi}.spotDataVectors.spotInfoNumberInWorm];
        [~,iTraining,iInWorm]=intersect(trainingSet.spotInfo(:,1:3),spotInfo,'rows');
        if ~isempty(iTraining)
            fprintf('%d spots are already in the training set....\n',length(iTraining))
            spotStats{wi}.classification(iInWorm,1)=trainingSet.spotInfo(iTraining,4);
        end
        
        % Check if the manual classification doesn't agree with the auto
        % classification.  Use the manual classification if they don't agree
        % with each other.
        manualIndex=spotStats{wi}.classification(:,1)~=-1;
        diffIndex=spotStats{wi}.classification(:,1)~=spotStats{wi}.classification(:,2);
        index=(manualIndex+diffIndex)==2;
        spotStats{wi}.classification(:,3)=spotStats{wi}.classification(:,2);
        spotStats{wi}.classification(index,3)=spotStats{wi}.classification(index,1);
        if sum(index)~=0
            fprintf('%d spots out of  %d manually curated spots were classified incorrectly.\n', sum(index),sum(manualIndex))
            spotStats{wi}.msg=[ num2str(sum(index)) ' spots out of ' num2str(sum(manualIndex))  ' manually curated spots were classified incorrectly.'];
        end
        %spotStats{wi}.spotNumFinal=spotStats{wi}.SpotNumEstimate-;      
        toc
    spotStats{wi}.trainingSetName=trainingSet.RF.FileName;
    end
    
    spotStatsName=[dye '_Pos' num2str(posNumber) '_spotStats.mat'];
    save(spotStatsName,'spotStats')
else
    disp('This stack is bad. Skip spot classification.')
end
end