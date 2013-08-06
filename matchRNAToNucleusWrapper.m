function matchRNAToNucleusWrapper(varargin)

%matchRNAToNucleus takes as input
%worms (required) - from wormGaussianFitFiles
%nucLocations %optional
%spotStats %optional
%outputs - it saves a new wormGaussianFitFile

%This collates info from a directory into a big matrix
%data structure for nuclei in a directory
%struct with spotNum, U, L just like wormData
%spotNum: matrix
%each row is a nucleus
%columns:
% 1) nucleusMatrixIndex(row)
% 2) StackPosIndex
% 3) embIndexInStack
% 4) nucIndexInEmb
% 5) numNucsInEmb
% 6) Time from convertNucleiToTime2.m (includes some randomness)
% 7) row - relative to emb mask
% 8) col - relative to emb mask
% 9) z - relative to emb mask
% 10..12) dye_estimates
%
%U matrix
%nuclei (rows) dyes (columns) this is error up for each nucleus
%
%L matrix
%nuclei (rows) dyes (columns) this is error down for each nucleus



%go through directories: start in SexDet
SexDetDir='/Volumes/rifkinlab/sarifkin/Projects/Worms/SexDet/';
cd(SexDetDir);
doBeforeDate=datenum('25-Mar-2013 01:24:59');

if size(varargin,2)>0
    [~,dirs(1).name]=fileparts(varargin{1});
    dirs(1).isdir=1;
else
    dirs=dir;
end;
for iDir=1:length(dirs)
    
    if dirs(iDir).isdir && ~strcmp(dirs(iDir).name(1),'.')
        
        cd(dirs(iDir).name);
        disp(['Entering ' dirs(iDir).name]);
        
        %Check if the wormData_byNum exists and whether it is before
        %datenum
        disp('Checking whether wormData_byNuc file already exists');
        wdb=dir(['wormDataByNuc_' dirs(iDir).name '*']);
        %disp(wdb);
        %disp(['wormDataByNuc_' dirs(iDir).name]);
        
        if ~isempty(wdb)
            disp('Already exists...');
            if doBeforeDate-wdb(1).datenum<=0 && ~strcmp(dirs(iDir).name,'3_1_09_N2_25C_xol1cy5_sdc2tmr') && ~strcmp(dirs(iDir).name,'5_29_09_N2_25C_sex1tmr_xol1cy5')
                disp('Recently...moving on...');
                cd(SexDetDir);
                continue
            end;
        end;
        
        disp('Okay to do this directory...');
        system('rm PROBLEM_RNA*');
        
        
        
        %first make sure an appropriate trainingSet is in here.  don't use
        %training sets here but is a good way to check whether this is a
        %directory to run
        tsToUse=checkTrainingSetToUse(pwd);
        if ~isempty(tsToUse)
            
            %%dyes
            % Find available color channels first
            initialnumber = '_Pos1';
            d = dir(['*' initialnumber '_spotStats.mat']);
            if isempty(d)
                disp(['No spotStats.mat files in ' dirs(iDir).name '!!!!!  Abandoning this directory']);
                cd(SexDetDir);
                continue
            end;
            
            currcolor = 1;
            for i = 1:length(d)
                tmp = strrep(d(i).name,[initialnumber '_spotStats.mat'],'');
                tmp = strrep(tmp,'_','');
                if ~sum(strcmp(tmp,{'segment','trans','thumbs','gfp','dapi'}))  %trans and dapi are "special"
                    dye{currcolor} = tmp;
                    currcolor = currcolor+1;
                end;
            end;
            dye=sort(dye);
            disp(dye);
            
            colsBeforeRNA=9;
            
            %setup the initial
            spotStats_byNuc.spotNum=zeros(10000000,colsBeforeRNA+length(dye));
            spotStats_byNuc.U=zeros(length(spotStats_byNuc.spotNum),length(dye));
            spotStats_byNuc.L=zeros(length(spotStats_byNuc.spotNum),length(dye));
            
            currentNuc=0;
            
            wormGaussianFits=dir('*wormGaussianFit.mat*');
            disp([num2str(size(wormGaussianFits,1)) ' wgf files to do']);
            if ~isempty(wormGaussianFits)
                posNums={};
                for i=1:length(wormGaussianFits)
                    stackName=regexprep(wormGaussianFits(i).name,'_','\.');
                    stackPrefix=regexp(stackName,'\.','split');
                    if length(stackPrefix)==4
                        posNums{end+1}=stackPrefix{2};
                    end;
                end;
                posNums=unique(posNums);
                
                for iPosNum=1:length(posNums)
                    for k=1:length(dye)
                        wgfName=[dye{k} '_' posNums{iPosNum} '_wormGaussianFit.mat'];
                        wFile=dir(wgfName);
                        if isempty(wFile)
                            disp([dye{k} '_' posNums{iPosNum} '_wormGaussianFit.mat does not exist']);
                            continue
                        end;
                        ae=load(wgfName);
                        posNum=posNums{iPosNum};
                        tic
                        try
                            if doBeforeDate-wFile(1).datenum>0 || strcmp(dirs(iDir).name,'3_1_09_N2_25C_xol1cy5_sdc2tmr') || strcmp(dirs(iDir).name,'5_29_09_N2_25C_sex1tmr_xol1cy5')
                                disp('------------------------------');
                                disp(['        Matching ' dirs(iDir).name filesep wgfName ' to ' 'nucLocations' posNum ]);
                                
                                worms=matchRNAToNucleus(ae.worms);
                                disp(['        ** Matched ' dirs(iDir).name filesep wgfName ' to ' 'nucLocations' posNum ]);
                            else
                                worms=ae.worms;
                                disp('------------------------------');
                                disp(['        ** Already Matched ' dirs(iDir).name filesep wgfName ' to ' 'nucLocations' posNum ]);
                            end;
                            clear ae
                            positionColumn=str2double(posNum);
                            for iW=1:size(worms,1)
                                if isfield(worms{iW},'nucDataStats')
                                    nNucs=size(worms{iW}.nucDataStats.nucLocations,1);
                                    spotNum=zeros(nNucs,size(spotStats_byNuc.spotNum,2));
                                    U=zeros(nNucs,size(spotStats_byNuc.U,2));
                                    L=zeros(nNucs,size(spotStats_byNuc.L,2));
                                    spotNum(:,2)=positionColumn;
                                    spotNum(:,3)=iW;
                                    spotNum(:,4)=(1:nNucs)';
                                    spotNum(:,5)=nNucs;
                                    %Convert nuclei to time later
                                    spotNum(:,7:9)=worms{iW}.nucDataStats.nucLocations;
                                    spotNum(:,colsBeforeRNA+k)=worms{iW}.nucDataStats.SpotNumEstimate;
                                    U(:,k)=abs(worms{iW}.nucDataStats.SpotNumRange(2)-worms{iW}.nucDataStats.SpotNumEstimate);
                                    L(:,k)=abs(worms{iW}.nucDataStats.SpotNumRange(1)-worms{iW}.nucDataStats.SpotNumEstimate);
                                    
                                    %find them in the big matrix if they
                                    %exist
                                    iStartSearch=max(currentNuc-2000,1);
                                    iEndSearch=currentNuc;
                                    bigIndicesToSearch=(iStartSearch:iEndSearch);
                                    [~,iBig,iWorm]=intersect(spotStats_byNuc.spotNum(bigIndicesToSearch,2:4),spotNum(:,2:4),'rows');
                                    if isempty(iBig)%then it is new
                                        newIndices=(currentNuc+1:currentNuc+nNucs);
                                        spotStats_byNuc.spotNum(newIndices,:)=spotNum;
                                        spotStats_byNuc.U(newIndices,:)=U;
                                        spotStats_byNuc.L(newIndices,:)=L;
                                        currentNuc=currentNuc+nNucs;
                                    else %found it - only need to add rna stuff
                                        spotStats_byNuc.spotNum(bigIndicesToSearch(iBig),colsBeforeRNA+k)=spotNum(iWorm,colsBeforeRNA+k);
                                        spotStats_byNuc.U(bigIndicesToSearch(iBig),k)=U(iWorm,k);
                                        spotStats_byNuc.L(bigIndicesToSearch(iBig),k)=L(iWorm,k);
                                    end;
                                else
                                    disp(['no nucDataStats field for ' dye{k} ' for worm ' num2str(iW)]);
                                end;
                            end;
                        catch ME
                            parsaveProblem(posNum,ME);
                            disp(['        -- Failed Matching ' dirs(iDir).name filesep wgfName ' to ' 'nucLocations' posNum]);
                            disp(ME.stack(1).name);
                            disp(ME.stack(1).line);
                            disp(ME.stack(1).file);
                        end;
                        
                    end;% for dye
                    toc
                end;%for iPosNum
            end;%if ~isempty wgf
            disp(['    Finished with ' dirs(iDir).name]);
            
            %Save the spotStats_byNuc
            %first get rid of extra rows
            spotStats_byNuc.spotNum(currentNuc+1:end,:)=[];
            spotStats_byNuc.U(currentNuc+1:end,:)=[];
            spotStats_byNuc.L(currentNuc+1:end,:)=[];
            disp([num2str(length(spotStats_byNuc.U)) ' nuclei in directory']);
            %Convert nuclei to time
            spotStats_byNuc.spotNum(:,6)=convertNucleiToTime2(spotStats_byNuc.spotNum(:,5));
            %Add the first column
            spotStats_byNuc.spotNum(:,1)=(1:size(spotStats_byNuc.spotNum,1))';
            save(['wormDataByNuc_' dirs(iDir).name],'spotStats_byNuc');
            dlmwrite(['wormDataByNuc_' dirs(iDir).name '.csv'],[spotStats_byNuc.spotNum spotStats_byNuc.L spotStats_byNuc.U],',');
            disp('spotStats_byNuc saved');
            
        else
            disp([dirs(iDir).name ' is not in my list of directories to run']);
        end;%if ~isepmty tsToUse
        
        
    end;%if dir is good
    cd(SexDetDir);
end;% for iDir

end

function parsaveWorms(filename,worms)
save(filename,'worms');
end

function parsaveProblem(stackName,error)
save(['PROBLEM_RNAToNUCS_' stackName '.mat'],'error');
end