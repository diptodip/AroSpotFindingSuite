function convertWormFitFilesWrapper()
%Moves all the old files to Version1.4.Analyses/ (makes the directory too)
%runs the createSegStacks function
%dirs all the SegStacks
%goes through them and loads the old worm file based on the name (removes '_')
%then converts

%go through all directories: start in SexDet
SexDetDir='/Volumes/rifkinlab/sarifkin/Projects/Worms/SexDet/';
cd(SexDetDir);
dirs=dir;
for iDir=1:length(dirs)
    
    if dirs(iDir).isdir && ~strcmp(dirs(iDir).name(1),'.')
        
        cd(dirs(iDir).name);
        disp(['Entering ' dirs(iDir).name]);
        
        oldDir='Version1.4.Analyses';
        
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
        
        wormGaussianFits=dir([oldDir filesep '*wormGaussianFit*']);
        if ~isempty(wormGaussianFits)
            
            
            %create SegStacks
%             disp('Creating SegStacks');
%             tic
%             createSegImages('stk');
%             disp('Done creating SegStacks');
%             toc
            dyes={'cy','alexa','tmr'};
            for iDye=1:3
                tic
                segstacks=dir([dyes{iDye} '*SegStacks*']);
                parfor i=1:length(segstacks)
                    prefix=regexprep(segstacks(i).name,'_SegStacks.mat','');
                    shortPrefix=regexprep(prefix,'_','');
                    %if ~exist([prefix '_wormGaussianFit.mat'],'file')
                        if exist([oldDir filesep shortPrefix '_wormGaussianFit.mat'],'file')
                            old=load([oldDir filesep shortPrefix '_wormGaussianFit.mat']);
                            disp(['converting ' dirs(iDir).name filesep oldDir filesep shortPrefix '_wormGaussianFit.mat']);
                            convertWormFitFile1p4To2p0(old,prefix);
                        else
                            disp([oldDir filesep shortPrefix '_wormGaussianFit.mat does not exist']);
                        end;
                    %else
                        %disp([prefix '_wormGaussianFit.mat' ' already exists']);
                    %end;
                end;
                toc
            end;
            disp(['Finished with ' dirs(iDir).name]);
            
        else
            disp(['No conversions to be done in ' dirs(iDir).name]);
        end;
    end;
    cd(SexDetDir);
end;

end