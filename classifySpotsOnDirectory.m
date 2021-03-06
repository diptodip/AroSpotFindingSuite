function classifySpotsOnDirectory(varargin)
    %% ========================================================================
    %   Name:       classifySpotsOnDirectory.m
    %   Version:    2.0.1, 5th July 2012
    %   Author:     Allison Wu
    %   Command:    classifySpotsOnDirectory(toOverWrite,trainingSet,dye*)  *Optional Input
    %   Description: a wrapper function that calls classifySpots to execute on all the files on directory
    %       - classifySpotsOnDirectory(toOverWrite,trainingSet, dye*)
    %       - toOverWrtie=varargin{1}: [0,1], 0 by default.
    %         A flag that tells the code to overwrite spotStats.mat file or not.
    %       - trainingSet=varargin{2}:
    %         You can specify particular trained random forest to use by loading in the trainingSet.
    %       - If a particular trainingSet is specified but the dye is not specified,
    %         the user will be prompted with entering the channel manually.
    %
    %   Update Log:
    %       - 2012.09.18 add in the dye input
    %       - 2013.03.27 small bug fixes.
    %% ========================================================================
    
    %need to predeclare relevant variables
    WormGaussianFitDir='';
    intervalWidth=0.95;
    dyesUsed={};
    run('Aro_parameters.m');
    
    
    trainingSetSpecified=0;
    toOverWrite=0;
    
    switch length(varargin)
        case 1
            toOverWrite=varargin{1};
        case 2
            toOverWrite=varargin{1};
            trainingSet=varargin{2};
            trainingSetSpecified=1;
        case 3
            toOverWrite=varargin{1};
            trainingSet=varargin{2};
            reply=varargin{3};
            trainingSetSpecified=1;
    end
    
    if trainingSetSpecified
        %fprintf('%s is specified as the trainingSet...\n', trainingSet.FileName)
        %probeName=input('Please specify the probe name: ','s');
        
        % Check which channel to apply the trained classifier on.
        if ~exist('reply','var')
            reply=input('Which channel do you want to apply your specified trained classifier on? [alexa, tmr, cy5 , all]: ','s');
        end
        
        if isempty(reply)
            reply='all';
        else
            switch reply
                case {'alexa','a594'}
                    dyeToDo={'alexa','a594'};
                case 'tmr'
                    dyeToDo={'tmr'};
                case {'cy5','cy'}
                    dyeToDo={'cy5','cy'};
                case {'yfp'}
                    dyeToDo={'yfp'};
                case 'all'
                    dyeToDo={'alexa','a594','tmr','cy5','cy','yfp'};
                case 'gold'
                    dyeToDo={'gold'};
            end
        end
    else
        trainingSet=[];
        dyeToDo=dyesUsed;%{'alexa','a594','tmr','cy5','cy'};
    end
    
    switch nestedOrFlatDirectoryStructure
        case 'flat'
            stacks=dir('*_wormGaussianFit.mat');
            for i=1:length(stacks)
                stackName=stacks(i).name;
                [dye, ~, ~, ~,spotStatsFileName]=parseStackNames(regexprep(stackName,'_wormGaussianFit.mat',''));
                w=load(stacks(i).name);
                worms=w.worms;
                if sum(strcmpi(dye,dyeToDo))~=0
                    if toOverWrite
                        fprintf('Doing %...\n', stacks(i).name)
                        classifySpots(worms,trainingSet);
                    else
                        if exist(spotStatsFileName,'file')
                            fprintf('%s is already done.\n', stacks(i).name)
                        else
                            fprintf('Doing %...\n', stacks(i).name)
                            classifySpots(worms,trainingSet);
                        end
                    end
                end               
            end
        case 'nested'
            for iD=1:length(dyeToDo)                
                if exist([WormGaussianFitDir filesep dyeToDo{iD}],'dir')
                    stacks=dir(fullfile(WormGaussianFitDir,dyeToDo{iD},'*_wormGaussianFit.mat'));
                    parfor i=1:length(stacks)
                        stackName=stacks(i).name;
                        [dye, ~, ~, ~,spotStatsFileName]=parseStackNames(regexprep(stackName,'_wormGaussianFit.mat',''));
                        w=load(fullfile(WormGaussianFitDir,dyeToDo{iD},stacks(i).name));
                        worms=w.worms;
                        if sum(strcmpi(dye,dyeToDo))~=0
                            if toOverWrite
                                fprintf('Doing %...\n', stacks(i).name)
                                classifySpots(worms,trainingSet);
                            else
                                if exist(spotStatsFileName,'file')
                                    fprintf('%s is already done.\n', stacks(i).name)
                                else
                                    fprintf('Doing %...\n', stacks(i).name)
                                    classifySpots(worms,trainingSet);
                                end
                            end
                        end
                    end;
                end;          
            end
    end;
end