function classifySpotsWrapper()


%go through all directories: start in SexDet
SexDetDir='/Volumes/rifkinlab/sarifkin/Projects/Worms/SexDet/';
cd(SexDetDir);
dirs=dir;

for iDir=1:length(dirs)
    
    if dirs(iDir).isdir && ~strcmp(dirs(iDir).name(1),'.')
        
        cd(dirs(iDir).name);
        disp(['Entering ' dirs(iDir).name]);
        tss=dir('trainingSet*mat');
        if ~isempty(tss)
            try
                classifySpotsOnDirectory();
            catch ME
                %parsaveProblem(ME);
                disp(['******** PROBLEM in ' dirs(iDir).name]);
            end;
        else
            disp(['No trainingSets in ' dirs(iDir).name]);
        end;
    end;
    
    cd(SexDetDir);
end;

end


%%
function parsaveProblem(error)
save('PROBLEM.mat','error');
end