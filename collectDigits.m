function digits=collectDigits(s,varargin)
%  =============================================================
%  Name: collectDigits.m   %nameMod
%  Version: 1.0 9 November 2011   %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  =============================================================
%This is a utility function to extract digits from a string

digits=regexp(s,'\d+','match');
if size(varargin,2)>0
    digits=digits{varargin{1}};
end;
end