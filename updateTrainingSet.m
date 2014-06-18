function trainingSet=updateTrainingSet(trainingSet, worms, spotInfo, varargin)
%% ========================================================================
%   Name:       updateTrainingSet.m
%   Version:    2.5, 25th Apr. 2013
%   Author:     Allison Wu
%   Command:    trainingSet=updateTrainingSet(trainingSet,worms,spotInfo,toRemove*) 
%   Description:
%       - spotInfo=[position_Number, worm_Number, SpotIndexInWorm, classification]: 
%         the information of the spots to be added/removed
%       - The indicated spots are removed if toRemove==1.
%       - This code first checks if the spot is already in the training set:
%               * If it's not, it will add the spot into the training set
%               and recalculate and update the stats.
%               * If it is in the training set and toRemove==1, it removes
%               the spot from the training set and recalculate and update
%               teh stats.
%               * If it is in the training set and toRemove==0, it only
%               updates the classification.
%% ========================================================================

% toRemove=varargin{1} remove or add spot, default=0
% Check if the newly added spot is already in the training set.
%spotInfo
if isempty(varargin)
    toRemove=0;
else
    toRemove=varargin{1};
end
for si=1:size(spotInfo,1)
    [~,~,iTrainingSet]=intersect(spotInfo(si,1:3),trainingSet.spotInfo(:,1:3),'rows');
    
    if isempty(iTrainingSet) % the spot is not in the training set.
        disp('The spot is not in the training set.  Add the spot into the training set and recalculate the stats.')
        trainingSet.spotInfo=[trainingSet.spotInfo;spotInfo(si,:)];
        wi=spotInfo(si,2);
        wormData=worms{wi};
        statNames=fieldnames(worms{wi}.spotDataVectors);
        spotIndex=spotInfo(si,3);
        for st=1:length(statNames)
            
            if ~strcmp(statNames{st},'spotInfoNumberInWorm')
                
                if ~isfield(trainingSet.stats, statNames{st})
                    if ~sum(strcmp(statNames{st},{'dataMat','dataFit'}))
                        trainingSet.stats.(statNames{st})=wormData.spotDataVectors.(statNames{st})(spotIndex,:);
                    else
                        trainingSet.stats.(statNames{st})=wormData.spotDataVectors.(statNames{st})(spotIndex,:,:);
                    end
                else
                    if ~sum(strcmp(statNames{st},{'dataMat','dataFit'}))
                        %display(statNames{st})
                        trainingSet.stats.(statNames{st})=[trainingSet.stats.(statNames{st});wormData.spotDataVectors.(statNames{st})(spotIndex,:)];
                    else
                        trainingSet.stats.(statNames{st})=[trainingSet.stats.(statNames{st});wormData.spotDataVectors.(statNames{st})(spotIndex,:,:)];
                    end
                    
                end
            end
        end
        recalculateStats=1;
        
    else % The spot is already in the training set.
        if toRemove==0 % Do not remove the spot that is already in the training set.
            disp('The spot is already in the training set.  Update the calssification.')
            trainingSet.spotInfo(iTrainingSet,end)=spotInfo(si,end);
            trainingSet.dataMatrix.Y=trainingSet.spotInfo(:,end);
            recalculateStats=0;
        elseif toRemove==1 % Remove the spot that is already in the training set.
            disp('Remove the spot and re-calculate the stats.')
            
            [~,iSpotsLeft]=setdiff(trainingSet.spotInfo(:,1:3),spotInfo(si,1:3),'rows');
            trainingSet.spotInfo=trainingSet.spotInfo(iSpotsLeft,:);
            wi=spotInfo(si,2);
            wormData=worms{wi};
            statNames=fieldnames(worms{wi}.spotDataVectors);
            spotIndex=spotInfo(si,3);
            for st=1:length(statNames)
                
                if ~strcmp(statNames{st},'spotInfoNumberInWorm')
                    if ~sum(strcmp(statNames{st},{'dataMat','dataFit'}))
                        trainingSet.stats.(statNames{st})=trainingSet.stats.(statNames{st})(iSpotsLeft,:);
                    else
                        trainingSet.stats.(statNames{st})=trainingSet.stats.(statNames{st})(iSpotsLeft,:,:);
                    end
                    
                end
            end            
            recalculateStats=1;
        end
    end
    
end


if recalculateStats==1

    % Recalculate SVD
    allDataPixelValues=trainingSet.stats.dataMat(:,:);
    %center data
    trainingSet.allDataCenter=mean(allDataPixelValues,1);
    allDataPixelValuesCentered=allDataPixelValues-repmat(trainingSet.allDataCenter,size(allDataPixelValues,1),1);
    [~,~,v]=svd(allDataPixelValuesCentered,0);
    trainingSet.svdBasisRightMultiplier=(v')^(-1);
    rotatedAllDataPixelValues=allDataPixelValuesCentered*trainingSet.svdBasisRightMultiplier;
    %trainingSet.stats.sv=zeros(length(trainingSet.spotInfo),5);
    for i=1:5
        %take the first five coordinates of in the new basis
        trainingSet.stats.(['sv' num2str(i)])=rotatedAllDataPixelValues(:,i);
    end
    
    % Stores a dataMatrix ready for Matlab random forest.
    statsToUse=trainingSet.statsUsed;
    
    % Update the dataMatrix
    trainingSet.dataMatrix.X=zeros(size(trainingSet.spotInfo,1),length(statsToUse));
    startj=1;
    for j=1:length(statsToUse)
        stat=trainingSet.stats.(statsToUse{j});
        trainingSet.dataMatrix.X(:,j)=stat;
    end
    trainingSet.dataMatrix.Y=trainingSet.spotInfo(:,end);
end

end