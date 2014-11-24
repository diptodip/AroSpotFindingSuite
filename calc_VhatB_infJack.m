function vhatBIJ_U=calc_VhatB_infJack(spotTreeProbs,nBi)
%calculates eqn (5) from Wager, Hastie, Efron 2014.
%nBi_m_1 is nTrainingSetSpots x nTrees

B=size(nBi,2);
classified=spotTreeProbs>=.5;
tbarStarX=mean(classified,2);
tbx_m_tbarx=classified-repmat(tbarStarX,1,B);%this is nX x nTrees (B)
n=size(nBi,1);
vhatBIJ=zeros(n,1);
for ix=1:size(classified,1)
    for iTS=1:n
        covi=0;
        covi=covi+dot(nBi(iTS,:)-1,tbx_m_tbarx(ix,:));
        covi=covi/B;
        vhatBIJ(ix)=vhatBIJ(ix)+covi^2;
    end;
end;

bias=(n/(B^2))*sum(tbx_m_tbarx.^2,2);

vhatBIJ_U=vhatBIJ-bias;


end

