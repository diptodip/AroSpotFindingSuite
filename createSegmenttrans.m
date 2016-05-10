function createSegmenttrans(positionIdentifier)
%% ========================================================================
%   Name:       createSegmenttrans.m
%   Version:    2.5, 18 Dec 13
%   Author:     Scott Rifkin
%   Command:    createSegmenttrans(positionIdentifier)
%   Description:
%       - Creates "segmenttrans*.mat" file for a set of masks
%       - segmenttrans.mat files can be used for spot analysis and nuclei counting
%       - They are the input to createSegImages.m
%       - Each segmenttrans file has a cell array called "currpolys"
%       - currpolys contains the masks
%  
%
%   Files required:     tiff mask files
%                       File name examples: Mask_Pos0.tif, Mask_Pos0_1.tif
%
%   Files generated:    segmenttrans_{stackSuffix}.mat
%
%
%   Attribution: Wu, AC-Y and SA Rifkin. spotFinding Suite version 2.5, 2013 [journal citation TBA]
%
% Copyright 2013 Scott Rifkin, Allison Wu
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
% http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%
%
%   Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%   Email for comments, questions, bugs, requests:  Allison Wu < allison.cy.wu at gmail dot com >, Scott Rifkin < sarifkin at ucsd dot edu >
%
%% ========================================================================

%% Find all mask files associated with the positionIdentifier in the directory
   run('Aro_parameters.m');
maskFiles=dir(fullfile(SegmentationMaskDir,['Mask_' positionIdentifier '*.tif']));
if isempty(maskFiles)
    fprintf('Failed to find any mask files associated with position identifier %s .\nCheck your naming scheme. Examples are: "Mask_Pos1.tif" and "Mask_Pos1_1.tif".\n', positionIdentifier);
else
    n=length(maskFiles);
    currpolys=cell(1,n);
    for iMask=1:n
        currpolys{iMask}=logical(loadtiff(fullfile(SegmentationMaskDir,maskFiles(iMask).name)));
    end;
    save(fullfile(SegmentationMaskDir,['segmenttrans_' positionIdentifier '.mat']),'currpolys');
end;
end
        
        
    
    
    
