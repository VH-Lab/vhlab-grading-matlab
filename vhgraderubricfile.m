function f = vhgraderubricfile(vhgradedirname, inputitem)
% VHGRADERUBRICFILE - compute the path of the shared rubric file for an item
%
% F = VHGRADERUBRICFILE(VHGRADEDIRNAME, INPUTITEM)
%
% Returns the filename where the (shared, cross-student) rubric for the item
% INPUTITEM is persisted. VHGRADEDIRNAME is the directory of the student that
% is currently being graded (as passed to VHGRADEQUESTION); the rubric is
% stored one level up, in a 'RUBRICS' subfolder of the parent directory that
% holds all of the student directories, so that rubric entries added while
% grading one student are available when grading the next student.
%
% The file is named 'rubric_<Item_filename without extension>.mat'.
%
% See also: VHGRADERUBRICLOAD, VHGRADERUBRICSAVE, VHGRADEQUESTION

parentdir = fileparts(vhgradedirname);

[~,base] = fileparts(inputitem.Item_filename);

f = [parentdir filesep 'RUBRICS' filesep 'rubric_' base '.mat'];
