function spotStatsDataAligning(fileSuffix,varargin)
%% ========================================================================
%   Name:       spotStatsDataAligning.m
%   Version:    2.1, 5th July 2012
%   Author:     Allison Wu
%   Command:    spotStatsDataAligning(fileSuffix,alignDapi*) *Optional Input
%   Description: aligns spot number estimates and nuclei counts into wormData matrix
%       - alignDapi=varargin{1}: [0,1] flag. By default, alignDapi=1 and
%       the program will search for possible files that save nuclei number
%       information.
%       - saves spot number estimates in a wormData structure array:
%           * wormData.spotNum=[worm_Index position_Number  worm_Number  a595  cy5  tmr (nuclei)]   
%               > worm_Index: unique index for each worm within the whole data set
%               > worm_Number: the worm number within the stack.
%           * wormData.U: upper error bar length for each worm each channel
%           * wormData.L: lower error bar length for each worm each channel
% 
%   Files required: 
%       - **_spotStats.mat
%       - **_embryoDataStructure_**.mat or newNucallembryos_**.mat if alignDapi==1
%   Files generated: 
%       - wormData_{fileSuffix}.mat,
%       - wormData_{fileSuffix}_quickPlots.fig if alignDapi==1

%   Updates: 
%       - 2012 Aug. 8th: add in the field of meanRange to
%       give a rough idea of how well the spots are classified.
%% ========================================================================

if isempty(varargin)
    alignDapi=1;
else
    alignDapi=varargin{1};
end

% Find available color channels first
initialnumber = '_Pos1';
d = dir(['*' initialnumber '_spotStats.mat']);
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

% figure out how many embryos are in this dataset.
wormCount=0;
posCount=dir([dye{1} '**_spotStats.mat']);
for i=1:length(posCount)
    load(posCount(i).name);
    wormCount=wormCount+length(spotStats);
end
fprintf('There are %d embryos in the dataset.\n', wormCount);


disp('Aligning fluorescence data...')
wormData.spotNum=-1*ones(wormCount,length(dye)+3+alignDapi);
wormData.U=zeros(wormCount,length(dye));
wormData.L=zeros(wormCount,length(dye));
wormData.spotNum(:,1)=[1:wormCount]';

wormIndex=0;
for n=1:length(posCount)
    load(posCount(n).name)
    stackName=regexprep(posCount(n).name,'_','\.');
    stackPrefix=regexp(stackName,'\.','split');
    posNum=stackPrefix{2};
    posNum=str2num(cell2mat(regexp(posNum,'\d+','match')));
    wormNum=length(spotStats);
    for p=1:wormNum
        wormIndex=wormIndex+1;
        wormData.spotNum(wormIndex,1:3)=[wormIndex posNum p];
    end
end


for k=1:length(dye)
    posCount=dir([dye{k} '*_spotStats.mat']);
    for j=1:length(posCount)
        load(posCount(j).name)
        stackName=regexprep(posCount(j).name,'_','\.');
        stackPrefix=regexp(stackName,'\.','split');
        posNum=stackPrefix{2};
        posNum=str2num(cell2mat(regexp(posNum,'\d+','match')));
        fprintf('Aligning data at position %d ...\n', posNum)
        
        for i=1:length(spotStats)
            [~,~,wormIndex]=intersect([posNum i],wormData.spotNum(:,2:3),'rows');
            if strcmp(dye{k},stackPrefix{1})
                if spotStats{i}.SpotNumEstimate>1000
                    disp(posCount(j).name)
                end
                wormData.spotNum(wormIndex,3+k)=spotStats{i}.SpotNumEstimate;
                wormData.U(wormIndex,k)=abs(spotStats{i}.SpotNumRange(2)-spotStats{i}.SpotNumEstimate);
                wormData.L(wormIndex,k)=abs(spotStats{i}.SpotNumRange(1)-spotStats{i}.SpotNumEstimate);
            end
            
        end
    end
end

wormData.meanRange=mean(wormData.U+wormData.L);

if alignDapi
    disp('Find nuclei number data...')
    % old stk embryoDataStructure format?
    l=dir('**_embryoDataStructure**.mat');
    curatedNuclei=dir('curated_newNucallembryos**.mat');
    nuclei=dir('newNucallembryos_**.mat');
    wData=dir('wormData.mat');
    if ~isempty(l)
        load(l.name)
        wormData.spotNum(:,end)=out.dapis';
        clear out
    elseif ~isempty(nuclei)
        % Search for newNucallembryos format if embryoDataStructure format
        % is not found.
        for n=1:length(nuclei)
            nameSplit=regexprep(nuclei(n).name,'_','\.');
            nameSplit=regexp(nameSplit,'\.','split');
            nameSplit=nameSplit(~cellfun('isempty',nameSplit));
            posNum=str2num(cell2mat(regexp(nameSplit{2},'\d+','match')));
            load(nuclei(n).name)
            for j=1:length(allembryos)
                [~,~,wormIndex]=intersect([posNum,j],wormData.spotNum(:,2:3),'rows');
                if isfield(allembryos{j}.dapistr, 'pts') 
                    if ~isempty(allembryos{j}.dapistr.pts)
                        wormData.spotNum(wormIndex,end)=length(allembryos{j}.dapistr.pts);
                    end
                end
                
            end
            
        end
    elseif ~isempty(wData)
        wormDataOld=load(wData.name);
        wormDataOld=wormDataOld.wormData;
        
        for n=1:length(wormDataOld)
            [~,wormIndex,wormIndexOld]=intersect(wormData.spotNum(:,2:3),wormDataOld(n,2:3),'rows');
            wormData.spotNum(wormIndex,end)=wormDataOld(n,end);
        end
        
    end
    
    
    
    % Plot womrData by dye
    color={'b','g','m'};
    for p=1:length(dye)
        subplot(length(dye),1,p)
        %scatter(wormData.spotNum(:,end),wormData.spotNum(:,3+p),color{p},'.')
        h=errorbar(wormData.spotNum(:,end),wormData.spotNum(:,3+p),wormData.L(:,p),wormData.U(:,p),[color{p} '.']);
        errorbar_tick(h,1000)
        xlim([0, 250]);ylim([0,1000]);
        xlabel('Number of Nuclei');ylabel('Number of Spots');
        title(dye{p})
    end
    saveas(gcf, fullfile(pwd,['wormData_' fileSuffix '_quickPlots.fig']))
end

save(fullfile(pwd,['wormData_' fileSuffix '.mat']),'wormData')



end

