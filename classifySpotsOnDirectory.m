function classifySpotsOnDirectory(varargin)
%% ========================================================================
%   Name:       classifySpotsOnDirectory.m
%   Version:    2.0, 5th July 2012
%   Author:     Allison Wu
%   Command:    classifySpotsOnDirectory(toOverWrite*)  *Optional Input
%   Description: a wrapper function that calls classifySpots to execute on all the files on directory
%       - classifySpotsOnDirectory(toOverWrite,trainingSet), optional inputs
%       - toOverWrtie=varargin{1}: [0,1], 0 by default.
%         A flag that tells the code to overwrite spotStats.mat file or not.
%       - trainingSet=varargin{2}:
%         You can specify particular trained random forest to use by loading in the trainingSet.
%       - If a particular trainingSet is specified, the user will be prompted with 2 questions:
%               1) Which channel to apply the trained classifier on?
%               2) What is the probe's name? 
%% ========================================================================

stacks=dir('*_wormGaussianFit.mat');

trainingSetSpecified=0;
toOverWrite=0;

switch length(varargin)
    case 1
        toOverWrite=varargin{1};
    case 2
        toOverWrite=varargin{1};
        trainingSet=varargin{2};
        trainingSetSpecified=1;
end

if trainingSetSpecified
    fprintf('%s is specified as the trainingSet...\n', trainingSet.FileName)
    reply=input('Please specify the probe name: ','s');
    probeName=reply;
    
    % Check which channel to apply the trained classifier on.
    reply=input('Which channel do you want to apply your specified trained classifier on? [alexa, tmr, cy5 , all]: ','s');
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
            case 'all'
                dyeToDo={'alexa','a594','tmr','cy5','cy'};
        end
    end
else
    trainingSet=[];
    dyeToDo={'alexa','a594','tmr','cy5','cy'};
end


for i=1:length(stacks)
    stackName=stacks(i).name;
    [dye, ~, ~, ~,spotStatsFileName]=parseStackNames(regexprep(stackName,'_wormGaussianFit.mat',''));
    load(stacks(i).name)
    
    if sum(strcmpi(dye,dyeToDo))~=0
        if toOverWrite
            fprintf('Doing %...\n', stacks(i).name)
            spotStats=classifySpots(worms,trainingSet);
        else
            if exist(spotStatsFileName,'file')
                fprintf('%s is already done.\n', stacks(i).name)
            else
                fprintf('Doing %...\n', stacks(i).name)
                spotStats=classifySpots(worms,trainingSet);
            end
        end
    end
    
end
end