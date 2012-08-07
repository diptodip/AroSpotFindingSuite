function createSegImages(stackFileType,varargin)
%% ========================================================================
%   Name:       createSegImages.m
%   Version:    2.1, 3 July 2012
%   Author:     Allison Wu
%   Command:    createSegImages(stackFileType)
%   Description:
%       - Creates "dye_posSuffix_segStacks.mat" files for each position and each channel
%       - segStacks.mat files can be used for spot analysis and nuclei counting
%       - Each segStacks.mat file has two cell arrays.
%         One is segStacks,which saves all the segmented image stacks for each worm in each cell.
%         The other is segMasks, which saves the mask matrix for each worm in each cell.
%       - reSize: the scale you want to resize your image. (if it's 0-1, it
%       shrinks the image.)%
%   Files required:     stk or tiff image stacks, segmenttrans_{stackSuffix}.mat, metaInfo.mat (for tif)
%   Files generated:    {dye}_{stackSuffix}_segStacks.mat
%% ========================================================================
%
% Modifications
% 6 Aug 2012.  Modified clear, load, and save functions to work with a
% parfor loop over the stacks
%

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
                
if ~isempty(varargin)
    reSize=varargin{1};
else
    reSize=1;
end
%changed to parfor which means that can't clear inside loop%6Aug12 SR
%and save, load, and exist become morecomplicated

parfor i=1:length(stacks)%6Aug12 SR
    for di=1:length(dye)
        
        %Had to modify to work with my segmenttrans which don't have '_' in
        %them
        %Also had to modify load to work with parfor
        if size(regexp(stacks(i).name,'_','split'),2)>1%then it has a '_' in it%6Aug12 SR
            
            stackName=regexprep(stacks(i).name,'_','\.');
            nameSplit=regexp(stackName,'\.','split');
            nameSplit=nameSplit(~cellfun('isempty',nameSplit));
            stackSuffix=nameSplit{2};
            segStackFileName=[dye{di} '_' stackSuffix '_SegStacks.mat'];
            cps=load(['segmenttrans_' stackSuffix '.mat']);%6Aug12 SR
            currpolys=cps.currpolys;%6Aug12 SR
        else%6Aug12 SR
            stackSuffix=collectDigits(stacks(i).name);%6Aug12 SR
            stackSuffix=stackSuffix{1};%6Aug12 SR
            segStackFileName=[dye{di} '_' stackSuffix '_SegStacks.mat'];%6Aug12 SR
            cps=load(stacks(i).name);%6Aug12 SR
            currpolys=cps.currpolys;%6Aug12 SR
        end;%6Aug12 SR
        
        
        
        
        if ~exist(segStackFileName,'file') %cy5_Pos0_segStacks.mat
            fprintf('Creating %s segStacks of %s ....\n',dye{di},stackSuffix);
            tic
            fprintf('Dye %s: \n',dye{di})
            segStacks=cell(length(currpolys),1);
            segMasks=cell(length(currpolys),1);
            stackFound=0;%flag to see if the file is good or not
            if strcmp(stackFileType,'stk')
                if exist([dye{di} stackSuffix '.stk'],'file')
                    disp(['reading ' dye{di} stackSuffix '.stk']);
                    stackInfo=readmm([dye{di} stackSuffix '.stk']);
                    stack=stackInfo.imagedata;
                    stackInfo=[];%6Aug12 SR
                    %clear stackInfo%6Aug12 SR
                    stack=double(stack);
                    stackFound=1;
                else
                    fprintf('Failed to find the file %s .', [dye{di} stackSuffix '.stk'])
                end
            elseif strcmp(stackFileType,'tif') || strcmp(stackFileType,'tiff')
                if exist([dye{di} '_' stackSuffix '.tif'],'file')
                    stack=double(readTiffStack([dye{di} '_' stackSuffix '.tif']));
                    stackFound=1;
                elseif exist([dye{di} '__' stackSuffix '.tif'],'file')
                    stack=readTiffStack([dye{di} '__' stackSuffix '.tif']);
                    stackFound=1;
                else
                    fprintf('Failed to find the file %s .', [dye{di} '_' stackSuffix '.tif'])
                end
            end
            if stackFound%this will remain 0 if the file was not found %6Aug12 SR
                for wi=1:length(currpolys)
                    bb=regionprops(double(currpolys{wi}),'BoundingBox');
                    %disp(size(currpolys{wi}));
                    wormMask=imresize(imcrop(currpolys{wi},bb.BoundingBox),reSize);
                    wormImage=zeros([size(wormMask), size(stack,3)]);
                    %fprintf('Worm %d : ', wi)
                    segMasks{wi}=wormMask;
                    
                    for zi=1:size(stack,3)
                    %disp(bb.BoundingBox);
                    %disp(size(stack(:,:,zi)));
                        wormImage(:,:,zi)=double(imcrop(stack(:,:,zi),bb.BoundingBox)).*wormMask;
                        wil=wormImage(:,:,zi);
                        wil=wil(wil>0);%don't change to their suggested equivalent...doesn't work
                        pwil=max(prctile(wil,20));
                        %disp([num2str(zi) ' ' num2str(pwil)]);
                        wormImage(:,:,zi)=wormImage(:,:,zi)/pwil;%takes care of out of focus ones
                        %clear('wil'); %6Aug12 SR
                        wil=[]; %6Aug12 SR
                    end
                    segStacks{wi}=wormImage;
                    wormImage=[];%6Aug12 SR
                    %clear wormImage %6Aug12 SR
                    fprintf('%g%% ', wi/length(currpolys)*100)
                end
                
                %adjusted for parfor %6Aug12 SR
                parsaveSegInfo(fullfile(pwd,segStackFileName),segStacks,segMasks);%6Aug12 SR
                %save(fullfile(pwd,segStackFileName),'segStacks','segMasks')%6Aug12 SR
                fprintf('\n')
                tElapsed=toc;%6Aug12 SR
                %tElapsed=tElapsed/60;%6Aug12 SR
                fprintf('For %s in position %s , it took %g seconds. \n', dye{di}, stackSuffix, tElapsed)%6Aug12 SR
                
                %clear stack
                stack=[];
            end;%6Aug12 SR
        else
            fprintf('%s segStacks of %s is already saved.\n', dye{di},stackSuffix)
            
        end
        fprintf('\n')
        
    end
end
%stack=readTiffStack(['dapi' stackSuffix '.tif'],1,stackSize(di,3));
%stack=double(stack);

end

function parsaveSegInfo(fileName,segStacks,segMasks)%6Aug12 SR
%http://www.mathworks.com/support/solutions/en/data/1-D8103H/index.html?product=DM&solution=1-D8103H
%Takes care of the problem of saving within parfor loops
save(fileName, 'segStacks','segMasks')
end