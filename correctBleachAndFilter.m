function [segStacks,bleachFactors]=correctBleachAndFilter(segStacks,varargin)
%  ============================================================
%  Name: correctBleachAndFilter.m
%  Version: 2.0, 3rd July 2012
%  Author: Allison Wu, Scott Rifkin
%  * Build from correctForBleach
%  * Correct for bleach with respect to individual worms in individual channel.
%  * Varagin{1}: [0,1] whether to apply laplacian filter, 0 by default.
%
%   Attribution: Wu, AC-Y and SA Rifkin. spotFinding Suite version 2.5, 2013 [journal citation TBA]
%   License: Creative Commons Attribution-ShareAlike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%   Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%   Email for comments, questions, bugs, requests:  Allison Wu < dblue0406 at gmail dot com >, Scott Rifkin < sarifkin at ucsd dot edu >
%
%  =============================================================


% Find out the size of the segmented stacks
h=size(segStacks{1},3); % Assuming all stacks are the same height
%% Slice as reference
wormNum=length(segStacks);
iRefSlice=floor(h/2);
bleachFactors=zeros(h,wormNum);

if isempty(varargin)
    toFilter=0;
else
    toFilter=varargin{1};
end

for wi=1:wormNum
    stack=segStacks{wi};
    refSlice=stack(:,:,iRefSlice);
    medRefSlice=median(refSlice(refSlice(:)>0));
    for zi=1:h
        slice=stack(:,:,zi);
        medSlice=median(slice(slice(:)>0));
        bleachFactors(zi,wi)=medSlice/medRefSlice;
        stack(:,:,zi)=stack(:,:,zi)/bleachFactors(zi,wi);
        if toFilter==1
            stack(:,:,zi)=laplaceembryos(stack(:,:,zi));
        end
    end
    segStack{wi}=stack;
end

end