function [embryosegments,outlab,currpolys] = findembryosPreManual(fishmax)

    %originally written by Arjun Raj and modified by Scott Rifkin
    
    %fishmax is a max merege of the fish stack
    
fishmax = double(fishmax);

h = fspecial('log',50,.5);

%h = fspecial('log',50,5);

%fishmax = double(stk(31).data);

fprintf('Filtering image...\n');

L = imfilter(fishmax,h,'replicate');

fprintf('Removing small stuff...\n');

er = imerode(medfilt2(L,[5 5])<0,strel('disk',5));

bw = bwareaopen(er,10000);

fprintf('Watershedding...\n');

dist = bwdist(bw);

mask_em = imextendedmax(dist,10);


dd = -dist;
dd = dd-min(dd(:));
dd = dd/max(dd(:));


I_mod = imimposemin(dd,mask_em);

ws = watershed(I_mod);


fprintf('Finding embryos...\n');

bw2 = ws==0;

bw3 = (bw+bw2)>0;

bw4 = ~bw3;

[lab,n] = bwlabeln(bw4);

currI = lab;
sz = size(currI);


perimvals = currI(1,1:sz(2));
perimvals = [perimvals currI(sz(1),1:sz(2))];
perimvals = [perimvals currI(1:sz(1),1)'];
perimvals = [perimvals currI(1:sz(1),sz(2))'];

remperim = unique(perimvals);
%badareas = find(areas > 2000);
%remperim = intersect(remperim,badareas);

mas = ismember(currI,remperim);

bw5 = lab & ~mas;

[lab,n] = bwlabeln(bw5);

s = regionprops(lab,'basic');

areas = [s.Area];

goodinds = find(areas>20000);

bw6 = ismember(lab,goodinds);
[lab,n] = bwlabeln(bw6);

s = regionprops(lab,'Area','Centroid','BoundingBox','Image','ConvexHull');

currpolys={};
outlab = zeros(size(lab));
%expand it  just so it doesn't crop off  -will have to fix neighboring ones
%anyway
se=strel('disk',25);
for i = 1:n
  %outlab = outlab + (i*poly2mask(s(i).ConvexHull(:,1),s(i).ConvexHull(:,2),1024,1024)).*(outlab==0);
  currpolys{i}=imdilate((i*poly2mask(s(i).ConvexHull(:,1),s(i).ConvexHull(:,2),1024,1024)),se);
  outlab = outlab + (currpolys{i}).*(outlab==0);
end;
embryosegments = regionprops(outlab,'Area','Centroid','BoundingBox','Image');

% Okay, now let's fix that annoying boundingbox thing:

for i = 1:length(embryosegments)
  R = embryosegments(i).BoundingBox;
  R(1:2) = R(1:2)+1;
  R(3:4) = R(3:4)-1;
  embryosegments(i).imageframe = R;
end;
