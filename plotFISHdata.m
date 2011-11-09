function plotFISHdata(FISHdata)

dyes={'alexa','cy','tmr'};
DropBoxDir='/Users/BrutusXPro/Dropbox/Projects/Worms/SexDet/FISHdataFolder/';
[~,n,~,~]=fileparts(pwd);
FISHdataDirectory='/Volumes/rifkinlab/sarifkin/Projects/Worms/SexDet/FISHdataFolder/';
close all
figure(1)
subplot(2,2,1)

hold on
if isfield(FISHdata,'tmr')
    plot(FISHdata.timeFilt,FISHdata.tmrFilt,'r.','MarkerSize',15)
end;
if isfield(FISHdata,'cy')
    plot(FISHdata.timeFilt,FISHdata.cyFilt,'b.','MarkerSize',15)
end;
if isfield(FISHdata,'alexa')
    plot(FISHdata.timeFilt,FISHdata.alexaFilt,'c.','MarkerSize',15)
end;
title(sprintf('%s\nred tmr blue cy cyan alexa',regexprep(pwd,'_','__')))
xlabel('time')
xlim([0 250]);
hold off
sp=2;
for i=1:2
    if isfield(FISHdata,dyes{i})
        for j=(i+1):3
            if isfield(FISHdata,dyes{j})
                subplot(2,2,sp);
                for ni=1:length(FISHdata.timeFilt)
                    hold on
                    plot(FISHdata.([dyes{i} 'Filt'])(ni),FISHdata.([dyes{j} 'Filt'])(ni),'o','MarkerFaceColor',[.2 FISHdata.timeFilt(ni)/max(FISHdata.timeFilt) FISHdata.timeFilt(ni)/max(FISHdata.timeFilt)],'MarkerSize',5);
                end;
                hold off
                xlabel(dyes{i});
                ylabel(dyes{j});
                sp=sp+1;
            end;
        end;
    end;
end;
print -dpdf -r300 'FISHdataTime.pdf'
system(sprintf('cp FISHdataTime.pdf %sFISHdataTime_%s.pdf',FISHdataDirectory,n));
system(sprintf('cp FISHdataTime.pdf %sFISHdataTime_%s.pdf',DropBoxDir,n));






close(1)











figure(1)
subplot(2,2,1)
hold on
if isfield(FISHdata,'tmr')
    plot(FISHdata.dapiFilt,FISHdata.tmrFilt,'r.','MarkerSize',15)
end;
if isfield(FISHdata,'cy')
    plot(FISHdata.dapiFilt,FISHdata.cyFilt,'b.','MarkerSize',15)
end;
if isfield(FISHdata,'alexa')
    plot(FISHdata.dapiFilt,FISHdata.alexaFilt,'c.','MarkerSize',15)
end;
title(sprintf('%s\nred tmr blue cy cyan alexa',regexprep(pwd,'_','__')))
xlabel('nucs')
xlim([0 250]);
hold off
sp=2;
for i=1:2
    if isfield(FISHdata,dyes{i})
        for j=(i+1):3
            if isfield(FISHdata,dyes{j})
                subplot(2,2,sp);
                for ni=1:length(FISHdata.dapiFilt)
                    hold on
                    plot(FISHdata.([dyes{i} 'Filt'])(ni),FISHdata.([dyes{j} 'Filt'])(ni),'o','MarkerFaceColor',[.2 FISHdata.dapiFilt(ni)/max(FISHdata.dapiFilt) FISHdata.dapiFilt(ni)/max(FISHdata.dapiFilt)],'MarkerSize',5);
                end;
                hold off
                xlabel(dyes{i});
                ylabel(dyes{j});
                sp=sp+1;
            end;
        end;
    end;
end;


print -dpdf -r300 'FISHdataNucs.pdf'
system(sprintf('cp FISHdataNucs.pdf %sFISHdataNucs_%s.pdf',FISHdataDirectory,n));
system(sprintf('cp FISHdataNucs.pdf %sFISHdataNucs_%s.pdf',DropBoxDir,n));

close(1)

system(sprintf('cp FISHdata.mat %sFISHdata_%s.mat',FISHdataDirectory,n));
system(sprintf('cp FISHdata.mat %sFISHdata_%s.mat',DropBoxDir,n));


end
