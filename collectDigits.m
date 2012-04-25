function digits=collectDigits(s,varargin)
%  =============================================================
%  Name: collectDigits.m   %nameMod
%  Version: 1.0 9 November 2011   %nameMod
%  Author: Scott Rifkin, webpage: http://www.biology.ucsd.edu/labs/rifkin/
%  Attribution: Rifkin SA., Identifying fluorescently labeled single molecules in image stacks using machine learning.  Methods Mol Biol. 2011;772:329-48.
%  License: Creative Commons Attribution-Share Alike 3.0 United States, http://creativecommons.org/licenses/by-sa/3.0/us/
%  Website: http://www.biology.ucsd.edu/labs/rifkin/software/spotFindingSuite
%  Email for comments, questions, bugs, requests:  sarifkin at ucsd dot edu
%  =============================================================
%This is a utility function to extract digits from a string

digits=regexp(s,'\d+','match');
if size(varargin,2)>0
    digits=digits{varargin{1}};
end;
end