function tiff = readmm(infile,varargin)
%  =============================================================
%  Name: readmm.m   %nameMod
%  Author:  Arjun Raj
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%  =============================================================
% Reads MM stk files.  Use readmm('blah',3:34) to load just images 3 to 34, etc.

if  isempty(findstr(infile,'.'))
   infile=[infile,'.stk'];
end

disp(['Reading ' infile]);
fid = fopen(infile,'r');

if infile(1) == '/' % We already have a full path
  tiff.filename = infile;
else
  tiff.filename = fullfile(pwd,infile);
end;

a = fread(fid,2,'char'); % This should be 'II'
a = fread(fid,1,'uint16');  % This should be 42

currifd = fread(fid,1,'uint32');  % This is the location of the first IFD

fseek(fid,currifd,-1);  % Seek to the first IFD (location from bof)

numentries = fread(fid,1,'uint16');

%clear entry
for i = 1:numentries
  entries_one(i).tag    = fread(fid,1,'uint16');
  entries_one(i).type   = fread(fid,1,'uint16');
  entries_one(i).count  = fread(fid,1,'uint32');
  entries_one(i).value  = fread(fid,1,'uint32');
end;

tags = [entries_one(:).tag];

i = find(tags == 258);
tiff.bitspersample = entries_one(i).value;

i = find(tags == 256);
tiff.width = entries_one(i).value;

i = find(tags == 257);
tiff.length = entries_one(i).value;

i = find(tags == 306);
fseek(fid,entries_one(i).value,-1);
str = fread(fid,20,'*char');
tiff.datetime = str';
%tiff.length = entries_one(i).value;




i = find(tags == 33629);  % This is UIC2
% It contains the z positions and creation date and so forth
tiff.numplanes = entries_one(i).count;
numplanes = tiff.numplanes;
zpos = zeros(numplanes,1);
creationdate = zeros(numplanes,1,'uint32');
creationtime = zeros(numplanes,1,'uint32');
modificationdate = zeros(numplanes,1,'uint32');
modificationtime = zeros(numplanes,1,'uint32');
fseek(fid,entries_one(i).value,-1);

% The following code was for reading date and time info.
% I don't use it, so I thought, whatever, just remove it.
for i = 1:numplanes
  num = fread(fid,1,'uint32');
  den = fread(fid,1,'uint32');
  zpos(i) = num/den;
  creationdate(i) = fread(fid,1,'uint32');
  creationtime(i) = fread(fid,1,'uint32');
  modificationdate(i) = fread(fid,1,'uint32');
  modificationtime(i) = fread(fid,1,'uint32');
end;
tiff.creationdate = creationdate;
tiff.creationtime = creationtime;


% Now let's read the annotations.
i = find(tags == 270);
fseek(fid,entries_one(i).value,-1);  % This is the location of the annotation
for i = 1:numplanes
  byte = fread(fid,1,'*char');
  string = byte;
  while byte ~= 0
    byte = fread(fid,1,'*char');
    string = [string byte];
  end;
  tiff.annotation{i} = string;
end;
% Now let's read the exposure times out.
for i = 1:numplanes
  an = tiff.annotation{i};
  [a,b] = strread(an,'%s%s','delimiter',':');
  tiff.exposure(i) = b(1);
end

% Okay, now we'll read the rest of the file to get the illumination settings.
% This is a pretty bad hack, but whatever... it seems to work.
rest = fread(fid,inf,'*char')';
idx = strfind(rest,'Illum');
% Now we have the offsets.  The way it works is that first you have the text
% "_IllumSetting_" followed by the number 2 (byte), followed by 32 bytes
% that I don't understand, followed by a byte containing the length of
% the string.  In total, this number is 18 bytes later.
for i = 1:length(idx) % length(idx) should equal numplanes
  pos = idx(i)+18;
  len = double(rest(pos));
  tiff.illumination{i} = rest( (pos+1):(pos+len) );
end;


% This actually reads the data
i = find(tags == 273);
fseek(fid,entries_one(i).value,-1);
stripoffset = fread(fid,1,'uint32');

if length(varargin) == 0  % Then we read all the data
    fseek(fid,stripoffset,-1);
    tiff.imagedata = fread(fid,tiff.width*tiff.length*numplanes,'*uint16');
    tiff.imagedata = reshape(tiff.imagedata,tiff.width,tiff.length,numplanes);
else % Okay, so now we have to read out individual files
    inds = varargin{1};
    tiff.imagedata = zeros(tiff.width,tiff.length,length(inds),'uint16');
    for i = 1:length(inds)
        currpos = stripoffset + tiff.width*tiff.length*(inds(i)-1)*tiff.bitspersample/8;
        fseek(fid,currpos,-1);
        tmp2 = fread(fid,tiff.width*tiff.length,'*uint16');
        tiff.imagedata(:,:,i) = reshape(tmp2,tiff.width,tiff.length);
    end;
end;%  for i = 1:length(


if length(varargin) ~=0  %If we just want a few images, let's clean up
    inds = varargin{1};
    tiff.numplanes = length(inds);
    for i = 1:length(inds)
        tmp.annotation{i}   = tiff.annotation{inds(i)};
    tmp.exposure{i}     = tiff.exposure{inds(i)};
    tmp.illumination{i} = tiff.illumination{inds(i)};
  end;
  tiff.annotation   = tmp.annotation;
  tiff.exposure     = tmp.exposure;
  tiff.illumination = tmp.illumination;
else
  inds = 1:numplanes;
end;

tiff.imageindices = inds;

fclose(fid);
