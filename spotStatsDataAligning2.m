function spotStatsDataAligning2(fileSuffix)
    %% ========================================================================
    %   Name:       spotStatsDataAligning2.m
    %   Version:    3  17Feb2015
    %   Author:     Allison Wu
    %   Command:    spotStatsDataAligning(fileSuffix) *Optional Input
    %   Description: aligns spot number estimates and nuclei counts into wormData struct
    %       - saves spot number estimates in a wormData structure:
    %           * For each dye a matrix with columns:
    %                 iObjectInDataset
    %                 spotNum
    %                 L (lower interval bound)
    %                 U (upper interval bound)
    %
    %             * a matrix:  (called spotInfo)
    %                 iObjectInDataset
    %                 iPos (position number)
    %                 iObjectInPosition
    %
    %
    %   Files required:
    %       - **_spotStats.mat
    %   Files generated:
    %       - wormData_{fileSuffix}.mat,
    %
    %
    %   Updates:
    %       - 2012 Aug. 8th: add in the field of meanRange to
    %       give a rough idea of how well the spots are classified.
    %       - 2013 March: add in the field of errorPercentage and plot out a
    %       scatter plot of errorPercentage v.s. spot number.
    %       - 2013 May 22th: fix the plotting problem of having only several
    %       channels.
    %       - 2015 Feb 17:  reorganized into a structure.  split the dapi part off
    %% ========================================================================
    
    
    run('Aro_parameters.m');
    
    % Find available color channels first
    %initialnumber = '_Pos0';
    % initialnumber = '_Pos1';
    % d = dir(['*' initialnumber '_spotStats.mat']);
    % currcolor = 1;
    % for i = 1:length(d)
    %     tmp = strrep(d(i).name,[initialnumber '_spotStats.mat'],'');
    %     tmp = strrep(tmp,'_','');
    %     if ~sum(strcmp(tmp,{'segment','trans','thumbs','gfp','dapi'}))  %trans and dapi are "special"
    %         dye{currcolor} = tmp;
    %         currcolor = currcolor+1;
    %     end;
    % end;
    % dye=sort(dye);
    disp(dyesUsed);
    
    
    
    
    disp('Aligning fluorescence data...')
    wormData=struct('spotInfo',[],'dye',dyesUsed);
    for d=1:length(dyesUsed)
        wormData.(dyesUsed{d})=[];
    end;
    % Check if there are embryos denoted as bad embryos.
    % position and embryo number
    if exist(fullfile(AnalysisDir,'badEmbryos.mat'),'file')
        load(fullfile(AnalysisDir,'badEmbryos.mat'));
    end
    
    
    
    iObjectInDataset=0;
    
    
    for k=1:length(wormData.dye)
        posFiles=dir(fullfile(SpotStatsDir,wormData.dye{k},[wormData.dye{k} '**_spotStats.mat']));
        for j=1:length(posFiles)
            load(posCount(j).name)
            stackName=regexprep(posCount(j).name,'_','\.');
            stackPrefix=regexp(stackName,'\.','split');
            posNum=stackPrefix{2};
            posNum=str2num(cell2mat(regexp(posNum,'\d+','match')));
            fprintf('Aligning data at position %d ...\n', posNum)
            
            for i=1:length(spotStats)
                if isempty(intersect([posNum i],badEmbryos,'rows'))
                    if k==1
                        iObjectInDataset=iObjectInDataset+1;
                        wormData.spotInfo=[wormData.spotInfo; [iObjectInDataset posNum  i]];
                    end;
                    
                    
                    
                    r=intersect([posNum i],wormData.spotInfo(:,2:3),'rows');
                    if isempty(r) %in case there are any that the first dye doesn't have
                        iObjectInDataset=iObjectInDataset+1;
                        wormData.spotInfo=[wormData.spotInfo; [iObjectInDataset posNum  i]];
                        r=intersect([posNum i],wormData.spotInfo(:,2:3),'rows');
                    end;
                    objectIndex=r(1);
                    if isfield(spotStats{i},'noSpot')
                        dataToAdd=[objectIndex 0 0 0];
                    else
                        dataToAdd=[objectIndex spotStats{i}.SpotNumEstimate abs(spotStats{i}.SpotNumRange(2)-spotStats{i}.SpotNumEstimate) abs(spotStats{i}.SpotNumRange(1)-spotStats{i}.SpotNumEstimate)];
                    end
                    wormData.(wormData.dye{k})=[ wormData.(wormData.dye{k}); dataToAdd];
                    
                end
            end
        end
    end;

    
    wormData.meanRange=cellfun(@(x) mean(sum(wormData.(x)(:,3:4),2)),wormData.dye);
    wormData.errorPercentage=  cellfun(@(x) (sum(wormData.(x)(:,3:4),2)/2)./(wormData.(x)(:,2)),wormData.dye);
    clf
    h=figure(1);
    for k=1:length(wormData.dye)
        scatter(wormData.(wormData.dye{k})(:,2),wormData.errorPercentage(:,k),'.')
        hold on
    end
    xlim([0 1500])
    ylim([0 2])
    xlabel('Spot Number')
    ylabel('ErrorRange/SpotNumEstimate')
    legend(wormData.dye{:})
    saveas(h,fullfile(PlotDir,['ErrorPercentagePlot_' fileSuffix]))
    hold off
    
    %wormData.header={'worm_Index', 'position_Number','worm_Number', dye{1:end}, 'nuclei'}
    save(fullfile(AnalysisDir,['wormData_' fileSuffix '.mat']),'wormData')
    
    
    
end

