function stack=readTiffStack(fileName,varargin)
%%  =============================================================
%  Name: readTiffStack.m
%  Version: 2.0, 3rd Nov 2011
%  Author: Allison Wu
%  Description: 
%       - varargin{1}: startPlane. Default: 1
%       - varargin{2}: endPlane. Default: read till the end of the tif file.
%       - Detects the end of the tif file automatically.
%% ==============================================================

switch nargin
    case 1
        startPlane=1;
        endPlane=[];
    case 2
        startPlane=varargin{1};
        endPlane=[];
    case 3
    startPlane=varargin{1};
    endPlane=varargin{2};

end
err=[];
if isempty(endPlane)
    k=1;
    while isempty(err)
        try
            stack(:,:,k)=imread(fileName,startPlane+k-1);
            k=k+1;
        catch err
            if strcmp(err.identifier, 'MATLAB:rtifc:invalidDirIndex')
                disp('Finished loading the whole stack.')
            else
                rethrow(err)
            end
        end
    end
    
else
    for k=1:(endPlane-startPlane+1)
        stack(:,:,k)=imread(fileName,startPlane+k-1);
    end
end


end