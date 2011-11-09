function FISHdata=extractFISHdataFromCSVs(dye)
allDye=[];

%use segment files to figure out how many there should be
%or check to see if data structure already in there

if exist('FISHdata.mat')
    load('FISHdata');
else
    segments=dir('segmenttrans*');
    for i=1:size(segments,1)
        load(segments(i).name);
        stackSuff=collectDigits(segments(i).name);%This will have to be modified for tif files
        stackSuff=stackSuff{1};
        FISHdata.(['Stack' stackSuff]).nEmbryos=size(currpolys,2);
    end;
end;
%use -100 to mark bad ones (bad or too many nuclei)

fn=fieldnames(FISHdata);
for i=1:length(fn)
    stackName=fn(i);
    stackName=stackName{1};
    if length(stackName)>6
        if strcmp(stackName(1:5),'Stack')
            FISHdata.(stackName).(dye)=zeros(1,FISHdata.(stackName).nEmbryos)-100;
        end;
    end;
end;


if strcmp(dye,'dapi')
    dyes=dir('nuclearResults*.csv');
    FISHdata.time=[];
else
    dyes=dir([dye '*Results.csv']);
end;

for i=1:size(dyes,1)
    stackSuff=collectDigits(dyes(i).name);
    stackSuff=stackSuff{1};
    if isfield(FISHdata,['Stack' stackSuff]);
        fid=fopen(dyes(i).name);
        data=textscan(fid,'%d %s %d %s','delimiter',',');
        fclose(fid);
        dyedata=zeros(1,FISHdata.(['Stack' stackSuff]).nEmbryos)-100;
        for j=1:size(data{1},1)
            dyedata(data{3}(j))=data{1}(j);
        end;
        FISHdata.(['Stack' stackSuff]).(dye)=dyedata;
    end;
end;

FISHdata.(dye)=[];
for i=1:length(fn)
    stackName=fn(i);
    stackName=stackName{1};
    if length(stackName)>6
        if strcmp(stackName(1:5),'Stack')
            FISHdata.(dye)=[FISHdata.(dye) FISHdata.(stackName).(dye)];
            if strcmp(dye,'dapi')
                for k=1:length(FISHdata.(stackName).(dye))
                    if FISHdata.(stackName).(dye)(k)>0
                        FISHdata.time=[FISHdata.time convertNucsToTime(FISHdata.(stackName).(dye)(k))];
                    else
                        FISHdata.time=[FISHdata.time -100];
                    end;
                end;
            end;
        end;
    end;
end;
FISHdata.([dye 'Filt'])=FISHdata.(dye)(FISHdata.dapi>0);
if strcmp(dye,'dapi')
    FISHdata.timeFilt=FISHdata.time(FISHdata.dapi>0);
end;

FISHdata.lastModified=date;
FISHdata.directory=pwd;
save('FISHdata','FISHdata');
[~,n,~,~]=fileparts(pwd);
save(sprintf('/Volumes/rifkinlab/sarifkin/Projects/Worms/SexDet/FISHdataFolder/FISHdata_%s',n),'FISHdata');

end