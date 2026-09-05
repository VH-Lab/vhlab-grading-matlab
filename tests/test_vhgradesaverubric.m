function tests = test_vhgradesaverubric
% TEST_VHGRADESAVERUBRIC - round-trip tests for the JSON writer.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
tc.TestData.here    = fileparts(mfilename('fullpath'));
tc.TestData.fixture = fullfile(tc.TestData.here, 'fixtures', 'tiny_rubric.json');
addpath(fileparts(tc.TestData.here));
tc.TestData.tmpDir = tempname; mkdir(tc.TestData.tmpDir);
end

function teardownOnce(tc)
if isfield(tc.TestData,'tmpDir') && isfolder(tc.TestData.tmpDir)
    rmdir(tc.TestData.tmpDir, 's');
end
end

function testRoundTripMetadata(tc)
[items, meta] = vhgradeloadrubric(tc.TestData.fixture);
outfile = fullfile(tc.TestData.tmpDir, 'roundtrip.json');
vhgradesaverubric(outfile, items, meta);
verifyTrue(tc, isfile(outfile), 'save must produce an output file');

[items2, meta2] = vhgradeloadrubric(outfile);
verifyEqual(tc, meta2.assignment_name, meta.assignment_name);
verifyEqual(tc, meta2.assignment_url,  meta.assignment_url);
verifyEqual(tc, meta2.points_model,    meta.points_model);
verifyEqual(tc, numel(meta2.shared_comment_bank), numel(meta.shared_comment_bank));
verifyEqual(tc, meta2.shared_comment_bank(2).points_delta, ...
             meta.shared_comment_bank(2).points_delta);
verifyEqual(tc, numel(items2), numel(items));
end

function testRoundTripItems(tc)
[items, meta] = vhgradeloadrubric(tc.TestData.fixture);
outfile = fullfile(tc.TestData.tmpDir, 'roundtrip_items.json');
vhgradesaverubric(outfile, items, meta);
items2 = vhgradeloadrubric(outfile);

for i = 1:numel(items)
    a = items(i); b = items2(i);
    verifyEqual(tc, b.Item_name,       a.Item_name);
    verifyEqual(tc, b.Subfolder,       a.Subfolder);
    verifyEqual(tc, b.Item_filename,   a.Item_filename);
    verifyEqual(tc, b.Points_possible, a.Points_possible);
    verifyEqual(tc, b.Skills,          a.Skills);
    verifyEqual(tc, b.CodeFiles,       a.CodeFiles);
    verifyEqual(tc, lower(char(b.Parameters(1).type)), lower(char(a.Parameters(1).type)));
    verifyEqual(tc, numel(b.Parameters), numel(a.Parameters));
    verifyEqual(tc, numel(b.Rubric),      numel(a.Rubric));
    verifyEqual(tc, numel(b.Comment_bank), numel(a.Comment_bank));
end
end

function testRoundTripAutograderChecks(tc)
[items, meta] = vhgradeloadrubric(tc.TestData.fixture);
outfile = fullfile(tc.TestData.tmpDir, 'roundtrip_checks.json');
vhgradesaverubric(outfile, items, meta);
items2 = vhgradeloadrubric(outfile);

% Q2 has an anyvartest with 2 weighted checks.
p1 = items(2).Parameters;
p2 = items2(2).Parameters;
verifyEqual(tc, numel(p2), numel(p1));
for k = 1:numel(p1)
    verifyEqual(tc, p2(k).criterion, p1(k).criterion);
    verifyEqual(tc, p2(k).value,     p1(k).value);
    verifyEqual(tc, p2(k).tolerance, p1(k).tolerance);
    verifyEqual(tc, p2(k).points,    p1(k).points);
end
end

function testRoundTripResponseName(tc)
[items, meta] = vhgradeloadrubric(tc.TestData.fixture);
outfile = fullfile(tc.TestData.tmpDir, 'roundtrip_resp.json');
vhgradesaverubric(outfile, items, meta);
items2 = vhgradeloadrubric(outfile);

verifyEqual(tc, items2(1).Parameters(1).response_name, ...
                items(1).Parameters(1).response_name);
end
