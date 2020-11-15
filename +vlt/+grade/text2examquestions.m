function qdb = text2examquestions(t,qdb)
% TEXT2EXAMQUESTIONS - modify an exam question database from edits from a text file
%
% QDB = TEXT2EXAMQUESTIONS(T, QDB)
%
% 
% 

for i=1:numel(qdb),
	% look for representation in the text file
	str_beg = ['BEGIN QUESTION ' int2str(i) ' ----' newline];
	str_end = ['END QUESTION ' int2str(i) ' ----' newline];

	start = strfind(t,str_beg);
	stop = strfind(t,str_end);

	if ~isempty(start) & ~isempty(stop),
		start_pos = start + numel(str_beg);
		stop_pos = stop -1;

		t_new = t(start_pos:stop_pos);
		t_new(find(t_new==newline)) = ' ';
		[aiken_here, out_here] = vlt.grade.text2aiken(t_new);
		qdb(i).question.question = out_here.question;
		qdb(i).question.answer = out_here.answer;
		qdb(i).question.correct_answer= out_here.correct_answer;
		qdb(i).question.tokens_here= out_here.tokens_here;
		qdb(i).question.match_type = out_here.match_type;
		qdb(i).aiken = aiken_here;
	else,
		qdb(i).isexamcandidate = 0;
		disp(['NO QUESTION ' int2str(i) '.']);
	end;

end;
