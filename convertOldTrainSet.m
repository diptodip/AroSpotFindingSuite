function trainingSet=convertOldTrainSet(trainingSet)
if ~isfield(trainingSet,'version')
    trainingSet_old=trainingSet;
    clear trainingSet
    spotNum=length(trainingSet_old.spotInfo);
    trainingSet.spotInfo=zeros(spotNum,4);
    disp('Constructing the spotInfo field...')
    for k=1:spotNum
        wormNum=trainingSet_old.spotInfo{k}.wormNumber;
        posNum=str2num(cell2mat(regexp(trainingSet_old.spotInfo{k}.stackSuffix,'\d+','match')));
        if isfield(trainingSet_old.spotInfo{k},'spotInfoNumberInWorm')
            trainingSet.spotInfo(k,:)=[posNum wormNum trainingSet_old.spotInfo{k}.spotInfoNumberInWorm trainingSet_old.spotInfo{k}.classification.manual];  % Don't know where to find spotNumberInWorm yet.
        else
            
            %use location info if spot number isn't there
            %first load the wormGaussianFit file
            spotInfoNumberInWorm=-1;
            load([trainingSet_old.spotInfo{k}.dye '_' trainingSet_old.spotInfo{k}.stackSuffix '_wormGaussianFit.mat']);
            for iS=1:length(worms{wormNum}.spotDataVector.locationStack)
                if isequal(worms{wormNum}.spotDataVector.locationStack(iS,:),trainingSet_old.spotInfo{k}.locations.stack)
                    disp(['found spot number: ' num2str(iS)]);
                    spotInfoNumberInWorm=iS;
                    break
                end;
            end;
            
            
            
            trainingSet.spotInfo(k,:)=[posNum wormNum spotInfoNumberInWorm trainingSet_old.spotInfo{k}.classification.manual];
            %Some of them somehow don't have the spotInfoNumberInWorm
            %field.  Need to look into the wormGaussianFit files.
        end
    end
    
    disp('Constructing the stats field...')
    fieldsToAdd=fields(trainingSet_old.spotInfo{1}.stat.statValues);
    trainingSet.stats.locationStack=zeros(spotNum,3);
    % Use the fields from old format.  The fields might be fewer.  Need to
    % check!
    trainingSet.stats.dataFit=zeros(spotNum,7,7);
    trainingSet.stats.dataMat=zeros(spotNum,7,7);
    for k=1:spotNum
        for fta=1:length(fieldsToAdd)
        if ~isfield(trainingSet.stats, fieldsToAdd{fta})
            if ~sum(strcmp(fieldsToAdd{fta},{'dataMat','dataFit'}))
                trainingSet.stats.(fieldsToAdd{fta})=trainingSet_old.spotInfo{k}.stat.statValues.(fieldsToAdd{fta});
            else
                trainingSet.stats.(fieldsToAdd{fta})(k,:,:)=trainingSet_old.spotInfo{k}.stat.statValues.(fieldsToAdd{fta})(:,:);
            end
        else
            if ~sum(strcmp(fieldsToAdd{fta},{'dataMat','dataFit'}))
                trainingSet.stats.(fieldsToAdd{fta})=[trainingSet.stats.(fieldsToAdd{fta});trainingSet_old.spotInfo{k}.stat.statValues.(fieldsToAdd{fta})];
            else
                trainingSet.stats.(fieldsToAdd{fta})(k,:,:)=trainingSet_old.spotInfo{k}.stat.statValues.(fieldsToAdd{fta})(:,:);
            end
        end
        end
        trainingSet.stats.locationStack(k,:)=trainingSet_old.spotInfo{k}.locations.worm;
        trainingSet.stats.dataMat(k,:,:)=trainingSet_old.spotInfo{k}.dataMat;
        
    end
    
    trainingSet.allDataCenter=trainingSet_old.allDataCenter;
    trainingSet.svdBasisRightMultiplier=trainingSet_old.svdBasisRightMultiplier;
    trainingSet.statsUsed=fieldsToAdd;
    trainingSet.version='ver. 2.0 - converted';
    trainingSet.FileName=trainingSet_old.name;
    % Stores a dataMatrix ready for Matlab random forest.
statsToUse = {'intensity';'rawIntensity';'totalHeight';'sigmax';'sigmay';'estimatedFloor';'scnmse';'scnrmse';'scr';'scd';'sce';
    'prctile_50';    'prctile_60'  ;  'prctile_70'  ;  'prctile_80'  ; 'prctile_90';
    'fraction_center';    'fraction_plusSign'  ;  'fraction_3box'  ;  'fraction_5star'  ;  'fraction_5box';    'fraction_7star' ; 'fraction_3ring';
    'raw_center';    'raw_plusSign'  ;  'raw_3box'  ;  'raw_5star'  ;  'raw_5box';    'raw_7star' ; 'raw_3ring';
    'total_area';'sv1';'sv2';'sv3';'sv4';'sv5'};

trainingSet.statsUsed=statsToUse;

% Create dataMatrix (with predictor X and response Y) for Matlab Random Forest
trainingSet.dataMatrix.X=zeros(spotNum,length(statsToUse));
startj=1;
for j=1:length(statsToUse)
    stat=trainingSet.stats.(statsToUse{j});
    endj=startj-1+size(stat,2);
    trainingSet.dataMatrix.X(:,startj:endj)=stat;
    startj=endj+1;
end
trainingSet.dataMatrix.Y=trainingSet.spotInfo(:,end);

    % missing these fields: filteredValue, rawValue, spotRank
disp('Training set is converted.')
if sum(trainingSet.spotInfo(:,3)==-1)>0
    fprintf('There are %d spots without spot index. \n', sum(trainingSet.spotInfo(:,3)==-1))
    reply=input('It will be a problem in future analyses. Do you want to just remove them? Y/N [Y]: ','s');
    if isempty(reply)
        reply='Y';
    end
    
    if strcmpi(reply,'n')
        disp('If you do not want to remove them, please make sure the wormGaussianFit files are under the same directory.')
        reply2=input('Are the wormGaussianFit files under the same directory? Y/N [Y]');
        if isempty(reply2)
            reply2='y';
        end
        if strcmpi(reply2,'n')
            return
        else
            
            % Look for the worms
        end
    elseif strcmpi(reply,'y')
        index=(trainingSet.spotInfo(:,3)~=-1);
        trainingSet.spotInfo=trainingSet.spotInfo(index,:);
        trainingSet.dataMatrix.X=trainingSet.dataMatrix.X(index,:);
        trainingSet.dataMatrix.Y=trainingSet.dataMatrix.Y(index,:);
        fieldsToAdd=fields(trainingSet.stats);
        for k=1:length(fieldsToAdd)
            if ~sum(strcmp(fieldsToAdd{k},{'dataMat','dataFit'}))
                trainingSet.stats.(fieldsToAdd{fta})=trainingSet.stats.(fieldsToAdd{fta})(index,:);
            else
                trainingSet.stats.(fieldsToAdd{fta})=trainingSet.stats.(fieldsToAdd{fta})(index,:,:);
            end
        end
        
        
    end
else
end


else
    fprintf('The version used to generate this training set is %s . \n', trainingSet.version)
    
end
end