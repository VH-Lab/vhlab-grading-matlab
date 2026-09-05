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

gl = uigridlayout(fig, [5 1]);
gl.RowHeight   = {40, 40, 26, 'fit', '1x'};
gl.ColumnWidth = {'1x'};
gl.Padding     = [10 10 10 10];
gl.RowSpacing  = 6;

% ---- toolbar (row 1) ----
tb = uigridlayout(gl, [1 6]);
tb.ColumnWidth = {90, 260, 260, 260, 160, '1x'};
tb.Padding = [0 0 0 0]; tb.ColumnSpacing = 8;

uibutton(tb, 'Text', 'Refresh', ...
    'Tooltip', 'Rescan the parent directory and reload every student''s GRADING/*.mat files.', ...
    'ButtonPushedFcn', @(~,~) refreshScan(fig));

uibutton(tb, 'Text', 'Grade one cell (student × item)', ...
    'Tooltip', 'Grade the currently-highlighted cell only. Opens the grader for that one student on that one item (force regrade).', ...
    'ButtonPushedFcn', @(~,~) onGradeCell(fig));

uibutton(tb, 'Text', 'Grade this item for all ungraded students', ...
    'Tooltip', 'Walk through every student who does not yet have this item graded. Skips students already graded on this item.', ...
    'BackgroundColor', [0.85 0.95 1], ...
    'ButtonPushedFcn', @(~,~) onGradeColumn(fig, false));

uibutton(tb, 'Text', 'Regrade this item for ALL students (force)', ...
    'Tooltip', 'Force-regrade every student on this item, even if it was already graded. Use if the rubric changed or you want to redo the whole column.', ...
    'ButtonPushedFcn', @(~,~) onGradeColumn(fig, true));

uibutton(tb, 'Text', 'Change directory…', ...
    'Tooltip', 'Point at a different parent directory of student folders.', ...
    'ButtonPushedFcn', @(~,~) onChangeDir(fig));

% ---- toolbar (row 2): summaries + exports ----
tb2 = uigridlayout(gl, [1 4]);
tb2.ColumnWidth = {260, 260, 260, '1x'};
tb2.Padding = [0 0 0 0]; tb2.ColumnSpacing = 8;

uibutton(tb2, 'Text', 'Refresh all summaries', ...
    'Tooltip', 'Rewrite the GRADING/summary.txt file inside every student folder from their current graded .mat files.', ...
    'ButtonPushedFcn', @(~,~) onRefreshSummaries(fig));

uibutton(tb2, 'Text', 'Open selected student''s summary', ...
    'Tooltip', 'Open the GRADING/summary.txt for whichever student is highlighted in the table.', ...
    'ButtonPushedFcn', @(~,~) onOpenStudentSummary(fig));

uibutton(tb2, 'Text', 'Export cohort CSV…', ...
    'Tooltip', 'Save a CSV with one row per student and one column per item, plus totals.', ...
    'ButtonPushedFcn', @(~,~) onExportCsv(fig));

% (selection label lives in the hint row below the toolbar)

% ---- hint row (row 3): parent dir + current selection ----
hintGrid = uigridlayout(gl, [1 2]);
hintGrid.ColumnWidth = {'1x', '1x'};
hintGrid.Padding = [0 0 0 0]; hintGrid.ColumnSpacing = 12;
pathLbl = uilabel(hintGrid, 'Text', '', 'FontAngle','italic');
selLbl  = uilabel(hintGrid, 'Text', '', 'HorizontalAlignment','right', ...
    'FontWeight','bold');

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

itemHeaders = arrayfun(@(k) sprintf('[%s] %s', ...
    vhgradeitemkind(s.items(k)), shortName(s.items(k).Item_name, 24)), ...
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
lines = cell(1, m + 2);
lines{1} = sprintf('%d students × %d items', n, m);
lines{2} = 'Kinds: [resp]=written response · [code]=runs student code · [code+resp]=both · [manual]=grader only';
for j = 1:m
    done = sum(~isnan(s.matrix(:, j)));
    lines{j+2} = sprintf('  [%-9s] %-40s  %d / %d graded (%.0f%%)', ...
        vhgradeitemkind(s.items(j)), shortName(s.items(j).Item_name, 40), ...
        done, n, 100*done/max(n,1));
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
item = s.items(itemCol);
restorePath = withStudentOnPath(s.parentDir, studentDir);
try
    vhgradequestion(studentDir, item, 1);
    vhgradesummary(studentDir, 'PS overview', s.items);
    after = readGradeFile(studentDir, item);
catch ME
    delete(restorePath);
    rethrow(ME);
end
delete(restorePath);
refreshScan(fig);

if ~isempty(after) && isfield(after,'Autograded_only') && after.Autograded_only
    txt = sprintf(['"%s" was saved without opening the manual grader.\n\n' ...
                   'Result: %g / %g\n\nReason:\n%s'], ...
                   item.Item_name, after.Points_earned, ...
                   after.Points_possible, commentSummary(after));
    uialert(fig, txt, 'Auto-saved (no UI needed)', 'Icon','info');
end
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
    restorePath = withStudentOnPath(s.parentDir, studentDir); %#ok<NASGU>
    try
        vhgradequestion(studentDir, item, double(forceAll));
        vhgradesummary(studentDir, 'PS overview', s.items);
    catch ME
        clear restorePath
        warning('vhgradeoverview:gradeFailed', ...
            'grading %s failed: %s', s.students{k}, ME.message);
        continue;
    end
    clear restorePath
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

function onRefreshSummaries(fig)
s = fig.UserData;
n = numel(s.students);
if n == 0
    uialert(fig, 'No student folders found.', 'Nothing to summarize');
    return;
end
dlg = uiprogressdlg(fig, 'Title','Refreshing summaries', ...
    'Message', sprintf('Writing summary.txt for %d students…', n), ...
    'Indeterminate','off');
for k = 1:n
    dlg.Value = k / n;
    dlg.Message = sprintf('Writing summary for %s (%d/%d)…', s.students{k}, k, n);
    studentDir = fullfile(s.parentDir, s.students{k});
    try
        vhgradesummary(studentDir, 'PS overview', s.items);
    catch ME
        warning('vhgradeoverview:summaryFailed', ...
            'summary failed for %s: %s', s.students{k}, ME.message);
    end
end
close(dlg);
uialert(fig, sprintf('Wrote / refreshed summary.txt for %d students.', n), ...
    'Summaries refreshed', 'Icon','success');
end

function onOpenStudentSummary(fig)
s = fig.UserData;
[row, ~, msg] = liveSelection(s);
if isempty(row)
    % Selection might be a Student-column click — still valid to pick a row.
    try
        sel = s.h.tbl.Selection;
        if ~isempty(sel), row = sel(1,1); end
    catch
    end
end
if isempty(row) || row < 1 || row > numel(s.students)
    uialert(fig, ...
        ['Click any cell in a student row first (' msg ')'], ...
        'Pick a student');
    return;
end
studentDir = fullfile(s.parentDir, s.students{row});
sumPath = fullfile(studentDir, 'GRADING', 'summary.txt');
if ~isfile(sumPath)
    % Try to generate it on the fly.
    try
        vhgradesummary(studentDir, 'PS overview', s.items);
    catch
    end
end
if ~isfile(sumPath)
    uialert(fig, sprintf('No summary.txt found for %s.', s.students{row}), ...
        'Nothing to open');
    return;
end
try
    open(sumPath);       % pick the OS's default text app; falls back to MATLAB
catch
    edit(sumPath);       % open in MATLAB editor as a fallback
end
end

function onExportCsv(fig)
s = fig.UserData;
n = numel(s.students);
m = numel(s.items);
if n == 0
    uialert(fig, 'No student folders found.', 'Nothing to export');
    return;
end
[fn, fp] = uiputfile({'*.csv','Comma-separated values'}, 'Save cohort CSV', ...
    fullfile(s.parentDir, 'cohort_grades.csv'));
if isequal(fn, 0), return; end
csvPath = fullfile(fp, fn);

fid = fopen(csvPath, 'w');
if fid == -1
    uialert(fig, ['Cannot write ' csvPath], 'Export failed');
    return;
end
c = onCleanup(@() fclose(fid));

% header
hdr = {'student'};
for j = 1:m, hdr{end+1} = s.items(j).Item_name; end %#ok<AGROW>
hdr{end+1} = 'total_earned';
hdr{end+1} = 'total_possible';
hdr{end+1} = 'percent';
fprintf(fid, '%s\n', strjoin(cellfun(@csvEscape, hdr, 'UniformOutput',false), ','));

totalPossible = sum(s.possible);
for i = 1:n
    row = cell(1, m + 4);
    row{1} = csvEscape(s.students{i});
    totalEarned = 0;
    for j = 1:m
        v = s.matrix(i, j);
        if isnan(v)
            row{j+1} = '';
        else
            row{j+1} = num2str(v);
            totalEarned = totalEarned + v;
        end
    end
    row{m+2} = num2str(totalEarned);
    row{m+3} = num2str(totalPossible);
    if totalPossible > 0
        row{m+4} = sprintf('%.1f', 100*totalEarned/totalPossible);
    else
        row{m+4} = '';
    end
    fprintf(fid, '%s\n', strjoin(row, ','));
end
uialert(fig, ['Wrote ' csvPath], 'CSV exported', 'Icon','success');
end

function s = csvEscape(x)
s = char(x);
if any(s == ',' | s == '"' | s == char(10) | s == char(13))
    s = ['"' strrep(s,'"','""') '"'];
end
end

function cleanupObj = withStudentOnPath(parentDir, studentDir)
% Put only STUDENTDIR on the MATLAB path for the duration of the
% returned onCleanup handle. Any other student folders under
% PARENTDIR are removed first so the wrong student's helpers
% cannot shadow the right one's. Path is restored when the cleanup
% object is destroyed (returns, errors, or clear).
ws = warning('state');
warning('off','MATLAB:rmpath:DirNotFound');
rmpath(genpath(parentDir));         % scrub any stale student folders
warning(ws);
addpath(genpath(studentDir));
cleanupObj = onCleanup(@() removePathQuietly(studentDir));
end

function removePathQuietly(studentDir)
ws = warning('state');
warning('off','MATLAB:rmpath:DirNotFound');
try, rmpath(genpath(studentDir)); end
warning(ws);
end


% ==================================================================
% ------- helpers -------
function name = shortName(name, n)
name = char(name);
if numel(name) > n
    name = [name(1:n-1) '…'];
end
end

% (itemKind moved to shared vhgradeitemkind.m)

function g = readGradeFile(studentDir, item)
g = [];
f = fullfile(studentDir, 'GRADING', item.Item_filename);
if isfile(f)
    try
        L = load(f, '-mat', 'grade');
        if isfield(L, 'grade'), g = L.grade; end
    catch
    end
end
end

function s = commentSummary(g)
c = g.Comment_1;
if iscell(c)
    s = strjoin(cellfun(@char, c(:), 'UniformOutput', false), char(10));
else
    s = char(c);
end
if isempty(s), s = '(no comment)'; end
end
