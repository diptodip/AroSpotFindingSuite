function spotStats=updateSpotStats(spotStats)
%% ========================================================================
%   Name:       updateSpotStats.m
<<<<<<< HEAD
%   Version:    2.5, 25th Apr. 2013
=======
%   Version:    2.5.1, 23rd Jul. 2014
>>>>>>> spotFindingSuite_v2.5.1
%   Author:     Allison Wu
%   Command:    spotStats=updateSpotStats(spotStats)
%   Description:
%       This code curates the total spot number and range by taking out the manually curated spots first, 
%       calculate the spot number and range and then put the manually curated spots back.
<<<<<<< HEAD
%
%   Attribution: Wu, AC-Y and SA Rifkin. spotFinding Suite version 2.5, 2013 [journal citation TBA]
%   License: Creative Commons Attribution-ShareAlike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%   Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%   Email for comments, questions, bugs, requests:  Allison Wu < dblue0406 at gmail dot com >, Scott Rifkin < sarifkin at ucsd dot edu >
%
=======
%       This is called when 'done' or alldone' buttons are pressed in the reviewFISHClassification GUI
%   Update:
%       2014.7.23 Fixed a bug at line 21 which gives the wrong
%       spotNumEstimates. Use the new prediction interval calculation.
>>>>>>> spotFindingSuite_v2.5.1
%% ========================================================================
spotStats.spotNumCurated=1;

<<<<<<< HEAD
Probs=spotStats.ProbEstimates(~mCuratedSpots);
IQR=spotStats.IQR(~mCuratedSpots);
IQRt=trainingSet.RF.IQRthreshold;
spotTreeProbs=spotStats.spotTreeProbs(~mCuratedSpots,:);
spotStats.SpotNumEstimate=sum(Probs>0.5)+sum(mCuratedSpots);

unreliableSpots=Probs(IQR>trainingSet.RF.IQRthreshold);
unreliableGoodSpots=unreliableSpots(unreliableSpots>0.5);
unreliableBadSpots=unreliableSpots(unreliableSpots<0.5);
randG=binornd(1,repmat(unreliableGoodSpots,1,1000),length(unreliableGoodSpots),1000);
randB=binornd(1,repmat(unreliableBadSpots,1,1000),length(unreliableBadSpots),1000);
g2b=prctile(sum(~randG),trainingSet.RF.quantile);
b2g=prctile(sum(randB), 100-trainingSet.RF.quantile);
ub=sum(Probs>0.5)+b2g;
lb=sum(Probs>0.5)-g2b;

spotStats.SpotNumRange=[lb+sum(mCuratedSpots) ub+sum(mCuratedSpots)];
=======
[lbub,dist,spotNumEstimate]=makeSpotCountInterval(spotStats,'spotStats');

spotStats.SpotNumEstimate=spotNumEstimate;
spotStats.SpotNumRange=lbub;
spotStats.SpotNumDistribution=dist;
>>>>>>> spotFindingSuite_v2.5.1


end