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

currpwd = pwd;

  % functions needed: vhgraderesponsegui, vhgradeloadresponse

if nargin<3,
	forceRegrade = 0;
end;

grade_directory = [vhgradedirname filesep 'GRADING']

filename = [grade_directory filesep inputitem.Item_filename];

warns = warning('state');
warning off;
try, mkdir(grade_directory); end;
warning('state',warns);

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
grade.CodeError = 0;

 % Step 0: set present working directory to Subfolder

cd([vhgradedirname filesep grade.Subfolder]);

 % Step 1: run the code

if ~isempty(inputitem.Code),
	try,
		evalin('base', [inputitem.Code]);
	catch,
		% code didn't run successfully
		grade.Comment_1 = ['Code ' inputitem.Code ' did not run successfully; error was ' lasterr];
		% here we need to pop up a dialog
		grade.CodeError = 1;
		save(filename,'grade','-mat');
		return;
	end;
end;

 % Step 2: if 'response_name', load it

if strcmpi(inputitem.Parameters(1).type,'response_name'),

 % load the response string
	if ~isempty(inputitem.Parameters(1).response_name),
		try,
			response_string = vhgradeloadresponse([vhgradedirname filesep grade.Subfolder filesep 'response.md'], ...
				inputitem.Parameters(1).response_name);
		catch,
			grade.Comment_1 = ['Response ' inputitem.Parameters(1).response_name ' not found in response.md'];
			save(filename,'grade','-mat');
			return;
		end;
	end;
else,
	response_string = '';
end;

 % Step 3: if compare variable, do it

if strcmpi(inputitem.Parameters(1).type, 'vartest'),
	variable_matched_expected = 1;

	comment = {};

	for i_loop_var=1:numel(inputitem.Parameters),
		varname = inputitem.Parameters(i_loop_var).varname;
		value = inputitem.Parameters(i_loop_var).value;
		tolerance = inputitem.Parameters(i_loop_var).tolerance;
		compare = [];
		try,
			compare = evalin('base', varname);
		end;
		if ~isnumeric(compare),
			variable_matched_expected = 0;
		elseif numel(compare)~=numel(value),
			variable_matched_expected = 0;
		elseif any((abs( (compare(:)-value(:)) )) > tolerance), % fails
			variable_matched_expected = 0;
		end;
		if ~variable_matched_expected,
			grade.Comment_1 = ['Variable ' varname ' value did not match target value within tolerance.'];
			variable_matched_expected = 0;
			save(filename,'grade','-mat');
			return;
		else,
			comment{end+1} = ['Variable ' varname ' value matched target value within tolerance.']; 
		end;
	end;

	if variable_matched_expected, % we are done
		grade.Comment_1 = comment;
		grade.Points_earned = inputitem.Points_possible;
		save(filename,'grade','-mat');
		return;
	end;
end;

 % Step 4: if test is 'anyvarmatch', do that
if strcmpi(inputitem.Parameters(1).type, 'anyvartest'),
	variable_matched_expected = 1;

	comment = {};

	ws = evalin('base','workspace2struct()');

	for i_loop_var=1:numel(inputitem.Parameters),
		found_this_value = 0;
		fn = fieldnames(ws);
		value = inputitem.Parameters(i_loop_var).value;
		tolerance = inputitem.Parameters(i_loop_var).tolerance;
		for j_loop_var=1:numel(fn),
			fn{j_loop_var};
			variable_j_matches = 1;
			compare = getfield(ws,fn{j_loop_var});
			if numel(compare)~=numel(value),
				variable_j_matches = 0;
			elseif ~isnumeric(compare),
				variable_j_matches = 0;
			elseif any((abs( (compare(:)-value(:)) )) > tolerance), % fails
				variable_j_matches = 0;
			end;
			if variable_j_matches, % we have a match here,
				comment{end+1} = ['Variable ' fn{j_loop_var} ' value matched target ' mat2str(value) ' within tolerance.'];
				found_this_value = 1;
				break;
			end;
		end;
		if ~found_this_value, % we reached end of j loop and no variable matched 
			grade.Comment_1 = ['No variable matched target value ' mat2str(value) ' within tolerance.'];
			variable_matched_expected = 0;
			save(filename,'grade','-mat');
			return;
		end;
	end;

	if variable_matched_expected, % we are done
		grade.Comment_1 = comment;
		grade.Points_earned = inputitem.Points_possible;
		save(filename,'grade','-mat');
		return;
	end;
end;

 % Step 5: ask for user input if needed

if strcmpi(inputitem.Parameters(1).type,'manual') | strcmpi(inputitem.Parameters(1).type,'response_name') | grade.CodeError,
	mycodewindow = [];
	if grade.CodeError,
		text_total = {};
		for i=1:numel(inputitem.CodeFiles),
			t_ = text2cellstr(inputitem.CodeFiles{i});
			text_total = cat(2,text_total,{['FILE: ' inputItem.CodeFiles{i} ' -----------------'},t_);
		end;
		mycodewindow = messagebox(text_total, 'Code window');
	end;
	h=vhgraderesponsegui('command', 'new', 'dirname', vhgradedirname, 'grade', grade, ...
		'response_string', response_string, 'inputgrade',inputitem);
	uiwait(h);
	if ~isempty(mycodewindow),
		delete(mycodewindow);
	end;
end;

cd(currpwd);
