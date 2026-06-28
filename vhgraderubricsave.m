function vhgraderubricsave(rubricfile, entries)
% VHGRADERUBRICSAVE - save rubric entries so they can be reused across students
%
% VHGRADERUBRICSAVE(RUBRICFILE, ENTRIES)
%
% Saves the rubric ENTRIES (a struct array with fields 'description',
% 'points', and 'comment') to RUBRICFILE, creating the containing directory
% if needed. This is called when a grader adds a new rubric entry while
% grading so that the entry becomes available for subsequent students.
%
% See also: VHGRADERUBRICFILE, VHGRADERUBRICLOAD, VHGRADEQUESTION

rubricdir = fileparts(rubricfile);

ws = warning('state');
warning off;
try, mkdir(rubricdir); end;
warning('state',ws);

save(rubricfile,'entries','-mat');
