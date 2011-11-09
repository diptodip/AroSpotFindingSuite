function [bestx, fval,best2DGaussian]=fitOf2DGaussianToSpot(spotMat,tolfun)
%V is variance in covar matrix...allow different ones for each direction
%a is intensity (multiplicative scaling)
%c is additive factor (baseline)
% centers=ceil(size(spotMat)/2);
% startV=var(spotMat(centers(1),:));

sz=size(spotMat);
options=optimset('Algorithm','active-set','MaxFunEvals',1000,'TolFun',tolfun,'Display','off');

mn=min(spotMat(:));
mx=max(spotMat(:));

x0=double([0 0 .7 mx mn]); %muX muY VX  a c
lb=double([-1 -1 .2  0 .5*mn]);
ub=double([1 1 5 2^16 mx]);
%for keeping the two variances the same use Aeq beq
tstart=tic;
[bestx, fval]=fmincon(@minimizingFunction,x0,[],[],[],[],lb,ub,[],options);
toc(tstart)
best2DGaussian=bestx(5)+bestx(4)*(volumeUnder2DGaussian(sz,[bestx(1),bestx(2)],[bestx(3) 0.; 0. bestx(3)]));

%disp(gfit2(spotMat,gaussianVol,{'3','7','8','9'}));
    function rmse=minimizingFunction(x)
        %x is [mu(1) mu(2) var a c
 
        % gaussianVol=x(5)+x(4)*(volumeUnder2DGaussian(size(spotMat),[x(1)
        % x(2)],[x(3) 0; 0 x(3)]));
       ts=tic;
        gaussianVol=(volumeUnder2DGaussian(sz,[x(1) x(2)],[x(3) 0; 0 x(3)]));
        gaussianVol=gaussianVol*x(4);
        gaussianVol=gaussianVol+x(5);
       k=toc(ts);
        %Scale volume to 1
        rmse=gfit2(spotMat,gaussianVol,'3');
        
      
    end
        function rmse=minimizingFunction1D(x)
        %x is [mu(1) mu(2) var a c
        
        % gaussianVol=x(5)+x(4)*(volumeUnder2DGaussian(size(spotMat),[x(1) x(2)],[x(3) 0; 0 x(3)]));
        gaussianVol=(volumeUnder1DGaussian(length(slice),x(1),x(2)));
        gaussianVol=gaussianVol*x(3);
        gaussianVol=gaussianVol+x(4);
        %Scale volume to 1
        rmse=gfit2(slice,gaussianVol,'3');
        
    end

    
    

end

