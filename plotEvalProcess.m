function plotEvalProcess(w)
%  =============================================================
%  Name: plotEvalProcess.m
%  Version: 1.0, 9 Nov 2011
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%
%   Attribution: Wu, AC-Y and SA Rifkin. spotFinding Suite version 2.5, 2013 [journal citation TBA]
%   License: Creative Commons Attribution-ShareAlike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%   Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%   Email for comments, questions, bugs, requests:  Allison Wu < dblue0406 at gmail dot com >, Scott Rifkin < sarifkin at ucsd dot edu >
%
%  =============================================================
%makes a plot of scd values by slice and ordered in the order they were evaluated, coded by classification

nP=w{1}.numberOfPlanes;

%Note that the evaluation is done on each worm and slice separately.  They are only
%joined in the identifySpots GUI
%regMax locations are in the worm


for wi=1:size(w,2)
    scds{wi}=[];
    lessThanCutoff{wi}=[];
    for si=1:size(w{wi}.spotInfo,2)
        scds{wi}=[scds{wi};[w{wi}.spotInfo{si}.locations.worm(3),w{wi}.spotInfo{si}.spotRank,w{wi}.spotInfo{si}.stat.statValues.scd, w{wi}.spotInfo{si}.classification.MachLearn{1}]];
    end;
    lessThanCutoff{wi}=find(scds{wi}(:,4)==0);
end;

for fi=1:size(w,2)
    figure(fi);
    plot(scds{fi}(:,3),'b.');
    hold on
    plot(lessThanCutoff{fi},scds{fi}(lessThanCutoff{fi},3),'r.');
    currSlice=1;
    for si=1:size(scds{fi},1)
        if scds{fi}(si,1)~=currSlice
            currSlice=scds{fi}(si,1);
            plot([si,si],[0,1],'k');
        end;
    end;
    ylabel('scd');
    title(sprintf('%s: Worm %d.  Probe: %s\nBlue dots are good. Red dots are rejected.',w{1}.stackName,fi,w{1}.probeName));
    xlabel(sprintf('Lines separate slices.\nOrdered by evaluation order within slice'));
    hold off
end;



end