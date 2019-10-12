function vhgradepost2github(parentdir, repository_prefix, push)
% VHGRADEPOST2GITHUB - post all git assignments in a directory back to GitHub
%
% VHGRADEPOST2GITHUB(PARENTDIR, REPOSITORY_PREFIX, PUSH)
%
% This function navigates through a directory of GitHub repositories that
% contain assignments of students. It is assumed that subdirectories in
% the PARENTDIR are named with the username of the GitHub user.
% 
% This function takes the following actions:
%
% 1) Calls git via SYSTEM to add all files of the folder GRADING for each
%    student repository
% 2) Calls git via SYSTEM to commit all changes with a note 'grading'.
% 3) If PUSH is 1, then the repositories are pushed back to 
%    ['https://github.com/' REPOSITORY_PREFIX USERNAME] where USERNAME is
%    the GitHub username that is taken from each subdirectory name of the
%    parent directory.
%
%
 
currdir = pwd;

d = dirstrip(dir(parentdir));

if nargin<3,
	push = 0;
end;

for i=1:numel(d),
	cd([parentdir filesep d(i).name]);
	system('git add GRADING/*');
	system('git commit -a -m ''grading''');
	if push,
		system(['git push https://github.com/' repository_prefix ...
			d(i).name]);
	end;
end;

cd(currdir);

