function convertOldTrainSetWrapper()
%Goes through and converts all old training sets to new format
%go through all directories: start in SexDet
SexDetDir='/Volumes/rifkinlab/sarifkin/Projects/Worms/SexDet/';
cd(SexDetDir);
dirs=dir;
for iDir=1:length(dirs)
    if dirs(iDir).isdir && ~strcmp(dirs(iDir).name(1),'.')
        cd(dirs(iDir).name);
        disp(['Entering ' dirs(iDir).name]);
        
        oldDir='Version1.4.Analyses';
        if exist(oldDir,'dir')
            
            trainSets=dir([oldDir filesep 'trainingSet_*.mat']);
            if ~isempty(trainSets)
                for i=1:length(trainSets)
                    %if ~exist(trainSets(i).name)
                        disp(['Converting ' oldDir filesep trainSets(i).name ' to ' trainSets(i).name]);
                        a=load([oldDir filesep trainSets(i).name]);
                        newTrainingSet=convertOldTrainSet(a.trainingSet);
                        parsaveTS(trainSets(i).name,newTrainingSet);
                    %else
                        %disp([trainSets(i).name ' already exists']);
                    %end;
                end;
                
                
                disp(['Finished with ' dirs(iDir).name]);
                
            else
                disp(['No conversions to be done in ' dirs(iDir).name]);
            end;
        end;
        cd(SexDetDir);
    end;
    
end;
end


function parsaveTS(fileName,trainingSet)%6Aug12 SR
%http://www.mathworks.com/support/solutions/en/data/1-D8103H/index.html?product=DM&solution=1-D8103H
%Takes care of the problem of saving within parfor loops
save(fileName, 'trainingSet');
end