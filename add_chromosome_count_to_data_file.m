function [] = add_chromosome_count_to_data_file(filename)
% this assumes that the chromosome counts file exists already and that the
% specified file exists
run('Aro_parameters.m');

fid = fopen(ChromosomeFile,'r');
i = 1;
tline = fgetl(fid);
if tline ~= -1
    chromosome_counts{i} = strsplit(string(tline), ',');
    chromosome_counts{i} = chromosome_counts{i}{2};
end

while ischar(tline)
    i = i+1;
    tline = fgetl(fid);
    if tline ~= -1
        count = strsplit(string(tline), ',');
        count = count{2};
        chromosome_counts{i} = count;
    else
        chromosome_counts{i} = -1;
    end
end
fclose(fid);

disp(chromosome_counts);

fid = fopen(filename,'r');
i = 2;
tline = fgetl(fid);
file{1} = 'id, spot count,spot lower estimate,spot upper estimate,chromosome count';
file{i} = tline;
if tline ~= -1
    padded = [string(tline) ',' chromosome_counts{i-1}];
    file{i} = padded;
end
while ischar(tline)
    i = i+1;
    tline = fgetl(fid);
    if tline ~= -1
        padded = [string(tline) ',' chromosome_counts{i-1}];
        file{i} = padded;
    else
        file{i} = -1;
    end
end
fclose(fid);

% Write cell array file into specified csv file
fid = fopen(filename, 'w');
for i = 1:numel(file)
    if file{i+1} == -1
        fprintf(fid,'%s', file{i});
        break
    else
        fprintf(fid,'%s\n', file{i});
    end
end

