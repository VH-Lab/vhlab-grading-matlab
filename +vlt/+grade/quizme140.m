function [p,questions,myanswers] = quizme140
% QUIZME140 - Make a quiz based on NBio140 questions in question databases
%
% [P, QUESTIONS, MYANSWERS] = QUIZME140
%
% Asks the user which database to use, and how many questions to use.
%
% P is the fraction correct; QUESTIONS are the questions you were asked, and
% MYANSWERS are the answers you gave.
%
% 

w = which('vlt.grade.quizme140')
[filepath,filename] = fileparts(w);
addpath(genpath(filepath));
if isempty(filepath), filepath = pwd; end;

d = dir([filepath filesep 'question_databases' filesep '*.qdb']);

disp(newline);
disp(newline);
disp(['Select a question database to use for your quiz:']);
for i=1:numel(d),
	[dbpath,dbfilename] = fileparts(d(i).name);
	disp([int2str(i) '. ' dbfilename]);
end;

r = input('Which database would you like to use?');

if r>=1 & r<= numel(d), % we are good
	q = load([filepath filesep 'question_databases' filesep d(r).name],'-mat');
	fn = fieldnames(q);
	q = getfield(q,fn{1});
else,
	error(['Number entered was out of range.']);
end;

r = input('How many questions shall we ask?');

[p,questions,myanswers]=vlt.grade.quizme(q,r);

