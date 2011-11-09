function matr=volumeUnder1DGaussian(vectorSize,mu,variance,varargin)

%mu is a 2D vector 
% 
%         Xi=[-.5 .5 .5 -.5]';
%         Xj=[-.5 -.5 .5 .5]';
% 
% for i=1:rectangleSize(1)
%     for j=1:rectangleSize(2)
%         X=[i-Xi j-Xj];
%         corners=mvncdf(X,mu,sigma);
%         matr1(i,j)=corners(3)-corners(2)-corners(4)+corners(1);
%     end;
% end;

stepSize=1;
if size(varargin,2)>0
    stepSize=varargin{1};
end;
xcoords=(-vectorSize/2:stepSize:vectorSize/2)';
corners=normcdf(xcoords,mu,sqrt(variance));
matr=corners(2:end)-corners(1:(end-1));


end