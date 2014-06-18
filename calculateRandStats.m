function [randStats,cumSumPrctiles]=calculateRandStats(dataMat_o)
%% ========================================================================
%   Name:       calculateRandStats.m
%   Version:    2.5, 25th Apr. 2013
%   Author:     Allison Wu
%   Command:    [randStats,cumSumPrctiles]=calculateRandStats(dataMat_o)
%   Description:
%       - take in the m-by-7-by-7 dataMat matrix, which have m number of
%       spots with 7x7 pixels.
%       - calculate cumulative sum percentiles (cumSumPrctiles)
%       - calculate the randStats which compare the cumSumPrctiles to
%       cumSumPrctiles distribution from randomly generated 7x7 pixels.
%% ========================================================================
[m,n,z]=size(dataMat_o);
randTimes=1000;
pixNum=n*z;
bDataMat=rand(pixNum,randTimes);
rdPrctiles=prctile(cumsum(sort(bDataMat)),[90,70,50,30])';
randStats=zeros(m,5);
cumSumPrctiles=zeros(m,4);
if n==7 && z==7
    for i=1:m
        dataMat=dataMat_o(i,:,:);
        dataMat=dataMat(:);
        dataMat=(dataMat-min(dataMat))/(max(dataMat)-min(dataMat));
        cumSumPrctiles(i,:)=prctile(cumsum(sort(dataMat)),[90,70,50,30]); % percentiles of cumulative sum of intensity 
        randStats(i,1)=mean(sum(bDataMat)>sum(dataMat)); % Total Area p-value
        randStats(i,2:5)=mean(rdPrctiles>repmat(cumSumPrctiles(i,:),randTimes,1));% prctile p-value
                
    end
else
    fprintf('dataMat size is not 7x7.  No bootstrap stats calcuated.')
    
end




end