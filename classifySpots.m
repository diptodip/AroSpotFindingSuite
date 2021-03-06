function spotStats=classifySpots(worms,varargin)

    %% ========================================================================
    %   Name:       classifySpots.m
    %   Version:    2.5.1, 23rd Jul. 2014
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
    %       - spotStats{}.classification is a spotNumber-by-3 matrix which saves [manual, auto, final] classification:
    %               * Manual classification (0, bad spots; 1, good spots; -1, not manually curated)
    %               * Auto classification by random forest
    %               * Final classification: auto classification curated by manual classification
    %       - spotStats{}.locAndClass is a spotNumber-by-4 double matrix with the first three columns specifying the
    %         x-y-z coordinates of each spot and the last column indicating the final classification of each spot.
    %
    %   Files required:
    %       - 'worms' loaded from {dye}_{posNum}_wormGaussianFit.mat,
    %       - trainingSet_**.mat, **_RF.mat
    %   Files generated: {dye}_{stackSuffix}_spotStats.mat
    %
    %   Updates:
    %       - 2014.07.23 : new prediction interval.
    %       - add in version check to detect older version.  If detected, new
    %       stats will be calculated and added.
    %       - update the way of spot number estimation.
    %       - add in the field with location and final classification together.
    %       2013 May 9th:
    %           - use calculateErrorRange.m to calculate error range.
    %% ========================================================================
    if ~isempty(worms)

        %read in parameters
        if exist('Aro_parameters.m','file')
            run('Aro_parameters.m');
        else
            intervalWidth=95;
        end;


        % Find the dye and posNumber.
        [~,segStackName,~]=fileparts(worms{1}.segStackFile);
        prefix=regexprep(segStackName,'_SegStacks','');
        prefix=regexp(prefix,'_','split');
        dye=prefix{1};
        posNumber=prefix{2};
        posNumber=regexprep(posNumber,'Pos','');
        posNumber=regexprep(posNumber,'_','');
        posNumber=str2num(posNumber);
        if ~isempty(posNumber)

            fprintf('dye: %s , position: %d \n', dye, posNumber)

            spotStats=cell(size(worms));
            wormNum=size(worms);



            % Load in the compact random forests.
            disp('Load in the random forests...')
            if ~isempty(varargin)&&~isempty(varargin{1})
                trainingSet=varargin{1};
                fprintf('Using trained classifier linked to %s \n', trainingSet.FileName)
                load(trainingSet.RF.RFfileName);
            else
                t=dir(fullfile(TrainingSetDir,['trainingSet_' dye '**.mat']));
                disp(dye);
                switch length(t)
                    case 0
                        fprintf('Cannot find a trained classifier corresponding to this dye.')
                        name=input('Please specify the correct training set file (full file name): ','s');
                        load(name)
                    case 1
                        fprintf('Using trained classifier linked to %s \n', fullfile(TrainingSetDir,t.name))
                        load(fullfile(TrainingSetDir,t.name));
                    otherwise
                        disp('There are multiple trained classifiers found for this dye:')
                        for k=1:length(t)
                            disp([num2str(k) '): ' t(k).name]);
                        end
                        ttNum=input('Which one do you want to use? Enter NUMBER: ');
                        load(fullfile(TrainingSetDir,t(ttNum).name));
                end
                load(trainingSet.RF.RFfileName);
            end

            statsToUse=trainingSet.RF.statsUsed;
            % Version check
            if ~strcmp('v2.5',worms{1}.version)
                display('Detect an older version. Update the wormGaussianFit with new stats.')
                worms=addStatsToWormGaussian(worms);
            end


            for wi=1:wormNum
                tic

                fprintf('Doing worm %d ...\n',wi)
                if ~isempty(worms{wi}.spotDataVectors)

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
                    %% Run each spot down each tree
                    disp('Running each spot through each tree and calculate the probabilities...')
                    spotTreeProbs=zeros(spotNum,length(Trees));
                    for n=1:length(Trees)
                        [~,nodes]=eval(Trees{n},dataMatrix);
                        ClassProbs=classprob(Trees{n},nodes);
                        spotTreeProbs(:,n)=ClassProbs(:,2);
                    end


                    %% Automatically classify the spot based on calibrated probabilities
                    load parametersForSigmoidProbabilityCalibrationCurve
                    sigfunc=@(A,x)(1./(1+exp(-x*A(1)+A(2))));

                    spotStats{wi}.spotTreeProbs=spotTreeProbs;
                    Probs=sigfunc(parametersForSigmoidProbabilityCalibrationCurve,mean(spotTreeProbs,2));
                    spotStats{wi}.ProbEstimates=Probs;

                    %% Resolve automatic-manual classification conflicts in favor of manual classification
                    % => spotStats{wi}.classification columns:  (#1) -1 if not manually
                    % correccted, 0 if manually corrected bad, 1 if manually corrected
                    % good.  (#2)  automatic classification based on calibrated
                    % probability.  (#3) final classification with manual having
                    % precedence
                    spotStats{wi}.classification=zeros(spotNum,3);
                    spotStats{wi}.classification(:,1)=-1; % won't be -1 if manually corrected.
                    spotStats{wi}.classification(:,2)=Probs>0.5;


                    % Check if the spot is already in the training set.
                    disp('Check if the spot is already in the training set...')
                    spotInfo=[ones(spotNum,1)*posNumber ones(spotNum,1)*wi worms{wi}.spotDataVectors.spotInfoNumberInWorm];
                    [~,iTraining,iInWorm]=intersect(trainingSet.spotInfo(:,1:3),spotInfo,'rows');
                    if ~isempty(iTraining)
                        fprintf('%d spots in %s, worm %d are already in the training set....\n',length(iTraining),[dye '_' num2str(posNumber)],wi)
                        spotStats{wi}.classification(iInWorm,1)=trainingSet.spotInfo(iTraining,4);
                    end

                    % Check if the manual classification doesn't agree with the auto
                    % classification.  Use the manual classification if they don't agree
                    % with each other.
                    manualIndex=spotStats{wi}.classification(:,1)~=-1;%manually corrected
                    diffIndex=spotStats{wi}.classification(:,1)~=spotStats{wi}.classification(:,2);%either automatically classified (:,1)=-1) or manual~=automatic
                    index=(manualIndex+diffIndex)==2; %manually corrected and manual~=automatic
                    spotStats{wi}.classification(:,3)=spotStats{wi}.classification(:,2); %assign column 3 to automatic
                    spotStats{wi}.classification(index,3)=spotStats{wi}.classification(index,1); %assign column 3 to manual where manual ~= automatic
                    if sum(index)~=0
                        fprintf('%d spots in %s, worm %d are already in the training set....\n',length(iTraining),[dye '_' num2str(posNumber)],wi);
                        spotStats{wi}.msg=[ num2str(sum(index)) ' spots out of ' num2str(sum(manualIndex))  ' manually curated spots were classified incorrectly.'];
                    end

                    %% Calculate spot count estimate and the interval estimate
                    spotStats{wi}.intervalWidth=intervalWidth;
                    spotStats{wi}.SpotNumEstimate=sum(spotStats{wi}.classification(:,3)==1);
                    [lbub,dist,sne]=makeSpotCountInterval(spotStats{wi},'spotStats');
                    if sne~=spotStats{wi}.SpotNumEstimate
                        disp('Problem!: spot number estimate equality failure');
                        disp(sne);
                        disp(spotStats{wi}.SpotNumEstimate);
                    end;
                    spotStats{wi}.SpotNumRange=lbub;
                    spotStats{wi}.SpotNumDistribution=dist;




                    %% Final fields
                    spotStats{wi}.trainingSetName=trainingSet.RF.FileName;
                    toc


                    spotStats{wi}.locAndClass=[worms{wi}.spotDataVectors.locationStack spotStats{wi}.classification(:,3)];
                else
                    spotStats{wi}.noSpot=1;
                end

            end

            spotStatsName=[dye '_Pos' num2str(posNumber) '_spotStats.mat'];
            save(fullfile(SpotStatsDir,dye,spotStatsName),'spotStats')
        else
            disp(['posNumber is empty!  prefix is: ' prefix{2}]);
        end;
    else
        disp('This stack is bad. Skip spot classification.')
        spotStats={};
    end
end
