function fig = vhgraderesponsegui(varargin)
% VHGRADERESPONSEGUI - 

command = 'new';    % internal variable, the command
fig = '';                 % the figure
success = 0;
windowheight = 600;
windowwidth = 650;
windowrowheight = 35;

grade = [];
dirname = [];
inputgrade = [];
response_string = '';
rubric = [];

 % user-specified variables
windowlabel = 'Grading';

varlist = {'dirname','grade','inputgrade', 'response_string', 'rubric', 'windowheight','windowwidth','windowrowheight','windowlabel'};

assign(varargin{:});

 % make room for the rubric column if a rubric was provided
if ~isempty(rubric),
	if isfield(rubric,'entries') & ~isempty(rubric.entries),
		windowwidth = 1020;
	end;
end;

if isempty(fig),
        z = findobj(allchild(0),'flat','tag','vhintan_spikesorting');
        if isempty(z),
                fig = figure('name',windowlabel, 'NumberTitle','off'); % we need to make a new figure
        else,
		fig = z;
		figure(fig);
		return; % just pop up the existing window
        end;
end;


 % initialize userdata field
if strcmp(command,'new'),
	for i=1:length(varlist),
		eval(['ud.' varlist{i} '=' varlist{i} ';']);
	end;
else,
	ud = get(fig,'userdata');
end;

%command,

switch command,
	case 'new',
		set(fig,'userdata',ud);
		vhgraderesponsegui('command','NewWindow','fig',fig);
	case 'NewWindow',
		% control object defaults

		% this callback was a nasty puzzle in quotations:
		callbackstr = [  'eval([get(gcbf,''Tag'') ''(''''command'''','''''' get(gcbo,''Tag'') '''''' ,''''fig'''',gcbf);'']);'];

		button.Units = 'pixels';
		button.BackgroundColor = get(fig,'color');
		button.HorizontalAlignment = 'center';
		button.Callback = callbackstr;
		txt.Units = 'pixels';
		txt.BackgroundColor = get(fig,'color');
		txt.fontsize = 12;
		txt.fontweight = 'normal';
		txt.HorizontalAlignment = 'left';
		txt.Style='text';
		edit = txt;
		edit.BackgroundColor = [ 1 1 1];
		edit.Style = 'Edit';
		popup = txt;
		popup.style = 'popupmenu';
		popup.Callback = callbackstr;
		list = txt;
		list.style = 'list';
		list.Callback = callbackstr;
		cb = txt;
		cb.Style = 'Checkbox';
		cb.Callback = callbackstr;
		cb.fontsize = 12;

		right = ud.windowwidth;
		row = ud.windowrowheight;
		top = ud.windowheight - row;

		itemstring = ['Item: ' ud.grade.Item_name ];

		set(fig,'position',[50 50 ud.windowwidth ud.windowheight ],'tag','vhgraderesponsegui');
                uicontrol(txt,'position',[5 top-row*1 600 30],'string',itemstring,'horizontalalignment','left','fontweight','bold','tag','itemTxt');
		uicontrol(txt,'position',[5 top-row*2 600 row*3],'string',ud.grade.Description,'horizontalalignment','left','tag','descriptionTxt');
		uicontrol(list,'position',[5 top-row*5 600 row*4],'string',ud.response_string,'horizontalalignment','left','tag','responseList');
		uicontrol(edit,'position',[5 top-row*9 600 row*3],'string',ud.inputgrade.Comment_1_default,...
			'horizontalalignment','left','tag','comment1Edit');
		uicontrol(edit,'position',[5 top-row*12 600 row*3],'string',ud.inputgrade.Comment_2_default, ...
			'horizontalalignment','left','tag','comment2Edit');

		uicontrol(txt,'position',[5 top-row*15 100 30], 'string', 'Points:','horizontalalignment','left');
		uicontrol(edit,'position',[105 top-row*15 40 30], 'string', '0', 'tag', 'pointsEarnedEdit');
		uicontrol(txt,'position',[105+40+5 top-row*15 30 30], 'string', 'of');
		uicontrol(txt,'position',[105+40+5+30+5 top-row*15 40 30], 'string', num2str(ud.grade.Points_possible), 'tag', 'pointsPossibleTxt');

		uicontrol(button, 'position',[300 top-row*16 100 30],'string','OK','tag','OKBt');
		uicontrol(button, 'position',[400+10 top-row*16 100 30],'string','Cancel','tag','CancelBt');
		uicontrol(button, 'position',[500+20 top-row*16 100 30],'string','Full Credit','tag','FullCreditBt');
		uicontrol(button, 'position',[300-10-100 top-row*16 100 30],'string','Missing','tag','MissingBt');

		 % rubric column (only drawn if a rubric was provided)
		if isfield(ud,'rubric') & ~isempty(ud.rubric),
			if isfield(ud.rubric,'entries') & ~isempty(ud.rubric.entries),
				rx = 660; rw = 340;
				if strcmpi(ud.rubric.mode,'single'),
					rubrichdr = 'Rubric (select ONE level):';
					maxval = 1;
				else,
					rubrichdr = 'Rubric (select all that apply):';
					maxval = numel(ud.rubric.entries)+1;
				end;
				uicontrol(txt,'position',[rx top-row*1 rw 30],'string',rubrichdr,...
					'horizontalalignment','left','fontweight','bold','tag','rubricTxt');
				uicontrol(list,'position',[rx top-row*12 rw row*11],...
					'string',vhgraderubriclabels(ud.rubric.entries),...
					'Max',maxval,'Min',0,'value',[],'tag','rubricList');
				uicontrol(button,'position',[rx top-row*13 170 30],...
					'string','+ Add rubric item','tag','AddRubricBt');

				 % initialize the points field from the rubric base
				initpts = 0;
				if strcmpi(ud.rubric.mode,'additive'),
					initpts = ud.rubric.base_points;
				end;
				if initpts<0, initpts = 0; end;
				if initpts>ud.grade.Points_possible, initpts = ud.grade.Points_possible; end;
				set(findobj(fig,'tag','pointsEarnedEdit'),'string',num2str(initpts));
			end;
		end;

	case 'rubricList',
		sel = get(findobj(fig,'tag','rubricList'),'value');
		entries = ud.rubric.entries;
		if strcmpi(ud.rubric.mode,'single'),
			pts = 0;
			cmt = '';
			if ~isempty(sel),
				pts = entries(sel(1)).points;
				cmt = entries(sel(1)).comment;
			end;
		else, % additive
			pts = ud.rubric.base_points;
			cmts = {};
			for ii=1:numel(sel),
				pts = pts + entries(sel(ii)).points;
				if ~isempty(entries(sel(ii)).comment),
					cmts{end+1} = entries(sel(ii)).comment;
				end;
			end;
			cmt = strjoin(cmts,' ');
		end;
		if pts<0, pts = 0; end;
		if pts>ud.grade.Points_possible, pts = ud.grade.Points_possible; end;
		set(findobj(fig,'tag','pointsEarnedEdit'),'string',num2str(pts));
		if ~isempty(cmt),
			set(findobj(fig,'tag','comment1Edit'),'string',cmt);
		end;

	case 'AddRubricBt',
		answ = inputdlg({'Description (shown to grader):', ...
			'Points (delta if additive; score if single-select):', ...
			'Comment (added to student feedback):'}, ...
			'Add rubric item', [1 60; 1 30; 4 60]);
		if isempty(answ),
			return;
		end;
		p = str2num(answ{2});
		if isempty(p),
			errordlg('Points must be a number.');
			return;
		end;
		cmt3 = answ{3};
		if size(cmt3,1)>1,
			cmt3 = strtrim(strjoin(cellstr(cmt3),' '));
		end;
		newentry = struct('description',answ{1},'points',p,'comment',cmt3);
		if isempty(ud.rubric.entries),
			ud.rubric.entries = newentry;
		else,
			ud.rubric.entries(end+1) = newentry;
		end;
		set(fig,'userdata',ud);
		try,
			vhgraderubricsave(ud.rubric.file, ud.rubric.entries);
		catch,
			warning(['Could not persist rubric: ' lasterr]);
		end;
		maxval = 1;
		if strcmpi(ud.rubric.mode,'additive'),
			maxval = numel(ud.rubric.entries)+1;
		end;
		set(findobj(fig,'tag','rubricList'),'string',vhgraderubriclabels(ud.rubric.entries),'Max',maxval);

	case 'OKBt',
		try,
			ud.grade.Comment_1 = get(findobj(fig,'tag','comment1Edit'),'string');
			ud.grade.Comment_2 = get(findobj(fig,'tag','comment2Edit'),'string');
			numstring = get(findobj(fig,'tag','pointsEarnedEdit'),'string');
			ud.grade.Points_earned = str2num(numstring);
			if ud.grade.Points_earned<0,
				errordlg(['Points no good.']);
			end;
		catch,
			errordlg(['Error: ' lasterr]);
			return; % make user do more
		end;

		% if we are here, we are ready to save
		grade_directory = [ud.dirname filesep 'GRADING'];
		filename = [grade_directory filesep ud.grade.Item_filename];
		grade = ud.grade;
		save(filename,'grade','-mat');

		close(fig);

	case 'MissingBt',
		try,
			ud.grade.Comment_1 = 'Missing/incomplete.'
			ud.grade.Comment_2 = get(findobj(fig,'tag','comment2Edit'),'string');
			numstring = get(findobj(fig,'tag','pointsEarnedEdit'),'string');
			ud.grade.Points_earned = str2num(numstring);
			if ud.grade.Points_earned<0,
				errordlg(['Points no good.']);
			end;
		catch,
			errordlg(['Error: ' lasterr]);
			return; % make user do more
		end;

		% if we are here, we are ready to save
		grade_directory = [ud.dirname filesep 'GRADING'];
		filename = [grade_directory filesep ud.grade.Item_filename];
		grade = ud.grade;
		save(filename,'grade','-mat');

		close(fig);

	case 'FullCreditBt',
		try,
			ud.grade.Comment_1 = get(findobj(fig,'tag','comment1Edit'),'string');
			ud.grade.Comment_2 = get(findobj(fig,'tag','comment2Edit'),'string');
			ud.grade.Points_earned = ud.grade.Points_possible;
		catch,
			errordlg(['Error: ' lasterr]);
			return; % make user do more
		end;

		% if we are here, we are ready to save
		grade_directory = [ud.dirname filesep 'GRADING'];
		filename = [grade_directory filesep ud.grade.Item_filename];
		grade = ud.grade;
		save(filename,'grade','-mat');

		close(fig);

	case 'CancelBt',
		close(fig); % do not save anything
		return;
	otherwise,
		disp(['do not know how to process command ' command '.']);
end;
