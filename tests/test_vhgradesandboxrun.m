function tests = test_vhgradesandboxrun
% TEST_VHGRADESANDBOXRUN - tests for the isolated code-runner.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
tc.TestData.here = fileparts(mfilename('fullpath'));
addpath(fileparts(tc.TestData.here));
tc.TestData.tmpDir = tempname; mkdir(tc.TestData.tmpDir);
end

function teardownOnce(tc)
if isfield(tc.TestData,'tmpDir') && isfolder(tc.TestData.tmpDir)
    rmdir(tc.TestData.tmpDir, 's');
end
end

function testEmptyCode(tc)
[ws, err] = vhgradesandboxrun('');
verifyEmpty(tc, err);
verifyEmpty(tc, fieldnames(ws), 'no fields for empty code');
end

function testSimpleVariables(tc)
[ws, err] = vhgradesandboxrun('a = 3; b = [1 2 3]; c = ''hello'';');
verifyEmpty(tc, err);
verifyEqual(tc, ws.a, 3);
verifyEqual(tc, ws.b, [1 2 3]);
verifyEqual(tc, ws.c, 'hello');
end

function testErrorReturnsEmptyWorkspace(tc)
[ws, err] = vhgradesandboxrun('error(''vhgrade:test:oops'', ''nope'')');
verifyNotEmpty(tc, err);
verifyEqual(tc, err.identifier, 'vhgrade:test:oops');
verifyEmpty(tc, fieldnames(ws), ...
    'workspace is empty when code errors');
end

function testDoesNotPolluteBase(tc)
% Seed the base workspace with a canary, then run sandbox code that also
% names it — the base value should be untouched.
canary = 'vhgrade_test_canary_47';
assignin('base', canary, 999);
cleanup = onCleanup(@() evalin('base', ['clear ' canary]));

[~, err] = vhgradesandboxrun([canary ' = 1;']);
verifyEmpty(tc, err);
verifyEqual(tc, evalin('base', canary), 999, ...
    'sandbox must not overwrite base workspace variable');
end

function testCdChangesAndRestores(tc)
startDir = pwd;
[ws, err] = vhgradesandboxrun('here = pwd;', tc.TestData.tmpDir);
verifyEmpty(tc, err);
verifyEqual(tc, pwd, startDir, 'pwd must be restored after sandbox call');
% Compare canonical paths — some platforms symlink tempdir.
verifyEqual(tc, whatFolder(ws.here), whatFolder(tc.TestData.tmpDir), ...
    'code should have run inside runDir');
end

function testCdRestoredOnError(tc)
startDir = pwd;
[~, err] = vhgradesandboxrun('error(''boom'')', tc.TestData.tmpDir);
verifyNotEmpty(tc, err);
verifyEqual(tc, pwd, startDir, 'pwd must be restored even when code errors');
end

function testReservedNamesNotLeaked(tc)
% Names used inside vhgradesandboxrun (codeText, runDir, ws, err, etc.)
% must not appear as fields in the returned workspace even though they
% exist in the function's own scope.
[ws, err] = vhgradesandboxrun('x = 42;');
verifyEmpty(tc, err);
leaked = intersect(fieldnames(ws), ...
    {'codeText','runDir','ws','err','startDir','cleanup','ME','reservedNames'});
verifyEmpty(tc, leaked, ...
    sprintf('reserved names leaked: %s', strjoin(leaked, ', ')));
verifyEqual(tc, ws.x, 42);
end


% ----- helpers -----
function p = whatFolder(p)
% Canonicalize a folder path so tempdir-symlink differences don't fail.
d = dir(p);
if ~isempty(d)
    p = d(1).folder;
end
end
