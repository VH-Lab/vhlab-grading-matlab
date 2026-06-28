function entries = vhgraderubricload(static_entries, rubricfile)
% VHGRADERUBRICLOAD - load and merge the rubric entries for a free-response item
%
% ENTRIES = VHGRADERUBRICLOAD(STATIC_ENTRIES, RUBRICFILE)
%
% Builds the list of rubric ENTRIES to present to the grader. STATIC_ENTRIES
% are the entries defined ahead of time in the grading script (the item's
% Parameters(1).entries). RUBRICFILE is the path returned by
% VHGRADERUBRICFILE, where any entries that were added on-the-fly during
% grading have been saved.
%
% The script's STATIC_ENTRIES are always authoritative for their own fields.
% Any entry persisted in RUBRICFILE whose 'description' does not already
% appear among the static entries is appended (these are the entries a grader
% created while grading earlier students).
%
% ENTRIES is a struct array with fields 'description', 'points', and 'comment'.
%
% See also: VHGRADERUBRICFILE, VHGRADERUBRICSAVE, VHGRADEQUESTION

entries = static_entries;

if isempty(entries),
	entries = emptystruct('description','points','comment');
end;

if isfile(rubricfile),
	s = load(rubricfile,'-mat');
	if isfield(s,'entries'),
		existing_desc = {};
		if ~isempty(entries),
			existing_desc = {entries.description};
		end;
		for i=1:numel(s.entries),
			if ~any(strcmp(s.entries(i).description, existing_desc)),
				entries(end+1) = struct('description', s.entries(i).description, ...
					'points', s.entries(i).points, ...
					'comment', s.entries(i).comment);
			end;
		end;
	end;
end;
