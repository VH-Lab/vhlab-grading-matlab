function [p, questions, youranswers] = quizme(qdb, N)
% QUIZME - take a quiz from a set of questions in a database
%
% [P, QUESTIONS, YOURANSWERS] = QUIZME(QDB, N)
%
% Given a question database QDB with a field 'question' with subfields
% 'question','answer', and 'correct_answer', this function gives the user
% a practice quiz, choosing N questions at random from the whole list
% (without replacement).
%
% P is the fraction correct; QUESTIONS are the questions that were asked, 
% and YOURANSWERS is a character array of the user's answers.
%
% Example:
%    load question_db_visual.mat
%    [p,qs,myans] = vlt.grade.quizme(question_db_visual, 10);
%

index = randperm(numel(qdb));
if N>numel(qdb),
	N = numel(qdb);
end;
questions = qdb(index(1:N));
youranswers = '';
correct = 0;

for i=1:numel(questions),

	disp(newline);
	disp(newline);

	answer_pos = strfind(questions(i).aiken,'ANSWER:');
	aiken_text_trimmed = questions(i).aiken(1:answer_pos-1);

	disp(aiken_text_trimmed);

	r = input('What is your answer?','s');
	youranswers(i) = char(upper(r(1)));
	if strcmpi(r,questions(i).question.correct_answer),
		disp(['Correct!!']);
		correct = correct + 1;
	else,
		disp(['Noooo, sorry, the correct answer was ' questions(i).question.correct_answer '.']);
	end;
	disp(newline);
	disp(newline);
end;

p = correct / N;

disp(['You answered ' int2str(correct) ' of ' int2str(N) ' questions attempted.']);

