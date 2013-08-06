function [results] = autoGaussianSurf(xi,yi,zi)
%Copyright (c) 2011, Patrick Mineault
%All rights reserved.
%
%Redistribution and use in source and binary forms, with or without
%modification, are permitted provided that the following conditions are
%met:
%
%    * Redistributions of source code must retain the above copyright
%      notice, this list of conditions and the following disclaimer.
%    * Redistributions in binary form must reproduce the above copyright
%      notice, this list of conditions and the following disclaimer in
%      the documentation and/or other materials provided with the distribution
%
%THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
%LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%POSSIBILITY OF SUCH DAMAGE.    
%
%function [results] = autoGaussianSurf(xi,yi,zi)
    %
    %Fit a surface zi = a*exp(-((xi-x0).^2/2/sigmax^2 + ...
    %                           (yi-y0).^2/2/sigmay^2)) + b
    %
    %On the assumption of Gaussian noise through maximum likelihood
    %(least-squares).
    %
    %The procedure is "robust" in the sense that it is unlikely to get 
    %stuck in local minima which makes it appropriate in fully automated 
    %scenarios. This is accomplished through an initial exhaustive search 
    %for the parameters, followed by refinement with lsqcurvefit
    %
    %Currently only regular grids (generated through meshgrid) are accepted
    %for xi and yi. 
    %Example use:
    %
    %[xi,yi] = meshgrid(-10:10,-20:20);
    %zi = exp(-(xi-3).^2-(yi+4).^2) + randn(size(xi));
    %results = autoGaussianSurf(xi,yi,zi)
    %
    %Returns results, a struct with elements a,b,x0,y0,sigmax,sigmay for
    %the estimated model parameters, G which is the Gaussian evaluated with
    %the estimated model params, and sse, sse0 and r2, which are the sum of
    %squared error for the fitted Gaussian, the sum of squared error for a
    %model with only an offset, and the R^2 proportion of variance
    %accounted for.
    sz = size(zi);
    
    %Verify that the grid is regular
    if any(any(abs(diff(xi,2,2)) >=1e3*eps)) || any(any(diff(yi,2,1) >= 1e3*eps))
        error('xi or yi is not a regular grid');
    end
    
    if any(size(zi)~=size(xi)) || any(size(zi)~=size(yi))
        error('xi, yi and zi are not the same size');
    end
    
    xi = xi(:);
    yi = yi(:);
    boundx = [min(xi),max(xi)];
    boundy = [min(yi),max(yi)];
    
    %Find a minimum sigma based on number of elements, range of x and y
    rgx = diff(boundx);
    minsigmax = rgx/sz(2)/5;
    maxsigmax = rgx/2;

    rgy = diff(boundy);
    minsigmay = rgy/sz(1)/5;
    maxsigmay = rgy/2;
    
    minsigma = min(minsigmax,minsigmay);
    maxsigma = max(maxsigmax,maxsigmay);
    sigmas = exp(log(minsigma):.3:log(maxsigma));
    
    rgx = [0:sz(2)/2,-ceil(sz(2)/2)+1:-1]';
    rgy = [0:sz(1)/2,-ceil(sz(1)/2)+1:-1]';
    
    res = zeros(length(sigmas),7);
    
    %Run through all the different values for sigma
    for ii = 1:length(sigmas)
        thefiltx = exp(-rgx.^2/2/sigmas(ii));
        thefilty = exp(-rgy.^2/2/sigmas(ii));
        %convolve zi with gaussian filters and find the maximum response
        %(matched filtering)
        zi2 = reflectconv(reflectconv(zi,thefilty)',thefiltx)';
        [~,pos] = max(zi2(:));
        x0 = xi(pos);
        y0 = yi(pos);
        %[y0,x0] = ind2sub(sz,pos);
        
        %Determine the residual error for the optimal x, y for this sigma
        G = exp(-((xi-x0).^2+(yi-y0).^2)/2/sigmas(ii)^2);
        X = [G,ones(length(G),1)];
        ps = X\zi(:);
        res(ii,:) = [sum((zi(:) - X*ps).^2),ps(:)',x0,y0,sigmas(ii),sigmas(ii)];
    end
    
    %Find sigma with corresponding least error
    [~,optsigma] = min(res(:,1));
    
    %Fit the parameters again through lsqcurvefit
    opts = optimset('Display','off');
    lb = [-Inf,-Inf,boundx(1),boundy(1),minsigmax /1.01,minsigmay /1.01]';
    ub = [ Inf, Inf,boundx(2),boundy(2),maxsigmax + .01,maxsigmay + .01]';
    [params,residual] = lsqcurvefit(@(x,xdata) pointgaussian(x,[xi,yi]),res(optsigma,2:end)',xi,zi(:),lb,ub,opts);
    
    %Collect the results
    results.a = params(1);
    results.b = params(2);
    results.x0 = params(3);
    results.y0 = params(4);
    results.sigmax = params(5);
    results.sigmay = params(6);
    results.sse = residual;
    results.sse0 = sum((zi(:)-mean(zi(:))).^2);
    results.r2 = 1-results.sse/results.sse0;
    
    results.G = reshape(pointgaussian(params,[xi,yi]),size(zi));
end

function [thef] = pointgaussian(x,xdata)
    thef = x(1)*exp(-.5*(bsxfun(@minus,xdata,x(3:4)').^2)*(1./x(5:6).^2)) + x(2);
end

%Convolution with reflected edge handling
function A = reflectconv(A,f)
    A = bsxfun(@times,fft([A(end:-1:1,:);A;A(end:-1:1,:)]),fft([f(1:floor(end/2));zeros(length(f)*2,1);f(floor(end/2)+1:end)]));
    A = ifft(A);
    A = A(length(f)+1:2*length(f),:);
end