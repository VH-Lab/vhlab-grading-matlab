function t = examquestions2text(question_db, varargin)
% EXAMQUESTIONS2TEXT - convert an exam question database to text
% 
% T = EXAMQUESTIONS2TEXT(QUESTION_DB, ...)
%
% Converts exam questions to a text stream, for editing or for use in an exam question bank.
%
% This function also takes parameters that alter its behavior as name/value pairs:
% Parameter (default)    | Description
% ------------------------------------------------------------------
% IncludeHeaders (1)     | Include a header above and below each question so the file can
%                        |   be re-read into a question database.
% 

IncludeHeaders = 1;

vlt.data.assign(varargin{:});

t = '';

for i=1:numel(question_db),
	if question_db.isexamcandidate > 0,
		if IncludeHeaders,
			str_beg = ['BEGIN QUESTION ' int2str(i) ' ----' newline];
			str_end = ['END QUESTION ' int2str(i) ' ----' newline];
		else,
			str_beg = '';
			str_end = '';
		end;
		t = cat(2,t,str_beg,question_db(i).aiken,str_end);
	end;
end;

