function vhgradesaverubric(jsonfile, items, meta)
% VHGRADESAVERUBRIC - write a grading struct array back to a JSON rubric file
%
% VHGRADESAVERUBRIC(JSONFILE, ITEMS, META)
%
% Inverse of VHGRADELOADRUBRIC: takes the ITEMS struct array and META struct
% and writes them as pretty-printed JSON. Preserves the schema described in
% VHGRADELOADRUBRIC's help.
%
% See also: VHGRADELOADRUBRIC
%

if nargin < 3
    meta = struct();
end

J = struct();
J.assignment_name    = char(getfielddef(meta, 'assignment_name', ''));
J.assignment_url     = char(getfielddef(meta, 'assignment_url', ''));
J.points_model       = char(getfielddef(meta, 'points_model', 'rubric_additive'));
J.shared_comment_bank = commentBankToCells( ...
    getfielddef(meta, 'shared_comment_bank', []));

J.items = cell(1, numel(items));
for i = 1:numel(items)
    it = items(i);
    ji = struct();
    ji.item_name        = char(it.Item_name);
    ji.subfolder        = char(it.Subfolder);
    ji.item_filename    = char(it.Item_filename);
    ji.points_possible  = double(it.Points_possible);
    ji.description      = char(it.Description);
    ji.skills           = it.Skills;      % cellstr -> JSON array of strings
    ji.code             = char(it.Code);
    ji.code_files       = it.CodeFiles;   % cellstr
    ji.autograder       = autograderFromParameters(it.Parameters);
    ji.rubric           = rubricToCells(it.Rubric);
    ji.comment_bank     = commentBankToCells(it.Comment_bank);
    J.items{i} = ji;
end

txt = jsonencode(J, 'PrettyPrint', true);
fid = fopen(jsonfile, 'w');
if fid == -1
    error('vhgradesaverubric:cannotOpen', 'Cannot open %s for writing.', jsonfile);
end
cleanup = onCleanup(@() fclose(fid));
fwrite(fid, txt, 'char');


% ----- helpers -----

function v = getfielddef(s, f, d)
if isstruct(s) && isfield(s, f) && ~isempty(s.(f))
    v = s.(f);
else
    v = d;
end

function C = rubricToCells(r)
C = cell(1, numel(r));
for k = 1:numel(r)
    C{k} = struct('name', char(r(k).name), ...
                  'points', double(r(k).points));
end

function C = commentBankToCells(cb)
if isempty(cb) || ~isstruct(cb)
    C = {};
    return;
end
C = cell(1, numel(cb));
for k = 1:numel(cb)
    C{k} = struct('label', char(cb(k).label), ...
                  'text', char(cb(k).text), ...
                  'points_delta', double(cb(k).points_delta));
end

function a = autograderFromParameters(P)
if isempty(P) || ~isstruct(P) || ~isfield(P,'type')
    a = struct('type','manual');
    return;
end
t = lower(char(P(1).type));
switch t
    case 'response_name'
        a = struct('type','response_name', ...
                   'response_name', char(getfielddef(P(1),'response_name','')));
    case {'vartest','anyvartest'}
        a = struct('type', t);
        checks = cell(1, numel(P));
        for k = 1:numel(P)
            c = struct();
            c.criterion = char(getfielddef(P(k),'criterion',''));
            v = getfielddef(P(k),'varname','');
            if ~isempty(v), c.varname = char(v); end
            c.value     = double(getfielddef(P(k),'value',0));
            c.tolerance = double(getfielddef(P(k),'tolerance',0));
            c.points    = double(getfielddef(P(k),'points',0));
            checks{k} = c;
        end
        a.checks = checks;
    otherwise
        a = struct('type', t);
end
