function vhgradesummary(dirname, assignmentname, inputitemlist)
% VHGRADESUMMARY - produce a summary for the grading of an assignment
%
% VHGRADESUMMARY(DIRNAME, ASSIGNMENTNAME, INPUTITEMLIST)
%
% 

grade_directory = [dirname filesep 'GRADING'];

ws = warning('state');
warning off;
try, mkdir(grade_directory); end;
warning('state',ws);

summaryfilename = [grade_directory filesep 'summary.txt'];

text_out = {};

inter_question_text = {'', '---------------------------------------', ''};

points_earned = 0;
points_possible = 0;

present = [];

for i=1:numel(inputitemlist),
	filename = [grade_directory filesep inputitemlist(i).Item_filename];

	if isfile(filename),
		present(i) = 1;
		g = load(filename,'-mat');
		points_earned = points_earned + g.grade.Points_earned;
		points_possible = points_possible + g.grade.Points_possible;
	else,
		present(i) = 0;
	end;
end;

for i=1:numel(inputitemlist),

	filename = [grade_directory filesep inputitemlist(i).Item_filename];

	if isfile(filename),
		g = load(filename,'-mat');
		text_out = cat(2,text_out, inter_question_text);
		text_out{end+1} = ['Item: ' g.grade.Item_name];
		text_out{end+1} = ['Points: ' num2str(g.grade.Points_earned) ' of ' num2str(g.grade.Points_possible)];
		text_out{end+1} = ['Description: '];

		if iscell(g.grade.Description),
			text_out = cat(2,text_out,g.grade.Description);
		else,
			text_out{end+1} = g.grade.Description;
		end;
		text_out{end+1} = ['Comments: '];
		if iscell(g.grade.Comment_1),
			text_out = cat(2,text_out,g.grade.Comment_1);
		else,
			text_out{end+1} = g.grade.Comment_1;
		end;
		if iscell(g.grade.Comment_2),
			text_out = cat(2,text_out,g.grade.Comment_2);
		else,
			text_out{end+1} = g.grade.Comment_2;
		end;
	end;
end;

text_above = {['Assignment: ' assignmentname], ...
	 ['Points: ' num2str(points_earned) ' of ' num2str(points_possible) ' (' num2str(100*points_earned/points_possible,4) '%)'] };

if any(~present),
	text_above{end+1} = ['Incomplete grading: ' mat2str(present) ];
end;

text_out = cat(2,text_above,text_out);
cellstr2text(summaryfilename, text_out);


