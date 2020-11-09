function questions_out = grade_140_exam_questions(questions_in)
% GRADE_140_EXAM_QUESTIONS - grade submitted exam question candidates
%
% QUESTIONS_OUT = GRADE_140_EXAM_QUESTIONS(QUESTIONS_IN)
%
% 

questions_out = questions_in;

for i=1:numel(questions_out),
	if isempty(questions_out(i).iscorrect),

		disp(['Question ' int2str(i) ' of ' int2str(numel(questions_out)) '.']);

		disp(newline);
		disp(newline);

		disp([questions_out(i).aiken])

		r = input('Is the question correct? 1=yes, 0=no, 2=needs attention, 3=ignoring, 4=not my section, -1=abort :');
		if r==-1, return; end; % abort
		questions_out(i).iscorrect = r;

		if r==4, continue; end;

		r = input('Is the question a candidate for the exam? 1=yes, 0=no, 2=maybe , -1=abort :');
		if r==-1, return; end; % abort
		questions_out(i).isexamcandidate = r;

		r = input('Is the question lame? 1=yes, 0=no, 2=maybe , -1=abort :');
		if r==-1, return; end; % abort
		questions_out(i).islame = r;
	end;
end;
