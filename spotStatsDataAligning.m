function spotStatsDataAligning(fileSuffix,varargin)
%% ========================================================================
%   Name:       spotStatsDataAligning.m
%   Version:    2.5.1, 25th March 2013
%   Author:     Allison Wu
%   Command:    spotStatsDataAligning(fileSuffix,alignDapi*) *Optional Input
%   Description: aligns spot number estimates and nuclei counts into wormData matrix
%       - alignDapi=varargin{1}: [0,1] flag. By default, alignDapi=1 and
%       the program will search for possible files that save nuclei number
%       information.
%       - saves spot number estimates in a wormData structure array:
%           * wormData.spotNum=[worm_Index position_Number  worm_Number  a595  cy5  tmr nuclei]   
%               > worm_Index: unique index for each worm within the whole data set
%               > worm_Number: the worm number within the stack.
%               > for the columns 1:4, if there's no values retrieved (channel absent or data not analyzed 
%                 or nuclei not counted),it will have a -1 entry.
%           * wormData.U: upper error bar length for each datapoint in each channel
%           * wormData.L: lower error bar length for each datapoint in each channel
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
%       - 2013 March: add in the field of errorPercentage and plot out a
%       scatter plot of errorPercentage v.s. spot number.
%       - 2013 May 22th: fix the plotting problem of having only several
%       channels.
%% ========================================================================

if isempty(varargin)
    alignDapi=1;
else
    alignDapi=varargin{1};
end

% Find available color channels first
initialnumber = '_Pos0';
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
wormData.dye=dye;
% figure out how many embryos are in this dataset.
wormCount=0;
posCount=dir([dye{1} '**_spotStats.mat']);
for i=1:length(posCount)
    load(posCount(i).name);
    wormCount=wormCount+length(spotStats);
end
fprintf('There are %d embryos in the dataset.\n', wormCount);


disp('Aligning fluorescence data...')
% This assumes there are 3 channels - alexa, cy5, tmr.
% If the data set doesn't have any one of the channel, the values would be -1.
wormData.spotNum=-1*ones(wormCount,3+4+alignDapi);
wormData.U=zeros(wormCount,4);
wormData.L=zeros(wormCount,4);
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
                switch stackPrefix{1}
                    case {'a594','alexa'}
                        di=1;
                    case {'cy5','cy'}
                        di=2;
                    case {'tmr'}
                        di=3;
                    case {'yfp'}
                        di=4;
                end
                wormData.spotNum(wormIndex,3+di)=spotStats{i}.SpotNumEstimate;
                wormData.U(wormIndex,di)=abs(spotStats{i}.SpotNumRange(2)-spotStats{i}.SpotNumEstimate);
                wormData.L(wormIndex,di)=abs(spotStats{i}.SpotNumRange(1)-spotStats{i}.SpotNumEstimate);
            end
            
        end
    end
end

wormData.meanRange=mean(wormData.U+wormData.L);
wormData.errorPercentage=((wormData.U+wormData.L)/2)./wormData.spotNum(:,4:7);
clf
h=figure(1);
for k=1:4
    scatter(wormData.spotNum(:,k+3),wormData.errorPercentage(:,k),'.')
    hold on
end
xlim([0 1500])
ylim([0 2])
xlabel('Spot Number')
ylabel('ErrorRange/SpotNumEstimate')
legend('alexa','cy5','tmr','yfp')
saveas(h,['ErrorPercentagePlot_' fileSuffix])
hold off

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
                if allembryos{j}.isgood
                if isfield(allembryos{j}.dapistr, 'pts') 
                    if ~isempty(allembryos{j}.dapistr.pts)
                        wormData.spotNum(wormIndex,end)=length(allembryos{j}.dapistr.pts);
                    end
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
    
    % Check if there are embryos denoted as bad embryos.
    if exist('badEmbryos.mat','file')
        load badEmbryos.mat
        [~,I,~]=intersect(wormData.spotNum(:,2:3),badEmbryos,'rows');
        wormData.spotNum(I,end)=-1;
    end
    
       
    % Plot womrData by dye
    color={'b','g','m','r'};
    clf
    for p=1:length(dye)
        subplot(length(dye),1,p)
        %scatter(wormData.spotNum(:,end),wormData.spotNum(:,3+p),color{p},'.')
        n=find(strcmp(dye(p),{'a594','cy5','tmr','yfp'}));
        h=errorbar(wormData.spotNum(:,end),wormData.spotNum(:,3+n),wormData.L(:,n),wormData.U(:,n),[color{p} '.']);
        errorbar_tick(h,1000)
        %xlim([0, 250]);
        %ylim([0,1500]);
        xlabel('Number of Nuclei');ylabel('Number of Spots');
        title(dye{p})
    end
    hold off
    fprintf('Plotted %d embryos.\n', sum(wormData.spotNum(:,end)>0))
    saveas(gcf, fullfile(pwd,['wormData_' fileSuffix '_quickPlots.fig']))
end

%wormData.header={'worm_Index', 'position_Number','worm_Number', dye{1:end}, 'nuclei'}
save(fullfile(pwd,['wormData_' fileSuffix '.mat']),'wormData')



end

