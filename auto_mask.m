function [] = auto_mask(filename, output)

if (~(exist('trim', 'dir') == 7))
    disp('[ERROR] You need to have trimmed image stacks in a folder called "trim" first!');
    return;
end

if (~(exist('mask', 'dir') == 7))
    mkdir('mask');
end

info = imfinfo(filename);

I = imread(filename, 1);

bg_brightness = mean(mean(I));

rows = size(I, 1);
cols = size(I, 2);

num_frames = length(info);

max_merge = zeros(size(I, 1), size(I, 2));

totals = [num_frames, 1];

for i = 1:num_frames
    I = imread(filename, i);
    total = sum(sum(I));
    totals(i, 1) = total;
    I = imgaussfilt(I, 2);
    for y = 1:rows
        for x = 1:cols
            if I(x, y) > max_merge(x, y)
                max_merge(x, y) = I(x, y);
            end
        end
    end
end

sigma = std(totals, 0, 1);

dim = false;

if (sigma(1)/bg_brightness) < 3.000e+03
    dim = true;
end

decrementer = ones(rows, cols);
seg_I = ones(rows, cols);

%I = imread(filename, max_index);

I = max_merge;

if ~dim
    level = 1.08 * bg_brightness;
    seg_I = imquantize(I, level);

else
    level = 1.05 * bg_brightness;
    seg_I = imquantize(I, level);
end

seg_I = seg_I - decrementer;

blur = imgaussfilt(seg_I, 10);

I = reshape(blur, rows * cols, 1);

ncolors = 2;

[cluster_idx, cluster_center] = kmeans(I,ncolors,'distance','sqEuclidean','Replicates',3);

pixel_labels = reshape(cluster_idx, rows, cols);

pixel_labels = pixel_labels - decrementer;

num_white = 0;
num_black = 0;

for y = 1:cols
    if pixel_labels(1, y) == 1
        num_white = num_white + 1;
    else
        num_black = num_black + 1;
    end
end

for y = 1:cols
    if pixel_labels(rows, y) == 1
        num_white = num_white + 1;
    else
        num_black = num_black + 1;
    end
end

for x = 1:rows
    if pixel_labels(x, 1) == 1
        num_white = num_white + 1;
    else
        num_black = num_black + 1;
    end
end

for x = 1:rows
    if pixel_labels(x, 512) == 1
        num_white = num_white + 1;
    else
        num_black = num_black + 1;
    end
end

if num_white > num_black
    pixel_labels = ~pixel_labels;
end

connected_components = bwconncomp(pixel_labels);

component_sizes = cellfun(@numel,connected_components.PixelIdxList);

[max_val, idx] = max(component_sizes);

mask_image = zeros(rows, cols);

mask_image(connected_components.PixelIdxList{idx}) = 1;

se = strel('disk', 10, 4);

mask_image = imdilate(mask_image, se);

imshow(mask_image, []), title('2 means clustered');

imwrite(mask_image(:, :), strcat('mask/',output), 'WriteMode', 'append',  'Compression','none');

clear;
return;
