%  =============================================================
%  Name: newFISHfilter.m   %nameMod
%  Author: Arjun Raj
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%  =============================================================
%sets up a filter to highlight FISH spots

h3 = [ [0 0 0 0 0 0 0 0 0]; ...
       [0 0 0 0 0 0 0 0 0]; ...
       [0 0 0 0 1 0 0 0 0]; ...
       [0 0 0 3 4 3 0 0 0]; ...
       [0 0 1 4 5 4 1 0 0]; ...
       [0 0 0 3 4 3 0 0 0]; ...
       [0 0 0 0 1 0 0 0 0]; ...
       [0 0 0 0 0 0 0 0 0]; ...
       [0 0 0 0 0 0 0 0 0] ];
       
       
h3 = [ [0  0  0  0  0]; ...
       [0  0  2  0  0]; ...
       [0  2  10 2  0]; ...
       [0  0  2  0  0]; ...
       [0  0  0  0  0]; ];

h3(find(h3 == 0)) = -1;


m1 = -ones(5);
%m1 = -ones(9);
m2 = zeros(5);
%h4 = cat(3,m1,h3,h3,h3,m1);
h4 = cat(3,m2,h3,h3,h3,m2);


sm = sum(h3(:));
h3 = h3 - sm/length(h3(:));
h3 = h3/1000;


sm = sum(h4(:));
h4 = h4 - sm/length(h4(:));
h4 = h4/1000;
