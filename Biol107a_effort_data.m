function effortdata = Biol107a_effort_data(docid, datelow, datehigh, students)
% BIOL107A_EFFORT_DATA - read in effort data for Biol107a survey responses
%
% EFFORTDATA = BIOL107A_EFFORT_DATA(DOCID, DATELOW, DATEHIGH, STUDENTS)
%
% Returns all entries of effort spreadsheet where the timestamp is 
% between DATELOW and DATEHIGH. DATELOW and DATEHIGH should be in
% 'YYYY-MM-DD'.
%

myspreadsheet = GetGoogleSpreadsheet(docid);

myspreadsheet = spreadsheet_filterbydate(myspreadsheet,datelow,datehigh);

 % first, ensure all students have turned in the survey

email_column = find(strcmpi('Email Address',myspreadsheet(1,:)));

submitted_emails = myspreadsheet(2:end,email_column);
unsubmitted = setdiff(setdiff({students.email},submitted_emails),'noreply@brandeis.edu');

disp(['The following students have not yet submitted their survey.']);

unsubmitted'

 % check to make sure every student name that is submitted is identifyable while categorizing scores

teammate1_column = find(strcmp('Name of teammate #1',myspreadsheet(1,:)));
teammate2_column = find(strcmp('Name of teammate #2',myspreadsheet(1,:)));

scores = NaN(numel(students),2,3);

scoreindexes = [ ...
	find(strcmpi('Effort of teammate #1 on Team Project 1',myspreadsheet(1,:))) find(strcmpi('Effort of teammate #2 on Team Project 1',myspreadsheet(1,:)))
	find(strcmpi('Effort of teammate #1 on Team Project 2',myspreadsheet(1,:))) find(strcmpi('Effort of teammate #2 on Team Project 2',myspreadsheet(1,:)))
	find(strcmpi('Effort of teammate #1 on Team Project 3',myspreadsheet(1,:))) find(strcmpi('Effort of teammate #2 on Team Project 3',myspreadsheet(1,:)))
	];

for i=2:numel(myspreadsheet(:,teammate1_column)),
	name1 = strtrim(myspreadsheet{i,teammate1_column});
	student_index1 = namestring2student(name1,students); 
	if numel(student_index1)~=1,
		disp(['Unknown student ' name1 '.']);
	else,
		if isnan(scores(student_index1,1,1)), fillindex = 1; else, fillindex = 2; end;
		for j=1:size(scoreindexes,1),
			scores(student_index1,fillindex,j) = str2num(myspreadsheet{i,scoreindexes(j,1)});
		end
	end
	name2 = strtrim(myspreadsheet{i,teammate2_column});
	if ~ (strcmp(strtrim(lower(name2)),'na') | strcmp(strtrim(lower(name2)),'n/a')  ),
		student_index2 = namestring2student(name2,students); 
		if numel(student_index2)~=1,
			disp(['Unknown student ' name2 '.']);
		else,
			if isnan(scores(student_index2,1,1)), fillindex = 1; else, fillindex = 2; end;
			for j=1:size(scoreindexes,1),
				scores(student_index2,fillindex,j) = str2num(myspreadsheet{i,scoreindexes(j,2)});
			end
		end
	end
end

for i=1:size(scores,1),
	scorevector = scores(i,:,:);
	overallscore = nanmean(scorevector(:));
	disp([students(i).surname  ',' students(i).firstname ' received ' mat2str([ squeeze(scores(i,:,:))]) '; nanmean ' mat2str(nanmean(squeeze(scores(i,:,:)))) ', overall ' num2str(overallscore) '.']);
end
