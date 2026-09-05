function fig = vhgraderubriceditor(jsonfile)
% VHGRADERUBRICEDITOR - view and edit a grading rubric JSON file
%
% FIG = VHGRADERUBRICEDITOR()          - open an empty editor
% FIG = VHGRADERUBRICEDITOR(JSONFILE)  - open the editor on JSONFILE
%
% Provides a uifigure UI for browsing and editing the JSON rubric files
% consumed by VHGRADELOADRUBRIC.
%
% Layout:
%   Left column   : items list, meta fields (assignment name, url, points
%                   model), and the assignment-wide shared comment bank.
%   Middle column : editor for the currently-selected item — name,
%                   subfolder, filename, points possible, description,
%                   skills, code, code files, autograder spec, per-item
%                   rubric criteria, per-item comment bank.
%   Toolbar       : Open / Save / Save As / New item / Delete item.
%
% Changes are held in memory; File > Save writes back to the JSON file
% via VHGRADESAVERUBRIC.
%
% See also: VHGRADELOADRUBRIC, VHGRADESAVERUBRIC

if nargin < 1, jsonfile = ''; end

fig = uifigure('Name', 'vhlab Grading Rubric Editor', ...
    'Position', [50 50 1500 850]);

state = struct();
state.jsonfile = '';
state.meta     = defaultMeta();
state.items    = emptyItemArray();
state.selIdx   = 0;
state.dirty    = false;

fig.UserData = state;
buildUI(fig);
if ~isempty(jsonfile)
    loadFile(fig, jsonfile);
end


% ==================================================================
function buildUI(fig)

top = uigridlayout(fig, [2 3]);
top.RowHeight   = {40, '1x'};
top.ColumnWidth = {'1x', '1.6x', '1x'};
top.Padding     = [8 8 8 8];
top.RowSpacing  = 6;
top.ColumnSpacing = 8;

% ------ toolbar ------
tb = uigridlayout(top, [1 7]);
tb.Layout.Row = 1; tb.Layout.Column = [1 3];
tb.ColumnWidth = {80, 80, 90, 90, 90, '1x', '2x'};
tb.Padding = [0 0 0 0]; tb.ColumnSpacing = 6;
openBt   = uibutton(tb, 'Text', 'Open…',       'ButtonPushedFcn', @(~,~) onOpen(fig));
saveBt   = uibutton(tb, 'Text', 'Save',        'ButtonPushedFcn', @(~,~) onSave(fig));
saveAsBt = uibutton(tb, 'Text', 'Save as…',    'ButtonPushedFcn', @(~,~) onSaveAs(fig));
newBt    = uibutton(tb, 'Text', 'New item',    'ButtonPushedFcn', @(~,~) onNewItem(fig));
delBt    = uibutton(tb, 'Text', 'Delete item', 'ButtonPushedFcn', @(~,~) onDeleteItem(fig));
uilabel(tb, 'Text', 'File:');
pathLbl  = uilabel(tb, 'Text', '(no file loaded)', 'FontAngle','italic');

% ------ left column ------
leftGrid = uigridlayout(top, [3 1]);
leftGrid.Layout.Row = 2; leftGrid.Layout.Column = 1;
leftGrid.RowHeight = {'1x', 170, '1x'};
leftGrid.Padding = [0 0 0 0]; leftGrid.RowSpacing = 6;

itemsPanel = uipanel(leftGrid, 'Title', 'Items');
itemsGrid = uigridlayout(itemsPanel, [1 1]); itemsGrid.Padding = [4 4 4 4];
itemsList = uilistbox(itemsGrid, 'Items', {}, ...
    'ValueChangedFcn', @(src,~) onItemSelected(fig, src));

metaPanel = uipanel(leftGrid, 'Title', 'Assignment metadata');
mGrid = uigridlayout(metaPanel, [5 2]);
mGrid.RowHeight = {'fit','fit','fit','fit','fit'};
mGrid.ColumnWidth = {'fit','1x'};
mGrid.Padding = [4 4 4 4]; mGrid.RowSpacing = 3;
uilabel(mGrid, 'Text','Name:');
metaNameEd = uieditfield(mGrid, 'text', 'ValueChangedFcn', @(s,~) setMeta(fig,'assignment_name',s.Value));
uilabel(mGrid, 'Text','URL:');
metaUrlEd  = uieditfield(mGrid, 'text', 'ValueChangedFcn', @(s,~) setMeta(fig,'assignment_url',s.Value));
uilabel(mGrid, 'Text','Points model:');
metaModelDd = uidropdown(mGrid, 'Items', {'rubric_additive','deductive'}, ...
    'ValueChangedFcn', @(s,~) setMeta(fig,'points_model',s.Value));

sharedPanel = uipanel(leftGrid, 'Title', 'Shared comment bank');
sGrid = uigridlayout(sharedPanel, [2 1]); sGrid.RowHeight = {'1x','fit'};
sGrid.Padding = [4 4 4 4];
sharedT = uitable(sGrid, ...
    'ColumnName', {'Label','Text','Δ pts'}, ...
    'ColumnEditable', [true true true], ...
    'ColumnWidth', {110, 'auto', 60}, ...
    'Data', cell(0,3), ...
    'CellEditCallback', @(s,e) onSharedEdit(fig, s, e));
sBt = uigridlayout(sGrid, [1 2]); sBt.Padding = [0 0 0 0];
uibutton(sBt, 'Text','+ Row', 'ButtonPushedFcn', @(~,~) addBankRow(fig, sharedT, true));
uibutton(sBt, 'Text','− Row', 'ButtonPushedFcn', @(~,~) removeBankRow(fig, sharedT, true));

% ------ middle column: item editor ------
midPanel = uipanel(top, 'Title', 'Item editor');
midPanel.Layout.Row = 2; midPanel.Layout.Column = 2;
mid = uigridlayout(midPanel, [9 4]);
mid.RowHeight = {'fit','fit','fit','fit', 90, 'fit', 'fit', '1x', '1x'};
mid.ColumnWidth = {'fit', '1x', 'fit', '1x'};
mid.Padding = [8 8 8 8]; mid.RowSpacing = 4; mid.ColumnSpacing = 6;

uilabel(mid, 'Text','Item name:');
itemNameEd = uieditfield(mid,'text','ValueChangedFcn',@(s,~) setItemField(fig,'Item_name',s.Value));
itemNameEd.Layout.Column = [2 4];
uilabel(mid, 'Text','Subfolder:');
subfolderEd = uieditfield(mid,'text','ValueChangedFcn',@(s,~) setItemField(fig,'Subfolder',s.Value));
uilabel(mid, 'Text','Filename:');
filenameEd  = uieditfield(mid,'text','ValueChangedFcn',@(s,~) setItemField(fig,'Item_filename',s.Value));
uilabel(mid, 'Text','Points:');
pointsEd    = uieditfield(mid,'numeric','ValueChangedFcn',@(s,~) setItemField(fig,'Points_possible',s.Value));
uilabel(mid, 'Text','Skills (comma):');
skillsEd    = uieditfield(mid,'text','ValueChangedFcn',@(s,~) setItemField(fig,'Skills',splitComma(s.Value)));
uilabel(mid, 'Text','Description:');
descTA      = uitextarea(mid, 'ValueChangedFcn', @(s,~) setItemField(fig,'Description',joinLines(s.Value)));
descTA.Layout.Column = [2 4];
uilabel(mid, 'Text','Code:');
codeTA      = uitextarea(mid, 'ValueChangedFcn', @(s,~) setItemField(fig,'Code',joinLines(s.Value)));
codeTA.Layout.Column = [2 4];
uilabel(mid, 'Text','Code files (comma):');
codeFilesEd = uieditfield(mid,'text','ValueChangedFcn',@(s,~) setItemField(fig,'CodeFiles',splitComma(s.Value)));
codeFilesEd.Layout.Column = [2 4];

% autograder panel
agPanel = uipanel(mid, 'Title', 'Autograder');
agPanel.Layout.Row = 8; agPanel.Layout.Column = [1 4];
agGrid = uigridlayout(agPanel, [3 4]);
agGrid.RowHeight = {'fit','fit','1x'};
agGrid.ColumnWidth = {'fit','fit','fit','1x'};
agGrid.Padding = [4 4 4 4];
uilabel(agGrid, 'Text','Type:');
agTypeDd = uidropdown(agGrid, 'Items', {'manual','response_name','vartest','anyvartest'}, ...
    'ValueChangedFcn', @(s,~) onAutoTypeChanged(fig, s.Value));
uilabel(agGrid, 'Text','response_name:');
agRespEd = uieditfield(agGrid, 'text', ...
    'ValueChangedFcn', @(s,~) setAutoResponseName(fig, s.Value));
agRespEd.Layout.Column = [4 4];
agChecksT = uitable(agGrid, ...
    'ColumnName', {'Criterion','Var name','Value','Tolerance','Points'}, ...
    'ColumnEditable', [true true true true true], ...
    'ColumnWidth', {110, 110, 90, 80, 60}, ...
    'Data', cell(0,5), ...
    'CellEditCallback', @(s,e) onChecksEdit(fig, s, e));
agChecksT.Layout.Row = 3; agChecksT.Layout.Column = [1 4];
agChecksBtnGrid = uigridlayout(agGrid, [1 2]);
agChecksBtnGrid.Padding = [0 0 0 0];
% (buttons for add/remove check rows go on rubric side to save space)

% rubric + comment bank side-by-side
rubricPanel = uipanel(mid, 'Title', 'Rubric criteria');
rubricPanel.Layout.Row = 9; rubricPanel.Layout.Column = [1 2];
rgrid = uigridlayout(rubricPanel, [2 1]); rgrid.RowHeight = {'1x','fit'};
rgrid.Padding = [4 4 4 4];
rubricT = uitable(rgrid, ...
    'ColumnName', {'Criterion','Points'}, ...
    'ColumnEditable', [true true], ...
    'ColumnWidth', {'auto', 60}, ...
    'Data', cell(0,2), ...
    'CellEditCallback', @(s,e) onRubricEdit(fig, s, e));
rbtn = uigridlayout(rgrid, [1 4]); rbtn.Padding = [0 0 0 0];
uibutton(rbtn, 'Text','+ Rubric', 'ButtonPushedFcn', @(~,~) addRubricRow(fig, rubricT));
uibutton(rbtn, 'Text','− Rubric', 'ButtonPushedFcn', @(~,~) removeRubricRow(fig, rubricT));
uibutton(rbtn, 'Text','+ Check',  'ButtonPushedFcn', @(~,~) addCheckRow(fig, agChecksT));
uibutton(rbtn, 'Text','− Check',  'ButtonPushedFcn', @(~,~) removeCheckRow(fig, agChecksT));

itemBankPanel = uipanel(mid, 'Title', 'Item comment bank');
itemBankPanel.Layout.Row = 9; itemBankPanel.Layout.Column = [3 4];
ibGrid = uigridlayout(itemBankPanel, [2 1]); ibGrid.RowHeight = {'1x','fit'};
ibGrid.Padding = [4 4 4 4];
itemBankT = uitable(ibGrid, ...
    'ColumnName', {'Label','Text','Δ pts'}, ...
    'ColumnEditable', [true true true], ...
    'ColumnWidth', {110, 'auto', 60}, ...
    'Data', cell(0,3), ...
    'CellEditCallback', @(s,e) onItemBankEdit(fig, s, e));
ibBtn = uigridlayout(ibGrid, [1 2]); ibBtn.Padding = [0 0 0 0];
uibutton(ibBtn, 'Text','+ Row', 'ButtonPushedFcn', @(~,~) addBankRow(fig, itemBankT, false));
uibutton(ibBtn, 'Text','− Row', 'ButtonPushedFcn', @(~,~) removeBankRow(fig, itemBankT, false));

% ------ right column: totals + validation ------
rPanel = uipanel(top, 'Title', 'Totals & validation');
rPanel.Layout.Row = 2; rPanel.Layout.Column = 3;
rGrid = uigridlayout(rPanel, [3 1]);
rGrid.RowHeight = {'fit', '1x', '1x'};
rGrid.Padding = [8 8 8 8]; rGrid.RowSpacing = 8;
totalsLbl = uilabel(rGrid, 'Text','', 'WordWrap','on');
validationTA = uitextarea(rGrid, 'Editable','off', 'Value',{''});
usageTA = uitextarea(rGrid, 'Editable','off', 'Value', helpText());

% stash handles for later refresh
h = struct( ...
    'pathLbl',pathLbl, 'itemsList',itemsList, ...
    'metaNameEd',metaNameEd, 'metaUrlEd',metaUrlEd, 'metaModelDd',metaModelDd, ...
    'sharedT',sharedT, ...
    'itemNameEd',itemNameEd, 'subfolderEd',subfolderEd, 'filenameEd',filenameEd, ...
    'pointsEd',pointsEd, 'skillsEd',skillsEd, 'descTA',descTA, 'codeTA',codeTA, ...
    'codeFilesEd',codeFilesEd, ...
    'agTypeDd',agTypeDd, 'agRespEd',agRespEd, 'agChecksT',agChecksT, ...
    'rubricT',rubricT, 'itemBankT',itemBankT, ...
    'totalsLbl',totalsLbl, 'validationTA',validationTA);
fig.UserData.h = h;
refreshAll(fig);


% ==================================================================
% ------- file actions -------
function onOpen(fig)
[fn,fp] = uigetfile({'*.json','JSON rubric files'}, 'Open rubric', pwd);
if isequal(fn,0), return; end
loadFile(fig, fullfile(fp,fn));

function onSave(fig)
s = fig.UserData;
if isempty(s.jsonfile)
    onSaveAs(fig);
    return;
end
vhgradesaverubric(s.jsonfile, s.items, s.meta);
s.dirty = false; fig.UserData = s;
refreshTitle(fig);

function onSaveAs(fig)
s = fig.UserData;
def = s.jsonfile; if isempty(def), def = 'rubric.json'; end
[fn,fp] = uiputfile({'*.json','JSON rubric files'}, 'Save rubric as', def);
if isequal(fn,0), return; end
s.jsonfile = fullfile(fp,fn);
vhgradesaverubric(s.jsonfile, s.items, s.meta);
s.dirty = false; fig.UserData = s;
refreshTitle(fig);

function loadFile(fig, jsonfile)
try
    [items, meta] = vhgradeloadrubric(jsonfile);
catch ME
    uialert(fig, ['Load failed: ' ME.message], 'Load error');
    return;
end
s = fig.UserData;
s.jsonfile = jsonfile;
s.items = items;
s.meta  = meta;
s.selIdx = 1 * (~isempty(items));
s.dirty = false;
fig.UserData = s;
refreshAll(fig);

function onNewItem(fig)
s = fig.UserData;
it = defaultItem(s.meta);
if isempty(s.items), s.items = it; else, s.items(end+1) = it; end
s.selIdx = numel(s.items);
s.dirty = true; fig.UserData = s;
refreshAll(fig);

function onDeleteItem(fig)
s = fig.UserData;
if s.selIdx < 1 || s.selIdx > numel(s.items), return; end
s.items(s.selIdx) = [];
s.selIdx = min(s.selIdx, numel(s.items));
s.dirty = true; fig.UserData = s;
refreshAll(fig);

% ------- selection / field wiring -------
function onItemSelected(fig, listBox)
s = fig.UserData;
sel = find(strcmp(listBox.Items, listBox.Value), 1);
if isempty(sel), sel = 0; end
s.selIdx = sel;
fig.UserData = s;
refreshItemForm(fig);

function setMeta(fig, field, val)
s = fig.UserData;
s.meta.(field) = val;
if strcmp(field,'shared_comment_bank')
    for i = 1:numel(s.items), s.items(i).Shared_comment_bank = val; end
end
s.dirty = true; fig.UserData = s;
refreshTitle(fig); refreshTotals(fig);

function setItemField(fig, field, val)
s = fig.UserData;
if s.selIdx < 1, return; end
s.items(s.selIdx).(field) = val;
s.dirty = true; fig.UserData = s;
if any(strcmp(field, {'Item_name','Points_possible'}))
    refreshItemsList(fig);
end
refreshTotals(fig);

function onAutoTypeChanged(fig, newType)
s = fig.UserData;
if s.selIdx < 1, return; end
switch newType
    case 'response_name'
        s.items(s.selIdx).Parameters = struct('type','response_name','response_name','');
    case {'vartest','anyvartest'}
        s.items(s.selIdx).Parameters = struct('type',newType, ...
            'varname','','value',0,'tolerance',0,'criterion','','points',0);
    otherwise
        s.items(s.selIdx).Parameters = struct('type','manual');
end
s.dirty = true; fig.UserData = s;
refreshItemForm(fig);

function setAutoResponseName(fig, val)
s = fig.UserData;
if s.selIdx < 1, return; end
if strcmpi(s.items(s.selIdx).Parameters(1).type,'response_name')
    s.items(s.selIdx).Parameters(1).response_name = val;
end
s.dirty = true; fig.UserData = s;
refreshTitle(fig);

function onChecksEdit(fig, tbl, ~)
s = fig.UserData;
if s.selIdx < 1, return; end
D = tbl.Data;
t = char(s.items(s.selIdx).Parameters(1).type);
P = struct('type',{},'varname',{},'value',{},'tolerance',{},'criterion',{},'points',{});
for i = 1:size(D,1)
    P(i).type      = t;
    P(i).criterion = char(D{i,1});
    P(i).varname   = char(D{i,2});
    P(i).value     = double(D{i,3});
    P(i).tolerance = double(D{i,4});
    P(i).points    = double(D{i,5});
end
if isempty(P), P = struct('type',t,'varname','','value',0,'tolerance',0,'criterion','','points',0); end
s.items(s.selIdx).Parameters = P;
s.dirty = true; fig.UserData = s;
refreshTotals(fig);

function onRubricEdit(fig, tbl, ~)
s = fig.UserData;
if s.selIdx < 1, return; end
D = tbl.Data;
R = struct('name',{},'points',{});
for i = 1:size(D,1)
    R(i).name = char(D{i,1});
    R(i).points = double(D{i,2});
end
s.items(s.selIdx).Rubric = R;
s.dirty = true; fig.UserData = s;
refreshTotals(fig);

function onItemBankEdit(fig, tbl, ~)
s = fig.UserData;
if s.selIdx < 1, return; end
D = tbl.Data;
B = struct('label',{},'text',{},'points_delta',{});
for i = 1:size(D,1)
    B(i).label = char(D{i,1});
    B(i).text  = char(D{i,2});
    B(i).points_delta = double(D{i,3});
end
s.items(s.selIdx).Comment_bank = B;
s.dirty = true; fig.UserData = s;

function onSharedEdit(fig, tbl, ~)
s = fig.UserData;
D = tbl.Data;
B = struct('label',{},'text',{},'points_delta',{});
for i = 1:size(D,1)
    B(i).label = char(D{i,1});
    B(i).text  = char(D{i,2});
    B(i).points_delta = double(D{i,3});
end
s.meta.shared_comment_bank = B;
for i = 1:numel(s.items), s.items(i).Shared_comment_bank = B; end
s.dirty = true; fig.UserData = s;

function addRubricRow(fig, tbl)
tbl.Data = [tbl.Data; {'New criterion', 0}];
onRubricEdit(fig, tbl, []);
function removeRubricRow(fig, tbl)
if isempty(tbl.Data), return; end
tbl.Data(end,:) = [];
onRubricEdit(fig, tbl, []);
function addCheckRow(fig, tbl)
tbl.Data = [tbl.Data; {'new check','',0,0,0}];
onChecksEdit(fig, tbl, []);
function removeCheckRow(fig, tbl)
if isempty(tbl.Data), return; end
tbl.Data(end,:) = [];
onChecksEdit(fig, tbl, []);
function addBankRow(fig, tbl, isShared)
tbl.Data = [tbl.Data; {'New label','', 0}];
if isShared, onSharedEdit(fig, tbl, []); else, onItemBankEdit(fig, tbl, []); end
function removeBankRow(fig, tbl, isShared)
if isempty(tbl.Data), return; end
tbl.Data(end,:) = [];
if isShared, onSharedEdit(fig, tbl, []); else, onItemBankEdit(fig, tbl, []); end

% ------- refreshers -------
function refreshAll(fig)
refreshTitle(fig);
s = fig.UserData; h = s.h;
h.metaNameEd.Value  = char(s.meta.assignment_name);
h.metaUrlEd.Value   = char(s.meta.assignment_url);
h.metaModelDd.Value = ternary(any(strcmp(h.metaModelDd.Items, s.meta.points_model)), ...
    char(s.meta.points_model), h.metaModelDd.Items{1});
h.sharedT.Data = commentBankToData(s.meta.shared_comment_bank);
refreshItemsList(fig);
refreshItemForm(fig);
refreshTotals(fig);

function refreshTitle(fig)
s = fig.UserData; h = s.h;
if isempty(s.jsonfile)
    h.pathLbl.Text = '(no file loaded)';
else
    marker = ''; if s.dirty, marker = ' *'; end
    h.pathLbl.Text = [s.jsonfile marker];
end

function refreshItemsList(fig)
s = fig.UserData; h = s.h;
names = arrayfun(@(k) sprintf('%d. %s (%g)', k, s.items(k).Item_name, ...
    s.items(k).Points_possible), 1:numel(s.items), 'UniformOutput', false);
h.itemsList.Items = names;
if s.selIdx >= 1 && s.selIdx <= numel(names)
    h.itemsList.Value = names{s.selIdx};
elseif ~isempty(names)
    h.itemsList.Value = names{1};
end

function refreshItemForm(fig)
s = fig.UserData; h = s.h;
if s.selIdx < 1 || s.selIdx > numel(s.items)
    h.itemNameEd.Value = '';   h.subfolderEd.Value = '';
    h.filenameEd.Value = '';   h.pointsEd.Value = 0;
    h.skillsEd.Value = '';     h.descTA.Value = {''};
    h.codeTA.Value = {''};     h.codeFilesEd.Value = '';
    h.agTypeDd.Value = 'manual';
    h.agRespEd.Value = '';     h.agChecksT.Data = cell(0,5);
    h.rubricT.Data = cell(0,2); h.itemBankT.Data = cell(0,3);
    return;
end
it = s.items(s.selIdx);
h.itemNameEd.Value  = char(it.Item_name);
h.subfolderEd.Value = char(it.Subfolder);
h.filenameEd.Value  = char(it.Item_filename);
h.pointsEd.Value    = double(it.Points_possible);
h.skillsEd.Value    = strjoin(it.Skills, ', ');
h.descTA.Value      = splitLines(it.Description);
h.codeTA.Value      = splitLines(it.Code);
h.codeFilesEd.Value = strjoin(it.CodeFiles, ', ');
autoType = 'manual';
if ~isempty(it.Parameters), autoType = char(it.Parameters(1).type); end
h.agTypeDd.Value = autoType;
if strcmp(autoType,'response_name')
    h.agRespEd.Value = char(getfielddef(it.Parameters(1),'response_name',''));
    h.agRespEd.Enable = 'on';
    h.agChecksT.Data = cell(0,5);
else
    h.agRespEd.Value = '';
    h.agRespEd.Enable = 'off';
    if any(strcmp(autoType, {'vartest','anyvartest'}))
        D = cell(numel(it.Parameters), 5);
        for i = 1:numel(it.Parameters)
            D{i,1} = char(getfielddef(it.Parameters(i),'criterion',''));
            D{i,2} = char(getfielddef(it.Parameters(i),'varname',''));
            D{i,3} = double(getfielddef(it.Parameters(i),'value',0));
            D{i,4} = double(getfielddef(it.Parameters(i),'tolerance',0));
            D{i,5} = double(getfielddef(it.Parameters(i),'points',0));
        end
        h.agChecksT.Data = D;
    else
        h.agChecksT.Data = cell(0,5);
    end
end
h.rubricT.Data   = rubricToData(it.Rubric);
h.itemBankT.Data = commentBankToData(it.Comment_bank);

function refreshTotals(fig)
s = fig.UserData; h = s.h;
lines = {};
grand = 0;
warns = {};
for i = 1:numel(s.items)
    it = s.items(i);
    rsum = 0;
    if ~isempty(it.Rubric)
        rsum = sum([it.Rubric.points]);
    end
    grand = grand + it.Points_possible;
    lines{end+1} = sprintf('%d. %s: possible=%g, rubric sum=%g', ...
        i, it.Item_name, it.Points_possible, rsum); %#ok<AGROW>
    if ~isempty(it.Rubric) && abs(rsum - it.Points_possible) > 1e-9
        warns{end+1} = sprintf('Item %d "%s": rubric sums to %g but points_possible=%g', ...
            i, it.Item_name, rsum, it.Points_possible); %#ok<AGROW>
    end
end
lines{end+1} = '';
lines{end+1} = sprintf('Total possible: %g', grand);
h.totalsLbl.Text = strjoin(lines, char(10));
if isempty(warns), warns = {'No warnings.'}; end
h.validationTA.Value = warns;


% ==================================================================
% helpers
function m = defaultMeta()
m.assignment_name = '';
m.assignment_url  = '';
m.points_model    = 'rubric_additive';
m.shared_comment_bank = struct('label',{},'text',{},'points_delta',{});

function it = defaultItem(meta)
it.Item_name        = 'New item';
it.Subfolder        = '';
it.Item_filename    = 'new_item.mat';
it.Points_possible  = 0;
it.Description      = '';
it.Skills           = {};
it.Code             = '';
it.CodeFiles        = {};
it.Comment_1_default = '';
it.Comment_2_default = '';
it.Parameters       = struct('type','manual');
it.Rubric           = struct('name',{},'points',{});
it.Comment_bank     = struct('label',{},'text',{},'points_delta',{});
it.Shared_comment_bank = meta.shared_comment_bank;

function A = emptyItemArray()
A = repmat(defaultItem(defaultMeta()), 0, 0);

function D = rubricToData(R)
D = cell(numel(R), 2);
for i = 1:numel(R)
    D{i,1} = char(R(i).name);
    D{i,2} = double(R(i).points);
end

function D = commentBankToData(B)
D = cell(numel(B), 3);
for i = 1:numel(B)
    D{i,1} = char(B(i).label);
    D{i,2} = char(B(i).text);
    D{i,3} = double(B(i).points_delta);
end

function v = getfielddef(s, f, d)
if isstruct(s) && isfield(s, f) && ~isempty(s.(f))
    v = s.(f);
else
    v = d;
end

function c = splitLines(x)
if isempty(x), c = {''}; return; end
if iscell(x), c = x(:); return; end
c = regexp(char(x), '\r?\n', 'split'); c = c(:);

function s = joinLines(x)
if isempty(x), s = ''; return; end
if iscell(x)
    s = strjoin(x, char(10));
else
    s = char(x);
end

function c = splitComma(x)
if isempty(x), c = {}; return; end
parts = strsplit(char(x), ',');
c = strtrim(parts); c = c(~cellfun(@isempty, c));

function v = ternary(cond, a, b)
if cond, v = a; else, v = b; end

function t = helpText()
t = { ...
'Usage:', ...
'  Open a JSON rubric with the Open… button.', ...
'  Pick an item on the left to edit its fields.', ...
'  Autograder types: manual, response_name, vartest, anyvartest.', ...
'    - response_name adds a response.md section regex.', ...
'    - vartest / anyvartest use the checks table (per-check points).', ...
'  Rubric: check-off criteria whose points sum to the item total.', ...
'  Item comment bank: canned comments (with point deltas) shown only', ...
'    for this item.', ...
'  Shared comment bank: canned comments available for every item.', ...
'  Save writes back to the JSON file via vhgradesaverubric.'};
