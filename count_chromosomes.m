function [current_count] = count_chromosomes(filename, maskname)

info = imfinfo(filename);

I = imread(filename, 1);
mask = ones(size(I, 1), size(I, 2))
if maskname ~= '0'
    mask = imread(maskname);
end

bg_brightness = mean(mean(I));

rows = size(I, 1);
cols = size(I, 2);

sensitive = false;

if rows >= 1000 || cols >= 1000
    sensitive = true;
end

num_frames = length(info);

totals = [num_frames, 1];

start = ((num_frames - 1)/2) + 1;
ending = num_frames - 1;

for i = start:ending
    I = imread(filename, i);
    total = sum(sum(I));
    totals(i, 1) = total;
end

sigma = std(totals, 0, 1);

dim = false;

if (sigma(1)/bg_brightness) < 3.000e+03
    dim = true;
end

decrementer = ones(rows, cols);
seg_I = ones(rows, cols);

threshold = 2.5;
level = threshold * bg_brightness;

if ~dim
    threshold = 2.5;
    if sensitive
        threshold = 3.0;
    end
    level = threshold * bg_brightness;

else
    threshold = 1.7;
    level = threshold * bg_brightness;
end

previous_count = 0;
current_count = 0;

display = seg_I;

for i = start:ending
    I = imread(filename, i);
    I = imgaussfilt(I, 3);
    seg_I = imquantize(I, level);
    seg_I = seg_I - decrementer;
    if sum(sum(seg_I)) > 0.5 * rows * cols
        seg_I = ~seg_I;
    end
    if i == (start + ending) / 2
        display = seg_I;
    end
    seg_I(~mask) = 0;
    seg_I = imgaussfilt(seg_I, 5);
    [cluster_idx, cluster_center] = kmeans(seg_I, 2, 'distance', 'sqEuclidean', 'Replicates', 3);
    pixel_labels = reshape(cluster_idx, rows, cols);
    pixel_labels = pixel_labels - decrementer;
    current = length(bwboundaries(seg_I));
    if current > previous_count
        current_count = current_count + (current - previous_count);
    end
    previous_count = current;
end

disp(current_count);
return;
