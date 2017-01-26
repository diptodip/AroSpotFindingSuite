function [] = collect_stats(filename)

run('Aro_parameters.m');
for i = 1:numel(dyesUsed)
    dye = dyesUsed{i};
    list = dir([SpotStatsDir filesep dye filesep '*.mat']);
    list = {list.name};
    list = list.';
    if numel(list) > 0
        list = natsortfiles(list);
        worm_counts = cell(size(list, 1), 4);
        for i = 1:size(list, 1)
            disp(list{i});
            load([SpotStatsDir filesep dye filesep list{i}]);
            f = list{i};
            end_index = length(f) - 14;
            worm_counts{i, 1} = str2num(list{i}(8:end_index));
            worm_counts{i, 2} = spotStats{1}.SpotNumEstimate;
            worm_counts{i, 3} = spotStats{1}.SpotNumRange(1);
            worm_counts{i, 4} = spotStats{1}.SpotNumRange(2);
        end
        mat_out = cell2mat(worm_counts);
        csvwrite(filename, mat_out);
    else
        disp('[WARN] No spot counts found -- not writing file. Try running classifySpotsOnDirectory.');
    end
end

