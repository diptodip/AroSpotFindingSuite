function d=scopeDistance(pt1,pt2)
%calculates the distance between pt1 and pt2 keeping in mind different XY
%and Z resolutions on the scope
res=[.13 .13 .3];%in um

d=sqrt(sum(((pt1-pt2).*res).^2));
end