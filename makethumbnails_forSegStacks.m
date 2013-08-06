function makethumbnails_forSegStacks
%  =============================================================
%  Name: makethumbnails_forSegStacks.m          %nameMod
%  Author: Allison Wu, webpage: http://www.biology.ucsd.edu/labs/rifkin/%
%   Attribution: Wu, AC-Y and SA Rifkin. spotFinding Suite version 2.5, 2013 [journal citation TBA]
%   License: Creative Commons Attribution-ShareAlike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%   Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%   Email for comments, questions, bugs, requests:  Allison Wu < dblue0406 at gmail dot com >, Scott Rifkin < sarifkin at ucsd dot edu >
%
%%  =============================================================

% First, let's find the color channels
initialnumber='001';
d = dir(['*' initialnumber '_SegStacks.mat']);
currcolor = 1;
for i = 1:length(d)
    tmp = strrep(d(i).name,[initialnumber '_SegStacks.mat'],'');
    tmp = strrep(tmp,'_','');
    if ~sum(strcmp(tmp,{'segment','trans','thumbs','gfp'}))  %trans and dapi are "special"
        colors{currcolor} = tmp;
        currcolor = currcolor+1;
    end;
end;
colors=sort(colors);
disp(colors);
posInd=dir(['cy*_SegStacks.mat']);
numcolors=length(colors);
for k=1:length(posInd)
    posNum=strrep(posInd(k).name,'cy_','');
    posNum=strrep(posNum,'_SegStacks.mat','');
    fprintf('Making thumbnails for position %s \n',posNum)
    for i=1:length(colors)
        fileName=strrep(posInd(k).name,'cy',colors{i});
        
        load(fileName)
        if i==1
            sz=size(segStacks{1});
            mx=zeros(sz(1),sz(2),numcolors);
        end
        mx(:,:,i)=max(segStacks{1}(:,:,3:25),[],3);
    end
    if numcolors==4
        output = [ [mx(:,:,1) , mx(:,:,2)]; [mx(:,:,3) , mx(:,:,4)] ];
    elseif numcolors==3
        output = [ [mx(:,:,1) , mx(:,:,2)]; [mx(:,:,3) , zeros(size(mx(:,:,1)))] ];
    elseif numcolors==2
        output = [mx(:,:,1) , mx(:,:,2)];
    elseif numcolors==1
        output=mx(:,:,1);
    end;
    write8bitTiffStack(output,['thumbs_' posNum '.tiff'])
end


end