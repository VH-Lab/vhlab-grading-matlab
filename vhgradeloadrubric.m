function [items, meta] = vhgradeloadrubric(jsonfile)
% VHGRADELOADRUBRIC - load a JSON rubric into a grading struct array
%
% [ITEMS, META] = VHGRADELOADRUBRIC(JSONFILE)
%
% Reads a JSON rubric file and returns:
%   ITEMS - struct array with the fields VHGRADEQUESTION consumes, extended
%           with rubric and comment-bank fields for the additive-scoring UI.
%   META  - struct with top-level rubric metadata (assignment_name,
%           assignment_url, points_model, shared_comment_bank).
%
% Fields produced per item:
%   Item_name, Subfolder, Item_filename, Points_possible, Description,
%   Skills (cellstr), Code (char), CodeFiles (cellstr),
%   Comment_1_default (char), Comment_2_default (char),
%   Parameters (struct array in the old shape: type + response_name,
%              or type + varname/value/tolerance for {any}vartest, one
%              element per autograder check),
%   Rubric (struct array with .name, .points),
%   Comment_bank (struct array with .label, .text, .points_delta),
%   Shared_comment_bank (struct array, same shape, copied from META).
%
% See also: VHGRADESAVERUBRIC, VHGRADEQUESTION
%

raw = fileread(jsonfile);
J = jsondecode(raw);

meta = struct();
meta.assignment_name = getfielddef(J, 'assignment_name', '');
meta.assignment_url  = getfielddef(J, 'assignment_url',  '');
meta.points_model    = getfielddef(J, 'points_model',    'rubric_additive');
meta.shared_comment_bank = normalizeCommentBank( ...
    getfielddef(J, 'shared_comment_bank', []));

rawitems = getfielddef(J, 'items', []);
rawitems = ensureCellOfStructs(rawitems);

items = repmat(emptyItem(), 0, 0);

for i = 1:numel(rawitems)
    it = rawitems{i};
    out = emptyItem();
    out.Item_name        = char(getfielddef(it, 'item_name', ''));
    out.Subfolder        = char(getfielddef(it, 'subfolder', ''));
    out.Item_filename    = char(getfielddef(it, 'item_filename', ''));
    out.Points_possible  = double(getfielddef(it, 'points_possible', 0));
    out.Description      = char(getfielddef(it, 'description', ''));
    out.Skills           = ensureCellStr(getfielddef(it, 'skills', {}));
    out.Code             = char(getfielddef(it, 'code', ''));
    out.CodeFiles        = ensureCellStr(getfielddef(it, 'code_files', {}));
    out.Comment_1_default = '';
    out.Comment_2_default = '';
    out.Parameters       = parametersFromAutograder(getfielddef(it, 'autograder', struct()));
    out.Rubric           = normalizeRubric(getfielddef(it, 'rubric', []));
    out.Comment_bank     = normalizeCommentBank(getfielddef(it, 'comment_bank', []));
    out.Shared_comment_bank = meta.shared_comment_bank;

    if isempty(items)
        items = out;
    else
        items(end+1) = out; %#ok<AGROW>
    end
end


% ----- helpers -----

function s = emptyItem()
s = struct('Item_name','','Subfolder','','Item_filename','', ...
    'Points_possible',0,'Description','','Skills',{{}}, ...
    'Code','','CodeFiles',{{}}, ...
    'Comment_1_default','','Comment_2_default','', ...
    'Parameters',struct('type','manual'), ...
    'Rubric',emptyRubric(), ...
    'Comment_bank',emptyCommentBank(), ...
    'Shared_comment_bank',emptyCommentBank());

function r = emptyRubric()
r = struct('name',{},'points',{});

function c = emptyCommentBank()
c = struct('label',{},'text',{},'points_delta',{});

function v = getfielddef(s, f, d)
if isstruct(s) && isfield(s, f) && ~isempty(s.(f))
    v = s.(f);
else
    v = d;
end

function c = ensureCellStr(x)
if isempty(x)
    c = {};
elseif ischar(x)
    c = {x};
elseif iscellstr(x) %#ok<ISCLSTR>
    c = x(:).';
elseif isstring(x)
    c = cellstr(x(:).');
elseif iscell(x)
    c = cellfun(@char, x(:).', 'UniformOutput', false);
else
    c = {char(string(x))};
end

function c = ensureCellOfStructs(x)
if isempty(x)
    c = {};
elseif isstruct(x)
    c = arrayfun(@(k) x(k), 1:numel(x), 'UniformOutput', false);
elseif iscell(x)
    c = x(:).';
else
    c = {x};
end

function r = normalizeRubric(x)
r = emptyRubric();
xs = ensureCellOfStructs(x);
for k = 1:numel(xs)
    e = xs{k};
    r(end+1).name   = char(getfielddef(e, 'name', ''));    %#ok<AGROW>
    r(end).points   = double(getfielddef(e, 'points', 0));
end

function c = normalizeCommentBank(x)
c = emptyCommentBank();
xs = ensureCellOfStructs(x);
for k = 1:numel(xs)
    e = xs{k};
    c(end+1).label        = char(getfielddef(e, 'label', ''));   %#ok<AGROW>
    c(end).text           = char(getfielddef(e, 'text', ''));
    c(end).points_delta   = double(getfielddef(e, 'points_delta', 0));
end

function P = parametersFromAutograder(a)
% Convert the JSON autograder block into the classic Parameters struct array.
% - {any}vartest  -> one Parameters entry per check
% - response_name -> single Parameters entry
% - manual        -> single Parameters entry
if ~isstruct(a) || ~isfield(a,'type') || isempty(a.type)
    P = struct('type','manual');
    return;
end
switch lower(char(a.type))
    case {'response_name'}
        P = struct('type','response_name', ...
                   'response_name', char(getfielddef(a,'response_name','')));
    case {'vartest','anyvartest'}
        checks = ensureCellOfStructs(getfielddef(a, 'checks', []));
        if isempty(checks)
            P = struct('type', char(a.type));
            return;
        end
        P = repmat(struct('type', char(a.type), ...
                          'varname','', 'value',[], 'tolerance',0, ...
                          'criterion','', 'points',0), 1, numel(checks));
        for k = 1:numel(checks)
            c = checks{k};
            P(k).type      = char(a.type);
            P(k).varname   = char(getfielddef(c, 'varname', ''));
            P(k).value     = double(getfielddef(c, 'value', []));
            P(k).tolerance = double(getfielddef(c, 'tolerance', 0));
            P(k).criterion = char(getfielddef(c, 'criterion', ''));
            P(k).points    = double(getfielddef(c, 'points', 0));
        end
    otherwise
        P = struct('type', char(a.type));
end
