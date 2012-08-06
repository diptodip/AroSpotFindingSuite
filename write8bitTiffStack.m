function write8bitTiffStack(I,filename)
% I: a M*N*P double matrix, that saves the intensity as a double format
% Rescale each slice to [0, 255] and save as 8bit Tiff stack

for k=1:size(I,3)
    maxI=max(max(I(:,:,k)));
    minI=min(min(I(:,:,k)));
    slice=I(:,:,k);
    scaledSlice=uint8((slice-minI)/(maxI-minI) * 255);
    if k==1
        imwrite(scaledSlice,filename,'tif','compression','none')
    else
        imwrite(scaledSlice,filename,'tif','compression','none','writemode','append')
    end
end

end