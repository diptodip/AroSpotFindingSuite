function deltaStats=calculateDeltaStats(dataMat_o)
%% ========================================================================
%   Name:       calculateDeltaStats.m
%   Version:    2.5, 25th Apr. 2013
%   Author:     Allison Wu
%   Command:    deltaStats=calculateDeltaStats(dataMat_o)
%   Description:
%       - take in the m-by-7-by-7 dataMat matrix, which have m number of
%       spots with 7x7 pixels.
%       - calculate delta stats by comparing metric stats to those from
%       shuffled pixels.
%% ========================================================================
[m,n,z]=size(dataMat_o);
permTimes=1000;

plusIndex=[4,11,18,22,23,24,26,27,28,32,39,46]';
starIndex=[4,11,18,22,23,24,26,27,28,32,39,46,1,9,17,31,37,43,7,13,19,33,41,49]';
boxIndex=[17:19,24,26,31:33]';
minusCenter=[1:24,26:49]';
I={plusIndex, starIndex, boxIndex};

deltaStats=zeros(m,length(I)*4);

if n==7 && z==7
    for i=1:m
        dataMat=dataMat_o(i,:,:);
        dataMat=dataMat(:);
        dataMat=dataMat/max(dataMat);
        
        plusSign=dataMat(plusIndex);
        starSign=dataMat(starIndex);
        centerBox=dataMat(boxIndex);
        
        k=1;
       
        dataMat_x=dataMat(minusCenter); %Take away the center pixel.
        sDataMat=zeros(length(dataMat_x),permTimes);
        while k<permTimes+1
            sDataMat(:,k)=dataMat_x(randperm(48));
            k=k+1;
        end
        
        
        
        for j=1:length(I)
            sValues=sDataMat(1:length(I{j}),:);
            value=dataMat(I{j});
            deltaStats(i,4*j-3) = median(sum(abs(sValues-repmat(value,1,permTimes))./repmat(value,1,permTimes))) ; % sum(abs(delta)) , absDeltaSign
            deltaStats(i,4*j-2) = median(sum(sValues-repmat(value,1,permTimes)./repmat(value,1,permTimes))) ; % sum(delta), deltaSign
            deltaStats(i,4*j-1) = median(abs(sum(sValues)-sum(value))); % abs(delta(sum)), absSignDelta
            deltaStats(i,4*j)   = mean(sum(sValues)>sum(value)); % pvalue
        end
       
    end
else
    fprintf('dataMat size is not mx7x7.  No delta stats calcuated.\n')
end
end