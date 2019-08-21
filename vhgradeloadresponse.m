function str = vhgradeloadresponse(filename, response_name)
% VHGRADELOADRESPONSE - load a response from a text file
%
% STR = VHGRADELOADRESPONSE(FILENAME, RESPONSE_NAME)
%
% Loads a section of text that begins with a regular expression match for
% RESPONSE_NAME and keeps reading until the end of the file or if there 
% there is a subsequent regular expression match for '#(\s*)Q'.
% 
% 

t = text2cellstr(filename);

line_start = regexpi(t,response_name,'forceCellOutput');

good_start = [];

for i=1:numel(t),
	if ~isempty(line_start{i})
		good_start = i;
		break;
	end;
end;

line_qs = regexpi(t,'(\s*)#(\s*)Q','forceCellOutput');

linemarks = [];

for i=1:numel(t),
	if ~isempty(line_qs{i}),
		linemarks(end+1) = i;
	end;
end;

linemarks(end+1) = numel(line_qs);

good_stop = [];

if ~isempty(good_start),
	good_stop = linemarks(find(linemarks>good_start,1,'first'));
end;

if ~isempty(good_start) & ~isempty(good_stop),
	str = t(good_start:good_stop);
else,
	error(['Could not find matching section.']);
end;




