function [g2b b2g]=calculateErrorRange(Probs, IQR, IQRt,quantile)
unreliableSpots=Probs(IQR>IQRt);
unreliableGoodSpots=unreliableSpots(unreliableSpots>0.5);
unreliableBadSpots=unreliableSpots(unreliableSpots<0.5);
if ~isempty(unreliableGoodSpots)
    randG=binornd(1,repmat(unreliableGoodSpots,1,1000),length(unreliableGoodSpots),1000);
    g2b=prctile(sum(~randG,1),100-quantile);
else
    g2b=0;
end

if ~isempty(unreliableBadSpots)
    randB=binornd(1,repmat(unreliableBadSpots,1,1000),length(unreliableBadSpots),1000);
    b2g=prctile(sum(randB,1), quantile);
else 
    b2g=0;
end
end