function [a_text, output] = text2aiken(t, varargin)
% vlt.grade.text2aiken - convert a multiple choice question provided in a text string into an Aiken format question
%
% [A_TEXT, OUTPUT] = vlt.grade.text2aiken(T)
% 
% Example:
%    t = ['Which protein both prevents active rhodopsin from activating transducin '...
%         'and also helps break down the activated rhodopsin?  (A) Rhodopsin kinase '...
%         '(B) T-alpha subunit (C) Arrestin (D) Retinol  Correct answer: C'];
%    a_text = vlt.grade.text2aiken(t);
%    % a_text = ['Which protein both prevents active rhodopsin from activating transducin ' ...
%    %           'and also helps break down the activated rhodopsin?' newline 'A. Rhodopsin kinase' newline ...
%    %           'B. T-alpha subunit' newline 'C. Arrestin' newline ' D. Retinol' newline '...
%    %           'ANSWER: C']    
% 
%   


choice_delimiter = '. ';


vlt.data.assign(varargin{:});


 % questions might be (S), S),  S., ( S ), 

  % search for '(a ) ', ' a )', or ' a.' 

regexp_options = { '\(([ ]*)#()([ ]*)\)', '([ ]+)#\)', '([ ]+)#([ ]*)\.', '([ ]+)#([ ]*):'};
tokens = 'abcdefgh'; % cut off at h
answer_tokens = {'(correct )?answer([:\)\.]*)', 'correct([ ]*)(answer)?([:\)\.]*)'};

match_type = 0;

tokens_start = [];

question = [];
end_of_last_token = [];
answer = {};
correct_answer = [];
tokens_here = char([]);

for i=1:numel(tokens),
	match = 0;
	% try expressions in order
	for j=1:numel(regexp_options),
		this_exp = regexp_options{j};
		this_exp(find(this_exp=='#')) = tokens(i); % look for our tokens in order
		[starts,ends] = regexpi(t,this_exp,'forceCellOutput');
		if ~isempty(starts{1}), % a match
			tokens_here(end+1) = tokens(i);
			if isempty(tokens_start), % this is our first token
				tokens_start = starts{1}(1);
				question = strtrim(t(1:tokens_start-1));
				match_type = j;
			else, % this is our next token
				answer{end+1} = strtrim(t(end_of_last_token+1:starts{1}(1)-1));
			end;
			end_of_last_token = ends{1}(1);
			if j~=match_type,
				t(starts{1}:ends{1})
				error(['We were matching ' int2str(match_type) ' but suddenly switched to ' int2str(j) '.']);
			end;
		end;
	end;
end;

 % now we need to get the answer

for i=1:numel(answer_tokens),
	[starts,ends] = regexpi(t,answer_tokens{i},'forceCellOutput');
	if ~isempty(starts{1}), % we've got it
		correct_answer = strip(strtrim(t(ends{1}(end)+1:end)), 'right','.');
		correct_answer = correct_answer(find(isletter(correct_answer)));
		% finish last answer
		answer{end+1} = strtrim(t(end_of_last_token+1:starts{1}(end)-1));
		break; % don't run the next one
	end;
end;

if numel(correct_answer)>1,
	error(['More than one character in correct answer: ' correct_answer '.']);
end;

tokens_here(end+1) = 'm';

index = find(lower(correct_answer) == lower(tokens_here));

if isempty(index),
	error(['No such token ' correct_answer ' in ' tokens_here '.']);
end;

a_text = [question newline];
for i=1:numel(answer),
	a_text = cat(2,a_text,[upper(tokens_here(i)) ') ']);
	a_text = cat(2,a_text,[answer{i} newline]);
end;
a_text = cat(2,a_text,['ANSWER: ' correct_answer newline]);

tokens_here = upper(tokens_here);

output = vlt.data.var2struct('question','answer','correct_answer','tokens_here','match_type');


