function b = vhgradeassignment(parentdir, assignmentname, inputitemlist, itemname, forceRegrade)
% VHGRADEASSIGNMENT - grade an assignment where each student's answers are in a folder
%
% B = VHGRADEASSIGNMENT(PARENTDIR, ASSIGNMENTNAME, INPUTITEMLIST, [ITEMNAME], [FORCEREGRADE])
%
% Grades a SET of assignments, each with its own subdirectory in PARENTDIR, according to the
% rubric INPUTITEMLIST. If a specific ITEMNAME is provided, then only that item is graded.
% FORCEREGRADE will grade an item even if it has already been saved in the 'GRADING' subfolder.
%
% The INPUTITEMLIST should be a struct array with the following fields:
%
% Fieldname                         | Description
% -----------------------------------------------------------------------------------
% Item_name                         | The item name 
% Subfolder                         | Subfolder to use, if any
% Item_filename                     | The item's filename in the GRADING subfolder
% Points_possible                   | The points possible
% Code                              | The code to run
% Description                       | A string of the description of what is being sought
% Skills                            | A cell array of strings of all the skills used in this problem
%                                   |  (e.g., {'coding','loops','stats'} 
% Comment_1_default                 | Default first comment string
% Comment_2_default                 | Default second comment string
% Parameters                        | A structure array of 2 types:
%                                   |    can have fields: type='vartest', varname, value, tolerance to test variable names
%                                   |    can have field: type='manual', (opens GUI window for completion)
%                                   |    can have field: type='response_name', response_name (opens GUI window for completion)
%
% RESULTS of the grading will be saved in each subfolder of PARENTFOLDER.
% The results will be a structure array with the following fields:
%
% Fieldname                         | Description
% -----------------------------------------------------------------------------------
% Item_name                         | The item name (from INPUTITEMLIST)
% Item_filename                     | The itme's filename in the GRADING folder 
% Subfolder                         | The subfolder within the experiment to examine
% Points_possible                   | The points possible (from INPUTITEMLIST)
% Description                       | A string of the description of what is being sought
%                                   |   (from INPUTITEMLIST)
% Skills                            | A cell array of strings of all the skills used in this problem
%                                   |  (e.g., {'coding','loops','stats'}  (from INPUTITEMLIST)
% Points_earned                     | The number of points earned
% Comment_1                         | A first comment
% Comment_2                         | A second comment


if nargin<3,
	itemname = {inputitemlist.Item_name};
else,
	if ~iscell(itemname),
		itemname = {itemname};
	end;
end;

if nargin<4,
	forceRegrade = 0;
end;

[I,K1,K2] = intersect({inputitemlist.Item_name},itemname);

d = dirstrip(dir(parentdir)),

for i=1:numel(d),
	if d(i).isdir,
		% get ready to grade
		warnstate=warning('state');
		warning off;
		rmpath(genpath(parentdir)); % make sure we have no other graded files on the path
		warning('state', warnstate);

		addpath(genpath([parentdir filesep d(i).name]));

		for k=1:numel(K2),
			inputitemlist(K2(k)),
			vhgradequestion([parentdir filesep d(i).name], inputitemlist(K2(k)),forceRegrade);
		end;

		rmpath(genpath([parentdir filesep d(i).name]));

		vhgradesummary([parentdir filesep d(i).name], assignmentname, inputitemlist);
	end;
end;


