function out = vhgraderesponsegui(varargin)
% VHGRADERESPONSEGUI - 

command = 'new';    % internal variable, the command
fig = '';                 % the figure
success = 0;
windowheight = 380;
windowwidth = 450;
windowrowheight = 35;

grade = [];
dirname = [];

 % user-specified variables
windowlabel = 'Grading';

varlist = {'dirname','grade','inputgrade', 'windowheight','windowwidth','windowrowheight','windowlabel'};

assign(varargin{:});

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
if strcmp(command,'Main'),
	for i=1:length(varlist),
		eval(['ud.' varlist{i} '=' varlist{i} ';']);
	end;
else,
	ud = get(fig,'userdata');
end;

%command,

switch command,
	case 'Main',
		set(fig,'userdata',ud);
		vhgraderesponsegui('command','NewWindow','fig',fig);
	case 'NewWindow',
		% control object defaults

		% this callback was a nasty puzzle in quotations:
		callbackstr = [  'eval([get(gcbf,''Tag'') ''(''''command'''','''''' get(gcbo,''Tag'') '''''' ,''''fig'''',gcbf);'']);'];

		button.Units = 'pixels';
		button.BackgroundColor = [0.8 0.8 0.8];
		button.HorizontalAlignment = 'center';
		button.Callback = callbackstr;
		txt.Units = 'pixels';
		txt.BackgroundColor = [0.8 0.8 0.8];
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
		top = ud.windowheight;
		row = ud.windowrowheight;

		itemstring = ['Item: ' ud.grade.Item_name ];

		set(fig,'position',[50 50 right top],'tag','vhgraderesponsegui');
                uicontrol(txt,'position',[5 top-row*1 600 30],'string',itemstring,'horizontalalignment','left','fontweight','bold','tag','itemTxt');
		uicontrol(txt,'position',[5 top-row*2 600 row*3],'string',ud.grade.Description,'horizontalalignment,'left','tag','descriptionTxt');
		uicontrol(list,'position',[5 top-row*5 600 row*4],'string',ud.response_string,'horizontalalignment,'left','tag','responseList');
		uicontrol(edit,'position',[5 top-row*9 600 row*3],'string',ud.inputgrade.Comment_1_default,...
			'horizontalalignment','left','tag','comment1Edit');
		uicontrol(edit,'position',[5 top-row*12 600 row*3],'string',ud.inputgrade.Comment_2_default, ...
			'horizontalalignment','left','tag','comment2Edit');

		uicontrol(txt,'position',[5 top-row*15 100 30], 'string', 'Points:','horizontalalignment','left');
		uicontrol(edit,'position',[105 top-row*15 40 30], 'string', '0', 'tag', 'pointsEdit');
		uicontrol(txt,'position',[105+40+5 top-row*15 30 30], 'string', 'of');
		uicontrol(txt,'position',[105+40+5+30+5 top-row*15 40 30], 'string', num2str(ud.grade.Points_possible), 'tag', 'pointsEdit');

		uicontrol(button, 'position',[300 top-row*16 100 30],'string','OK','tag','OKBt');
		uicontrol(button, 'position',[400+10 top-row*16 100 30],'string','Cancel','tag','CancelBt');

	case 'OKBt',
		try,
			ud.grade.Comment_1 = get(findobj(fig,'tag','Comment1Edit'),'string');
			ud.grade.Comment_2 = get(findobj(fig,'tag','Comment2Edit'),'string');
			numstring = get(findobj(fig,'tag','pointsEdit');
			ud.grade.Points_earned = num2str(numstring);
			if ud.grade.Points_earned<0,
				errordlg(['Points no good.']);
			end;
		catch,
			return; % make user do more
		end;

		% if we are here, we are ready to save
		grade_directory = [ud.dirname filesep 'GRADING'];
		filename = [grade_directory filesep ud.grade.Item_filename];
		grade = ud.grade;
		save(filename,'grade','-mat');

	case 'CancelBt',
		close(fig); % do not save anything
		return;
	otherwise,
		error(['do not know how to process command ' command '.']);
end;

