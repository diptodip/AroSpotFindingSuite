function matr=volumeUnder2DGaussian(rectangleSize,mu,sigma,varargin)
%sigma is the covariance matrix
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
xcoords=(-rectangleSize(1)/2:stepSize:rectangleSize(1)/2)';
ycoords=(-rectangleSize(2)/2:stepSize:rectangleSize(2)/2)';
[X1 X2]=meshgrid(xcoords,ycoords);
X=[X1(:) X2(:)];
corners=mvncdf(X,mu,sigma);
corners=reshape(corners,length(xcoords),length(ycoords));
matr=corners(2:end,2:end)-corners(2:end,1:(end-1))-corners(1:(end-1),2:end)+corners(1:(end-1),1:(end-1));


end