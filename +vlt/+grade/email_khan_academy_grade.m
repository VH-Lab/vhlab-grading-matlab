function [outputs] = email_khan_academy_grade(g)


outputs = vlt.data.emptystruct('lastfirst','email','subject','message_body');

for i=2:numel(g),

	output_here.lastfirst = strip(g{i}{1},sprintf('\t'));
	output_here.email = strip(g{i}{2},sprintf('\t'));

	video_grade = g{i}{16};
	overall_khan = g{i}{17};
	feedback = strip(g{i}{15},sprintf('\t'));

	output_here.subject = ['Nbio140: Khan Academy assignment grade'];
	output_here.message_body = ...
		['Hello ' output_here.lastfirst ',' newline newline ...
		 'Your Khan Academy Video and Submitted Exam Questions have been graded.' newline newline ...
		'Your video grade is ' num2str(video_grade) '.' newline newline ...
		'Your overall Khan Academy assignment grade is ' num2str(overall_khan) '.' newline newline ...
		'Your instructor (Jason or Steve) writes: ' feedback newline newline ...
		'Best' newline 'Steve' newline]; 

	outputs(end+1) = output_here;

end;

