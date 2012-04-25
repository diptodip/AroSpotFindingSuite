function runInfo=runEvaluateFISHImageStackOnDirectory(directory,dyeIn,cutoffDate)
%  =============================================================
%  Name: runEvaluateFISHImageStackOnDirectory.m
%  Version: 1.4.2, 9 Nov 2011
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%  License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%  Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%  =============================================================
%Function to run evaluateFISHImageStack on a directory so can process a set of images all at once
%20Sep2011 - integrated with bleachCorrection stuff
%21 Sep 2011 Changed arguments passed so can just pass a directory and it decides what
%to do...dye is an optional argument
%Returns string with time and directory and dye run and functionname
runInfo='';
%% Find dyes in directory if not given.  Note that dye names are given
%% here.  will need to change if these change

cd(directory);
if isempty(dyeIn)
    dyes={'cy','tmr','alexa'};
    for di=1:3
        if isempty(dir([dyes{di} '*stk']))
            dyes{di}=[];
        end;
    end;
else
    dyes=dyeIn;
end;

if cutoffDate==[]
    cutoffDate=datenum('2100-09-01');%way far in the future - the program will probably be obsolete by then
end;
disp(['cutoffDate ' datestr(cutoffDate)]);
for di=1:size(dyes,2)
    if ~isempty(dyes{di})
        dye=dyes{di};
        fprintf('Dye: %s |||| Directory: %s\n',dye,pwd);
        files=dir([dye '*stk']);
        endi=length(files);
        numsToRun=1:endi;
        % if size(varargin,2)>1
        %     if length(varargin{2})==1
        %         numsToRun=varargin{2}:endi;
        %     elseif length(varargin{2})>1
        %         numsToRun=varargin{2};
        %     end;
        % end;
        
        probeName=[];
        tStart=tic;
        
        %         if matlabpool('size')>0
        %             parfor gfi=numsToRun
        %                 fprintf('Running gaussianFit #%d named %s\n',gfi,files(gfi).name);
        %                 if files(gfi).datenum<cutoffDate
        %                     worms=evaluateFISHImageStack(files(gfi).name,1);
        %                 else
        %                     fprintf('%s already processed since %s\n',files(gfi).name,datestr(cutoffDate));
        %                 end;
        %
        %             end;
        %         else
        for gfi=numsToRun
            wgff=dir(regexprep(files(gfi).name,'.stk','_wormGaussianFit.mat'));
            
            if ~isempty(wgff)
                fprintf('Running gaussianFit #%d named %s with datestr %s. ',gfi,regexprep(files(gfi).name,'.stk','_wormGaussianFit.mat'),datestr(wgff(1).datenum));
                
                if wgff(1).datenum<cutoffDate
                    worms=evaluateFISHImageStack(files(gfi).name,1);
                    fprintf(' Done at %s\n',datestr(now));
                else
                    fprintf(' already processed after the cutoff date of %s\n',datestr(cutoffDate));
                end;
            else
                fprintf('Running gaussianFit #%d named %s. No wormGaussianFit file.  ',gfi,files(gfi).name);
                worms=evaluateFISHImageStack(files(gfi).name,1);
                fprintf(' Done at %s\n',datestr(now));
            end;
        end;
        %         end;
        
        aa=toc(tStart);
        hours=floor(aa/3600);
        mins=floor((aa-hours*3600)/60);
        seconds=floor(aa-hours*3600-mins*60);
        
        disp(sprintf('Evaluating the directory for dye %s took %d hours %d minutes %d seconds',dye,hours, mins, seconds));
        runInfo=sprintf('%s%s\t%s\t%d:%d:%d\t%s\t%s\n',runInfo,dye,directory,hours,mins,seconds,datestr(clock),mfilename);
    end;
end


