function d=scopeDistanceForpdist2(pt1,pts2)
%calculates the distance between pt1 and pts2 (matrix of pts) keeping in mind different XY
%and Z resolutions on the scope
res=[.13 .13 .3];%in um
nPts2=size(pts2,1);
diffVects=repmat(pt1,nPts2,1)-pts2;
scaledDiffVects=diffVects.*repmat(res,nPts2,1);
d=sqrt(sum(scaledDiffVects.^2,2));
end