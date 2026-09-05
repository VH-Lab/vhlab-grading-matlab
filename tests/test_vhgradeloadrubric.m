function tests = test_vhgradeloadrubric
% TEST_VHGRADELOADRUBRIC - function-based tests for vhgradeloadrubric.
%
% Run with:  results = runtests('test_vhgradeloadrubric')
tests = functiontests(localfunctions);
end

function setupOnce(tc)
tc.TestData.here    = fileparts(mfilename('fullpath'));
tc.TestData.fixture = fullfile(tc.TestData.here, 'fixtures', 'tiny_rubric.json');
addpath(fileparts(tc.TestData.here));
end

function testMetadata(tc)
[~, meta] = vhgradeloadrubric(tc.TestData.fixture);
verifyEqual(tc, meta.assignment_name, 'Tiny Test Rubric');
verifyEqual(tc, meta.assignment_url,  'http://example.invalid/tiny');
verifyEqual(tc, meta.points_model,    'rubric_additive');
verifyEqual(tc, numel(meta.shared_comment_bank), 2);
verifyEqual(tc, meta.shared_comment_bank(1).label, 'Nice');
verifyEqual(tc, meta.shared_comment_bank(2).points_delta, -1);
end

function testItemCountAndTopFields(tc)
items = vhgradeloadrubric(tc.TestData.fixture);
verifyEqual(tc, numel(items), 3);
verifyEqual(tc, items(1).Item_name, 'Q1 response text');
verifyEqual(tc, items(2).Points_possible, 10);
verifyEqual(tc, items(3).Item_filename, 'q3.mat');
verifyEqual(tc, items(1).Skills, {'writing'});
verifyEqual(tc, items(2).CodeFiles, {'q2.m'});
end

function testResponseNameAutograder(tc)
items = vhgradeloadrubric(tc.TestData.fixture);
p = items(1).Parameters;
verifyEqual(tc, lower(char(p(1).type)), 'response_name');
verifyEqual(tc, p(1).response_name, '(\s*)#(\s*)Q(\s*)1');
end

function testAnyVartestExpandedToChecks(tc)
items = vhgradeloadrubric(tc.TestData.fixture);
p = items(2).Parameters;
verifyEqual(tc, numel(p), 2);
verifyEqual(tc, lower(char(p(1).type)), 'anyvartest');
verifyEqual(tc, p(1).criterion, 'answer_a');
verifyEqual(tc, p(1).value, 3.5);
verifyEqual(tc, p(1).tolerance, 0.001);
verifyEqual(tc, p(1).points, 6);
verifyEqual(tc, p(2).points, 4);
end

function testManualAutograder(tc)
items = vhgradeloadrubric(tc.TestData.fixture);
verifyEqual(tc, lower(char(items(3).Parameters(1).type)), 'manual');
end

function testRubricParsed(tc)
items = vhgradeloadrubric(tc.TestData.fixture);
r = items(1).Rubric;
verifyEqual(tc, numel(r), 2);
verifyEqual(tc, r(1).name, 'Attempted');
verifyEqual(tc, r(1).points, 3);
verifyEqual(tc, r(2).points, 2);
end

function testCommentBankAndShared(tc)
items = vhgradeloadrubric(tc.TestData.fixture);
verifyEqual(tc, numel(items(1).Comment_bank), 1);
verifyEqual(tc, items(1).Comment_bank(1).points_delta, -1);

% Shared bank propagates to every item.
for i = 1:numel(items)
    verifyEqual(tc, numel(items(i).Shared_comment_bank), 2, ...
        sprintf('shared bank size on item %d', i));
    verifyEqual(tc, items(i).Shared_comment_bank(1).label, 'Nice');
end
end

function testRubricSumsMatchPointsPossible(tc)
% Every item in the fixture is designed so rubric points sum to
% points_possible; this test catches accidental fixture drift.
items = vhgradeloadrubric(tc.TestData.fixture);
for i = 1:numel(items)
    if isempty(items(i).Rubric), continue; end
    s = sum([items(i).Rubric.points]);
    verifyEqual(tc, s, items(i).Points_possible, ...
        sprintf('item %d rubric sum', i));
end
end
