function fig = vhgradeoverview(parentDir, items)
% VHGRADEOVERVIEW - dashboard showing per-item grading progress for a cohort
%
% FIG = VHGRADEOVERVIEW(PARENTDIR, ITEMS)
%
% Scans every student subfolder of PARENTDIR for its GRADING/<item_filename>
% .mat files and shows a table with students down the rows and rubric items
% across the columns. Each cell shows either "-" (ungraded) or "N of M"
% (points earned / points possible). Selecting a cell (or a column) and
% clicking one of the action buttons resumes grading only for the ungraded
% students in that item, grades a single student × item cell, or forces a
% re-grade of an entire column.
%
% ITEMS is the struct array returned by e.g. BIO107A_PS_1_1_GRADING or
% VHGRADELOADRUBRIC.
%
% See also: VHGRADEQUESTION, VHGRADEASSIGNMENT, VHGRADELOADRUBRIC

if nargin < 2, error('vhgradeoverview:usage', 'Usage: vhgradeoverview(parentDir, items)'); end

fig = uifigure('Name', 'vhlab Grading Overview', 'Position', [50 50 1300 720]);

state = struct();
state.parentDir = parentDir;
state.items     = items;
state.students  = {};        % cellstr of subdir names, sorted
state.matrix    = [];        % numeric matrix nStudents x nItems, NaN = ungraded
state.possible  = [items.Points_possible];
fig.UserData    = state;

buildUI(fig);
refreshScan(fig);
end


% ==================================================================
function buildUI(fig)

gl = uigridlayout(fig, [3 1]);
gl.RowHeight   = {56, 'fit', '1x'};
gl.ColumnWidth = {'1x'};
gl.Padding     = [10 10 10 10];
gl.RowSpacing  = 8;

% ---- toolbar ----
tb = uigridlayout(gl, [1 8]);
tb.ColumnWidth = {90, 200, 200, 200, 200, 90, '1x', '1x'};
tb.Padding = [0 0 0 0]; tb.ColumnSpacing = 8;
uibutton(tb, 'Text', 'Refresh', 'ButtonPushedFcn', @(~,~) refreshScan(fig));
uibutton(tb, 'Text', 'Grade this cell', ...
    'ButtonPushedFcn', @(~,~) onGradeCell(fig));
uibutton(tb, 'Text', 'Resume item (ungraded)', ...
    'ButtonPushedFcn', @(~,~) onGradeColumn(fig, false));
uibutton(tb, 'Text', 'Regrade full item column', ...
    'ButtonPushedFcn', @(~,~) onGradeColumn(fig, true));
uibutton(tb, 'Text', 'Change directory…', ...
    'ButtonPushedFcn', @(~,~) onChangeDir(fig));
uilabel(tb, 'Text', 'Parent:');
pathLbl = uilabel(tb, 'Text', '', 'FontAngle','italic');
selLbl  = uilabel(tb, 'Text', '', 'HorizontalAlignment','right');

% ---- summary panel ----
summaryPanel = uipanel(gl, 'Title', 'Item completion');
sGrid = uigridlayout(summaryPanel, [1 1]); sGrid.Padding = [6 6 6 6];
summaryLbl = uilabel(sGrid, 'Text', '', 'WordWrap','on');

% ---- table ----
tblPanel = uipanel(gl, 'Title', 'Students × items');
tGrid = uigridlayout(tblPanel, [1 1]); tGrid.Padding = [6 6 6 6];
tbl = uitable(tGrid, 'Data', cell(0,0), 'ColumnEditable', false);
tbl.SelectionType = 'cell';
tbl.Multiselect   = 'off';
tbl.SelectionChangedFcn = @(~,~) refreshLabels(fig);

h = struct('pathLbl',pathLbl, 'selLbl',selLbl, 'summaryLbl',summaryLbl, 'tbl',tbl);
fig.UserData.h = h;
end


% ==================================================================
function refreshScan(fig)
s = fig.UserData;
d = dir(s.parentDir);
d = d([d.isdir]);
names = {d.name};
names = names(~ismember(names, {'.','..','GRADING'}));
% keep only real assignment folders (skip hidden)
names = names(~startsWith(names, '.'));
names = sort(names(:))';

n = numel(names);
m = numel(s.items);
matrix = NaN(n, m);
for i = 1:n
    gdir = fullfile(s.parentDir, names{i}, 'GRADING');
    if ~isfolder(gdir), continue; end
    for j = 1:m
        f = fullfile(gdir, s.items(j).Item_filename);
        if isfile(f)
            try
                L = load(f, '-mat', 'grade');
                if isfield(L,'grade') && isfield(L.grade,'Points_earned')
                    matrix(i, j) = L.grade.Points_earned;
                end
            catch
                % leave as NaN
            end
        end
    end
end

s.students = names;
s.matrix   = matrix;
fig.UserData = s;
refreshTable(fig);
refreshSummary(fig);
refreshLabels(fig);
end


% ==================================================================
function refreshTable(fig)
s = fig.UserData;
h = s.h;
n = numel(s.students);
m = numel(s.items);
data = cell(n, m+1);
for i = 1:n
    total = 0; possible = 0;
    for j = 1:m
        v = s.matrix(i, j);
        if isnan(v)
            data{i, j} = '—';
        else
            data{i, j} = sprintf('%g / %g', v, s.items(j).Points_possible);
            total = total + v;
            possible = possible + s.items(j).Points_possible;
        end
    end
    if possible > 0
        data{i, m+1} = sprintf('%g / %g  (%.0f%%)', total, ...
            sum(s.possible), 100*total/sum(s.possible));
    else
        data{i, m+1} = '—';
    end
end

itemHeaders = arrayfun(@(k) shortName(s.items(k).Item_name, 26), ...
    1:m, 'UniformOutput', false);
h.tbl.ColumnName = [{'Student'}, itemHeaders, {'Total'}];
h.tbl.RowName    = {};
h.tbl.Data       = [s.students(:), data];

% column widths
cw = [{200}, repmat({'auto'}, 1, m), {150}];
h.tbl.ColumnWidth = cw;

% Style cells: red-ish for ungraded, green/yellow/orange by fraction earned.
removeStyle(h.tbl);
buckets = struct('ungraded',[],'high',[],'mid',[],'low',[]);
for i = 1:n
    for j = 1:m
        idx = [i j+1];
        if isnan(s.matrix(i,j))
            buckets.ungraded(end+1,:) = idx; %#ok<AGROW>
        else
            frac = s.matrix(i,j) / max(s.items(j).Points_possible, eps);
            if frac >= 0.9
                buckets.high(end+1,:) = idx; %#ok<AGROW>
            elseif frac >= 0.5
                buckets.mid(end+1,:)  = idx; %#ok<AGROW>
            else
                buckets.low(end+1,:)  = idx; %#ok<AGROW>
            end
        end
    end
end
if ~isempty(buckets.ungraded)
    addStyle(h.tbl, uistyle('BackgroundColor',[1 0.92 0.92]), 'cell', buckets.ungraded);
end
if ~isempty(buckets.high)
    addStyle(h.tbl, uistyle('BackgroundColor',[0.90 1 0.90]), 'cell', buckets.high);
end
if ~isempty(buckets.mid)
    addStyle(h.tbl, uistyle('BackgroundColor',[1 1 0.85]),    'cell', buckets.mid);
end
if ~isempty(buckets.low)
    addStyle(h.tbl, uistyle('BackgroundColor',[1 0.85 0.75]), 'cell', buckets.low);
end
end


% ==================================================================
function refreshSummary(fig)
s = fig.UserData; h = s.h;
n = numel(s.students);
m = numel(s.items);
if n == 0
    h.summaryLbl.Text = '(no student folders found)';
    return;
end
lines = cell(1, m + 1);
lines{1} = sprintf('%d students × %d items', n, m);
for j = 1:m
    done = sum(~isnan(s.matrix(:, j)));
    lines{j+1} = sprintf('  %-40s  %d / %d graded (%.0f%%)', ...
        shortName(s.items(j).Item_name, 40), done, n, 100*done/max(n,1));
end
h.summaryLbl.Text = strjoin(lines, char(10));
end


% ==================================================================
function refreshLabels(fig)
s = fig.UserData; h = s.h;
h.pathLbl.Text = s.parentDir;
[row, itemCol] = liveSelection(s);
if isempty(row) || isempty(itemCol)
    h.selLbl.Text = '(click an item cell in the table first)';
else
    h.selLbl.Text = sprintf('Selected: %s / %s', ...
        s.students{row}, s.items(itemCol).Item_name);
end
end


% ==================================================================
% ------- callbacks -------
function [row, itemCol, msg] = liveSelection(s)
% Read the uitable's live Selection at call time so the buttons never
% get out of sync with the visible highlight.
row = []; itemCol = []; msg = '';
try
    sel = s.h.tbl.Selection;
catch
    sel = [];
end
if isempty(sel)
    msg = 'Click an item cell in the table first.';
    return;
end
if size(sel, 2) < 2
    msg = 'Selection is not a cell (this should not happen).';
    return;
end
r = sel(1,1); c = sel(1,2);
if r < 1 || r > numel(s.students)
    msg = sprintf('Row %d is out of range.', r);
    return;
end
if c == 1
    msg = 'That is the Student name column — click a cell in one of the item columns.';
    return;
end
if c > numel(s.items) + 1
    msg = 'That is the Total column — click a cell in one of the item columns.';
    return;
end
row = r; itemCol = c - 1;
end

function onGradeCell(fig)
s = fig.UserData;
[row, itemCol, msg] = liveSelection(s);
if isempty(row) || isempty(itemCol)
    uialert(fig, msg, 'No cell selected');
    return;
end
studentDir = fullfile(s.parentDir, s.students{row});
vhgradequestion(studentDir, s.items(itemCol), 1);
vhgradesummary(studentDir, 'PS overview', s.items);
refreshScan(fig);
end

function onGradeColumn(fig, forceAll)
s = fig.UserData;
[~, itemCol, msg] = liveSelection(s);
if isempty(itemCol)
    uialert(fig, msg, 'No item selected');
    return;
end
item = s.items(itemCol);
if forceAll
    idx = 1:numel(s.students);
else
    idx = find(isnan(s.matrix(:, itemCol)))';
    if isempty(idx)
        uialert(fig, sprintf('All students already have "%s" graded.', item.Item_name), ...
            'Nothing to do', 'Icon','info');
        return;
    end
end
for k = idx
    studentDir = fullfile(s.parentDir, s.students{k});
    vhgradequestion(studentDir, item, double(forceAll));
    vhgradesummary(studentDir, 'PS overview', s.items);
end
refreshScan(fig);
end

function onChangeDir(fig)
s = fig.UserData;
d = uigetdir(s.parentDir, 'Choose parent directory of student folders');
if isequal(d, 0), return; end
s.parentDir = d;
fig.UserData = s;
refreshScan(fig);
end


% ==================================================================
% ------- helpers -------
function name = shortName(name, n)
name = char(name);
if numel(name) > n
    name = [name(1:n-1) '…'];
end
end
