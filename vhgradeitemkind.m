function k = vhgradeitemkind(item)
% VHGRADEITEMKIND - classify a rubric item by what a grader will encounter.
%
% K = VHGRADEITEMKIND(ITEM)
%
% Returns one of:
%   'resp'       - written response only (response_name autograder, no Code)
%   'code'       - runs student Code and/or checks variables
%   'code+resp'  - runs Code AND asks the grader to read a response section
%   'manual'     - grader must judge with no autograder and no Code
%
% Used by VHGRADEOVERVIEW to tag columns and by VHGRADERESPONSEGUI to
% tag the grader window title.

hasCode = false;
if isfield(item,'Code'), hasCode = ~isempty(strtrim(char(item.Code))); end

autoType = 'manual';
if isfield(item,'Parameters') && ~isempty(item.Parameters)
    autoType = lower(char(item.Parameters(1).type));
end

switch autoType
    case 'response_name'
        if hasCode, k = 'code+resp'; else, k = 'resp'; end
    case {'vartest','anyvartest'}
        k = 'code';
    otherwise
        if hasCode, k = 'code'; else, k = 'manual'; end
end
