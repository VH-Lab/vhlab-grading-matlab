function labels = vhgraderubriclabels(entries)
% VHGRADERUBRICLABELS - build display labels for a set of rubric entries
%
% LABELS = VHGRADERUBRICLABELS(ENTRIES)
%
% Returns a cell array of strings, one per entry in the struct array ENTRIES,
% formatted for display in the grading GUI's rubric list. Each label is of
% the form '[+N] description' or '[-N] description' depending on the sign of
% the entry's 'points' field.
%
% See also: VHGRADERESPONSEGUI, VHGRADERUBRICLOAD

labels = {};

for i=1:numel(entries),
	p = entries(i).points;
	if p>=0,
		ps = ['+' num2str(p)];
	else,
		ps = num2str(p);
	end;
	labels{end+1} = ['[' ps '] ' entries(i).description];
end;

if isempty(labels),
	labels = {' '};
end;
