function cellstr = latte_summarize(varargin)
% vlt.grade.latte_summarize - summarize grades obtained by grading Latte files
% 
% CELLSTR = vlt.grade.latte_summarize(Q1, Q2, ...)
%
% Given structures that are outputs of vlt.grade.latte, produces a summary.
% 
% Returns a cell array of strings in CELLSTR.

cellstr = {};

if numel(varargin)<0, return; end;

q1 = varargin{1};

for i=1:numel(q1),

	notes_here = {};
	name_here = q1(i).name;
	value = 0;
	
	for j=1:numel(varargin),
		fn = setdiff(fieldnames(varargin{j}),{'name','note'});

		index_here = find(strcmp(name_here, {varargin{j}.name}));
		if isempty(index_here),
			error(['Cannot find name ' name_here ' in question ' int2str(j) '.']);
		end;

		value_here = getfield(varargin{j}(index_here), fn{1});
		value = value + value_here;
		notes_here{end+1} = [fn{1} ' ' num2str(value_here) ', note:' getfield(varargin{j}(index_here),'note')];
	end;

	cellstr{end+1} = [name_here ' : ' num2str(value) ];
	for j=1:numel(notes_here),
		cellstr{end+1} = notes_here{j};
	end;
	cellstr{end+1} = '';
end;

