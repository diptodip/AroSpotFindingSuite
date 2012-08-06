function createSegImages(stackFileType,varargin)
%% ========================================================================
%   Name:       createSegImages.m
%   Version:    2.0, 3 July 2012
%   Author:     Allison Wu
%   Command:    createSegImages(stackFileType)
%   Description:
%       - Creates "dye_posSuffix_segStacks.mat" files for each position and each channel
%       - segStacks.mat files can be used for spot analysis and nuclei counting
%       - Each segStacks.mat file has two cell arrays.
%         One is segStacks,which saves all the segmented image stacks for each worm in each cell.
%         The other is segMasks, which saves the mask matrix for each worm in each cell.
%
%   Files required:     stk or tiff image stacks, segmenttrans_{stackSuffix}.mat, metaInfo.mat (for tif)
%   Files generated:    {dye}_{stackSuffix}_segStacks.mat
%% ========================================================================

% stackFileType: 'stk', 'tif'

% Determine filetype and find available color channels first
disp(['Stack file type is: ' stackFileType]);
disp('Determine the channels available : ')
if strcmp(stackFileType,'stk')
    initialnumber = '001';
    d = dir(['*' initialnumber '*.stk']);
    currcolor = 1;
    for i = 1:length(d)
        tmp = strrep(d(i).name,[initialnumber '.stk'],'');
        tmp = strrep(tmp,'_','');
        if ~sum(strcmp(tmp,{'segment','thumbs','gfp'}))  %these are "special"
            dye{currcolor} = tmp;
            currcolor = currcolor+1;
        end;
    end;
    
elseif strcmp(stackFileType,'tif') || strcmp(stackFileType,'tiff')
    initialnumber = '_Pos0';
    d = dir(['*' initialnumber '*.tif']);
    currcolor = 1;
    for i = 1:length(d)
        tmp = strrep(d(i).name,[initialnumber '.tif'],'');
        tmp = strrep(tmp,'_','');
        if ~sum(strcmp(tmp,{'segment','thumbs','gfp'}))  %these are "special"
            dye{currcolor} = tmp;
            currcolor = currcolor+1;
        end;
    end;
    
end;

dye=sort(dye);
disp(dye);


stacks=dir('segmenttrans*');
stackSize=zeros(length(dye),3);

for i=1:length(stacks)
    for di=1:length(dye)
        
        stackName=regexprep(stacks(i).name,'_','\.');
        nameSplit=regexp(stackName,'\.','split');
        nameSplit=nameSplit(~cellfun('isempty',nameSplit));
        stackSuffix=nameSplit{2};
        segStackFileName=[dye{di} '_' stackSuffix '_SegStacks.mat'];
        disp(stackSuffix);
        load(['segmenttrans_' stackSuffix '.mat'])
        if ~exist(segStackFileName,'file') %cy5_Pos0_segStacks.mat
            fprintf('Creating %s segStacks of %s ....\n',dye{di},stackSuffix);
            tic
            fprintf('Dye %s: \n',dye{di})
            segStacks=cell(length(currpolys),1);
            segMasks=cell(length(currpolys),1);
            if strcmp(stackFileType,'stk')
                if exist([dye{di} stackSuffix '.stk'],'file')
                    stackInfo=readmm([dye{di} stackSuffix '.stk']);
                    stack=stackInfo.imagedata;
                    clear stackInfo
                    stack=double(stack);
                else
                    fprintf('Failed to find the file %s .', [dye{di} stackSuffix '.stk'])
                end
            elseif strcmp(stackFileType,'tif') || strcmp(stackFileType,'tiff')
                if exist([dye{di} '_' stackSuffix '.tif'],'file')
                    stack=double(readTiffStack([dye{di} '_' stackSuffix '.tif']));
                elseif exist([dye{di} '__' stackSuffix '.tif'],'file')
                    stack=readTiffStack([dye{di} '__' stackSuffix '.tif']);
                else
                    fprintf('Failed to find the file %s .', [dye{di} '_' stackSuffix '.tif'])
                end
            end
            
            for wi=1:length(currpolys)
                bb=regionprops(double(currpolys{wi}),'BoundingBox');
                wormMask=imcrop(currpolys{wi},bb.BoundingBox);
                wormImage=zeros([size(wormMask), size(stack,3)]);
                %fprintf('Worm %d : ', wi)
                segMasks{wi}=wormMask;
                
                for zi=1:size(stack,3)
                    wormImage(:,:,zi)=double(imcrop(stack(:,:,zi),bb.BoundingBox)).*wormMask;
                    wil=wormImage(:,:,zi);
                    wil=wil(wil>0);%don't change to their suggested equivalent...doesn't work
                    pwil=max(prctile(wil,20));
                    %disp([num2str(zi) ' ' num2str(pwil)]);
                    wormImage(:,:,zi)=wormImage(:,:,zi)/pwil;%takes care of out of focus ones
                    clear('wil');
                end
                segStacks{wi}=wormImage;
                clear wormImage
                fprintf('%g%% ', wi/length(currpolys)*100)
            end
            
            save(fullfile(pwd,segStackFileName),'segStacks','segMasks')
            fprintf('\n')
            tElapsed=toc;
            tElapsed=tElapsed/60;
            fprintf('For %s in position %s , it took %g minutes. \n', dye{di}, stackSuffix, tElapsed)
            
            clear stack
            
            
        else
            fprintf('%s segStacks of %s is already saved.\n', dye{di},stackSuffix)
            
        end
        fprintf('\n')
        
    end
end
%stack=readTiffStack(['dapi' stackSuffix '.tif'],1,stackSize(di,3));
%stack=double(stack);
end