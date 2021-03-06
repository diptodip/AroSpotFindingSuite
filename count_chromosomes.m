function [current_count] = count_chromosomes(filename, maskname)

info = imfinfo(filename);

I = imread(filename, 1);
mask = ones(size(I, 1), size(I, 2));
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

start = ((num_frames - 1)/2) + 2;
ending = num_frames;

for i = start:ending
    I = imread(filename, i);
    total = sum(sum(I));
    totals(i, 1) = total;
end

sigma = std(totals, 0, 1);

dim = false;

if (sigma(1)/bg_brightness) < 3.000e+03
    dim = true;
    disp('this image is dim');
end
decrementer = ones(rows, cols);
seg_I = ones(rows, cols);

threshold = 2.5;
level = threshold * bg_brightness;

if ~dim
    threshold = 1.5;
    if sensitive
        threshold = 2.7;
    end
    level = threshold * bg_brightness;

else
    disp('dim');
    threshold = 1.7;
    level = threshold * bg_brightness;
end

previous_count = 1;
current_count = 0;

prev_labels = zeros(rows, cols);

for i = start:1:ending
    I = imread(filename, i);
    I = imgaussfilt(I, 3);
    seg_I = imquantize(I, level);
    seg_I = seg_I - decrementer;
    if sum(sum(seg_I)) > (0.5 * rows * cols)
        disp(seg_I);
        seg_I = ~seg_I;
    end
    if sum(sum(seg_I)) > (0.5 * rows * cols)
        seg_I = ~seg_I;
    end
    seg_I(~mask) = 0;
    seg_I = imgaussfilt(seg_I, 7);
    seg_I = reshape(seg_I, rows * cols, 1);
    [cluster_idx, ~] = kmeans(seg_I, 2, 'distance', 'sqEuclidean', 'Replicates', 3);
    pixel_labels = reshape(cluster_idx, rows, cols);
    pixel_labels = pixel_labels - decrementer;
    if sum(sum(pixel_labels)) ~= 0
        se = strel('disk', 9, 4);
        pixel_labels = imdilate(pixel_labels, se);
    end
    
    current_labels = pixel_labels;
    for j = 1:rows
        for k = 1:cols
            if prev_labels(j, k) > pixel_labels(j, k)
                pixel_labels(j, k) = prev_labels(j, k);
            end
        end
    end
    
    current = length(bwboundaries(pixel_labels));
    if current > previous_count
        current_count = current_count + (current - previous_count);
    end
    previous_count = current;
    if mod(i, 10) == 0
        prev_labels = current_labels;
        previous_count = 10000;
    else
        prev_labels = pixel_labels;
    end
end

disp(current_count);
return;
