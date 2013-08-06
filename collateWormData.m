%function collateWormData()
%Collect all wormData (total embryo) data into one

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

wDC.alexa=1;%wormData Columns
wDC.cy=2;
wDC.tmr=3;
wDC.pad=3;
wDC.nucs=7;



% 1) Overall Index
% 2) DirIndex
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



allWormData.bigMat=zeros(100000,32)-1;
allWormData.geneHash=geneHash;

counter=0;
for iDir=1:length(dirs)
    
    if dirs(iDir).isdir && ~strcmp(dirs(iDir).name(1),'.')
        
        cd(dirs(iDir).name);
        disp(['Entering ' dirs(iDir).name]);
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
                    if exist(['wormData_' dirs(iDir).name '.mat'],'file')
                        load(['wormData_' dirs(iDir).name]);
                        for iW=1:size(wormData.spotNum,1)
                            counter=counter+1;
                            allWormData.bigMat(counter,1)=counter;
                            allWormData.bigMat(counter,2:4)=wormData.spotNum(iW,1:3);
                            %alexa
                            if isfield(dyeHash,'alexa')
                                if wormData.meanRange(wDC.alexa)>0
                                    aWDC=geneHash.(dyeHash.alexa);
                                    allWormData.bigMat(counter,aWDC:aWDC+2)=[wormData.spotNum(iW,wDC.alexa+wDC.pad) wormData.L(iW,wDC.alexa) wormData.U(iW,wDC.alexa)];
                                end;
                            end;
                            %cy
                            if isfield(dyeHash,'cy')
                                if wormData.meanRange(wDC.cy)>0
                                    aWDC=geneHash.(dyeHash.cy);
                                    allWormData.bigMat(counter,aWDC:aWDC+2)=[wormData.spotNum(iW,wDC.cy+wDC.pad) wormData.L(iW,wDC.cy) wormData.U(iW,wDC.cy)];
                                end;
                            end;
                            %tmr
                            if isfield(dyeHash,'tmr')
                                if wormData.meanRange(wDC.tmr)>0
                                    aWDC=geneHash.(dyeHash.tmr);
                                    allWormData.bigMat(counter,aWDC:aWDC+2)=[wormData.spotNum(iW,wDC.tmr+wDC.pad) wormData.L(iW,wDC.tmr) wormData.U(iW,wDC.tmr)];
                                end;
                            end;
                            allWormData.bigMat(counter,26)=wormData.spotNum(iW,wDC.nucs);
                            allWormData.bigMat(counter,strainCol)=1;%just mark that strain column
                        end;%loop over worms
                    end;%if wormData exists
                    clear dyeHash dye gene PARTS nm wormData strainCol
                end;%if do this directory
            end;%check training sets
        end;%if there are training sets to check
    end;%if check this directory
    cd(SexDetDir);
end;%loop over directories
allWormData.bigMat=allWormData.bigMat(1:counter,:);
goodNucIndices=find(allWormData.bigMat(:,26)>0);
allWormData.bigMat(goodNucIndices,27)=convertNucleiToTime2(allWormData.bigMat(goodNucIndices,26),'med');
allWormData.goodNucIndices=goodNucIndices;


save(['allWormData_' date],'allWormData');
dlmwrite(['allWormData_' date '.csv'],allWormData.bigMat,',');








%end