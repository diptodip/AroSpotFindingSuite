function [] = auto_trim(filename, output)

if ~(exist('trim', 'dir') == 7)
    mkdir('trim');
end

I = imread(filename, 1);

rows = size(I, 1);
cols = size(I, 2);

decrementer = ones(rows, cols);

info = imfinfo(filename);

num_frames = length(info);

bg_brightness = mean(mean(I));

totals = [num_frames, 1];

for i = 1:num_frames
    I = imread(filename, i);
    total = sum(sum(I));
    totals(i, 1) = total;
end

sigma = std(totals, 0, 1);

dim = false;

if (sigma(1)/bg_brightness) < 3.000e+03
    dim = true;
end

gradients = [num_frames, 1];
start = 0;
if ~dim
    for i = 1:num_frames
        I = imread(filename, i);
        I = imgaussfilt(I, 5);
        seg_I = imquantize(I, 1.1 * bg_brightness);
        seg_I = seg_I - decrementer;
        total = sum(sum(seg_I));
        gradients(i, 1) = total;
        if total > 1
            if start == 0
                start = i;
            end
        end
    end
else
    for i = 1:num_Frames
        I = imread(filename, i);
        I = imgaussfilt(I, 5);
        seg_I = imquantize(I, 1.07 * bg_brightness);
        seg_I = seg_I - decrementer;
        total = sum(sum(seg_I));
        gradients(i, 1) = total;
        if total > 90
            if start == 0
                start = i;
            end
        end
    end
end

start = start - 2;

finish = 0;

for j = 1:(num_frames - 5)
    dx = gradient(gradients(j:j+5, 1));
    if dx < 0
        if finish == 0 || j < 151 - 15
            if j < 151 - 15
                finish = j+15;
            else
                finish = j+5;
            end
        end
    end
    disp(finish);
end

if start < 1
    start = 1;
end

if finish > num_frames
    finish = num_frames;
end

disp(start);
disp(finish);

for k = start:finish
    I = imread(filename, k);
    imwrite(I(:, :), output, 'WriteMode', 'append',  'Compression','none');
end
clear;
return;
