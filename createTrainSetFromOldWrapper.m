function createTrainSetFromOldWrapper()
%Moves all the old files to Version1.4.Analyses/ (makes the directory too)
%runs the createSegStacks function
%dirs all the SegStacks
%goes through them and loads the old worm file based on the name (removes '_')
%then converts

%go through all directories: start in SexDet
SexDetDir='/Volumes/rifkinlab/sarifkin/Projects/Worms/SexDet/';
cd(SexDetDir);
dirs=dir;
parfor iDir=1:length(dirs)
    
    if dirs(iDir).isdir && ~strcmp(dirs(iDir).name(1),'.')
        
        cd(dirs(iDir).name);
        disp(['Entering ' dirs(iDir).name]);
        
        oldDir='Version1.4.Analyses';
        
        
        %make sure wormGaussianFit is done
        kk=dir('*wormGaussian*');
        if ~isempty(kk)
            if datenum('09-Aug-2012 12:00:00')-kk(end).datenum<0
                
                %         %create oldDirectory
                %         if ~exist(oldDir,'dir')
                %             mkdir(oldDir);
                %         end;
                %
                %         %move things
                %         thingsToMove={'RF*','training*','cy0*worm*','FISH*','tmr0*worm*','alexa0*worm*','cy1*worm*','tmr1*worm*','alexa1*worm*'};
                %
                %         for iSearch=1:length(thingsToMove)
                %             fprintf('mv %s %s/  : %d files to move\n',thingsToMove{iSearch},oldDir,length(dir(thingsToMove{iSearch})));
                %             system(sprintf('mv %s %s/ \n',thingsToMove{iSearch},oldDir));
                %         end;
                %
                %         %make sure all the seg masks are logical
                %         ensureCurrpolysAreLogical();
                if isempty(dir('trainingSet*.mat'))
                    tss=dir([oldDir filesep 'trainingSet*Cel*mat']);
                    if ~isempty(tss)
                        for iT=1:length(tss)
                            parts=regexp(tss(iT).name,'_','split');
                            dye=parts{2};
                            probe=['Cel_' parts{4}(1:end-4)];%-.mat
                            if strcmp('Cel',parts{3})
                                disp(tss(iT).name);
                                createSpotTrainingSetFromPreexistingGoldRejectedSpotsFiles([dye '001.stk'],probe);
                                disp(['Finished with ' tss(iT).name]);
                                
                            end;
                        end;
                    else
                        disp(['No conversions to be done in ' dirs(iDir).name]);
                    end;
                end;
            else
                disp([dirs(iDir).name ' not ready yet']);
            end;
            
        end;
        
    end;
    cd(SexDetDir);
end;

end



%%