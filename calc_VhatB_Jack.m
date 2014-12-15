function vhatBJ_U=calc_VhatB_Jack(spotTreeProbs,nBi)
%calculates eqn (6) from Wager, Hastie, Efron 2014.
%nBi_m_1 is nTrainingSetSpots x nTrees

B=size(nBi,2);
classified=spotTreeProbs>=.5;
thetahatBX=mean(classified,2);
n=size(nBi,1);
vhatBJ=zeros(n,1);
for ix=1:size(classified,1)
    for iTS=1:n   
        treesToUse=find(nBi(iTS,:)==0);
        deltaHati=mean(classified(ix,treesToUse))-thetahatBX;
        vhatBJ(ix)=vhatBJ(ix)+(deltaHati)^2;
    end;
end;
vhatBJ=vhatBJ*(n-1)/n;
tbarStarX=mean(classified,2);
tbx_m_tbarx=classified-repmat(tbarStarX,1,B);%this is nX x nTrees (B)

bias=((exp(1)-1)*n/(B^2))*sum(tbx_m_tbarx.^2,2);

vhatBJ_U=vhatBJ - bias;

end

