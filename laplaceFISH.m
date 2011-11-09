function outims = laplaceFISH(ims,npasses)
%  =============================================================
%  Name: laplaceFISH.m   %nameMod
%  Version: 1.0, 9 Nov 2011   %nameMod
%  Author: Arjun Raj
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%  =============================================================
%This is a filtering function to do a laplace filter on a FISH image

newFISHfilter;
  
sz = size(ims);

outims = zeros(sz);

fprintf('Processing image stack, run number ');

ims = medianfilter(ims);
outims = ims;

for i = 1:npasses
  fprintf('%d ',i);
  outims = imfilter(outims,h4,'replicate');
  outims = (outims>0).*outims;
end;

fprintf('\n');