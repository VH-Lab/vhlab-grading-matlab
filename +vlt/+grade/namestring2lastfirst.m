function lastfirst = namestring2lastfirst(namestring)
% NAMESTRING2LASTFIRST - convert "John Smith" to "Smith, John"
%
% LASTFIRST = NAMESTRING2LASTFIRST(NAMESTRING)
%
% Converts a NAMESTRING like "John Smith" to a last, first string
% like "Smith, John"
%
% Example:
%   lastfirst = vlt.grade.namestring2lastfirst("John Smith")

sp = find(namestring==' ');

if isempty(sp),
	lastfirst = namestring; % can't do anything but don't error
	return;
end;

lastfirst = [namestring(sp(1)+1:end) ', ' namestring(1:sp(1)-1) ];

