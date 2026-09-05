function results = runalltests()
% RUNALLTESTS - run every function-based test in this folder.
%
% RESULTS = RUNALLTESTS()
%
% Adds the parent (toolbox root) to the path, then runs every test_*.m
% file in this directory via matlab.unittest. Returns the
% TestResult array so callers can inspect failures.

here = fileparts(mfilename('fullpath'));
addpath(fileparts(here));

import matlab.unittest.TestSuite
suite = TestSuite.fromFolder(here);
results = run(suite);

disp(table(results));
end
