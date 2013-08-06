%% ========================================================================
%   Name:       makeThumbNails_forTiff.m
%   Version:    2.0, 5th July 2012
%   Author:     Allison Wu
%   Command:    makeThumbNails_forTiff
%   Description: make thumbnails from tif stacks.
%
%   Attribution: Wu, AC-Y and SA Rifkin. spotFinding Suite version 2.5, 2013 [journal citation TBA]
%   License: Creative Commons Attribution-ShareAlike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%   Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%   Email for comments, questions, bugs, requests:  Allison Wu < dblue0406 at gmail dot com >, Scott Rifkin < sarifkin at ucsd dot edu >
%
%% ========================================================================
% makethumbnails_forTiff.m
% 2011/5/24 made to apply on .tif files
% This program goes through all the stacks in a directory and generates a composite image that is useful for a quick overview.
 
tiffind = 10:25;
 
 
initialnumber = '_Pos0';
 
% First, let's find the color channels
d = dir(['*' initialnumber '*.tif']);
 
clear colors
currcolor = 1;
for i = 1:length(d)
  tmp = strrep(d(i).name,[initialnumber '.tif'],'');
  tmp = strrep(tmp,'_','');
  if ~sum(strcmp(tmp,{'segment','trans','thumbs','gfp'}))  %trans and dapi are "special"
    colors{currcolor} = tmp;
    currcolor = currcolor+1;
  end;
end;
colors=sort(colors);
numcolors = length(colors); % This is the total number of colors
disp(colors);

sizes=zeros(length(colors),1);
for i =1:numcolors
    sizes(i)=length(dir([colors{i} '*tif']));
end;

sz=[min(sizes) numcolors];
posInd=dir(['dapi*tif']); % use dapi for position index
test=imread(posInd(1).name,1);
imsize=size(test);
for i = 1:sz(1)
  mx = zeros([imsize numcolors]);
  stackSuffix=strrep(posInd(i).name, '.tif','');
  stackSuffix=strrep(stackSuffix,['dapi_'],'');
  if isempty(dir(['thumbs' stackSuffix '.tiff']))
  for j = 1:sz(2)
      im=zeros([imsize length(tiffind)]);
      file=dir([colors{j} '_*' stackSuffix '.tif']);
      disp(file.name);
      for k=1:length(tiffind)
            im(:,:,k) = imread(file.name,tiffind(k));
      end
    mm = max(im,[],3);
    mx(:,:,j) = imscale(mm);
  end;
  if numcolors==4
      output = [ [mx(:,:,1) , mx(:,:,2)]; [mx(:,:,3) , mx(:,:,4)] ];
  elseif numcolors==3
      output = [ [mx(:,:,1) , mx(:,:,2)]; [mx(:,:,3) , zeros(size(mx(:,:,1)))] ];
  elseif numcolors==2
            output = [mx(:,:,1) , mx(:,:,2)];
  elseif numcolors==1
            output=mx(:,:,1);
  end;
  imwrite(output,['thumbs' stackSuffix '.tiff']);%num2str(i) '.tiff']);
  else
      fprintf('The thumb nail for %s has been made.\n', stackSuffix);
  end
end;
 