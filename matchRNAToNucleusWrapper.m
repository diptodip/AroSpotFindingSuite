function matchRNAToNucleusWrapper()
%Goes through all nucLocs and wormGF files and makes two new fields with
%the info about the nearest nucleus

%go through all directories: start in SexDet
SexDetDir='/Volumes/rifkinlab/sarifkin/Projects/Worms/SexDet/';
cd(SexDetDir);
dirs=dir;
doBeforeDate=datenum('12-Aug-2012 21:24:59');
for iDir=1:length(dirs)
    
    if dirs(iDir).isdir && ~strcmp(dirs(iDir).name(1),'.')
        
        cd(dirs(iDir).name);
        disp(['Entering ' dirs(iDir).name]);
        system('rm PROBLEM_RNA*');
        
        
        wormGaussianFits=dir('*wormGaussianFit.mat*');
        if ~isempty(wormGaussianFits)
            
            
            parfor i=1:length(wormGaussianFits)
                tic
                if doBeforeDate-wormGaussianFits(i).datenum>0
                    position=regexp(wormGaussianFits(i).name,'_','split');
                    disp(position);
                    position=position{2};
                    if exist(['nucLocations' position '.csv'],'file')
                        ae=load(wormGaussianFits(i).name);
                        %if ~isfield(ae.worms{1},'nucDataVectors')
                        disp(['        Matching ' dirs(iDir).name filesep wormGaussianFits(i).name ' to ' 'nucLocations' position '.csv']);
                        try
                            nucLocs=dlmread(['nucLocations' position '.csv']);
                            worms=matchRNAToNucleus(ae.worms,nucLocs);
                            parsaveWorms(wormGaussianFits(i).name,worms);
                            disp(['        ** Matched ' dirs(iDir).name filesep wormGaussianFits(i).name ' to ' 'nucLocations' position '.csv']);
                        catch ME
                            parsaveProblem(position,ME);
                            disp(['        -- Failed Matching ' dirs(iDir).name filesep wormGaussianFits(i).name ' to ' 'nucLocations' position '.csv']);
                            disp(ME.stack(1).name);
                            disp(ME.stack(1).line);
                            disp(ME.stack(1).file);
                        end;
                        %else
                        %   disp(['        already Done']);
                        %end;
                        
                    else
                        disp(['        ' dirs(iDir).name filesep 'nucLocations' position '.csv does not exist']);
                    end;
                else
                    disp(['        ' dirs(iDir).name filesep 'already Done']);
                end;
                toc
            end;
            
        end;
        disp(['    Finished with ' dirs(iDir).name]);
        
    end;
    cd(SexDetDir);
end;

end

function parsaveWorms(filename,worms)
save(filename,'worms');
end

function parsaveProblem(stackName,error)
save(['PROBLEM_RNAToNUCS_' stackName '.mat'],'error');
end