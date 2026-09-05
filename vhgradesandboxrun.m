function [ws, err] = vhgradesandboxrun(codeText, runDir)
% VHGRADESANDBOXRUN - run student code in an isolated function-scoped workspace
%
% [WS, ERR] = VHGRADESANDBOXRUN(CODETEXT, RUNDIR)
%
% Runs CODETEXT with EVAL inside this function's local workspace, so student
% variables never touch the base workspace. Returns:
%   WS  - struct whose fields are the local variables created by the code
%         (empty struct if the code errored)
%   ERR - MException raised by the code, or [] if it ran cleanly
%
% If RUNDIR is given the current directory is switched to it for the duration
% of the call and restored afterward, even on error.
%
% Caveats
%   * `clear` inside the student code clears this function's workspace
%     (harmless — we take a snapshot AFTER the eval).
%   * `global` and `persistent` variables still touch process-wide state.
%   * Figures the student opens remain open so the grader can look at them.
%     Caller is responsible for `close all hidden` between items if desired.
%   * `evalin('base',...)` inside student code will still reach the base
%     workspace; this is uncommon in student submissions.
%
% See also: VHGRADEQUESTION

if nargin < 2, runDir = ''; end

ws  = struct();
err = [];

startDir = pwd;
cleanup = onCleanup(@() cd(startDir));

if ~isempty(runDir)
    cd(runDir);
end

if isempty(codeText)
    return;
end

try
    eval(codeText);
catch ME
    err = ME;
    return;
end

% Snapshot every local variable created by the eval. The names we introduced
% ourselves (function args, cleanup, ME, etc.) are filtered out so they do
% not leak into the returned workspace.
reservedNames = {'codeText','runDir','ws','err','startDir','cleanup', ...
                 'ME','reservedNames','vhgrade__names','vhgrade__i','vhgrade__nm'};
vhgrade__names = who();
for vhgrade__i = 1:numel(vhgrade__names)
    vhgrade__nm = vhgrade__names{vhgrade__i};
    if ~any(strcmp(vhgrade__nm, reservedNames))
        ws.(vhgrade__nm) = eval(vhgrade__nm);
    end
end
