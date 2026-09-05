function tests = test_vhgradequestion_auto
% TEST_VHGRADEQUESTION_AUTO - end-to-end autograder happy-path tests.
%
% Only exercises the branch where every autograder check passes, since
% that branch saves the grade and returns without opening the GUI.
% Failing / partial-credit paths open vhgraderesponsegui and would block
% a headless test run.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
tc.TestData.here    = fileparts(mfilename('fullpath'));
tc.TestData.fixture = fullfile(tc.TestData.here, 'fixtures', 'tiny_rubric.json');
addpath(fileparts(tc.TestData.here));
end

function setup(tc)
tc.TestData.parentDir = tempname;
mkdir(tc.TestData.parentDir);
end

function teardown(tc)
if isfield(tc.TestData,'parentDir') && isfolder(tc.TestData.parentDir)
    rmdir(tc.TestData.parentDir, 's');
end
end

function testAllChecksPassAwardsFullCredit(tc)
items = vhgradeloadrubric(tc.TestData.fixture);
item = items(2);   % anyvartest, 10 points

qdir = fullfile(tc.TestData.parentDir, item.Subfolder);
mkdir(qdir);
writeQ2(qdir, 3.5, 17);

grade = vhgradequestion(tc.TestData.parentDir, item);

verifyEqual(tc, grade.Points_earned, item.Points_possible, ...
    'all checks pass → full credit');
verifyEqual(tc, grade.CodeError, 0, 'no code error expected');
verifyTrue(tc, isfile(fullfile(tc.TestData.parentDir,'GRADING',item.Item_filename)), ...
    'grade .mat should be written');
verifyTrue(tc, all(grade.Autograder_score.checks_passed), ...
    'every check should pass');
end

function testCachedGradeIsReturnedUnchanged(tc)
% Second call without forceRegrade must NOT re-run the sandbox; it should
% just reload the saved grade.
items = vhgradeloadrubric(tc.TestData.fixture);
item = items(2);
qdir = fullfile(tc.TestData.parentDir, item.Subfolder);
mkdir(qdir);
writeQ2(qdir, 3.5, 17);

g1 = vhgradequestion(tc.TestData.parentDir, item);

% Overwrite q2.m so the code would fail if it re-ran:
writeQ2(qdir, 0, 0);
g2 = vhgradequestion(tc.TestData.parentDir, item);

verifyEqual(tc, g2.Points_earned, g1.Points_earned, ...
    'cached grade must be reused when forceRegrade is 0');
end

function testDoesNotPolluteBaseWorkspace(tc)
% Belt-and-braces: make sure the autograder path leaves no trace in base.
items = vhgradeloadrubric(tc.TestData.fixture);
item = items(2);
qdir = fullfile(tc.TestData.parentDir, item.Subfolder);
mkdir(qdir);
writeQ2(qdir, 3.5, 17);

evalin('base', 'clear answer_a answer_b');
vhgradequestion(tc.TestData.parentDir, item);
baseNames = evalin('base', 'who');
verifyFalse(tc, any(strcmp(baseNames,'answer_a')), 'answer_a leaked to base');
verifyFalse(tc, any(strcmp(baseNames,'answer_b')), 'answer_b leaked to base');
end


% ----- helpers -----
function writeQ2(qdir, a, b)
fid = fopen(fullfile(qdir,'q2.m'),'w');
c = onCleanup(@() fclose(fid));
fprintf(fid, 'answer_a = %.6f;\nanswer_b = %.6f;\n', a, b);
end
