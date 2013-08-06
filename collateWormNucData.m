%function collateWormNucData()
%Collect all spotStats_byNuc (total embryo) data into one

trainingSets={{'3_1_09_N2_25C_xol1cy5_sdc2tmr','trainingSet_cy_Cel_xol1.mat','N2'},...
    {'3_1_09_N2_25C_xol1cy5_sdc2tmr','trainingSet_tmr_Cel_sdc2.mat','N2'},...
    {'3_2_09_fog2_25C_xol1cy5_sdc2_tmr','trainingSet_cy_Cel_xol1.mat','fog2'},...
    {'3_2_09_fog2_25C_xol1cy5_sdc2_tmr','trainingSet_tmr_Cel_sdc2.mat','fog2'},...
    {'5_10_09_Sex1Sea1_25C_xol1cy5_sdc2tmr','trainingSet_cy_Cel_xol1.mat','ss'},...
    {'5_10_09_Sex1Sea1_25C_xol1cy5_sdc2tmr','trainingSet_tmr_Cel_sdc2.mat','ss'},...
    {'5_13_09_Sex1Sea1_25C_xol1cy5_sdc2tmr','trainingSet_cy_Cel_xol1.mat','ss'},...
    {'5_13_09_Sex1Sea1_25C_xol1cy5_sdc2tmr','trainingSet_tmr_Cel_sdc2.mat','ss'},...
    {'5_29_09_N2_25C_sex1tmr_xol1cy5','trainingSet_cy_Cel_xol1.mat','N2'},...
    {'5_29_09_N2_25C_sex1tmr_xol1cy5','trainingSet_tmr_Cel_sex1.mat','N2'},...
    {'5_29_09_fog2_25C_sex1tmr_xol1cy5','trainingSet_cy_Cel_xol1.mat','fog2'},...
    {'5_29_09_fog2_25C_sex1tmr_xol1cy5','trainingSet_tmr_Cel_sex1.mat','fog2'},...
    {'6_11_09_sex1_25C_sdc2tmr_xol1cy5','trainingSet_cy_Cel_xol1.mat','s'},...
    {'6_11_09_sex1_25C_sdc2tmr_xol1cy5','trainingSet_tmr_Cel_sdc2.mat','s'},...
    {'6_16_09_fog2_25C_sea1cy5_sex1tmr','trainingSet_cy_Cel_sea1.mat','fog2'},...
    {'6_16_09_fog2_25C_sea1cy5_sex1tmr','trainingSet_tmr_Cel_sex1.mat','fog2'},...
    {'6_17_09_sex1sea1sea2_25C_sdc2tmr_xol1cy5','trainingSet_cy_Cel_xol1.mat','sss'},...
    {'6_17_09_sex1sea1sea2_25C_sdc2tmr_xol1cy5','trainingSet_tmr_Cel_sdc2.mat','sss'},...
    {'6_23_09_sex1sea1_25C_fox1A594_1_40_ceh39tmr_1_40_PFSrun','trainingSet_tmr_Cel_ceh39.mat','ss'},...
    {'6_4_09_sex1_25C_sex1tmr_xol1cy5','trainingSet_cy_Cel_xol1.mat','s'},...
    {'6_4_09_sex1_25C_sex1tmr_xol1cy5','trainingSet_tmr_Cel_sex1.mat','s'},...
    {'7_2_09_sex1sea1_25C_fox1alexa_sea1cy5_ceh39tmr','trainingSet_cy_Cel_sea1.mat','ss'},...
    {'7_3_09_N2_25C_sea2alexa_xol1cy5_sex1tmr','trainingSet_alexa_Cel_sea2.mat','N2'},...
    {'7_3_09_N2_25C_sea2alexa_xol1cy5_sex1tmr','trainingSet_cy_Cel_xol1.mat','N2'},...
    {'7_3_09_N2_25C_sea2alexa_xol1cy5_sex1tmr','trainingSet_tmr_Cel_sex1.mat','N2'},...
    {'7_3_09_N2_25C_xol1cy5_sea1A594_sdc2tmr_1_10','trainingSet_alexa_Cel_sea1.mat','N2'},...
    {'7_3_09_N2_25C_xol1cy5_sea1A594_sdc2tmr_1_10','trainingSet_cy_Cel_xol1.mat','N2'},...
    {'7_3_09_N2_25C_xol1cy5_sea1A594_sdc2tmr_1_10','trainingSet_tmr_Cel_sdc2.mat','N2'},...
    {'7_4_09_N2_25C_sea1A594_fox1cy5_ceh39tmr','trainingSet_alexa_Cel_sea1.mat','N2'},...
    {'7_4_09_N2_25C_sea1A594_fox1cy5_ceh39tmr','trainingSet_cy_Cel_fox1.mat','N2'},...
    {'7_4_09_N2_25C_sea1A594_fox1cy5_ceh39tmr','trainingSet_tmr_Cel_ceh39.mat','N2'},...
    {'7_5_09_fog2_25C_xol1cy5_sdc2A594_1_5_sex1IItmr_1_40_PFSrun','trainingSet_alexa_Cel_sdc2.mat','fog2'},...
    {'7_5_09_fog2_25C_xol1cy5_sdc2A594_1_5_sex1IItmr_1_40_PFSrun','trainingSet_cy_Cel_xol1.mat','fog2'},...
    {'more7_5_09_fog2_25C_xol1cy5_sdc2A594_1_5_sex1IItmr_1_40_PFSrun','trainingSet_alexa_Cel_sdc2.mat','fog2'},...
    {'more7_5_09_fog2_25C_xol1cy5_sdc2A594_1_5_sex1IItmr_1_40_PFSrun','trainingSet_cy_Cel_xol1.mat','fog2'},...
    {'6_4_09_sex1_25C_sdc2tmr_xol1cy5','trainingSet_cy_Cel_xol1.mat','s'},...
    {'6_4_09_sex1_25C_sdc2tmr_xol1cy5','trainingSet_tmr_Cel_sdc2.mat','s'}};
%     {'7_10_09_N2_25C_fox1A594_sea1cy5_sdc2tmr','trainingSet_alexa_Cel_fox1.mat','N2'},...
%     {'7_10_09_N2_25C_fox1A594_sea1cy5_sdc2tmr','trainingSet_cy_Cel_sea1.mat','N2'},...
%     {'7_10_09_N2_25C_fox1A594_sea1cy5_sdc2tmr','trainingSet_tmr_Cel_sdc2.mat','N2'},...
%



%go through all directories: start in SexDet
SexDetDir='/Volumes/rifkinlab/sarifkin/Projects/Worms/SexDet/';
cd(SexDetDir);
dirs=dir;

wDC.alexa=1;%spotStats_byNuc Columns
wDC.cy=2;
wDC.tmr=3;
wDC.pad=9;
wDC.totNucs=5;
wDC.totTime=6;

%%%%%%%%%%%%%%%%%%%% Structure of wormDataByNuc
%This collates info from a directory into a big matrix
%data structure for nuclei in a directory
%struct with spotNum, U, L just like spotStats_byNuc
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





% 1) Overall Index
% 2) DirIndex (in wormDataByNuc
% 3) Posnum
% 4) EmbNum
% 5) xol1 levels
% 6) xol1 L
% 7) xol1 U
% 8) sex1 levels
% 9) sex1 L
% 10) sex1 U
% 11) sea1 levels
% 12) sea1 L
% 13) sea1 U
% 14) sea2levels
% 15) sea2 L
% 16) sea2 U
% 17) sdc2 levels
% 18) sdc2 L
% 19) sdc2 U
% 20) ceh39 levels
% 21) ceh39 L
% 22) ceh39 U
% 23) fox1 levels
% 24) fox1 L
% 25) fox1 U
% 26) #Nucs
% 27) Converted Time
%   28) N2
%   29) fog2
%   30) s
%   31) ss
%   32) sss
% 33) NucIndexInEmb
% 34) row (spatial coord)
% 35) col (spatial coord)
% 36) z (spatial coord)
%37) directory counter index


%Note that L,U are distance away from spotNum

geneHash.xol1=5;
geneHash.sex1=8;
geneHash.sea1=11;
geneHash.sea2=14;
geneHash.sdc2=17;
geneHash.ceh39=20;
geneHash.fox1=23;

strainHash.N2=28;
strainHash.fog2=29;
strainHash.s=30;
strainHash.ss=31;
strainHash.sss=32;



allWormDataByNuc.bigMat=zeros(1000000,37)-1;
allWormDataByNuc.geneHash=geneHash;

counter=0;
dirCounter=0;
for iDir=1:length(dirs)
    
    if dirs(iDir).isdir && ~strcmp(dirs(iDir).name(1),'.')
        
        cd(dirs(iDir).name);
        disp(['Entering ' dirs(iDir).name]);
        
        %%%%%%% Get dyes
        
        
        
        
        
        tss=dir('trainingSet*mat');
        if ~isempty(tss)
            for iTSCheck=1:length(trainingSets)
                if strcmp(dirs(iDir).name,trainingSets{iTSCheck}{1})%do this directory
                    for iTS=1:length(tss)
                        
                        if strcmp(tss(iTS).name,trainingSets{iTSCheck}{2})
                            nm=regexprep(tss(iTS).name,'_','\.');
                            PARTS=regexp(nm,'\.','split');
                            dye=PARTS{2};
                            gene=PARTS{4};
                            dyeHash.(dye)=gene;
                            strainCol=strainHash.(trainingSets{iTSCheck}{3});
                            break %found training set
                        end;
                    end;
                    
                    
                    initialnumber = '_Pos2';
                    d = dir(['*' initialnumber '_spotStats.mat']);
                    currcolor = 1;
                    for i = 1:length(d)
                        tmp = strrep(d(i).name,[initialnumber '_spotStats.mat'],'');
                        tmp = strrep(tmp,'_','');
                        if ~sum(strcmp(tmp,{'segment','trans','thumbs','gfp','dapi'}))  %trans and dapi are "special"
                            dyelist{currcolor} = tmp;
                            currcolor = currcolor+1;
                        end;
                    end;
                    dyelist=sort(dyelist);
                    nDyes=length(dyelist);
                    
                    
                    
                    
                    
                    if exist(['wormDataByNuc_' dirs(iDir).name '.mat'],'file')
                        dirCounter=dirCounter+1;
                        load(['wormDataByNuc_' dirs(iDir).name]);
                        for iN=1:size(spotStats_byNuc.spotNum,1)
                            counter=counter+1;
                            allWormDataByNuc.bigMat(counter,1)=counter;
                            allWormDataByNuc.bigMat(counter,2:4)=spotStats_byNuc.spotNum(iN,1:3);
                            %alexa
                            if isfield(dyeHash,'alexa')
                                for idl=1:length(dyelist)
                                    if strcmp('alexa',dyelist{idl})
                                        colInc=idl;
                                        break
                                    end;
                                end;
                                if max(spotStats_byNuc.spotNum(:,colInc+wDC.pad))>0
                                    aWDC=geneHash.(dyeHash.alexa);
                                    allWormDataByNuc.bigMat(counter,aWDC:aWDC+2)=[spotStats_byNuc.spotNum(iN,colInc+wDC.pad) spotStats_byNuc.L(iN,colInc) spotStats_byNuc.U(iN,colInc)];
                                end;
                            end;
                            %cy
                            if isfield(dyeHash,'cy')
                                for idl=1:length(dyelist)
                                    if strcmp('cy',dyelist{idl})
                                        colInc=idl;
                                        break
                                    end;
                                end;
                                if max(spotStats_byNuc.spotNum(:,colInc+wDC.pad))>0
                                    aWDC=geneHash.(dyeHash.cy);
                                    allWormDataByNuc.bigMat(counter,aWDC:aWDC+2)=[spotStats_byNuc.spotNum(iN,colInc+wDC.pad) spotStats_byNuc.L(iN,colInc) spotStats_byNuc.U(iN,colInc)];
                                end;
                            end;
                            %tmr
                            if isfield(dyeHash,'tmr')
                                for idl=1:length(dyelist)
                                    if strcmp('tmr',dyelist{idl})
                                        colInc=idl;
                                        break
                                    end;
                                end;
                                if max(spotStats_byNuc.spotNum(:,colInc+wDC.pad))>0
                                    aWDC=geneHash.(dyeHash.tmr);
                                    allWormDataByNuc.bigMat(counter,aWDC:aWDC+2)=[spotStats_byNuc.spotNum(iN,colInc+wDC.pad) spotStats_byNuc.L(iN,colInc) spotStats_byNuc.U(iN,colInc)];
                                end;
                            end;
                            allWormDataByNuc.bigMat(counter,33)=spotStats_byNuc.spotNum(iN,4);
                            
                            allWormDataByNuc.bigMat(counter,26)=spotStats_byNuc.spotNum(iN,wDC.totNucs);
                            allWormDataByNuc.bigMat(counter,27)=spotStats_byNuc.spotNum(iN,wDC.totTime);
                            allWormDataByNuc.bigMat(counter,strainCol)=1;%just mark that strain column
                            allWormDataByNuc.bigMat(counter,34:36)=spotStats_byNuc.spotNum(iN,7:9);
                            allWormDataByNuc.bigMat(counter,37)=dirCounter;
                        end;%loop over worms
                    end;%if spotStats_byNuc exists
                    clear dyeHash dye gene PARTS nm spotStats_byNuc strainCol
                end;%if do this directory
            end;%check training sets
        end;%if there are training sets to check
    end;%if check this directory
    cd(SexDetDir);
end;%loop over directories
allWormDataByNuc.bigMat=allWormDataByNuc.bigMat(1:counter,:);
goodNucIndices=find(allWormDataByNuc.bigMat(:,26)>0);
%allWormDataByNuc.bigMat(goodNucIndices,27)=convertNucleiToTime2(allWormDataByNuc.bigMat(goodNucIndices,26),'med');
allWormDataByNuc.goodNucIndices=goodNucIndices;


save(['allWormDataByNuc_' date],'allWormDataByNuc');
dlmwrite(['allWormDataByNuc_' date '.csv'],allWormDataByNuc.bigMat,',');








%end