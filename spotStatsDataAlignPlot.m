function spotStatsDataAlignPlot(fileSuffix)
%% ========================================================================
%   Name:       spotStatsDataAlignPlot.m
%   Version:    2.1, 23 March 2013
%   Author:     Scott Rifkin
%   Command:    spotStatsDataAlignPlot(fileSuffix)
%   Description: this is the same as the plot function at the bottom of
%                 spotStatsDataAligning.m but it just takes the file suffix
%                 loads the corresponding wormData file
%                 and plots from there
%                 aligns spot number estimates and nuclei counts into wormData matrix
%
%   Files required:
%       - wormData_{fileSuffix}.mat,
%    Files generated:
%       - wormData_{fileSuffix}_quickPlots.fig
%       - wormData_{fileSuffix}_quickPlots.pdf
%% ====================================================================

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

load(['wormData_' fileSuffix '.mat']);



% Plot wormData by dye
color={'b','g','m'};
for p=1:length(dye)
    subplot(length(dye),1,p)
    %scatter(wormData.spotNum(:,end),wormData.spotNum(:,3+p),color{p},'.')
    h=errorbar(wormData.spotNum(:,end),wormData.spotNum(:,3+p),wormData.L(:,p),wormData.U(:,p),[color{p} '.']);
    errorbar_tick(h,1000)
    xlim([0, max([250,1.1*wormData.spotNum(:,end)'])]);ylim([0,max([1000,1.1*wormData.spotNum(:,3+p)'])]);
    xlabel('Number of Nuclei');ylabel('Number of Spots');
    title(dye{p})
end
saveas(gcf, fullfile(pwd,['wormData_' fileSuffix '_quickPlots.fig']));
saveas(gcf, fullfile(pwd,['wormData_' fileSuffix '_quickPlots.pdf']))
end
