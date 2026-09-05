function grade = vhgradequestion(vhgradedirname, inputitem, forceRegrade)
% VHGRADEQUESTION - grade a question
%
% GRADE = VHGRADEQUESTION(DIRNAME, INPUTITEM, FORCEREGRADE)
%
% Grade a question specified in the structure INPUTITEM (see VHGRADEASSIGNMENT
% for the classic fields, VHGRADELOADRUBRIC for the JSON-derived extension).
%
% Student code (INPUTITEM.Code) is executed by VHGRADESANDBOXRUN in an
% isolated function-scoped workspace, so it never touches the base workspace.
% Autograder checks read from that sandbox struct instead of the base.
%
% If INPUTITEM carries a .Rubric struct array (from a JSON rubric), its
% entries are passed to the manual-grading GUI so the grader can award
% points additively per rubric criterion. Likewise a .Comment_bank (and
% .Shared_comment_bank) drive the additive canned-comment checklist.

currpwd = pwd;

if nargin<3
    forceRegrade = 0;
end

grade_directory = [vhgradedirname filesep 'GRADING'];

filename = [grade_directory filesep inputitem.Item_filename];

warns = warning('state');
warning off;
try, mkdir(grade_directory); end
warning('state',warns);

if isfile(filename)
    if ~forceRegrade
        grade = load(filename);
        grade = grade.grade;
        return;
    end
end

% if we are here, we need to grade or re-grade

grade.Item_name       = inputitem.Item_name;
grade.Subfolder       = inputitem.Subfolder;
grade.Item_filename   = inputitem.Item_filename;
grade.Points_possible = inputitem.Points_possible;
grade.Description     = inputitem.Description;
grade.Skills          = inputitem.Skills;
grade.Comment_1       = '';
grade.Comment_2       = '';
grade.Points_earned   = 0;
grade.CodeError       = 0;
grade.Rubric_awarded  = [];         % logical vector (or empty), one per rubric criterion
grade.Comments_selected = {};       % cell of labels selected from the comment bank
grade.Autograder_score  = struct('checks_passed',[],'checks_points',[]);
grade.Autograded_only   = false;    % true when this grade was saved without the manual GUI

inputitem_alt = inputitem; % in case we edit the standard comments

% Step 1: run the code in a sandboxed workspace
sandboxWs = struct();
if isfield(inputitem,'Code') && ~isempty(inputitem.Code)
    [sandboxWs, sandboxErr] = vhgradesandboxrun(inputitem.Code, ...
        [vhgradedirname filesep grade.Subfolder]);
    if ~isempty(sandboxErr)
        grade.Comment_1 = ['Code ' inputitem.Code ' did not run successfully; error was ' sandboxErr.message];
        grade.CodeError = 2;
        inputitem_alt.Comment_1_default = char(strrep(grade.Comment_1, char(10), ';'));
    end
end

% Step 2: if 'response_name', load the response for the GUI
response_string = '';
if strcmpi(inputitem.Parameters(1).type,'response_name')
    if ~isempty(inputitem.Parameters(1).response_name)
        try
            response_string = vhgradeloadresponse([vhgradedirname filesep grade.Subfolder filesep 'response.md'], ...
                inputitem.Parameters(1).response_name);
        catch
            grade.Comment_1 = ['Response ' inputitem.Parameters(1).response_name ' not found in response.md'];
            grade.Autograded_only = true;
            save(filename,'grade','-mat');
            return;
        end
    end
end

% Step 3: autograder checks (vartest / anyvartest) against the sandbox workspace
autoType = lower(inputitem.Parameters(1).type);
if strcmp(autoType,'vartest') || strcmp(autoType,'anyvartest')
    n = numel(inputitem.Parameters);
    passed = false(1,n);
    pts    = zeros(1,n);
    fn = fieldnames(sandboxWs);

    for ci = 1:n
        p = inputitem.Parameters(ci);
        val = p.value;
        tol = p.tolerance;
        matched = false;

        if strcmp(autoType,'vartest')
            if isfield(sandboxWs, p.varname)
                compare = sandboxWs.(p.varname);
                matched = valuesMatch(compare, val, tol);
            end
        else % anyvartest
            for j = 1:numel(fn)
                if valuesMatch(sandboxWs.(fn{j}), val, tol)
                    matched = true;
                    break;
                end
            end
        end

        passed(ci) = matched;
        if isfield(p,'points') && ~isempty(p.points) && p.points > 0
            if matched, pts(ci) = p.points; end
        end
    end

    grade.Autograder_score.checks_passed = passed;
    grade.Autograder_score.checks_points = pts;

    haveWeights = any(arrayfun(@(x) isfield(x,'points') && ~isempty(x.points) && x.points>0, ...
        inputitem.Parameters));

    if all(passed)
        grade.Points_earned = inputitem.Points_possible;
        grade.Comment_1 = summarizeChecks(inputitem.Parameters, passed);
        grade.Autograded_only = true;
        save(filename,'grade','-mat');
        cd(currpwd);
        return;
    end

    if haveWeights
        % Award per-check partial credit up-front; still open the GUI so the
        % grader can adjust and add comments.
        grade.Points_earned = sum(pts);
    else
        if grade.CodeError == 0, grade.CodeError = 1; end
    end
    grade.Comment_1 = summarizeChecks(inputitem.Parameters, passed);
    inputitem_alt.Comment_1_default = grade.Comment_1;
end

% Step 4: ask for user input if needed
needsGui = strcmpi(inputitem.Parameters(1).type,'manual') ...
        || strcmpi(inputitem.Parameters(1).type,'response_name') ...
        || grade.CodeError ...
        || (isfield(inputitem,'Rubric') && ~isempty(inputitem.Rubric));

if needsGui
    mycodewindow = [];
    if 1 || grade.CodeError
        text_total = {};
        for i = 1:numel(inputitem.CodeFiles)
            t_ = text2cellstr(inputitem.CodeFiles{i});
            if eqlen(t_,{-1}), t_ = {''}; end
            text_total = cat(2, text_total, ...
                {['FILE: ' inputitem.CodeFiles{i} ' -----------------']}, t_);
        end
        if isempty(text_total), text_total = ' '; end
        mycodewindow = msgbox(text_total, 'Code window');
    end
    h = vhgraderesponsegui('command','new', 'dirname', vhgradedirname, ...
        'grade', grade, 'response_string', response_string, ...
        'inputgrade', inputitem_alt);
    try, figure(h); end   % pop the grader to the front
    uiwait(h);
    if ~isempty(mycodewindow)
        delete(mycodewindow);
    end
end

cd(currpwd);


% ----- helpers -----

function tf = valuesMatch(compare, value, tolerance)
tf = false;
if ~isnumeric(compare), return; end
if numel(compare) ~= numel(value), return; end
if any(abs(compare(:) - value(:)) > tolerance), return; end
tf = true;

function s = summarizeChecks(params, passed)
lines = cell(1, numel(params));
for i = 1:numel(params)
    if isfield(params(i),'criterion') && ~isempty(params(i).criterion)
        label = params(i).criterion;
    elseif isfield(params(i),'varname') && ~isempty(params(i).varname)
        label = params(i).varname;
    else
        label = sprintf('check %d', i);
    end
    if passed(i)
        lines{i} = sprintf('[OK]   %s matched.', label);
    else
        lines{i} = sprintf('[FAIL] %s did not match.', label);
    end
end
s = lines;
