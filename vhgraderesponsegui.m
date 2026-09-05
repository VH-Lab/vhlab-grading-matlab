function fig = vhgraderesponsegui(varargin)
% VHGRADERESPONSEGUI - grader window with additive rubric + comment bank
%
% FIG = VHGRADERESPONSEGUI('command','new', 'dirname',D, 'grade',G, ...
%           'response_string',R, 'inputgrade',I)
%
% Modernised UI (uifigure) with:
%   - The item name and description at the top.
%   - The student response (from response.md) below, if any.
%   - A rubric panel: one checkbox per criterion, labelled with its points.
%     Checking a criterion adds its points to the running total.
%   - A comment-bank panel: item-specific comments first, then the
%     assignment-shared comments. Each is a checkbox; selected labels are
%     assembled into Comment_1, and their points_delta values adjust the
%     running total.
%   - Two free-text comment boxes for anything the bank does not cover
%     (Comment_1 addendum + Comment_2).
%   - Points earned box (auto-computed, still editable by hand) next to
%     Points possible; buttons: Save, Cancel, Full Credit, Missing.
%
% Callers may omit the Rubric / Comment_bank fields on INPUTGRADE; the
% corresponding panels then render empty and the tool behaves like the
% classic two-text-box grader.

command = 'new';
fig = '';

grade = [];
dirname = [];
inputgrade = [];
response_string = '';
windowlabel = 'Grading';

varlist = {'command','fig','dirname','grade','inputgrade','response_string','windowlabel'};
assign(varargin{:});

if isempty(fig)
    figName = windowlabel;
    try
        k = vhgradeitemkind(inputgrade);
        if ~isempty(grade) && isfield(grade,'Item_name')
            figName = sprintf('%s  [%s]  %s', windowlabel, k, grade.Item_name);
        end
    catch
    end
    fig = uifigure('Name', figName, 'Position', [50 50 1000 820]);
end

switch command
    case 'new'
        buildUI(fig, dirname, grade, inputgrade, response_string);
    otherwise
        % Old-style tag-dispatch callbacks aren't needed with uifigure;
        % handlers below are wired directly.
end


% ==================================================================
function buildUI(fig, dirname, grade, inputgrade, responseString)

if ~isstruct(inputgrade), inputgrade = struct(); end

rubric      = getfielddef(inputgrade, 'Rubric', []);
commentBank = getfielddef(inputgrade, 'Comment_bank', []);
sharedBank  = getfielddef(inputgrade, 'Shared_comment_bank', []);
c1def       = getfielddef(inputgrade, 'Comment_1_default', '');
c2def       = getfielddef(inputgrade, 'Comment_2_default', '');

pointsPossible = getfielddef(grade, 'Points_possible', 0);

% -------- top: title + description --------
gl = uigridlayout(fig, [5 2]);
gl.RowHeight   = {36, 80, '1x', 180, 56};
gl.ColumnWidth = {'1.4x', '1x'};
gl.Padding     = [10 10 10 10];
gl.RowSpacing  = 8;
gl.ColumnSpacing = 10;

titleTxt = ['Item: ' grade.Item_name];
try
    titleTxt = sprintf('[%s]   %s', vhgradeitemkind(inputgrade), titleTxt);
catch
end
titleLbl = uilabel(gl, 'Text', titleTxt, ...
    'FontSize', 16, 'FontWeight', 'bold');
titleLbl.Layout.Row = 1; titleLbl.Layout.Column = [1 2];

descLbl = uitextarea(gl, 'Value', splitLines(grade.Description), 'Editable','off');
descLbl.Layout.Row = 2; descLbl.Layout.Column = [1 2];

% -------- middle-left: response --------
leftPanel = uipanel(gl, 'Title', 'Response');
leftPanel.Layout.Row = 3; leftPanel.Layout.Column = 1;
leftGrid = uigridlayout(leftPanel, [1 1]); leftGrid.Padding = [6 6 6 6];
respTA = uitextarea(leftGrid, 'Value', splitLines(responseString), 'Editable','off');

% -------- middle-right: rubric + comment bank (tabs) --------
rightPanel = uipanel(gl, 'Title', 'Rubric & Comments');
rightPanel.Layout.Row = 3; rightPanel.Layout.Column = 2;
rGrid = uigridlayout(rightPanel, [2 1]); rGrid.Padding = [6 6 6 6];
rGrid.RowHeight = {'1x', '1x'};

% rubric panel — scrollable so a long rubric doesn't clip
rubricPanel = uipanel(rGrid, 'Title', 'Rubric (checkbox = award points)', ...
    'Scrollable','on');
nRubricRows = max(1, numel(rubric)+1);
rubricInner = uigridlayout(rubricPanel, [nRubricRows 1]);
rubricInner.Padding = [4 4 4 4];
rubricInner.RowSpacing = 2;
rubricInner.RowHeight = repmat({'fit'}, 1, nRubricRows);
rubricInner.Scrollable = 'on';
rubricChecks = gobjects(1, numel(rubric));
for i = 1:numel(rubric)
    label = sprintf('[%g pts] %s', rubric(i).points, rubric(i).name);
    rubricChecks(i) = uicheckbox(rubricInner, 'Text', label, 'Value', false);
end
if isempty(rubric)
    uilabel(rubricInner, 'Text', '(no rubric criteria)', 'FontAngle','italic');
end

% comment bank panel — scrollable so a long bank doesn't clip
commentPanel = uipanel(rGrid, ...
    'Title', 'Comment bank (checked comments are added)', ...
    'Scrollable','on');
nBankRows = max(1, numel(commentBank) + numel(sharedBank) + 2);
commentInner = uigridlayout(commentPanel, [nBankRows 1]);
commentInner.Padding = [4 4 4 4];
commentInner.RowSpacing = 2;
commentInner.RowHeight = repmat({'fit'}, 1, nBankRows);
commentInner.Scrollable = 'on';
allBank = struct('label',{},'text',{},'points_delta',{},'source',{});
for i = 1:numel(commentBank)
    allBank(end+1) = withSource(commentBank(i), 'item'); %#ok<AGROW>
end
if ~isempty(commentBank) && ~isempty(sharedBank)
    sep = uilabel(commentInner, 'Text', '— shared —', 'FontAngle','italic'); %#ok<NASGU>
end
for i = 1:numel(sharedBank)
    allBank(end+1) = withSource(sharedBank(i), 'shared'); %#ok<AGROW>
end
commentChecks = gobjects(1, numel(allBank));
for i = 1:numel(allBank)
    if allBank(i).points_delta == 0
        deltaTxt = '';
    else
        deltaTxt = sprintf(' [%+g]', allBank(i).points_delta);
    end
    label = sprintf('%s%s', allBank(i).label, deltaTxt);
    commentChecks(i) = uicheckbox(commentInner, 'Text', label, 'Value', false);
end
if isempty(allBank)
    uilabel(commentInner, 'Text', '(no comment bank)', 'FontAngle','italic');
end

% -------- row 4: free-text comments + points panel --------
bottomPanel = uipanel(gl);
bottomPanel.Layout.Row = 4; bottomPanel.Layout.Column = [1 2];
bGrid = uigridlayout(bottomPanel, [1 2]);
bGrid.ColumnWidth = {'2x','1x'};
bGrid.Padding = [6 6 6 6];
bGrid.ColumnSpacing = 8;

% two free-text comment areas + a canned-comment insert row
extraPanel = uipanel(bGrid, 'Title', 'Additional comments (free text)');
extraGrid = uigridlayout(extraPanel, [3 1]);
extraGrid.RowHeight = {'fit','1x','1x'};
extraGrid.Padding = [4 4 4 4];
extraGrid.RowSpacing = 4;

insertRow = uigridlayout(extraGrid, [1 3]);
insertRow.ColumnWidth = {130, '1x', 160};
insertRow.Padding = [0 0 0 0]; insertRow.ColumnSpacing = 4;
uilabel(insertRow, 'Text', 'Insert canned comment:');
if isempty(allBank)
    bankItems = {'(no canned comments)'};
else
    bankItems = arrayfun(@(k) sprintf('%s%s', allBank(k).label, ...
        ternaryStr(allBank(k).points_delta ~= 0, ...
            sprintf(' [%+g]', allBank(k).points_delta), '')), ...
        1:numel(allBank), 'UniformOutput', false);
end
insertDD = uidropdown(insertRow, 'Items', bankItems);
insertBt = uibutton(insertRow, 'Text', 'Insert → Comment 2', ...
    'Tooltip', 'Copy the selected canned comment''s full text into the Extra comment 2 box below so you can edit it before saving.');

c1TA = uitextarea(extraGrid, 'Value', splitLines(c1def), ...
    'Placeholder','Extra comment 1');
c2TA = uitextarea(extraGrid, 'Value', splitLines(c2def), ...
    'Placeholder','Extra comment 2 (good place for a customised message)');

insertBt.ButtonPushedFcn = @(~,~) insertCanned(insertDD, allBank, c2TA);

% points display
ptsPanel = uipanel(bGrid, 'Title', 'Points');
ptsGrid = uigridlayout(ptsPanel, [2 3]);
ptsGrid.RowHeight   = {'fit','fit'};
ptsGrid.ColumnWidth = {'fit',80,'fit'};
ptsGrid.Padding = [8 8 8 8];
ptsGrid.RowSpacing = 6; ptsGrid.ColumnSpacing = 6;
uilabel(ptsGrid, 'Text', 'Earned:');
earnedEdit = uieditfield(ptsGrid, 'numeric', 'Value', 0, ...
    'Limits',[-inf inf], 'AllowEmpty',false);
uilabel(ptsGrid, 'Text', sprintf('of %g', pointsPossible));
uilabel(ptsGrid, 'Text', 'Auto:');
autoLbl  = uilabel(ptsGrid, 'Text', '0', 'FontWeight','bold');
useAutoBt = uibutton(ptsGrid, 'Text', 'Use auto', ...
    'ButtonPushedFcn', @(~,~) set(earnedEdit,'Value', str2doubleSafe(autoLbl.Text)));

% -------- row 5: action buttons in a horizontal strip --------
btnPanel = uipanel(gl, 'Title', 'Actions');
btnPanel.Layout.Row = 5; btnPanel.Layout.Column = [1 2];
btnGrid = uigridlayout(btnPanel, [1 5]);
btnGrid.Padding = [8 6 8 6];
btnGrid.ColumnSpacing = 10;
saveBt = uibutton(btnGrid, 'Text', 'Save', 'BackgroundColor', [0.85 0.95 0.85], ...
    'FontWeight','bold', 'Tooltip','Save this grade and go to the next student.');
fullBt = uibutton(btnGrid, 'Text', 'Full credit', ...
    'Tooltip','Award full points, save, and go to the next student.');
missBt = uibutton(btnGrid, 'Text', 'Missing / 0', ...
    'Tooltip','Score 0 with a "Missing / incomplete" comment, save, and go to the next student.');
skipBt = uibutton(btnGrid, 'Text', 'Skip this student', ...
    'Tooltip','Close without saving anything for this student. Batch grading continues to the next student.');
cancBt = uibutton(btnGrid, 'Text', 'Cancel (stop batch)', ...
    'BackgroundColor', [1 0.90 0.85], ...
    'Tooltip','Close without saving AND stop the batch grading loop.');

% wire callbacks — capture handles in closure
recalc = @() recalcAuto(rubricChecks, commentChecks, allBank, autoLbl, earnedEdit);
for i = 1:numel(rubricChecks)
    rubricChecks(i).ValueChangedFcn = @(~,~) recalc();
end
for i = 1:numel(commentChecks)
    commentChecks(i).ValueChangedFcn = @(~,~) recalc();
end
recalc();

saveBt.ButtonPushedFcn = @(~,~) onSave(fig, dirname, grade, ...
    rubricChecks, rubric, commentChecks, allBank, c1TA, c2TA, earnedEdit);
fullBt.ButtonPushedFcn = @(~,~) onFullCredit(fig, dirname, grade, ...
    rubricChecks, rubric, commentChecks, allBank, c1TA, c2TA, earnedEdit);
missBt.ButtonPushedFcn = @(~,~) onMissing(fig, dirname, grade, ...
    rubricChecks, rubric, commentChecks, allBank, c1TA, c2TA, earnedEdit);
skipBt.ButtonPushedFcn = @(~,~) delete(fig);   % skip this student only
cancBt.ButtonPushedFcn = @(~,~) onCancelBatch(fig);

% Treat window-close (X) the same as Cancel — safer: stops the batch,
% so an accidental close cannot silently move on to the next student.
fig.CloseRequestFcn = @(~,~) onCancelBatch(fig);


% ==================================================================
function recalcAuto(rubricChecks, commentChecks, allBank, autoLbl, earnedEdit)
total = 0;
for i = 1:numel(rubricChecks)
    if rubricChecks(i).Value
        v = sscanf(rubricChecks(i).Text, '[%g pts]', 1);
        if ~isempty(v), total = total + v; end
    end
end
for i = 1:numel(commentChecks)
    if commentChecks(i).Value
        total = total + allBank(i).points_delta;
    end
end
autoLbl.Text = num2str(total);
earnedEdit.Value = total;

% ==================================================================
function onSave(fig, dirname, grade, rubricChecks, rubric, ...
                commentChecks, allBank, c1TA, c2TA, earnedEdit)
try
    [comment1, selected, awarded] = ...
        composeComments(rubricChecks, rubric, commentChecks, allBank, c1TA);
    comment2 = joinLines(c2TA.Value);
    if ~hasAnyComment(awarded, selected, comment1, comment2)
        uialert(fig, ...
            ['Please leave at least one comment before saving. ' ...
             'Check a rubric criterion, tick a canned comment, or ' ...
             'type something in the free-text boxes. ' ...
             '(If the student simply did not do this item, use the ' ...
             '"Missing / 0" button.)'], ...
            'Comment required', 'Icon','warning');
        return;
    end
    grade.Points_earned    = earnedEdit.Value;
    grade.Comment_1        = comment1;
    grade.Comments_selected = selected;
    grade.Rubric_awarded   = awarded;
    grade.Comment_2        = comment2;
catch ME
    uialert(fig, ['Error: ' ME.message], 'Save failed');
    return;
end
persistGrade(dirname, grade);
delete(fig);

function onFullCredit(fig, dirname, grade, rubricChecks, rubric, ...
                      commentChecks, allBank, c1TA, c2TA, earnedEdit) %#ok<INUSD>
[comment1, selected, awarded] = ...
    composeComments(rubricChecks, rubric, commentChecks, allBank, c1TA);
comment2 = joinLines(c2TA.Value);
if ~hasAnyComment(awarded, selected, comment1, comment2)
    uialert(fig, ...
        ['Please leave at least one comment before awarding full credit. ' ...
         'A rubric criterion, a canned comment, or free text is fine.'], ...
        'Comment required', 'Icon','warning');
    return;
end
grade.Points_earned    = grade.Points_possible;
grade.Comment_1        = comment1;
grade.Comments_selected = selected;
grade.Rubric_awarded   = awarded;
grade.Comment_2        = comment2;
persistGrade(dirname, grade);
delete(fig);

function tf = hasAnyComment(awarded, selected, comment1, comment2)
tf = any(awarded) ...
     || ~isempty(selected) ...
     || (iscell(comment1) && ~isempty(comment1) && ~all(cellfun(@isempty, comment1))) ...
     || (~isempty(comment2) && ~all(comment2 == ' '));

function onMissing(fig, dirname, grade, rubricChecks, rubric, ...
                   commentChecks, allBank, c1TA, c2TA, earnedEdit) %#ok<INUSD>
grade.Points_earned = 0;
grade.Comment_1 = 'Missing / incomplete.';
grade.Comments_selected = {};
grade.Rubric_awarded = false(1, numel(rubric));
grade.Comment_2 = joinLines(c2TA.Value);
persistGrade(dirname, grade);
delete(fig);


% ==================================================================
function [comment1, selectedLabels, awarded] = composeComments( ...
    rubricChecks, rubric, commentChecks, allBank, c1TA)
awarded = false(1, numel(rubric));
for i = 1:numel(rubricChecks)
    awarded(i) = logical(rubricChecks(i).Value);
end
lines = {};
selectedLabels = {};
for i = 1:numel(commentChecks)
    if commentChecks(i).Value
        selectedLabels{end+1} = allBank(i).label;   %#ok<AGROW>
        lines{end+1}          = allBank(i).text;    %#ok<AGROW>
    end
end
free = joinLines(c1TA.Value);
if ~isempty(free)
    lines{end+1} = free;
end
comment1 = lines;

function onCancelBatch(fig)
% Signal the caller (vhgradeoverview / vhgradeassignment) to stop the
% batch after this fig closes. Also treats the OS window-close (X) as
% a batch cancel so an accidental close cannot silently move on.
setappdata(groot, 'vhgrade_cancelBatch', true);
delete(fig);

function insertCanned(dd, allBank, c2TA)
% Append the selected bank comment's full text to the Comment-2 box so
% the grader can edit it before saving.
if isempty(allBank), return; end
% Match by label (dropdown items are "label [±N]"); strip the [±N] tail.
val = char(dd.Value);
label = regexprep(val, '\s\[[-+]?[\d\.]+\]$', '');
idx = find(strcmp({allBank.label}, label), 1);
if isempty(idx), return; end
txt = allBank(idx).text;
existing = joinLines(c2TA.Value);
if isempty(strtrim(existing))
    combined = txt;
else
    combined = [existing char(10) char(10) txt];
end
c2TA.Value = splitLines(combined);

function s = ternaryStr(cond, a, b)
if cond, s = a; else, s = b; end

function persistGrade(dirname, grade)
grade_directory = [dirname filesep 'GRADING'];
filename = [grade_directory filesep grade.Item_filename];
save(filename, 'grade', '-mat');

function v = getfielddef(s, f, d)
if isstruct(s) && isfield(s, f) && ~isempty(s.(f))
    v = s.(f);
else
    v = d;
end

function s = withSource(x, src)
s.label        = char(x.label);
s.text         = char(x.text);
s.points_delta = double(x.points_delta);
s.source       = src;

function c = splitLines(x)
% Normalise anything text-shaped into a Nx1 cellstr suitable for
% assigning to a uitextarea's Value: '' | char row | char matrix |
% cellstr | string array.
if isempty(x)
    c = {''}; return;
end
if iscell(x)
    c = cellfun(@char, x(:), 'UniformOutput', false);
    return;
end
if isstring(x)
    c = cellstr(x(:));
    return;
end
if ischar(x)
    if size(x, 1) > 1
        c = cellstr(x);      % each row → one cell
        return;
    end
    c = regexp(x, '\r?\n', 'split');
    c = c(:);
    return;
end
c = {char(string(x))};

function s = joinLines(x)
if isempty(x)
    s = ''; return;
end
if iscell(x)
    s = strjoin(x, char(10));
else
    s = char(x);
end
s = strtrim(s);

function v = str2doubleSafe(s)
v = str2double(s);
if isnan(v), v = 0; end
