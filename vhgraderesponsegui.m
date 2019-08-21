function out = vhgraderesponsegui(varargin)
% VHGRADERESPONSEGUI - 

command = 'Main';    % internal variable, the command
fig = '';                 % the figure
success = 0;
windowheight = 380;
windowwidth = 450;
windowrowheight = 35;

 % user-specified variables
ds = [];               % dirstruct
windowlabel = 'Grading';

varlist = {'ds','windowheight','windowwidth','windowrowheight','windowlabel','spikesortingprefs','spikesortingprefs_help'};

assign(varargin{:});

if isempty(fig),
        z = findobj(allchild(0),'flat','tag','vhintan_spikesorting');
        if isempty(z),
                fig = figure('name','VHINTAN Spike Sorting','NumberTitle','off'); % we need to make a new figure
        else,
		fig = z;
		figure(fig);
		vhgraderesponsegui('fig',fig,'command','UpdateNameRefList');
		return; % just pop up the existing window after updating
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
		vhintan_spikesorting('command','NewWindow','fig',fig);
		vhintan_spikesorting('fig',fig,'command','UpdateNameRefList');
        case 'NewWindow',
                % control object defaults

                % this callback was a nasty puzzle in quotations:
                callbackstr = [  'eval([get(gcbf,''Tag'') ''(''''command'''','''''' get(gcbo,''Tag'') '''''' ,''''fig'''',gcbf);'']);'];

                button.Units = 'pixels';
                button.BackgroundColor = [0.8 0.8 0.8];
                button.HorizontalAlignment = 'center';
                button.Callback = callbackstr;
                txt.Units = 'pixels'; txt.BackgroundColor = [0.8 0.8 0.8];
                txt.fontsize = 12; txt.fontweight = 'normal';
                txt.HorizontalAlignment = 'left';txt.Style='text';
                edit = txt; edit.BackgroundColor = [ 1 1 1]; edit.Style = 'Edit';
                popup = txt; popup.style = 'popupmenu';
                popup.Callback = callbackstr;
                list = txt; list.style = 'list';
                list.Callback = callbackstr;
                cb = txt; cb.Style = 'Checkbox';
                cb.Callback = callbackstr;
                cb.fontsize = 12;

                right = ud.windowwidth;
                top = ud.windowheight;
                row = ud.windowrowheight;

        set(fig,'position',[50 50 right top],'tag','vhintan_spikesorting');
                uicontrol(txt,'position',[5 top-row*1 600 30],'string',ud.windowlabel,'horizontalalignment','left','fontweight','bold');

