function gaussfit=calculateFISHStatistics(dataColumn,centerR,centerC,iSlice,quickAndDirtyStats,varargin)
%  =============================================================
%  Name: calculateFISHStatistics.m
%  Version: 1.4.1, 20 Sept 2011
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%
%   Attribution: Wu, AC-Y and SA Rifkin. spotFinding Suite version 2.5, 2013 [journal citation TBA]
%   License: Creative Commons Attribution-ShareAlike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%   Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%   Email for comments, questions, bugs, requests:  Allison Wu < dblue0406 at gmail dot com >, Scott Rifkin < sarifkin at ucsd dot edu >
%
%  =============================================================
%This function calculates the statistics on the small data matrices which
%are passed in.  It is possible to modify this to use other statistics too.
% If this is done, make sure the changes propagate appropriately in the
% other files as well.
%center is at the center of dataMat which is 7x7 ...if I change this, I will have to change the diagonal
%finding
%adjacentSlices is just the dataMat of above and below slices
%version 1.2.  changed so that pass in the whole column, not just adjacent
%slices and the index of the slice.  this way can calculate stats on the
%max merge
%21April2011 - on further thought, max merge is not useful and decidedly
%unuseful if there are more than one spot in a dataColumn
%also modified so that all the stats are just fields
%26April2011 - got rid of 1D fitting.  not sure this was done correctly
%anyway...pdf vs. integral (cdf-like).  just have 2D fitting now.  also got
%rid of stats and just am using the statValues
%10May2011 Now can pass in value that tells it whether to just do 1D
%(quickAndDirty=1) or do 2D fits (quickAndDirty=0) 
%21 July - can paste new functions at end (or just call them if they live outside).  templates are provided below
%20 Sep 2011 - added the bleachFactors passed in so can have raw intensities and adjusted intensities...also made the quickAndDirtyStats a mandatory argument
%21 Sep 2011 use 2D gaussian fitting function instead of mine
if size(varargin,2)>0
	bleachFactors=varargin{1};
else
	bleachFactors=ones(1,iSlice);%In this case, the rawIntensities will be the same as the ordinary (bleachCorrected) ones
end;

dataMat=dataColumn(:,:,iSlice);

adjacentSlices=[];
if iSlice>1
    adjacentSlices=dataColumn(:,:,iSlice-1);
end;
if iSlice<size(dataColumn,3)
    adjacentSlices=cat(3,adjacentSlices,dataColumn(:,:,iSlice+1));
end;

adjs=[];
for adji=1:size(adjacentSlices,3)
    sl=adjacentSlices(:,:,adji);
    adjs=cat(3,adjs,sl(centerR,centerC)-min(sl(:)));
end;


%adjs=adjacentSlices(centerR,centerC,:)-min(dataMat(:));%deal with it here before dataMat has been altered
minDataMat=min(dataMat(:));

dataMat=dataMat-min(dataMat(:));
%names of functions to get statistics
	%gofOnDataMatrix2D
	%oneDGausStats
	%percentiles
	%threeDstat
	%areaStats
	

try
	gaussfit={};

	%%% 2D goodness of fit on data matrix

    if ~quickAndDirtyStats
      	%stats=gofOnDataMatrix2D(dataMat,bleachFactors(iSlice));
        stats=auto2DGaussianFit(dataMat,bleachFactors(iSlice));
        statFields=fieldnames(stats);
    	for fi=1:size(statFields,1)
        	gaussfit.statValues.(statFields{fi})=stats.(statFields{fi});
    	end;    	
    end;
    %Some of these will be NaNs, but it won't matter unless they are used
    
%     %%% 1D goodness of fit on data matrix
%     stats=oneDGaussStats(dataMat,centerR,centerC,bleachFactors(iSlice));
%     statFields=fieldnames(stats);
%    	for fi=1:size(statFields,1)
%        	gaussfit.statValues.(statFields{fi})=stats.(statFields{fi});
%    	end;
    	
    %%% percentiles 
	stats=percentiles(dataMat);
    statFields=fieldnames(stats);
   	for fi=1:size(statFields,1)
       	gaussfit.statValues.(statFields{fi})=stats.(statFields{fi});
   	end;

	%%% 3Dness	
	stats=threeDStat(dataMat,centerR,centerC,adjs);
    statFields=fieldnames(stats);
   	for fi=1:size(statFields,1)
       	gaussfit.statValues.(statFields{fi})=stats.(statFields{fi});
   	end;

	
	%%% area stats
	stats=areaStats(dataMat);
    statFields=fieldnames(stats);
   	for fi=1:size(statFields,1)
       	gaussfit.statValues.(statFields{fi})=stats.(statFields{fi});
   	end;
	
	
	%%% template for calling new statistics %%%
%	stats=myNewStatisticsFunction(dataMat, other arguments);  <-this is the only line you need to change up here
%    statFields=fieldnames(stats);
%   	for fi=1:size(statFields,1)
%       	gaussfit.statValues.(statFields{fi})=stats.(statFields{fi});
%   	end;


catch ME
    ME
    ME.stack.file
    ME.stack.name
    ME.stack.line
    
    gaussfit.message=ME.message;
    disp([ME 'in calculateFISHStatistics_1p4.m ']);
end;

%%%%% STATISTICS FUNCTION COLLECTION

%%%%%%%%%%%%%%%%%%%%%%

	function statValues = percentiles(dataMat)
	    %calculate percentile-fractions (like qq plot)...what fraction of max each
	    %decile is note that dataMat has been min subtracted
	    pctiles=10:10:90;
	    percentiles=prctile(dataMat(:)/max(dataMat(:)),pctiles);
	    for ppi=pctiles
	        statValues.(['prctile_' num2str(ppi)])=percentiles(ppi/10);
	    end;
    end
    
%%%%%%%%%%%%%%%%%%%%%%    
    
    function statValues = threeDStat(dataMat,centerR,centerC,adjs)
	    statValues.threeDness=max(adjs)/dataMat(centerR,centerC);
    end

%%%%%%%%%%%%%%%%%%%%%%

	function statValues = areaStats(dataMat)
		
	    
	    %what percentage in each area around 4,4
	    %these are not normalized basis matrices here
	    fractionLabels={'center','plusSign','3box','5star','5box','7star','3ring','all'};
	    areas=zeros([size(dataMat) 7]);
	    %center
	    areas(4,4,1)=1;
	    %+ in center
	    areas(4,3:5,2)=1;areas(3:5,4,2)=1;
	    %box around center
	    areas(3:5,3:5,3)=1;
	    %star
	    areas(3:5,3:5,4)=1;areas(2,4,4)=1;areas(4,2,4)=1;areas(6,4,4)=1;areas(4,6,4)=1;
	    %bigger box
	    areas(2:6,2:6,5)=1;
	    %bigger star
	    areas(:,:,6)=ones(size(dataMat));areas(1,1,6)=0;areas(7,7,6)=0;areas(1,7,6)=0;areas(7,1,6)=0;
	    %3ring
	    areas(:,:,7)=areas(:,:,3)-areas(:,:,1);
	    %all
	    areas(:,:,8)=ones(size(dataMat));
	    totalArea=sum(dataMat(:));
	    for fi=1:7
	        dataArea=dataMat.*areas(:,:,fi);
	        statValues.(['raw_' fractionLabels{fi}])=sum(dataArea(:));
	        statValues.(['fraction_' fractionLabels{fi}])=sum(dataArea(:))/totalArea;
	    end; %last one is just the total area
	    statValues.total_area=totalArea;
	end;
	
%%%%%%%%%%%%%%%%%%%%%%	
%
%    function twoDStatValues=gofOnDataMatrix2D(dataMatrix,bleachFactor)
%        [bestx, rmse,dataFit]=fitOf2DGaussianToSpot(dataMatrix,.05);
%        %bestx=muX muY VX  a c
%        twoDStatValues.Vx=bestx(3);
%        %twoDStatValues.Vy=bestx(4);
%        twoDStatValues.intensity=bestx(4);
%        twoDStatValues.rawIntensity=twoDStatValues.intensity*bleachFactor;
%        %twoDStatValues.varianceRatio=twoDStatValues.Vx/twoDStatValues.Vy;
%        twoDStatValues.estimatedFloor=bestx(5);
%        twoDStatValues.rmse=rmse;
%        twoDStatValues.nmse=gfit2(dataMatrix,dataFit,'2');
%        shrunkenData=dataMatrix(2:(end-1),2:(end-1));
%        shrunkenFit=dataFit(2:(end-1),2:(end-1));
%        shrunkenR=corr(shrunkenData(:),shrunkenFit(:));
%        twoDStatValues.shrunkenRsquared=(shrunkenR)^2;
%        
%        scaledDataMat=(dataMat-bestx(5))/bestx(4);
%        scaledDataFit=(dataFit-bestx(5))/bestx(4);
%        gfitLabels={'scmse';'scnmse';'scrmse';'scnrmse';'scmae';'scmare';'scr';'scd';'sce'};
%        gfs=gfit2(scaledDataMat,scaledDataFit,{'1' '2' '3' '4' '5' '6' '7' '8' '9'});
%        for gfi=1:length(gfs)
%            twoDStatValues.(gfitLabels{gfi})=gfs(gfi);
%        end;
%    end
   
%%%%%%%%%%%%%%%%%%%%%%	

    function twoDStatValues=auto2DGaussianFit(dataMatrix,bleachFactor)
        %uses autoGaussianSurf from
        %http://www.mathworks.com/matlabcentral/fileexchange/31485-auto-gaussian-gabor-surface-fit/content/autoGaussianSurf.m
        %To fit a 2D gaussian to the dataMatrix
        [xi, yi]=meshgrid(1:7,1:7);
        res=autoGaussianSurf(xi,yi,dataMatrix);
%         res = 
% 
%          a: 532.2046
%          b: 1.8088e+03
%         x0: 3.5637
%         y0: 4.2051
%     sigmax: 0.2777
%     sigmay: 0.5756
%        sse: 1.6034e+05
%       sse0: 1.8802e+05
%         r2: 0.1473
%          G: [7x7 double]
        twoDStatValues.intensity=res.a;
        twoDStatValues.rawIntensity=twoDStatValues.intensity*bleachFactor;
        twoDStatValues.totalHeight=res.a+res.b;
        twoDStatValues.sigmax=res.sigmax;
        twoDStatValues.sigmay=res.sigmay;
        twoDStatValues.estimatedFloor=res.b;
        dataFit=res.G;
        gfitNonscaled=gfit2(dataMatrix,dataFit,{'3'});
        twoDStatValues.rmse=gfitNonscaled(1);
        shrunkenData=dataMatrix(2:(end-1),2:(end-1));
        shrunkenFit=dataFit(2:(end-1),2:(end-1));
        shrunkenR=corr(shrunkenData(:),shrunkenFit(:));
        twoDStatValues.shrunkenRsquared=(shrunkenR)^2;
        scaledDataMat=(dataMatrix-res.b)/res.a;
        scaledDataFit=(dataFit-res.b)/res.a;
        gfitLabels={'scmse';'scnmse';'scrmse';'scnrmse';'scmae';'scmare';'scr';'scd';'sce'};
        gfs=gfit2(scaledDataMat,scaledDataFit,{'1' '2' '3' '4' '5' '6' '7' '8' '9'});
        for gfi=1:length(gfs)
            twoDStatValues.(gfitLabels{gfi})=gfs(gfi);
        end;
        twoDStatValues.dataFit=res.G;
    end

%%%%%%%%%%%%%%%%%%%%%%    

    function oneDstatValues=oneDGaussStats(dataMatrix,centerR,centerC,bleachFactor)
        %Note that this is just a quick and dirty heuristic, but it is
        %probably fine since it runs 10-15 times faster even if it
        %isn't proper
        %for the RF, intensity is really all that matters
        %for the decision of whether to stop getting spots, need an
        %rsquared
        cY=4;
        cX=4;
        
        if isnan(cY)
            cY=rowToY(centerR);cX=colToX(centerC);
        end;
        
        horizSection=dataMatrix(centerR,:);%+noNANBase;
        hX=cX-(1:size(dataMatrix,1));%calculate from the center of the spot
        vertSection=dataMatrix(:,centerC);%+noNANBase;
        vX=cY-(1:size(dataMatrix,1));%calculate from the center of the spot
        
        %polyfit doesn't like 0s.  add a little noise to avoid this
        horizSection=horizSection+random('unif',.001,.002,size(horizSection)).*(~horizSection);
        vertSection=vertSection+random('unif',.001,.002,size(vertSection)).*(~vertSection);
        
        [c1h,b1h,a1h]=mygaussfit(hX,horizSection-min(horizSection));
        %         disp('vx');
        %         disp(vX);
        %         disp(vertSection);
        [c1v,b1v,a1v]=mygaussfit(vX,vertSection'-min(vertSection));
        oneDstatValues.horizIntensity=a1h;
        oneDstatValues.vertIntensity=a1v;
        oneDstatValues.horizrsquare=gfit2(horizSection,a1h*pdf('Normal',hX,b1h,c1h)/.3989,'8');
        oneDstatValues.vertrsquare=gfit2(vertSection,a1v*pdf('Normal',vX,b1v,c1v)/.3989,'8');
        
        oneDstatValues.meanIntensity=mean([oneDstatValues.horizIntensity,oneDstatValues.vertIntensity]);%,gaufit.cfun.diag1.a1,gaufit.cfun.diag2.a1]);
        
        oneDstatValues.rawHorizIntensity=oneDstatValues.horizIntensity*bleachFactor;
        oneDstatValues.rawVertIntensity=oneDstatValues.vertIntensity*bleachFactor;
        oneDstatValues.rawMeanIntensity=oneDstatValues.meanIntensity*bleachFactor;
        
        oneDstatValues.meanrsquare=sign(oneDstatValues.horizrsquare)*sqrt(mean([oneDstatValues.horizrsquare^2,oneDstatValues.vertrsquare^2]));%,gaufit.gof.diag1.rsquare^2,gaufit.gof.diag2.rsquare^2]));
        
        
        
    end;
    
    %%%%%%%%%%%%%%%%%%%%%%

			function statValues = oneDRawIntensity(oneDstatValues,iSlice,bleachFactors)
				statValues.rawMeanIntensity=oneDstatValues.meanIntensity*bleachFactors(iSlice);
				statValues.rawVertIntensity=oneDstatValues.vertIntensity*bleachFactors(iSlice);
				statValues.rawHorizIntensity=oneDstatValues.horizIntensity*bleachFactors(iSlice);
			end;


%%%%%%%%%%%%%%%%%%%%%%  TEMPLATE for adding new statistics %%%%%%%%%%%%

%			function statValues = myNewStatisticsFunction(arguments passed in)
%				statValues.statisticFieldName = statisticCalculation
%			end;
%
%toc
%time=toc;
%fprintf('Spent % seconds./n',time);

end