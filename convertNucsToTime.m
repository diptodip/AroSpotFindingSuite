function T = convertNucsToTime(nNucs)
%converts number of nuclei to time based on AceTree in
%/Users/BrutusX/Projects/Worms/PartialPenetrance/divisiontimes.txt

divTimes=dlmread('/Volumes/rifkinlab/sarifkin/Projects/Worms/MicroscopeData_PartialPenetrance/PP_paper/divisiontimes.txt')';
possibleTimes=divTimes(1,find(divTimes(2,:)==nNucs));
if ~isempty(possibleTimes)>0
    T=possibleTimes(end);
    %     if length(possibleTimes)>1
    %         T=possibleTimes(ceil(rand()*length(possibleTimes)));
    %     else
    %         T=possibleTimes(1);
    %     end;
else
    lessThanTimes=find(divTimes(2,:)<nNucs);
    lessThanTimes=lessThanTimes(end);
    lessNuc=divTimes(2,lessThanTimes);
    moreNuc=divTimes(2,lessThanTimes+1);
    nucDiff=moreNuc-lessNuc;
    T=lessThanTimes+(nNucs-lessNuc)/nucDiff;
end;
end
