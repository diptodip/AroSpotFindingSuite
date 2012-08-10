function trainRFClassifierWrapper()


%go through all directories: start in SexDet
SexDetDir='/Volumes/rifkinlab/sarifkin/Projects/Worms/SexDet/';
cd(SexDetDir);
dirs=dir;

parfor iDir=1:length(dirs)
    
    if dirs(iDir).isdir && ~strcmp(dirs(iDir).name(1),'.')
        
        cd(dirs(iDir).name);
        disp(['Entering ' dirs(iDir).name]);
        tss=dir('trainingSet*mat');
        if ~isempty(tss)
            for iT=1:length(tss)
                disp(['Doing ' tss(iT).name]);
                ts=load(tss(iT).name);
                try
                    trainRFClassifier(ts.trainingSet);
                catch ME
                    fprintf('\n\n\n\n******************************\n\n%s failed\n\n******************\n\n\n\n\n\n\n\n',[dirs(iDir).name filesep tss(iT).name])
                end;
                disp(['Finished with ' tss(iT).name]);
                
            end;
        else
            disp(['No trainingSets in ' dirs(iDir).name]);
        end;
    end;
    
    cd(SexDetDir);
end;

end

function parsaveTS(filename,trainingSet)
save(filename,'trainingSet');
end

%%