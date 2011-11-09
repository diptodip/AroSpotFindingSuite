function outims = medianfilter(images)
%  =============================================================
%  Name: medianFilter.m   %nameMod
%  Author: Arjun Raj
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%  =============================================================
%does median filtering

sz = size(images);
outims = zeros(sz);

for i = 1:sz(3)
  outims(:,:,i) = medfilt2(images(:,:,i),[3 3]);
end;
