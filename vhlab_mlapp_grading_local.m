
 % this should NOT be part of the github distribution

docid_grading = '1YxECTep3C_POu6rlhXK5JeKH1rSLA-Th2QiGO5UU17k';

docid_effort = '1TpK9hfgQ19wSQYgcWXRB6jJ0eqXaz6cxSC5Hyo_8NUM';

docid_exitsurvey = '1eSUj6SpbTMthk8s0oGQPCgZs63FPRuOITxD6InmKlz8';


students=GoogleSpreadsheet2students(docid_grading),

Biol107a_effort_data(docid_effort,'2017-01-01','2017-12-31',students);

exit_survey = GetGoogleSpreadsheet(docid_exitsurvey);

answers = spreadsheet_multiplechoice(exit_survey,'Do you feel like you'll be able to make your own plots and perform your own statistics for your future work?');


