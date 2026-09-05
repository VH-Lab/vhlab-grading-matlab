function [ws, err] = vhgradesandboxrun(codeText, runDir)
% VHGRADESANDBOXRUN - run student code in an isolated function-scoped workspace
%
% [WS, ERR] = VHGRADESANDBOXRUN(CODETEXT, RUNDIR)
%
% Runs CODETEXT with EVAL inside a subfunction's local workspace, so
% student variables never touch the base workspace and a `clear`
% statement inside the student code only wipes the subfunction's own
% scope — never this function's ws/err outputs.
%
% Returns:
%   WS  - struct whose fields are the local variables created by the code
%         (empty struct if the code errored)
%   ERR - MException raised by the code, or [] if it ran cleanly
%
% If RUNDIR is given the current directory is switched to it for the
% duration of the call and restored afterward, even on error or if the
% student code calls `clear`.
%
% Caveats
%   * `global` and `persistent` variables still touch process-wide state.
%   * Figures the student opens remain open so the grader can look at them.
%     Caller is responsible for `close all hidden` between items if desired.
%   * `evalin('base',...)` inside student code will still reach base.
%
% See also: VHGRADEQUESTION

if nargin < 2, runDir = ''; end

startDir = pwd;
cleanup = onCleanup(@() cd(startDir)); %#ok<NASGU>
if ~isempty(runDir)
    cd(runDir);
end

ws  = struct();
err = [];

if isempty(codeText)
    return;
end

try
    ws = i_evalAndSnapshot(codeText);
catch ME
    ws  = struct();
    err = ME;
end
end


% ==================================================================
function outWs__ = i_evalAndSnapshot(codeIn__)
% Runs student code and snapshots its locals into a struct. Because this
% is a subfunction, `clear` inside the student code only touches THIS
% scope — the caller's ws/err/startDir/cleanup are safe.

eval(codeIn__);

% Re-establish our own locals AFTER the eval (they may have been cleared
% by student code). Snapshot every remaining local except our own names.
outWs__    = struct();
excluded__ = {'codeIn__','outWs__','excluded__','names__','k__','nm__'};
names__    = who();
for k__ = 1:numel(names__)
    nm__ = names__{k__};
    if ~any(strcmp(nm__, excluded__))
        outWs__.(nm__) = eval(nm__);
    end
end
end
