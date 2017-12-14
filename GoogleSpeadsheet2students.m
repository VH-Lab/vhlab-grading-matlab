function students=GoogleSpeadsheet2students(docid)
% GoogleSpeadsheet2students - read a student list from a Google spreadsheet
% 
% STUDENTS = GOOGLESPEADSHEET2STUDENTS(DOCID)
%
% Given a Google Spreadsheet, returns a structure of students. It is assumed that the
% Google Speadsheet has fields "Student" and "Email" that have the name and email address.
% The names of the students are assumed to be in "Lastname,firstname othername". The email address
% is taken verbatim.
%
% The structure of students includes 3 fields:
%    surname - the student's surname
%    firstname - the student's first name
%    othername - any other text in the student's name
%    email  - the student's email address
%
% Requires: GetGoogleSpeadsheet (or https://github.com/VH-Lab/vhlab_thirdparty, which includes this)
%  

myspeadsheet = GetGoogleSpeadsheet(docid);

namecolumn_label = 'Student';
emailcolumn_label = 'Email';

namecolumn = find(strcmp(namecolumn_label, myspreadsheet{1,:}));
emailcolumn = find(strcmp(emailcolumn, myspreadsheet{1,:}));

if isempty(namecolumn) | isempty(emailcolumn) | numel(namecolumn)>1 | numel(emailcolumn)>1,
	error(['cannot identify columns for names or email addresses.']);
end;

students = emptystruct('surname','firstname','othername','email');

for k=2:size(myspreadsheet(:,namecolumn)),
	student_string = myspreadsheet{k,namecolumn};
	email_string = strtrim(myspreadsheet{k,emailcolumn});
	comma = find(student_string==',');
	if numel(comma)~=1,
		error(['could not process student string ' student_string '.']);
	end;
	lastname = strtrim(student_string(1:comma-1)); % trim whitespace also
	restofname = student_string(comma+1:end);
	space = find(restofname==' ');
	if isempty(space),
		firstname = strtrim(restofname);
		restofname = '';
	else,
		firstname = strtrim(restofname(1:space-1));
		restofname = strtrim(restofname(space+1));
	end
	students(end+1) = struct('surname',lastname,'firstname',firstname,'restofname',restofname,'email',email);
end


