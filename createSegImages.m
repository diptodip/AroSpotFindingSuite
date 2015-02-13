function createSegImages(stackFileType,varargin)
%% ========================================================================
%   Name:       createSegImages.m
%   Version:    2.3, 6th Jan. 2014
%   Author:     Allison Wu
%   Command:    createSegImages(stackFileType,reSize*)
%   Description:
%       - Creates "dye_posSuffix_segStacks.mat" files for each position and each channel
%       - segStacks.mat files can be used for spot analysis and nuclei counting
%       - Each segStacks.mat file has two cell arrays.
%         One is segStacks,which saves all the segmented image stacks for each worm in each cell.
%         The other is segMasks, which saves the mask matrix for each worm in each cell.
%       - varagin has two potential arguments: reSize: the scale you want to resize your image. (if it's 0-1, it
%       shrinks the image.)
%
%   Files required:     stk or tiff image stacks, segmenttrans_{stackSuffix}.mat, metaInfo.mat (for tif)
%                       File name examples: cy5_Pos0.tif,
%                                           segmenttrans_Pos0.mat
%   Files generated:    {dye}_{stackSuffix}_segStacks.mat

%   Updates: 
%       - 2012 Aug. 6th, adding the input variable for users to resize the images.   
%       - 2013 Apr. 11th, change the way it finds the dye names, making it
%       more generic.
%       - 2013 Apr. 16th, replace readTiffStack with loadtiff to avoid
%       imread problem on Mac.
%       - 2014 Jan. 6th, modify the code to make it accomodate extra channels.    
%       - 2015 Feb. 11th, modified to take info from the parameter file
%       - 2015 Feb. 12th, segStacks is now not masked out.
%% ========================================================================

   run('Aro_parameters.m');

% stackFileType: 'stk', 'tif'

% Determine filetype and find available color channels first
disp(['Stack file type is: ' stackFileType]);
disp('Determine the channels available : ')
% 
% if strcmp(stackFileType,'stk')
%     initialnumber = '001';
%     d = dir(['*' initialnumber '*.stk']);
%     currcolor = 1;
%     for i = 1:length(d)
%         tmp = strrep(d(i).name,[initialnumber '.stk'],'');
%         tmp = strrep(tmp,'_','');
%         if ~sum(strcmp(tmp,{'segment','thumbs','gfp'}))  %these are "special"
%             dye{currcolor} = tmp;
%             currcolor = currcolor+1;
%         end;
%     end;
%     
% elseif strcmp(stackFileType,'tif') || strcmp(stackFileType,'tiff')
%     d = dir('*_*.tif');
%     if ~isempty(d)
%         tmp={length(d),1};
%         for k=1:length(d)
%             nameSplit=regexp(d(k).name,'_','split');
%             tmp{k}=nameSplit{1};
%         end
%         tmp=unique(tmp);
% 
%         j = 1;k=1;
%         while j<=length(tmp) 
%             if ~sum(strcmpi(tmp(j),{'segment','thumbs','gfp','trans'}))  %these are "special"
%                 dye{k} = tmp{j};
%                 k=k+1;
%             end
%                 j = j+1;
%         end;    
%     else
%         disp(['Length of d is 0 (no tiffs) in ' pwd]);
%     end;
% end;

dye=dyesUsed;
if ~isempty(isdapi)
    dye{end+1}='dapi';
end;


dye=sort(dye);
disp(dye);


stacks=dir(fullfile(SegmentationMaskDir,'segmenttrans*'));
stackSize=zeros(length(dye),3);

if ~isempty(varargin)
    reSize=varargin{1};
else
    reSize=1;
end


for i=1:length(stacks)
    for di=1:length(dye)
        if strcmp(stackFileType,'stk')
            stackName=regexprep(stacks(i).name,'segmenttrans','');
            stackSuffix=regexprep(stackName,'.mat','');
            load(fullfile(SegmentationMaskDir,['segmenttrans' stackSuffix '.mat']));
        elseif strcmp(stackFileType,'tif') || strcmp(stackFileType,'tiff')
            stackName=regexprep(stacks(i).name,'_','\.');
            nameSplit=regexp(stackName,'\.','split');
            nameSplit=nameSplit(~cellfun('isempty',nameSplit));
            stackSuffix=nameSplit{2};
            load(fullfile(SegmentationMaskDir,['segmenttrans_' stackSuffix '.mat']));
        end
        switch nestedOrFlatDirectoryStructure
            case 'flat'
                segStackFileName=[dye{di} '_' stackSuffix '_SegStacks.mat'];
            case 'nested'
                segStackFileName=fullfile(SegStacksDir,dye,[dye{di} '_' stackSuffix '_SegStacks.mat']);
        end;
        disp(stackSuffix);
        
        if ~exist(segStackFileName,'file') %e.g. cy5_Pos0_segStacks.mat % don't overWrite
            fprintf('Creating %s segStacks of %s ....\n',dye{di},stackSuffix);
            tic
            fprintf('Dye %s: \n',dye{di})
            segStacks=cell(length(currpolys),1);
            segMasks=cell(length(currpolys),1);
            if strcmp(stackFileType,'stk')
                switch nestedOrFlatDirectoryStructure
                    case 'flat'
                        imageFileName=[dye{di} stackSuffix '.stk'];
                    case 'nested'
                        imageFileName=fullfile(ImageDir,dye,[dye{di} stackSuffix '.stk']);
                end;
                if exist(imageFileName,'file')
                    stackInfo=readmm(imageFileName);
                    stack=stackInfo.imagedata;
                    clear stackInfo
                    stack=double(stack);
                else
                    fprintf('Failed to find the file %s .', imageFileName)
                end
            elseif strcmp(stackFileType,'tif') || strcmp(stackFileType,'tiff')
                switch nestedOrFlatDirectoryStructure
                    case 'flat'
                        imageFileName=[dye{di} '_' stackSuffix '.tif'];
                    case 'nested'
                        imageFileName=fullfile(ImageDir,dye,[dye{di} '_' stackSuffix '.tif']);
                end;

                if exist(imageFileName,'file') %tif
                    stack=double(loadtiff(imageFileName));
                elseif exist([imageFileName 'f'],'file') %tiff
                    stack=loadtiff([imageFileName 'f']);
                else
                    fprintf('Failed to find the file %s .', imageFileName)
                end
            end
            
            for wi=1:length(currpolys)
                bb=regionprops(double(currpolys{wi}),'BoundingBox');
                wormMask=imresize(imcrop(currpolys{wi},bb.BoundingBox),reSize);
                wormImage=zeros([size(wormMask), size(stack,3)]);
                %fprintf('Worm %d : ', wi)
                segMasks{wi}=wormMask;
                
                %A question of whether to mask the outside or keep it in.
                %If it is kept in, then it causes display problems in the
                %reviewing. Also it messes up spots on the edges because
                %they can be artificially clipped down to 0
                for zi=1:size(stack,3)
                    wormImage(:,:,zi)=imresize(double(imcrop(stack(:,:,zi),bb.BoundingBox)),reSize);
                    wil=wormImage(:,:,zi).*wormMask;
                    wil=wil(wil>0);
                    pwil=max(prctile(wil,20));%%? why max?
                    %disp([num2str(zi) ' ' num2str(pwil)]);
                    %%%%%%%%%%%%%%%%%%%%%%%%%%
                    %%%% Note that the following line also means that all
                    %%%% slices are scaled to their 20th percentile
                    wormImage(:,:,zi)=wormImage(:,:,zi)/pwil;%takes care of out of focus ones
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%
                    clear('wil');
                end
                segStacks{wi}=wormImage;
                clear wormImage
                fprintf('%g%% ', wi/length(currpolys)*100)
            end
            
            save(segStackFileName,'segStacks','segMasks')
            fprintf('\n')
            tElapsed=toc;
            tElapsed=tElapsed/60;
            fprintf('For %s in position %s , it took %g minutes. \n', dye{di}, stackSuffix, tElapsed)
            
            clear stack
            
            
        else
            fprintf('%s is already made and saved.\n', segStackFileName)
            
        end
        fprintf('\n')
        
    end
end
%stack=loadtiff(['dapi' stackSuffix '.tif'],1,stackSize(di,3));
%stack=double(stack);
end