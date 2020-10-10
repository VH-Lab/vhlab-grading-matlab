function qstruct = latte(dirname, fieldname, qstruct_continue, varargin)
% vlt.grade.latte - grade a question in files turned in on Latte
%
% QSTRUCT = vlt.grade.latte(DIRNAME, FIELDNAME, QSTRUCT_CONTINUE, ...)
%
% This function traverses a Latte file dump folder and prompts the grader
% to enter a score. DIRNAME is the directory name where the submissions have been
% downloaded. FIELDNAME is the field name where the result is stored 
% (e.g., 'q1a'), and QSTRUCT_CONTINUE can be empty or it can be a structure
% from a previous grading run that was aborted. FIELDNAME must be a valid name
% for a Matlab structure field (must begin with a letter, no spaces, etc).
%
% The program will launch a viewer to view the submission and prompt the
% grader with ['Score for ' FIELDNAME '?']. The user can enter a number, or
% a negative number to abort the run. 
%
% QSTRUCT has a field name (last name, then first name) and a field FIELDNAME
% with the value of the grade. If the grade has not been entered yet, then
% the value of the grade will be empty.
%
% The user will also have the opportunity to write a note.
%
% This function takes name/value pairs that override its default behavior:
% Parameter name (default value)       | Description
% -----------------------------------------------------------------------
% program ('open')                     | System program to be launched for 
%                                      |    file viewing
% name_end_token '_'                   | The token that ends each student's
%                                      |    name.
% First_Last (1)                       | Are student names in First/Last form?
% file_search (['*_file_'])            | Search string to find submission directories.
% 
%
% Example:
%  dirname = '/Users/vanhoosr/Desktop/203NBIO-140B-1-Homework 2 - Due 105-1250372';
%  hw2_q1a = vlt.grade.latte(dirname,'q1a',[]);
%  hw2_q1b = vlt.grade.latte(dirname,'q1b',[]);
%  hw2_q1c = vlt.grade.latte(dirname,'q1c',[]);
%  hw2_q1d = vlt.grade.latte(dirname,'q1d',[]);
%  cellstr = vlt.grade.latte_summarize(hw2_q1a,hw2_q1b,hw2_q1c,hw2_q1d);
%  vlt.file.cellstr2text('output.txt',cellstr);
%


program = 'open';
name_end_token = '_';
First_Last = 1;
file_search = ['*_file_'];

vlt.data.assign(varargin{:});

disp(['Examining ' dirname ' for files...']);

d = vlt.file.dirstrip(dir([dirname filesep file_search]));

qstruct = emptystruct('name',fieldname,'note');

if isempty(qstruct_continue),
	qstruct_continue = emptystruct('name',fieldname,'note');
end;

for i=1:numel(d),
	token_index = find(d(i).name==name_end_token);
	if isempty(token_index),
		error(['No name end token for ' d(i).name '.']);
	end;
	name_here = d(i).name(1:token_index(1)-1);
	if First_Last,
		sp = find(name_here==' ');
		if ~isempty(sp),
			name_here = [name_here(sp+1:end) ', ' name_here(1:sp-1) ];
		end;
	end;
	already_here = find(strcmp(name_here, {qstruct_continue.name}));
	if ~isempty(already_here),
		qstruct(end+1) = qstruct_continue(already_here(1));
	else, 
		qstruct(end+1) = struct('name',name_here,fieldname,[],'note','');
	end;
end;

for i=1:numel(d),
	if isempty(getfield(qstruct(i),fieldname)),
		% no grade here yet

		% Step 1: open files for viewing
		f = dir([dirname filesep d(i).name filesep '*'])
		foundsubmission = 0;
		for j=1:numel(f),
			[pname,fname,ext]=fileparts(f(j).name);
			if strcmpi(ext,'.pdf'),
				foundsubmission = 1;
				system_command =[program ' "' dirname filesep d(i).name filesep f(j).name '" &'],
				system(system_command);
			end;
		end;
		if foundsubmission==0,
			warning(['No submission found for student ' qstruct(i).name ', skipping.']);
		end;

		% interview

		q = input(['Score for ' fieldname ', -1 to abort: ']);
		if q<0, 
			disp('Aborting...');
			return;
		else,
			n = input('Any note?','s');
			qstruct(i) = setfield(qstruct(i),fieldname,q);
			qstruct(i) = setfield(qstruct(i),'note',n);
		end;
	end;
end;


