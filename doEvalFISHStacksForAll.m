function doEvalFISHStacksForAll(varargin)
%% ========================================================================
%   Name:       doEvalFISHStacksForAll.m
%   Version:    2.0, 5th July 2012
%   Author:     Allison Wu
%   Command:    doEvalFISHStacksForAll(toOverWrite*) *Optional Input
%   Description:
%       - a wrapper function that do evalFISHStacks on all the segStacks.mat files on the directory.
%       - toOverWrite=0 (by default), will skip the SegStacks.mat files
%       that already have corresponding wormGassianFit.mat files
%       - toOverWrite=1, it will not detect the existence of
%       wormGaussianFit.mat files and therefore, overwrites all the
%       wormGausianFit.mat files that exist.
%% ========================================================================

d=dir('**_SegStacks.mat')

if isempty(varargin)
    toOverWrite=0;
else
    toOverWrite=varargin{1};
end

for k=1:length(d)
    [dye, stackSuffix, wormFitName, ~,~]=parseStackNames(regexprep(d(k).name,'_SegStacks.mat',''));
    if ~sum(strcmp(dye,{'dapi','trans'}))
        if toOverWrite % Will overwrite all the wormGaussianFit.mat files
            fprintf('Evaluating the image stack %s ....\n', d(k).name)
            evalFISHStacks(d(k).name);
        else % detects the existence of wormGaussianFit.mat files and skip the ones already done
            if exist(wormFitName,'file')
                fprintf('Position %s in %s channel is already evaluated.\n', stackSuffix,dye)
            else
                fprintf('Evaluating the image stack %s ....\n', d(k).name)
                evalFISHStacks(d(k).name);
            end
        end
    end
end




end