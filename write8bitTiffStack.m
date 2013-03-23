function write8bitTiffStack(I,filename,varargin)
% I: a M*N*P double matrix, that saves the intensity as a double format
% Rescale each slice to [0, 255] and save as 8bit Tiff stack

if length(varargin)>2
    G=varargin{1};
    B=varargin{2};
    %K=varargin{3};
    excludeZeros=varargin{3};
end

for k=1:size(I,3)
    if isempty(varargin)|| length(varargin)==1 % only greyscale
        if length(varargin)==1
            excludeZeros=varargin{1};
        else
            excludeZeros=1;
        end
        scaledSlice=uint8(imscale(I(:,:,k),100,excludeZeros)*255);
        if k==1
            imwrite(scaledSlice,filename,'tif','compression','none')
        else
            imwrite(scaledSlice,filename,'tif','compression','none','writemode','append')
        end
    else
        sSliceR=uint8(imscale(I(:,:,k),100,excludeZeros(1))*255);
        sSliceG=uint8(imscale(G(:,:,k),100,excludeZeros(2))*255);
        sSliceB=uint8(imscale(B(:,:,k),100,excludeZeros(3))*255);
        %sSliceK=scaleSlice(K(:,:,k));
        scaledSlice=cat(3,sSliceR,sSliceG,sSliceB);%,sSliceK);
        if k==1
            imwrite(scaledSlice,filename,'tif','compression','none')
        else
            imwrite(scaledSlice,filename,'tif','compression','none','writemode','append')
        end
        
    end
end

end
