function histseries_forSpotTreeProbs(trainingSet,nbins,fignum,exportFig)

%this takes a trainingSet and calculates the things that needed to be
%precalculated before (see below)
%% TRAININGSET PROCESSING PORTION

meanProbs=mean(trainingSet.RF.spotTreeProbs,2);
[meanProbs,orderMeanProbs]=sort(meanProbs);



%% HISTSERIES PORTION
%function histseries_forSpotTreeProbs(meanProbs, fignum, nbins,varargin)
% based on histseries functions
%HISTSERIES(XLIMS, VARARGIN) - plots a series of non-normalized (ie., not same height)
%   distributions in  given by the data vectors supplied in VARARGIN.

%   MEANPROBS	- values for where the distributions should be plotted.  This
%   needs to be the same length as # of vectors and represents the mean
%   probability
%   VARARGIN	- series of data vectors (one for each distribution) to be plotted
%
%   Example:  If a series of vectors are in the cell array DATAFITTED:
%	HISTSERIES([min(cellfun(@min, DATAFITTED)), max(cellfun(@max, ...
%	 DATAFITTED))], DATAFITTED{1:end})
%
%F.Lam - 6/06
%




%numseries	= length(varargin); %not using varargin anymore
numseries=length(meanProbs);
% bins		= logspace(log10(xlims(1)), log10(xlims(2)), histbins)';
%bins        = logspace(xlims(1), xlims(2), histbins)';
bins        = linspace(0,1, nbins)';
Z			= zeros(nbins+2, numseries);

figure (fignum), 
for i = 1:numseries
	%tmp		= hist(varargin{i}, bins)'; %not using varargin anymore
	tmp=hist(trainingSet.RF.spotTreeProbs(orderMeanProbs(i),:),bins)';
	% Don't normalize histograms
	Z(2:(end-1),i)	= tmp;
end
% Set first, last bin of every distribution to 0 to avoid polygon closing artifact
% where the first and last vertices are connected.
%but add a first and last in

Z(1,:)		= 0;
Z(end,:)	= 0;

X		= repmat(meanProbs', nbins+2, 1);
Y		= repmat([0;bins;1], 1, numseries);




if numseries == 3
	% If numseries = 3 and color specified using 1:3, fill3 will interpret that as a 3 member [R G B] row vector instead of performing color scaling if numseries were other than 3.  Thus we need to use this alternate procedure to achieve the same effect.

	fill3(X, Y, Z, numseries);
	figh	= get(gca, 'Children');
	for i = 1:numseries
		set(figh(i), 'FaceColor','Flat', 'CData',i);
	end
else
	%fill3(X, Y, Z, 1:numseries);
	fill3(X, Y, Z, meanProbs');
end
grid on
%set(gca, 'yscale','log', 'ztick',[], 'xtick',[1:1:numseries]);
set(gca, 'yscale','linear', 'ztick',0:100:1000, 'xtick',0:.1:1);
%view([90, 60]); axis tight




%reversing x axis
%set(gca,'XDir','reverse');
%labeling x axis with [dox]
%set(gca,'XTickLabel',doxconc);
set(gca,'YDir','reverse');

%label

set(gca,'Fontsize',12,'FontWeight','bold')
ttle=title({pwd;[trainingSet.RF.FileName ' ' trainingSet.RF.RFfileName];trainingSet.RF.Version;[num2str(numseries) ' spots in training set']},'Fontsize',14,'FontWeight','bold');
set(ttle,'interpreter','none');
xlabel('Mean probability across trees for each local maximum','Fontsize',14,'FontWeight','bold');
ylabel('Probabilities from leaves','Fontsize',14,'FontWeight','bold');
zlabel('# of trees','Fontsize',14,'FontWeight','bold');
set(gcf,'units','normalized');
set(gcf,'Position',[0 0 1 1]);
if exportFig
   run('Aro_parameters.m');
    export_fig(fullfile(PlotDir,regexprep(trainingSet.RF.RFfileName,'.mat','_spotTreeProbs.png')),'-png');
end;