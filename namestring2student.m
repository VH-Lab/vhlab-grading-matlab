function student_index = namestring2student(namestring, students)
% NAMESTRING2STUDENT - identify a student by a string that contains his/her name
%
% STUDENT_INDEX = NAMESTRING2STUDENT(NAMESTRING, STUDENTS)
%
% NAMESTRING is a plain text string with the student's first and last name (e.g., 'John Smith') or
% a full name (e.g., 'John Joseph Smith').
% STUDENTS is a structure with fields 'surname', 'firstname', 'othername', and 'email.'
%
% STUDENT_INDEX is the index number(s) of the matching student(s), if any.
%

student_index = [];

spaces = find(namestring==' ');

if numel(spaces)==0,
	error(['There must be at least one space in the name, separating a potential first name from a surname (' namestring ').']);
end;

firstname = strtrim(namestring(1:spaces(1)-1));
if numel(spaces)==1,
	lastname = strtrim(namestring(spaces+1:end));
	lastname1='';
	lastname2='';
else, % its ambiguious
	lastname = '';
	lastname1 = strtrim(namestring(spaces(1)+1:end));
	lastname2 = strtrim(namestring(spaces(end)+1:end));
end;

for i=1:length(students),
	match = 0;
	if strcmp(lower(students(i).firstname),lower(firstname)),  % potential match
		if strcmp(lower(students(i).surname),lower(lastname)),
			match = 1;
		elseif strcmp(lower(students(i).surname),lower(lastname1)),
			match = 1;
		elseif strcmp(lower(students(i).surname),lower(lastname2)),
			match = 1;
		end
	end
	if match,
		student_index(end+1) = i;
	end
end;


