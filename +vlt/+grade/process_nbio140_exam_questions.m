function question_db = process_nbio140_exam_questions(filename, category)
% vlt.grade.process_nbio140_exam_questions - process tab delimited form entries
%
% QUESTION_DB = vlt.grade.process_nbio140_exam_questions(filename, category)
%
%
%

if nargin<1,
	filename = '/Users/vanhoosr/Downloads/Vision Multiple Choice Questions (Responses) - Form Responses 1.tsv';
end;

if nargin<2,
	category = 'vision';
end;

output_ = vlt.file.read_tab_delimited_file(filename);

question_db = vlt.data.emptystruct('timestamp','author','category','question','aiken','iscorrect','isexamcandidate','islame');

for i=2:size(output_,2),
	for j=3:numel(output_{i}),
		try,
			[aiken_text,question] = vlt.grade.text2aiken(output_{i}{j});
		catch,
			disp(['Error here, line ' int2str(i) ', entry ', int2str(j) ', text is']);
			output_{i}{j}
			error(lasterr);
		end;
		entry_here.timestamp = strtrim(output_{i}{1});
		entry_here.author = strtrim(output_{i}{2});
		entry_here.category = category;
		entry_here.question = question;
		entry_here.aiken = aiken_text;
		entry_here.iscorrect = '';
		entry_here.isexamcandidate = '';
		entry_here.islame = '';

		question_db(end+1) = entry_here;
	end;
end;
