function ensureCurrpolysAreLogical()
%for some reason a currpolys shows up that is a double
%This actually would make sense in the future to have them just be labeled
%regions and then create the individual segments on the fly...it would save
%space
%But this function just loads segmenttrans files and makes sure they are
%logical. if they are not then it resaves
segs=dir('segment*mat');
parfor iS=1:length(segs)
    q=load(segs(iS).name);
    currpolys=q.currpolys;
    toSave=0;
    for iW=1:size(currpolys,2)
        if ~islogical(currpolys{iW})
            currpolys{iW}=(currpolys{iW}>0);
            toSave=1;
        end;
    end;
    if toSave
        disp(['Fixed a non-logical segment in ' segs(iS).name]);
        parsaveCurrpolys(segs(iS).name,currpolys);
        toSave=0;
    else
        disp(['Nothing to fix in ' segs(iS).name]);
    end;
end;
end



function parsaveCurrpolys(fileName,currpolys)%6Aug12 SR
%http://www.mathworks.com/support/solutions/en/data/1-D8103H/index.html?product=DM&solution=1-D8103H
%Takes care of the problem of saving within parfor loops
save(fileName, 'currpolys')
end