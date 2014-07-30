function spotStats=updateSpotStats(spotStats)
%% ========================================================================
%   Name:       updateSpotStats.m
%   Version:    2.5.1, 23rd Jul. 2014
%   Author:     Allison Wu
%   Command:    spotStats=updateSpotStats(spotStats)
%   Description:
%       This code curates the total spot number and range by taking out the manually curated spots first, 
%       calculate the spot number and range and then put the manually curated spots back.
%       This is called when 'done' or alldone' buttons are pressed in the reviewFISHClassification GUI
%   Update:
%       2014.7.23 Fixed a bug at line 21 which gives the wrong
%       spotNumEstimates. Use the new prediction interval calculation.
%% ========================================================================
spotStats.spotNumCurated=1;

[lbub,dist,spotNumEstimate]=makeSpotCountInterval(spotStats,'spotStats');

spotStats.SpotNumEstimate=spotNumEstimate;
spotStats.SpotNumRange=lbub;
spotStats.SpotNumDistribution=dist;


end