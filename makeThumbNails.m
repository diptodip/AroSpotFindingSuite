function makeThumbNails(fileType)
%% ========================================================================
%   Name:       makeThumbNails.m
%   Version:    2.0, 5th July 2012
%   Author:     Allison Wu
%   Command:    makeThumbNails(fileType)
%   Description: make thumbnails from tif or stk stacks.
%
%% ========================================================================


switch fileType
    
    case {'tif','tiff'}
        fileType='.tif';
        isTiff=1;
    case {'stk'}
        fileType='.stk';
        ifTiff=0;
    otherwise
        disp('Cannot regcognize the input fileType.')
end

posInd=dir(['dapi*' fileType]);
for k=1:length(posInd)
    stackSuffix=regexprep(posInd(k).name,'dapi','');
    stackSuffix=regexprep(stackSuffix,fileType,'');
    stackSuffix=regexprep(stackSuffix,'_','');
    thumbName=['thumbs_' stackSuffix '.tif'];
    if ~exist(thumbName,'file')
        fprintf('Making thumbnails for position %s ... \n', stackSuffix)
        stacks=dir(['**' stackSuffix fileType]);
        stackNames=cell(length(stacks),1);
        for s=1:length(stacks)
            stackNames{s}=stacks(s).name;
        end
        stackNames=sort(stackNames);
        mx=[];
        for k=1:length(stackNames)
            nameSplit=regexprep(stackNames{k},'_','\.');
            nameSplit=regexp(nameSplit,'\.','split');
            dye=nameSplit{1};
            if sum(strcmpi(dye,{'alexa','a594','tmr','cy5','cy','dapi'}))~=0
                if isTiff
                    stack=readTiffStack(stacks(k).name);
                    
                else
                    stackInfo=readmm(stacks(k).name);
                    stack=stackInfo.imagedata;
                end
                stack=stack(:,:,10:25);
                slice=max(double(stack),[],3);
                mxSlice=max(slice(:));
                mnSlice=min(slice(:));
                rangeSlice=mxSlice-mnSlice;
                slice=(slice-mnSlice)/rangeSlice;
                mx=cat(3,mx,slice);
            end
        end
        numcolors=size(mx,3);
        if numcolors==4
            output = [ [mx(:,:,1) , mx(:,:,2)]; [mx(:,:,3) , mx(:,:,4)] ];
        elseif numcolors==3
            output = [ [mx(:,:,1) , mx(:,:,2)]; [mx(:,:,3) , zeros(size(mx(:,:,1)))] ];
        elseif numcolors==2
            output = [mx(:,:,1) , mx(:,:,2)];
        elseif numcolors==1
            output=mx(:,:,1);
        end;
        write8bitTiffStack(output,thumbName)
        
    else
        fprintf('%s is already made.\n',thumbName)
    end
end

end