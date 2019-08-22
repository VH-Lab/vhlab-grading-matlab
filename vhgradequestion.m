function grade = vhgradequestion(vhgradedirname, inputitem, forceRegrade)
% VHGRADEQUESTION - grade a question
% 
% GRADE = VHGRADEQUESTION(DIRNAME, INPUTITEM, FORCEREGRADE)
%
% Grade a question specified in the structure INPUTITEM (see VHGRADEASSIGNMENT for
% information about the structure). 
%
% 
%

  % functions needed: vhgraderesponsegui, vhgradeloadresponse

if nargin<3,
	forceRegrade = 0;
end;

grade_directory = [dirname filesep 'GRADING'];

filename = [grade_directory filesep inputitem.Item_filename];

try,
	mkdir(grade_directory);
end;

if exist(filename,'file'),
	if ~forceRegrade,
		grade = load(filename);
		grade = grade.grade;
		return;
	end;
end;

 % if we are here, we need to grade or re-grade

grade.Item_name = inputitem.Item_name;
grade.Subfolder = inputitem.Subfolder;
grade.Item_filename = inputitem.Item_filename;
grade.Points_possible = inputitem.Points_possible;
grade.Description = inputitem.Description;
grade.Skills = inputitem.Skills;
grade.Comment_1 = '';
grade.Comment_2 = '';
grade.Points_earned = 0;

 % Step 1: run the code

if ~isempty(inputitem.Code),
	try,
		evalin('base', [inputitem.Code]);
	catch,
		% code didn't run successfully
		grade.Comment_1 = ['Code ' inputitem.Code ' did not run successfully; error was ' lasterr];
		save(filename,'grade','-mat');
		return;
	end;
end;

 % Step 2: if 'response_name', load it

if strcmpi(inputitem.Parameters(1).type,'response_name'),

 % load the response string
	try,
		response_string = vhgradeloadresponse([vhgradedirname filesep grade.Subfolder filesep 'response.md'], ...
			input.Parameters(1).response_name);
	catch,
		grade.Comment_1 = ['Response ' input.Parameters(1).response_name ' not found in response.md'];
		save(filename,'grade','-mat');
		return;
	end;
else,
	response_string = '';
end;

 % Step 3: if compare variable, do it

if strcmpi(inputitem.Parameters(1).type, 'vartest'),
	variable_matched_expected = 1;

	for i_loop_var=1:numel(inputitem.Parameters),
		varname = inputname.Parameters(i_loop_var).varname;
		value = inputname.Parameters(i_loop_var).value;
		tolerance = inputname.Parameters(i_loop_var).tolerance;
		compare = [];
		try,
			compare = evalin('base', varname);
		end;
		if numel(compare)~=numel(value),
			variable_matched_expected = 0;
		elseif any((abs( (compare(:)-value(:)) )) > tolerance), % fails
			variable_matched_expected = 0;
		end;
		if ~variable_matched_expected,
			grade.Comment_1 = ['Variable ' varname ' value did not match target value within tolerance.'];
			variable_matched_expected = 0;
			save(filename,'grade','-mat');
			return;
		end;
	end;
end;

 % Step 4: ask for user input if needed

if strcmpi(inputitem.Parameters(1).type,'manual') | strcmpi(inputitem.Parameters(1).type,'response_name'),
	h=vhgraderesponsegui('command', 'new','dirname',vhgradedirname, 'grade', grade, 'response_string', response_string,'inputgrade',inputitem);
	uiwait(h);
end;


