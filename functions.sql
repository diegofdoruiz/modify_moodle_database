-----------------------------------------------
----------    DECLARE FUNCTIONS   -------------
-----------------------------------------------
--update users table
CREATE OR REPLACE FUNCTION updateUsers() 
RETURNS void AS $BODY$
DECLARE
    usuario mdl_user%rowtype;
	counter integer;
	new_username text;
BEGIN
	counter := 0;
    FOR usuario IN
        SELECT *
		FROM mdl_user
		ORDER BY id ASC
		--LIMIT 10
    LOOP

    	new_username := 'user'||counter;
    	IF position('-' in usuario.username) > 0
    		THEN new_username := 'code'||counter||'-program'||counter; 
    	END IF;

		UPDATE mdl_user 
		SET 
			username = new_username,
			firstname = 'name'||counter,
			lastname = 'lastname'||counter,
			email = 'email'||counter||'@correounivalle.edu.co',
			password = '$2y$10$LwvOW/um9fFEIrOhVT/W8OYzhOvv2sVvdr9bcndkhoJtJomOIhnBy',--desarrollo-ases
			picture = 0,
			idnumber = new_username,
			yahoo = '',
			aim = '',
			msn = '',
			phone1 = '',
			phone2 = '',
			lastip = '',
			description	= '',
			skype = '',
			institution = '',
			department = '',
			address = '',
			country = '',
			city = '',
			url = '',
			imagealt = '',
			lastnamephonetic = '',
			firstnamephonetic = '',
			middlename = '',
			alternatename = ''
		WHERE id = usuario.id;

		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--delete messages table
CREATE OR REPLACE FUNCTION deleteMessages() 
RETURNS void AS $BODY$
DECLARE
    message mdl_messages%rowtype;
BEGIN
    FOR message IN
        SELECT *
		FROM mdl_messages
		ORDER BY id ASC
		--LIMIT 10
    LOOP

    	DELETE FROM mdl_message_user_actions WHERE messageid = message.id;
		DELETE FROM mdl_messages WHERE id = message.id;

    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update assigns table
CREATE OR REPLACE FUNCTION updateAssigns() 
RETURNS void AS $BODY$
DECLARE
    assign mdl_assign%rowtype;
    assignment mdl_assignment%rowtype;
    assign_grade mdl_assign_grades%rowtype;
    new_grade numeric;
	counter integer;
BEGIN
	counter := 0;
    FOR assign IN
        SELECT id 
		FROM mdl_assign
		ORDER BY id ASC
    LOOP
		UPDATE mdl_assign 
		SET name = 'Assign '||counter, intro = 'Intro of assign '||counter
		WHERE id = assign.id;
		counter := counter + 1;
    END LOOP;

    counter := 0;
    FOR assignment IN
        SELECT  id
		FROM mdl_assignment
		ORDER BY id ASC
    LOOP
		UPDATE mdl_assignment 
		SET name = 'Name '||counter, intro='Intro of assignment '||counter
		WHERE id = assignment.id;
		counter := counter + 1;
    END LOOP;
    
    counter := 0;
    FOR assign_grade IN
        SELECT  *
		FROM mdl_assign_grades ag
		ORDER BY ag.id ASC
    LOOP
    	new_grade := floor(random() * ( 100 - 0 + 1) + 0);

    	RAISE NOTICE 'assignment id (%)', new_grade;

		UPDATE mdl_assign_grades 
		SET grade = new_grade
		WHERE id = assign_grade.id;

		counter := counter + 1;
    END LOOP;

    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update quices table
CREATE OR REPLACE FUNCTION updateQuices() 
RETURNS void AS $BODY$
DECLARE
    quiz mdl_quiz%rowtype;
	counter integer;
BEGIN
	counter = 0;
    FOR quiz IN
        SELECT id 
		FROM mdl_quiz
		ORDER BY id ASC
    LOOP
		UPDATE mdl_quiz 
		SET name = 'Quiz '||counter, intro = 'Intro of quiz '||counter
		WHERE id = quiz.id;
		counter = counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update quices attempts steps SYSTEM
CREATE OR REPLACE FUNCTION updateQuicesAttemptsSteps() 
RETURNS void AS $BODY$
DECLARE
	v_minfraction mdl_question_attempts.minfraction%TYPE;
	v_maxfraction mdl_question_attempts.maxfraction%TYPE;
    attempt_steep mdl_question_attempt_steps%rowtype;
    v_fraction float8;
	n_random numeric;
	v_state text;
BEGIN
    FOR attempt_steep IN
        SELECT *
		FROM mdl_question_attempt_steps st
		WHERE 
			state = 'gradedright' OR
			state = 'mangrwrong' OR
			state = 'mangrright' OR
			state = 'mangrpartial' OR
			state = 'gradedwrong'
		ORDER BY st.id ASC
		--LIMIT 20
    LOOP
		n_random := floor(random() * ( 10000 - 1 + 1) + 1);
		
		-- if random number is even this step not will be modified
		IF (n_random % 2) = 0 THEN
			CONTINUE;
		END IF;
		
		-- min and max fraction in a question attempt
    	SELECT minfraction INTO v_minfraction FROM mdl_question_attempts WHERE id = attempt_steep.questionattemptid;
    	SELECT maxfraction INTO v_maxfraction FROM mdl_question_attempts WHERE id = attempt_steep.questionattemptid;
		
		IF attempt_steep.state = 'gradedright' THEN
			v_fraction := v_minfraction;
			v_state := 'gradedwrong';
		ELSEIF attempt_steep.state = 'gradedwrong' THEN
			v_fraction := v_maxfraction;
			v_state := 'gradedright';
		ELSEIF attempt_steep.state = 'mangrwrong' THEN
			v_fraction := v_maxfraction;
			v_state := 'mangrright';
		ELSEIF attempt_steep.state = 'mangrright' THEN
			v_fraction := v_minfraction;
			v_state := 'mangrwrong';
		ELSEIF attempt_steep.state = 'mangrpartial' THEN
			v_fraction := random() * ( v_maxfraction - v_minfraction) + v_minfraction;
			v_state := 'mangrpartial';
		END IF;
		
		--Update step
		UPDATE mdl_question_attempt_steps
		SET fraction = v_fraction, state = v_state
		WHERE id = attempt_steep.id;
		
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;


--update quices_attempts table
CREATE OR REPLACE FUNCTION updateQuicesAttempts() 
RETURNS void AS $BODY$
DECLARE
	attempt mdl_quiz_attempts%rowtype;
	fractions_sum numeric DEFAULT 0;
BEGIN
    FOR attempt IN
        SELECT * 
		FROM mdl_quiz_attempts
		--WHERE id = 698785
		ORDER BY id ASC
		--LIMIT 10
    LOOP
		SELECT round(SUM(qas.fraction), 2) INTO fractions_sum
		FROM mdl_quiz_attempts quiza
		JOIN mdl_question_usages qu ON qu.id = quiza.uniqueid
		JOIN mdl_question_attempts qa ON qa.questionusageid = qu.id
		JOIN mdl_question_attempt_steps qas ON qas.questionattemptid = qa.id
		LEFT JOIN mdl_question_attempt_step_data qasd ON qasd.attemptstepid = qas.id
		WHERE quiza.id = attempt.id AND qasd.name = '-finish' AND quiza.state = 'finished';
		--RAISE NOTICE 'Grade = %', fractions_sum;
		
		UPDATE mdl_quiz_attempts
		SET sumgrades = fractions_sum
		WHERE id = attempt.id;
		
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;


--update questionnaires table
CREATE OR REPLACE FUNCTION updateQuestionnaires() 
RETURNS void AS $BODY$
DECLARE
    questionnaire mdl_questionnaire%rowtype;
	counter integer;
BEGIN
	counter = 0;
    FOR questionnaire IN
        SELECT id 
		FROM mdl_questionnaire
		ORDER BY id ASC
    LOOP
		UPDATE mdl_questionnaire 
		SET name = 'Questionnaire '||counter, intro = 'Intro of questionnaire '||counter
		WHERE id = questionnaire.id;
		counter = counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update questions categories table
CREATE OR REPLACE FUNCTION updateQuestionsCategories() 
RETURNS void AS $BODY$
DECLARE
    category mdl_question_categories%rowtype;
	counter integer;
BEGIN
	counter = 0;
    FOR category IN
        SELECT id 
		FROM mdl_question_categories
		ORDER BY id ASC
    LOOP
		UPDATE mdl_question_categories 
		SET name = 'Category '||counter, info = 'Category '||counter||' info'
		WHERE id = category.id;
		counter = counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update questions of questionnaire table
CREATE OR REPLACE FUNCTION updateQuestionsQuestionnaires() 
RETURNS void AS $BODY$
DECLARE
    question mdl_questionnaire_question%rowtype;
	counter integer;
BEGIN
	counter = 0;
    FOR question IN
        SELECT id 
		FROM mdl_questionnaire_question
		ORDER BY id ASC
    LOOP
		UPDATE mdl_questionnaire_question 
		SET name = 'Question '||counter, content = 'Question '||counter||' content', extradata = null
		WHERE id = question.id;
		counter = counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update questions choices of questionnaire table
CREATE OR REPLACE FUNCTION updateQuestionsQuestionnairesChices() 
RETURNS void AS $BODY$
DECLARE
    question mdl_questionnaire_quest_choice%rowtype;
	counter integer;
BEGIN
	counter = 0;
    FOR question IN
        SELECT id 
		FROM mdl_questionnaire_quest_choice
		ORDER BY id ASC
    LOOP
		UPDATE mdl_questionnaire_quest_choice 
		SET content = 'Question '||counter||' content'
		WHERE id = question.id;
		counter = counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update questions texts of questionnaire table
CREATE OR REPLACE FUNCTION updateQuestionsQuestionnairesTexts() 
RETURNS void AS $BODY$
DECLARE
    question mdl_questionnaire_response_text%rowtype;
	counter integer;
BEGIN
	counter = 0;
    FOR question IN
        SELECT id 
		FROM mdl_questionnaire_response_text
		ORDER BY id ASC
    LOOP
		UPDATE mdl_questionnaire_response_text 
		SET response = 'Question '||counter||' response'
		WHERE id = question.id;
		counter = counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update questions survey of questionnaire table
CREATE OR REPLACE FUNCTION updateQuestionsQuestionnairesSurvey() 
RETURNS void AS $BODY$
DECLARE
    question mdl_questionnaire_survey%rowtype;
	counter integer;
BEGIN
	counter = 0;
    FOR question IN
        SELECT id 
		FROM mdl_questionnaire_survey
		ORDER BY id ASC
    LOOP
		UPDATE mdl_questionnaire_survey 
		SET 
			name = 'Question '||counter||' name', 
			title = 'Question '||counter||' title',
			subtitle = '',
			info = '' 
		WHERE id = question.id;
		counter = counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update questions table
CREATE OR REPLACE FUNCTION updateQuestions() 
RETURNS void AS $BODY$
DECLARE
    question mdl_question%rowtype;
	counter integer;
BEGIN
	counter = 0;
    FOR question IN
        SELECT id 
		FROM mdl_question
		ORDER BY id ASC
    LOOP
		UPDATE mdl_question 
		SET name = 'Question'||counter, questiontext = 'Statement of Question'||counter
		WHERE id = question.id;
		counter = counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update answers table
CREATE OR REPLACE FUNCTION updateAnswers() 
RETURNS void AS $BODY$
DECLARE
    answer mdl_question_answers%rowtype;
	counter integer;
BEGIN
	counter = 0;
    FOR answer IN
        SELECT id 
		FROM mdl_question_answers 
		ORDER BY id ASC
    LOOP
		UPDATE mdl_question_answers 
		SET answer = 'Answer'||counter, feedback = 'feedback'||counter
		WHERE id = answer.id;
		counter = counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;


--update questions Ddimageortext1 table
CREATE OR REPLACE FUNCTION updateQuestionsDdimageortext1() 
RETURNS void AS $BODY$
DECLARE
    question mdl_qtype_ddimageortext_drags%rowtype;
	counter integer;
BEGIN
	counter = 0;
    FOR question IN
        SELECT id 
		FROM mdl_qtype_ddimageortext_drags
		ORDER BY id ASC
    LOOP
		UPDATE mdl_qtype_ddimageortext_drags 
		SET label = 'Label'||counter
		WHERE id = question.id;
		counter = counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update questions Ddimageortext2 table
CREATE OR REPLACE FUNCTION updateQuestionsDdimageortext2() 
RETURNS void AS $BODY$
DECLARE
    question mdl_qtype_ddimageortext_drops%rowtype;
	counter integer;
BEGIN
	counter = 0;
    FOR question IN
        SELECT id 
		FROM mdl_qtype_ddimageortext_drops
		ORDER BY id ASC
    LOOP
		UPDATE mdl_qtype_ddimageortext_drops 
		SET label = 'Label'||counter
		WHERE id = question.id;
		counter = counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update questions Ddmarker table
CREATE OR REPLACE FUNCTION updateQuestionsDdmarker() 
RETURNS void AS $BODY$
DECLARE
    question mdl_qtype_ddmarker_drags%rowtype;
	counter integer;
BEGIN
	counter = 0;
    FOR question IN
        SELECT id 
		FROM mdl_qtype_ddmarker_drags
		ORDER BY id ASC
    LOOP
		UPDATE mdl_qtype_ddmarker_drags 
		SET label = 'Label'||counter
		WHERE id = question.id;
		counter = counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update questions Kprime table
CREATE OR REPLACE FUNCTION updateQuestionsKprime() 
RETURNS void AS $BODY$
DECLARE
    question mdl_qtype_kprime_rows%rowtype;
	counter integer;
BEGIN
	counter = 0;
    FOR question IN
        SELECT id 
		FROM mdl_qtype_kprime_rows
		ORDER BY id ASC
    LOOP
		UPDATE mdl_qtype_kprime_rows 
		SET optiontext = '<p>Row'||counter||'<br></p>'
		WHERE id = question.id;
		counter = counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update questions Match table
CREATE OR REPLACE FUNCTION updateQuestionsMatch() 
RETURNS void AS $BODY$
DECLARE
    question mdl_qtype_match_subquestions%rowtype;
	counter integer;
BEGIN
	counter = 0;
    FOR question IN
        SELECT id 
		FROM mdl_qtype_match_subquestions
		ORDER BY id ASC
    LOOP
		UPDATE mdl_qtype_match_subquestions 
		SET questiontext = 'Question'||counter, answertext = 'Answer'||counter
		WHERE id = question.id;
		counter = counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update answres pilos table
CREATE OR REPLACE FUNCTION updatePilosAnswers() 
RETURNS void AS $BODY$
DECLARE
    answer mdl_talentospilos_df_respuestas%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR answer IN
        SELECT id 
		FROM mdl_talentospilos_df_respuestas
		WHERE id_pregunta IN (5,6,7,8,16,17,20,26,28,29,30,31,32,33,34,37,48,49,50,51,57)
		ORDER BY id ASC
    LOOP
		UPDATE mdl_talentospilos_df_respuestas 
		SET respuesta = 'Información sensible '||counter
		WHERE id = answer.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update users pilos table
CREATE OR REPLACE FUNCTION updatePilosUsers() 
RETURNS void AS $BODY$
DECLARE
    usuario mdl_talentospilos_usuario%rowtype;
    counter integer;
BEGIN
	counter := 0;
    FOR usuario IN
        SELECT * 
		FROM mdl_talentospilos_usuario
		ORDER BY id ASC
		LIMIT 10
    LOOP
		UPDATE mdl_talentospilos_usuario 
		SET 
			num_doc = 'Document '||counter, 
			num_doc_ini = 'Document '||counter, 
			dir_ini='999',
			barrio_ini = 'Meléndez',
			tel_ini='888', 
			direccion_res= '777', 
			barrio_res='Meléndez',
			tel_res='666', 
			celular='555', 
			emailpilos ='pruebaPilos@correo.com', 
			tel_acudiente='444',
			acudiente = 'Miss Rose',
			colegio = 'Liceo Mixto '||counter
		WHERE id = usuario.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_assignfeedback_comments
CREATE OR REPLACE FUNCTION updateAssignFeedBackComments() 
RETURNS void AS $BODY$
DECLARE
    object mdl_assignfeedback_comments%rowtype;
BEGIN
    FOR object IN
        SELECT id 
		FROM mdl_assignfeedback_comments
		ORDER BY id ASC
    LOOP
		UPDATE mdl_assignfeedback_comments 
		SET commenttext = NULL
		WHERE id = object.id;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;


--update mdl_assignfeedback_editpdf_cmnt
CREATE OR REPLACE FUNCTION updateAssignFeedBackPdfs() 
RETURNS void AS $BODY$
DECLARE
    object mdl_assignfeedback_editpdf_cmnt%rowtype;
BEGIN
    FOR object IN
        SELECT id 
		FROM mdl_assignfeedback_editpdf_cmnt
		ORDER BY id ASC
    LOOP
		UPDATE mdl_assignfeedback_editpdf_cmnt 
		SET rawtext = NULL
		WHERE id = object.id;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_assignfeedback_editpdf_quick
CREATE OR REPLACE FUNCTION updateAssignFeedBackPdfQuick() 
RETURNS void AS $BODY$
DECLARE
    object mdl_assignfeedback_editpdf_quick%rowtype;
BEGIN
    FOR object IN
        SELECT id 
		FROM mdl_assignfeedback_editpdf_quick
		ORDER BY id ASC
    LOOP
		UPDATE mdl_assignfeedback_editpdf_quick 
		SET rawtext = 'txt'
		WHERE id = object.id;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_assignsubmission_onlinetext
CREATE OR REPLACE FUNCTION updateAssignSubmission() 
RETURNS void AS $BODY$
DECLARE
    object mdl_assignsubmission_onlinetext%rowtype;
BEGIN
    FOR object IN
        SELECT id 
		FROM mdl_assignsubmission_onlinetext
		ORDER BY id ASC
    LOOP
		UPDATE mdl_assignsubmission_onlinetext 
		SET onlinetext = NULL
		WHERE id = object.id;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_attendance_sessions
CREATE OR REPLACE FUNCTION updateAttendanceSessions() 
RETURNS void AS $BODY$
DECLARE
    object mdl_attendance_sessions%rowtype;
BEGIN
    FOR object IN
        SELECT id 
		FROM mdl_attendance_sessions
		ORDER BY id ASC
    LOOP
		UPDATE mdl_attendance_sessions 
		SET description = 'Dsc'
		WHERE id = object.id;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_attendance_statuses
CREATE OR REPLACE FUNCTION updateAttendanceStatuses() 
RETURNS void AS $BODY$
DECLARE
    object mdl_attendance_statuses%rowtype;
BEGIN
    FOR object IN
        SELECT id 
		FROM mdl_attendance_statuses
		ORDER BY id ASC
    LOOP
		UPDATE mdl_attendance_statuses 
		SET description = 'Dsc'
		WHERE id = object.id;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_attendance_tempusers
CREATE OR REPLACE FUNCTION updateAttendanceTempUsers() 
RETURNS void AS $BODY$
DECLARE
    object mdl_attendance_tempusers%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_attendance_tempusers
		ORDER BY id ASC
    LOOP
		UPDATE mdl_attendance_tempusers 
		SET fullname = 'Name '||counter, email = 'email'||counter||'@correounivalle.edu.co'
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_badge
CREATE OR REPLACE FUNCTION updateBagde() 
RETURNS void AS $BODY$
DECLARE
    object mdl_badge%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_badge
		ORDER BY id ASC
    LOOP
		UPDATE mdl_badge 
		SET 
			name = 'Name'||counter, 
			description = 'Dsc'||counter,
			issuername = 'Name'||counter,
			issuerurl = 'Url'||counter,
			issuercontact = 'Cont'||counter,
			message = 'Msg'||counter,
			messagesubject = 'Subj'||counter,
			imageauthorname = 'ImgName'||counter,
			imageauthoremail = 'ImgEmail'||counter,
			imageauthorurl = 'Url'||counter,
			imagecaption = 'Caption'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_badge_backpack
CREATE OR REPLACE FUNCTION updateBagdeBackpack() 
RETURNS void AS $BODY$
DECLARE
    object mdl_badge_backpack%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_badge_backpack
		ORDER BY id ASC
    LOOP
		UPDATE mdl_badge_backpack 
		SET email = 'email'||counter||'@correounivalle.edu.co'
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--delete mdl_block_configurable_reports
CREATE OR REPLACE FUNCTION deleteConfigurableReports() 
RETURNS void AS $BODY$
DECLARE
    object mdl_block_configurable_reports%rowtype;
BEGIN
    DELETE FROM mdl_block_configurable_reports;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_block_rss_client
CREATE OR REPLACE FUNCTION updateRssClient() 
RETURNS void AS $BODY$
DECLARE
    object mdl_block_rss_client%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_block_rss_client
		ORDER BY id ASC
    LOOP
		UPDATE mdl_block_rss_client 
		SET 
			preferredtitle = 'PTtle'||counter,
			url = 'Url'||counter, 
			title = 'Ttle'||counter,
			description = 'Dsc'||counter		
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_blog_external
CREATE OR REPLACE FUNCTION updateBlogExternal() 
RETURNS void AS $BODY$
DECLARE
    object mdl_blog_external%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_blog_external
		ORDER BY id ASC
    LOOP
		UPDATE mdl_blog_external 
		SET 
			url = 'Url'||counter, 
			name = 'Name '||counter,
			description = 'Dsc'||counter,
			filtertags = NULL		
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_book
CREATE OR REPLACE FUNCTION updateBook() 
RETURNS void AS $BODY$
DECLARE
    object mdl_book%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_book
		ORDER BY id ASC
    LOOP
		UPDATE mdl_book 
		SET 
			name = 'Name'||counter,
			intro = 'Int'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_book_chapters
CREATE OR REPLACE FUNCTION updateBookChapters() 
RETURNS void AS $BODY$
DECLARE
    object mdl_book_chapters%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_book_chapters
		ORDER BY id ASC
    LOOP
		UPDATE mdl_book_chapters 
		SET 
			title = 'Ttle'||counter,
			content = 'Ctn'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_chat
CREATE OR REPLACE FUNCTION updateChat() 
RETURNS void AS $BODY$
DECLARE
    object mdl_chat%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_chat
		ORDER BY id ASC
    LOOP
		UPDATE mdl_chat 
		SET 
			name = 'Name'||counter,
			intro = 'In'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_checklist
CREATE OR REPLACE FUNCTION updateCheckList() 
RETURNS void AS $BODY$
DECLARE
    object mdl_checklist%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_checklist
		ORDER BY id ASC
    LOOP
		UPDATE mdl_checklist 
		SET 
			name = 'Name'||counter,
			intro = 'Int'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_checklist_item
CREATE OR REPLACE FUNCTION updateCheckListItem() 
RETURNS void AS $BODY$
DECLARE
    object mdl_checklist_item%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_checklist_item
		ORDER BY id ASC
    LOOP
		UPDATE mdl_checklist_item 
		SET 
			displaytext = 'Txt'||counter,
			linkurl = 'Url'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_choice
CREATE OR REPLACE FUNCTION updateChoice() 
RETURNS void AS $BODY$
DECLARE
    object mdl_choice%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_choice
		ORDER BY id ASC
    LOOP
		UPDATE mdl_choice 
		SET 
			name = 'Name'||counter,
			intro = 'Int'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_choice_options
CREATE OR REPLACE FUNCTION updateChoiceOption() 
RETURNS void AS $BODY$
DECLARE
    object mdl_choice_options%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_choice_options
		ORDER BY id ASC
    LOOP
		UPDATE mdl_choice_options 
		SET 
			text = 'Txt'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_choicegroup
CREATE OR REPLACE FUNCTION updateChoiceGroup() 
RETURNS void AS $BODY$
DECLARE
    object mdl_choicegroup%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_choicegroup
		ORDER BY id ASC
    LOOP
		UPDATE mdl_choicegroup 
		SET 
			name = 'Name'||counter,
			intro = 'Int'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_cohort
CREATE OR REPLACE FUNCTION updateCohort() 
RETURNS void AS $BODY$
DECLARE
    object mdl_cohort%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_cohort
		ORDER BY id ASC
    LOOP
		UPDATE mdl_cohort 
		SET 
			name = 'Name'||counter,
			description = 'Dsc'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_comments
CREATE OR REPLACE FUNCTION updateComments() 
RETURNS void AS $BODY$
DECLARE
    object mdl_comments%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_comments
		ORDER BY id ASC
    LOOP
		UPDATE mdl_comments 
		SET 
			content = 'Ctn'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_competency_userevidence
CREATE OR REPLACE FUNCTION updateCompetencyEvidence() 
RETURNS void AS $BODY$
DECLARE
    object mdl_competency_userevidence%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_competency_userevidence
		ORDER BY id ASC
    LOOP
		UPDATE mdl_competency_userevidence 
		SET 
			name = 'Name'||counter,
			description = 'Dsc'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_course
CREATE OR REPLACE FUNCTION updateCourse() 
RETURNS void AS $BODY$
DECLARE
    object mdl_course%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_course
		ORDER BY id ASC
    LOOP
		UPDATE mdl_course 
		SET 
			fullname = 'fname'||counter,
			shortname = 'Name'||counter,
			idnumber = 'Name'||counter,
			summary = 'Smry'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_course_categories
CREATE OR REPLACE FUNCTION updateCourseCategories() 
RETURNS void AS $BODY$
DECLARE
    object mdl_course_categories%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_course_categories
		ORDER BY id ASC
    LOOP
		UPDATE mdl_course_categories 
		SET 
			name = 'Name'||counter,
			description = 'Dsc'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_course_sections
CREATE OR REPLACE FUNCTION updateCourseSections() 
RETURNS void AS $BODY$
DECLARE
    object mdl_course_sections%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_course_sections
		ORDER BY id ASC
    LOOP
		UPDATE mdl_course_sections 
		SET 
			name = 'Name'||counter,
			summary = 'Smry'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_data
CREATE OR REPLACE FUNCTION updateData() 
RETURNS void AS $BODY$
DECLARE
    object mdl_data%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_data
		ORDER BY id ASC
    LOOP
		UPDATE mdl_data 
		SET 
			name = 'Name'||counter,
			intro = 'Int'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_data_content
CREATE OR REPLACE FUNCTION updateDataContent() 
RETURNS void AS $BODY$
DECLARE
    object mdl_data_content%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_data_content
		ORDER BY id ASC
    LOOP
		UPDATE mdl_data_content 
		SET 
			content = 'Ctn'||counter,
			content1 = 'Cont'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_deleted_users
CREATE OR REPLACE FUNCTION updateDeletedUsers() 
RETURNS void AS $BODY$
DECLARE
    object mdl_deleted_users%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_deleted_users
		ORDER BY id ASC
    LOOP
		UPDATE mdl_deleted_users 
		SET 
			username = 'uname'||counter,
			firstname = 'fname'||counter,
			lastname = 'lname'||counter,
			email = 'email'||counter||'@correounivalle.edu.co'
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--delete mdl_deleteoldcourses_deleted
CREATE OR REPLACE FUNCTION deleteCoursesHasDeleted() 
RETURNS void AS $BODY$
DECLARE
    object mdl_deleteoldcourses_deleted%rowtype;
BEGIN
    DELETE FROM mdl_deleteoldcourses_deleted;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_event
CREATE OR REPLACE FUNCTION updateEvents() 
RETURNS void AS $BODY$
DECLARE
    object mdl_event%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_event
		ORDER BY id ASC
    LOOP
		UPDATE mdl_event 
		SET 
			name = 'Name'||counter,
			description = 'Dsc'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_event_subscriptions
CREATE OR REPLACE FUNCTION updateEventsSuscriptions() 
RETURNS void AS $BODY$
DECLARE
    object mdl_event_subscriptions%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_event_subscriptions
		ORDER BY id ASC
    LOOP
		UPDATE mdl_event_subscriptions 
		SET 
			name = 'Name'||counter,
			url = 'Url'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--delete mdl_external_tokens
CREATE OR REPLACE FUNCTION deleteExternalTokens() 
RETURNS void AS $BODY$
DECLARE
    object mdl_external_tokens%rowtype;
BEGIN
    DELETE FROM mdl_external_tokens;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_feedback
CREATE OR REPLACE FUNCTION updateFeedback() 
RETURNS void AS $BODY$
DECLARE
    object mdl_feedback%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_feedback
		ORDER BY id ASC
    LOOP
		UPDATE mdl_feedback 
		SET 
			name = 'Name'||counter,
			intro = 'Int'||counter,
			page_after_submit = 'Thx'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_feedback_item
CREATE OR REPLACE FUNCTION updateFeedbackItem() 
RETURNS void AS $BODY$
DECLARE
    object mdl_feedback_item%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_feedback_item
		ORDER BY id ASC
    LOOP
		UPDATE mdl_feedback_item 
		SET 
			name = 'Name'||counter,
			label = 'Lb'||counter,
			presentation = 'x'||counter||'|y'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_feedback_template
CREATE OR REPLACE FUNCTION updateFeedbackTemplate() 
RETURNS void AS $BODY$
DECLARE
    object mdl_feedback_template%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_feedback_template
		ORDER BY id ASC
    LOOP
		UPDATE mdl_feedback_template 
		SET 
			name = 'Name'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_folder
CREATE OR REPLACE FUNCTION updateFolder() 
RETURNS void AS $BODY$
DECLARE
    object mdl_folder%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_folder
		ORDER BY id ASC
    LOOP
		UPDATE mdl_folder 
		SET 
			name = 'Name'||counter,
			intro = 'Int'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_forum
CREATE OR REPLACE FUNCTION updateForum() 
RETURNS void AS $BODY$
DECLARE
    object mdl_forum%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_forum
		ORDER BY id ASC
    LOOP
		UPDATE mdl_forum 
		SET 
			name = 'Name'||counter,
			intro = 'Int'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_forum_discussions
CREATE OR REPLACE FUNCTION updateForumDiscussion() 
RETURNS void AS $BODY$
DECLARE
    object mdl_forum_discussions%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_forum_discussions
		ORDER BY id ASC
    LOOP
		UPDATE mdl_forum_discussions 
		SET 
			name = 'Name'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_forum_posts
CREATE OR REPLACE FUNCTION updateForumPost() 
RETURNS void AS $BODY$
DECLARE
    object mdl_forum_posts%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_forum_posts
		ORDER BY id ASC
    LOOP
		UPDATE mdl_forum_posts 
		SET 
			subject = 'subj'||counter,
			message = 'msg'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_game_queries
CREATE OR REPLACE FUNCTION updateGameQueries() 
RETURNS void AS $BODY$
DECLARE
    object mdl_game_queries%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_game_queries
		ORDER BY id ASC
    LOOP
		UPDATE mdl_game_queries 
		SET 
			questiontext = 'qtxt'||counter,
			studentanswer = 'answ'||counter,
			answertext = 'atxt'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_glossary
CREATE OR REPLACE FUNCTION updateGlosary() 
RETURNS void AS $BODY$
DECLARE
    object mdl_glossary%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_glossary
		ORDER BY id ASC
    LOOP
		UPDATE mdl_glossary 
		SET 
			name = 'Name'||counter,
			intro = 'Int'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_glossary_alias
CREATE OR REPLACE FUNCTION updateGlosaryAlias() 
RETURNS void AS $BODY$
DECLARE
    object mdl_glossary_alias%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_glossary_alias
		ORDER BY id ASC
    LOOP
		UPDATE mdl_glossary_alias 
		SET 
			alias = 'alias'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_glossary_categories
CREATE OR REPLACE FUNCTION updateGlosaryCategories() 
RETURNS void AS $BODY$
DECLARE
    object mdl_glossary_categories%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_glossary_categories
		ORDER BY id ASC
    LOOP
		UPDATE mdl_glossary_categories 
		SET 
			name = 'Name'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_glossary_entries
CREATE OR REPLACE FUNCTION updateGlosaryEntries() 
RETURNS void AS $BODY$
DECLARE
    object mdl_glossary_entries%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_glossary_entries
		ORDER BY id ASC
    LOOP
		UPDATE mdl_glossary_entries 
		SET 
			concept = 'concept'||counter,
			definition = 'def'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_grade_grades_history
CREATE OR REPLACE FUNCTION updateGradesHistory() 
RETURNS void AS $BODY$
DECLARE
    object mdl_grade_grades_history%rowtype;
	counter integer DEFAULT 0;
	v_total numeric DEFAULT 0;
	v_limit numeric DEFAULT 0;
	v_offset numeric DEFAULT 0;
	v_partition numeric DEFAULT 0;
	v_iterations numeric DEFAULT 100;
	v_iterations_counter numeric DEFAULT 0;
BEGIN
	SELECT COUNT(*) INTO v_total FROM mdl_grade_grades_history;
	v_partition := ceil(v_total/v_iterations);

	--Iterations loop
	LOOP	
		EXIT WHEN v_iterations_counter = v_iterations; 
		v_offset = v_limit;
		v_limit := v_limit + v_partition;
	    FOR object IN
	        SELECT id 
			FROM mdl_grade_grades_history
			ORDER BY id ASC
			LIMIT v_limit
			OFFSET v_offset 
	    LOOP
			UPDATE mdl_grade_grades_history 
			SET 
				feedback = 'F'||counter
			WHERE id = object.id;
			counter := counter + 1;
	    END LOOP;

	    RAISE NOTICE 'End % Iteration with % registers, Limit: %, Offset: %', v_iterations_counter+1, counter, v_limit, v_offset;
	    v_iterations_counter := v_iterations_counter + 1;
	END LOOP;
	--/Iterations loop

    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_grade_import_newitem
CREATE OR REPLACE FUNCTION updateGradeImportNewitem() 
RETURNS void AS $BODY$
DECLARE
    object mdl_grade_import_newitem%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_grade_import_newitem
		ORDER BY id ASC
    LOOP
		UPDATE mdl_grade_import_newitem 
		SET 
			itemname = 'itname'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_grade_items
CREATE OR REPLACE FUNCTION updateGradeItems() 
RETURNS void AS $BODY$
DECLARE
    object mdl_grade_items%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_grade_items
		ORDER BY id ASC
    LOOP
		UPDATE mdl_grade_items 
		SET 
			itemname = 'itname '||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_grade_items_history
CREATE OR REPLACE FUNCTION updateGradeItemsHistory() 
RETURNS void AS $BODY$
DECLARE
    object mdl_grade_items_history%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_grade_items_history
		ORDER BY id ASC
    LOOP
		UPDATE mdl_grade_items_history 
		SET 
			itemname = 'itname '||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_grade_outcomes
CREATE OR REPLACE FUNCTION updateGradeOutcomes() 
RETURNS void AS $BODY$
DECLARE
    object mdl_grade_outcomes%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_grade_outcomes
		ORDER BY id ASC
    LOOP
		UPDATE mdl_grade_outcomes 
		SET 
			shortname = 'sname'||counter,
			fullname = 'Name'||counter,
			description = 'Dsc'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_grade_outcomes_history
CREATE OR REPLACE FUNCTION updateGradeOutcomesHistory() 
RETURNS void AS $BODY$
DECLARE
    object mdl_grade_outcomes_history%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_grade_outcomes_history
		ORDER BY id ASC
    LOOP
		UPDATE mdl_grade_outcomes_history 
		SET 
			shortname = 'sname'||counter,
			fullname = 'Name'||counter,
			description = 'dsc'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_grading_definitions
CREATE OR REPLACE FUNCTION updateGradingDefinitions() 
RETURNS void AS $BODY$
DECLARE
    object mdl_grading_definitions%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_grading_definitions
		ORDER BY id ASC
    LOOP
		UPDATE mdl_grading_definitions 
		SET 
			name = 'Name'||counter,
			description = 'dsc'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_gradingform_guide_criteria
CREATE OR REPLACE FUNCTION updateGradingFormGuideCriteria() 
RETURNS void AS $BODY$
DECLARE
    object mdl_gradingform_guide_criteria%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_gradingform_guide_criteria
		ORDER BY id ASC
    LOOP
		UPDATE mdl_gradingform_guide_criteria 
		SET 
			shortname = 'sname'||counter,
			description = 'dsc'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_gradingform_rubric_criteria
CREATE OR REPLACE FUNCTION updateGradingFormRubricCriteria() 
RETURNS void AS $BODY$
DECLARE
    object mdl_gradingform_rubric_criteria%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_gradingform_rubric_criteria
		ORDER BY id ASC
    LOOP
		UPDATE mdl_gradingform_rubric_criteria 
		SET 
			description = 'dsc'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_groupings
CREATE OR REPLACE FUNCTION updateGrouping() 
RETURNS void AS $BODY$
DECLARE
    object mdl_groupings%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_groupings
		ORDER BY id ASC
    LOOP
		UPDATE mdl_groupings 
		SET 
			name = 'Name'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_groups
CREATE OR REPLACE FUNCTION updateGroups() 
RETURNS void AS $BODY$
DECLARE
    object mdl_groups%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_groups
		ORDER BY id ASC
    LOOP
		UPDATE mdl_groups 
		SET 
			name = 'Name'||counter,
			description = 'Dsc'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_hotpot
CREATE OR REPLACE FUNCTION updateHotpot() 
RETURNS void AS $BODY$
DECLARE
    object mdl_hotpot%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_hotpot
		ORDER BY id ASC
    LOOP
		UPDATE mdl_hotpot 
		SET 
			name = 'Name'||counter,
			entrytext = 'txt'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_hotpot_cache
CREATE OR REPLACE FUNCTION updateHotpotCache() 
RETURNS void AS $BODY$
DECLARE
    object mdl_hotpot_cache%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_hotpot_cache
		ORDER BY id ASC
    LOOP
		UPDATE mdl_hotpot_cache 
		SET 
			name = 'Name'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_hotpot_questions
CREATE OR REPLACE FUNCTION updateHotpotQuestions() 
RETURNS void AS $BODY$
DECLARE
    object mdl_hotpot_questions%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_hotpot_questions
		ORDER BY id ASC
    LOOP
		UPDATE mdl_hotpot_questions 
		SET 
			name = 'Name'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_hotpot_strings
CREATE OR REPLACE FUNCTION updateHotpotStrings() 
RETURNS void AS $BODY$
DECLARE
    object mdl_hotpot_strings%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_hotpot_strings
		ORDER BY id ASC
    LOOP
		UPDATE mdl_hotpot_strings 
		SET 
			string = 'Str'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_hvp
CREATE OR REPLACE FUNCTION updateHvp() 
RETURNS void AS $BODY$
DECLARE
    object mdl_hvp%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_hvp
		ORDER BY id ASC
    LOOP
		UPDATE mdl_hvp 
		SET 
			name = 'Name'||counter,
			intro = 'Int'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_hvp_events
CREATE OR REPLACE FUNCTION updateHvpEvents() 
RETURNS void AS $BODY$
DECLARE
    object mdl_hvp_events%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_hvp_events
		ORDER BY id ASC
    LOOP
		UPDATE mdl_hvp_events 
		SET 
			content_title = 'CtnTtle'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_journal
CREATE OR REPLACE FUNCTION updateJournal() 
RETURNS void AS $BODY$
DECLARE
    object mdl_journal%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_journal
		ORDER BY id ASC
    LOOP
		UPDATE mdl_journal 
		SET 
			name = 'Name'||counter,
			intro = 'Int'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_journal_entries
CREATE OR REPLACE FUNCTION updateJournalEntries() 
RETURNS void AS $BODY$
DECLARE
    object mdl_journal_entries%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_journal_entries
		ORDER BY id ASC
    LOOP
		UPDATE mdl_journal_entries 
		SET 
			text = 'Txt'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_label
CREATE OR REPLACE FUNCTION updateLabel() 
RETURNS void AS $BODY$
DECLARE
    object mdl_label%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_label
		ORDER BY id ASC
    LOOP
		UPDATE mdl_label 
		SET 
			name = 'Name'||counter,
			intro = 'Int'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_lesson
CREATE OR REPLACE FUNCTION updateLesson() 
RETURNS void AS $BODY$
DECLARE
    object mdl_lesson%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_lesson
		ORDER BY id ASC
    LOOP
		UPDATE mdl_lesson 
		SET 
			name = 'Name'||counter,
			intro = 'Int'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_lesson_answers
CREATE OR REPLACE FUNCTION updateLessonAnswers() 
RETURNS void AS $BODY$
DECLARE
    object mdl_lesson_answers%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_lesson_answers
		ORDER BY id ASC
    LOOP
		UPDATE mdl_lesson_answers 
		SET 
			answer = 'Answ'||counter,
			response = 'Resp'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_lesson_attempts
CREATE OR REPLACE FUNCTION updateLessonAttemps() 
RETURNS void AS $BODY$
DECLARE
    object mdl_lesson_attempts%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_lesson_attempts
		ORDER BY id ASC
    LOOP
		UPDATE mdl_lesson_attempts 
		SET 
			useranswer = 'Answ'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_lesson_pages
CREATE OR REPLACE FUNCTION updateLessonPages() 
RETURNS void AS $BODY$
DECLARE
    object mdl_lesson_pages%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_lesson_pages
		ORDER BY id ASC
    LOOP
		UPDATE mdl_lesson_pages 
		SET 
			title = 'Ttle'||counter,
			contents = 'Ctn'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_lightboxgallery
CREATE OR REPLACE FUNCTION updateLightBoxGallery() 
RETURNS void AS $BODY$
DECLARE
    object mdl_lightboxgallery%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_lightboxgallery
		ORDER BY id ASC
    LOOP
		UPDATE mdl_lightboxgallery 
		SET 
			name = 'Name'||counter,
			intro = 'Int'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_lti
CREATE OR REPLACE FUNCTION updateLti() 
RETURNS void AS $BODY$
DECLARE
    object mdl_lti%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_lti
		ORDER BY id ASC
    LOOP
		UPDATE mdl_lti 
		SET 
			name = 'Name'||counter,
			intro = 'Int'||counter,
			toolurl = 'Url'||counter,
			resourcekey = NULL,
			password  = NULL
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_message
CREATE OR REPLACE FUNCTION updateMessage() 
RETURNS void AS $BODY$
DECLARE
    object mdl_message%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_message
		ORDER BY id ASC
    LOOP
		UPDATE mdl_message 
		SET 
			fullmessage = 'Msg'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_message_read
CREATE OR REPLACE FUNCTION updateMessageRead() 
RETURNS void AS $BODY$
DECLARE
    object mdl_message_read%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_message_read
		ORDER BY id ASC
    LOOP
		UPDATE mdl_message_read 
		SET 
			fullmessage = 'Msg'||counter,
			subject = 'Subj'||counter,
			fullmessagehtml = NULL,
			smallmessage  = NULL
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_notifications
CREATE OR REPLACE FUNCTION updateNotifications() 
RETURNS void AS $BODY$
DECLARE
    object mdl_notifications%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_notifications
		ORDER BY id ASC
    LOOP
		UPDATE mdl_notifications 
		SET 
			fullmessage = 'Msg'||counter,
			subject = 'Subj'||counter,
			fullmessagehtml = NULL,
			smallmessage  = NULL,
			contexturlname  = NULL
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--delete mdl_oauth2_issuer
CREATE OR REPLACE FUNCTION deleteOauth2Issue() 
RETURNS void AS $BODY$
DECLARE
    object mdl_oauth2_issuer%rowtype;
BEGIN
    DELETE FROM mdl_oauth2_issuer;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_page
CREATE OR REPLACE FUNCTION updatePage() 
RETURNS void AS $BODY$
DECLARE
    object mdl_page%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_page
		ORDER BY id ASC
    LOOP
		UPDATE mdl_page 
		SET 
			name = 'Name'||counter,
			intro = 'Int'||counter,
			content = 'Ctn'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_post
CREATE OR REPLACE FUNCTION updatePost() 
RETURNS void AS $BODY$
DECLARE
    object mdl_post%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_post
		ORDER BY id ASC
    LOOP
		UPDATE mdl_post 
		SET 
			subject = 'Subj'||counter,
			summary = 'Smry'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_question_attempts
CREATE OR REPLACE FUNCTION updateQuestionAttempts() 
RETURNS void AS $BODY$
DECLARE
    object mdl_question_attempts%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_question_attempts
		ORDER BY id ASC
    LOOP
		UPDATE mdl_question_attempts 
		SET 
			questionsummary = 'Smry'||counter,
			rightanswer = 'Ransw'||counter,
			responsesummary = 'Smryres'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_question_splitset_sub
CREATE OR REPLACE FUNCTION updateQuestionSplitsetSub() 
RETURNS void AS $BODY$
DECLARE
    object mdl_question_splitset_sub%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_question_splitset_sub
		ORDER BY id ASC
    LOOP
		UPDATE mdl_question_splitset_sub 
		SET 
			item = '<p>S'||counter||'</p>'
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_questionnaire_survey
CREATE OR REPLACE FUNCTION updateQuestionnaireSurvey() 
RETURNS void AS $BODY$
DECLARE
    object mdl_questionnaire_survey%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_questionnaire_survey
		ORDER BY id ASC
    LOOP
		UPDATE mdl_questionnaire_survey 
		SET 
			email = 'email'||counter||'@correounivalle.edu.co',
			thank_head = 'Thx'||counter,
			thank_body = 'Thxbody'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_quiz_feedback
CREATE OR REPLACE FUNCTION updateQuizFeedback() 
RETURNS void AS $BODY$
DECLARE
    object mdl_quiz_feedback%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_quiz_feedback
		ORDER BY id ASC
    LOOP
		UPDATE mdl_quiz_feedback 
		SET 
			feedbacktext = 'F'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_quiz_slot_tags
CREATE OR REPLACE FUNCTION updateQuizSlotTags() 
RETURNS void AS $BODY$
DECLARE
    object mdl_quiz_slot_tags%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_quiz_slot_tags
		ORDER BY id ASC
    LOOP
		UPDATE mdl_quiz_slot_tags 
		SET 
			tagname = 'Tag'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;


--update mdl_resource
CREATE OR REPLACE FUNCTION updateResource() 
RETURNS void AS $BODY$
DECLARE
    object mdl_resource%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_resource
		ORDER BY id ASC
    LOOP
		UPDATE mdl_resource 
		SET 
			name = 'Name'||counter,
			intro = 'Int'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_resource_old
CREATE OR REPLACE FUNCTION updateResourceOld() 
RETURNS void AS $BODY$
DECLARE
    object mdl_resource_old%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_resource_old
		ORDER BY id ASC
    LOOP
		UPDATE mdl_resource_old 
		SET 
			name = 'Name'||counter,
			reference = 'Ref'||counter,
			intro = 'Int'||counter,
			alltext = 'Txt'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_scale
CREATE OR REPLACE FUNCTION updateScale() 
RETURNS void AS $BODY$
DECLARE
    object mdl_scale%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_scale
		ORDER BY id ASC
    LOOP
		UPDATE mdl_scale 
		SET 
			name = 'Name'||counter,
			scale = '1,2,3,4,5',
			description = 'Dsc'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_scale_history
CREATE OR REPLACE FUNCTION updateScaleHistory() 
RETURNS void AS $BODY$
DECLARE
    object mdl_scale_history%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_scale_history
		ORDER BY id ASC
    LOOP
		UPDATE mdl_scale_history 
		SET 
			name = 'Name'||counter,
			scale = '1,2,3,4,5',
			description = 'Dsc'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_scorm
CREATE OR REPLACE FUNCTION updateScorm() 
RETURNS void AS $BODY$
DECLARE
    object mdl_scorm%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_scorm
		ORDER BY id ASC
    LOOP
		UPDATE mdl_scorm 
		SET 
			name = 'Name '||counter,
			reference = 'Ref'||counter,
			intro = 'Int'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_scorm_scoes
CREATE OR REPLACE FUNCTION updateScormScoes() 
RETURNS void AS $BODY$
DECLARE
    object mdl_scorm_scoes%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_scorm_scoes
		ORDER BY id ASC
    LOOP
		UPDATE mdl_scorm_scoes 
		SET 
			title = 'Ttle'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--delete mdl_sessions
CREATE OR REPLACE FUNCTION deleteSessions() 
RETURNS void AS $BODY$
DECLARE
    object mdl_sessions%rowtype;
BEGIN
    DELETE FROM mdl_sessions;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_survey
CREATE OR REPLACE FUNCTION updateSurvey() 
RETURNS void AS $BODY$
DECLARE
    object mdl_survey%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_survey
		ORDER BY id ASC
    LOOP
		UPDATE mdl_survey 
		SET 
			name = 'Name'||counter,
			intro = 'Int'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_tag
CREATE OR REPLACE FUNCTION updateTag() 
RETURNS void AS $BODY$
DECLARE
    object mdl_tag%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_tag
		ORDER BY id ASC
    LOOP
		UPDATE mdl_tag 
		SET 
			name = 'Name'||counter,
			rawname = 'Rname'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_talentospilos_academics_data
CREATE OR REPLACE FUNCTION updatePilosAcademicsData() 
RETURNS void AS $BODY$
DECLARE
    object mdl_talentospilos_academics_data%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_talentospilos_academics_data
		ORDER BY id ASC
    LOOP
		UPDATE mdl_talentospilos_academics_data 
		SET 
			resolucion_programa = 'Prog'||counter,
			creditos_totales = 100,
			otras_instituciones = 'Inst'||counter,
			dificultades = 'Prob'||counter,
			observaciones = 'So'||counter,
			titulo_academico_colegio = 'Prep'
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_talentospilos_retiros
CREATE OR REPLACE FUNCTION updatePilosRetiros() 
RETURNS void AS $BODY$
DECLARE
    object mdl_talentospilos_retiros%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_talentospilos_retiros
		ORDER BY id ASC
    LOOP
		UPDATE mdl_talentospilos_retiros 
		SET 
			detalle = 'Det'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_talentospilos_seguimiento
CREATE OR REPLACE FUNCTION updatePilosSeguimiento() 
RETURNS void AS $BODY$
DECLARE
    object mdl_talentospilos_seguimiento%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_talentospilos_seguimiento
		ORDER BY id ASC
    LOOP
		UPDATE mdl_talentospilos_seguimiento 
		SET 
			lugar = 'Uv',
			tema = 'Tpic'||counter,
			objetivos = 'Obj'||counter,
			familiar_desc = NULL,
			academico = NULL,
			economico = NULL,
			vida_uni = NULL,
			observaciones = ''
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_tool_recyclebin_category
CREATE OR REPLACE FUNCTION updateToolRecyclerCategory() 
RETURNS void AS $BODY$
DECLARE
    object mdl_tool_recyclebin_category%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_tool_recyclebin_category
		ORDER BY id ASC
    LOOP
		UPDATE mdl_tool_recyclebin_category 
		SET 
			shortname = 'It'||counter,
			fullname = 'Fname'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_tool_recyclebin_course
CREATE OR REPLACE FUNCTION updateToolRecyclerCourse() 
RETURNS void AS $BODY$
DECLARE
    object mdl_tool_recyclebin_course%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_tool_recyclebin_course
		ORDER BY id ASC
    LOOP
		UPDATE mdl_tool_recyclebin_course 
		SET 
			name = 'Name'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_url
CREATE OR REPLACE FUNCTION updateUrl() 
RETURNS void AS $BODY$
DECLARE
    object mdl_url%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_url
		ORDER BY id ASC
    LOOP
		UPDATE mdl_url 
		SET 
			name = 'Name'||counter,
			intro = 'Int'||counter,
			externalurl = 'url'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--delete mdl_user_devices
CREATE OR REPLACE FUNCTION deleteUserDevices() 
RETURNS void AS $BODY$
DECLARE
    object mdl_user_devices%rowtype;
BEGIN
    DELETE FROM mdl_user_devices;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_wiki
CREATE OR REPLACE FUNCTION updateWiki() 
RETURNS void AS $BODY$
DECLARE
    object mdl_wiki%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_wiki
		ORDER BY id ASC
    LOOP
		UPDATE mdl_wiki 
		SET 
			name = 'Name'||counter,
			intro = 'Int'||counter,
			firstpagetitle = 'Ttle'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_wiki_links
CREATE OR REPLACE FUNCTION updateWikiLinks() 
RETURNS void AS $BODY$
DECLARE
    object mdl_wiki_links%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_wiki_links
		ORDER BY id ASC
    LOOP
		UPDATE mdl_wiki_links 
		SET 
			tomissingpage = 'Wik'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_wiki_pages
CREATE OR REPLACE FUNCTION updateWikiPages() 
RETURNS void AS $BODY$
DECLARE
    object mdl_wiki_pages%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_wiki_pages
		ORDER BY id ASC
    LOOP
		UPDATE mdl_wiki_pages 
		SET 
			title = 'Ttle'||counter,
			cachedcontent = '<h1> Ctn:'||counter||'</h1>'
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_workshop
CREATE OR REPLACE FUNCTION updateWorkShop() 
RETURNS void AS $BODY$
DECLARE
    object mdl_workshop%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_workshop
		ORDER BY id ASC
    LOOP
		UPDATE mdl_workshop 
		SET 
			name = 'Name'||counter,
			intro = 'Int'||counter,
			instructauthors = NULL,
			instructreviewers = NULL,
			conclusion = NULL
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_workshop_assessments
CREATE OR REPLACE FUNCTION updateWorkShopAssesments() 
RETURNS void AS $BODY$
DECLARE
    object mdl_workshop_assessments%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_workshop_assessments
		ORDER BY id ASC
    LOOP
		UPDATE mdl_workshop_assessments 
		SET 
			feedbackauthor = '<p>F'||counter||'</p>'
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_workshop_grades
CREATE OR REPLACE FUNCTION updateWorkShopGrades() 
RETURNS void AS $BODY$
DECLARE
    object mdl_workshop_grades%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_workshop_grades
		ORDER BY id ASC
    LOOP
		UPDATE mdl_workshop_grades 
		SET 
			grade = floor(random() * ( 5 - 1 + 1) + 1),
			peercomment = 'Cmt'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_workshop_submissions
CREATE OR REPLACE FUNCTION updateWorkShopSubmissions() 
RETURNS void AS $BODY$
DECLARE
    object mdl_workshop_submissions%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_workshop_submissions
		ORDER BY id ASC
    LOOP
		UPDATE mdl_workshop_submissions 
		SET 
			title = 'Ttle'||counter,
			content = 'Ctn'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_workshopform_accumulative
CREATE OR REPLACE FUNCTION updateWorkShopFormAcumulative() 
RETURNS void AS $BODY$
DECLARE
    object mdl_workshopform_accumulative%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_workshopform_accumulative
		ORDER BY id ASC
    LOOP
		UPDATE mdl_workshopform_accumulative 
		SET 
			description = '<p>Dsc'||counter||'</p>'
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_workshopform_numerrors
CREATE OR REPLACE FUNCTION updateWorkShopFormErrors() 
RETURNS void AS $BODY$
DECLARE
    object mdl_workshopform_numerrors%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_workshopform_numerrors
		ORDER BY id ASC
    LOOP
		UPDATE mdl_workshopform_numerrors 
		SET 
			description = '<p>Dsc'||counter||'</p>'
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_workshopform_comments
CREATE OR REPLACE FUNCTION updateWorkShopFormComments() 
RETURNS void AS $BODY$
DECLARE
    object mdl_workshopform_comments%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_workshopform_comments
		ORDER BY id ASC
    LOOP
		UPDATE mdl_workshopform_comments 
		SET 
			description = '<p>Dsc'||counter||'</p>'
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_workshopform_rubric
CREATE OR REPLACE FUNCTION updateWorkShopFormRubric() 
RETURNS void AS $BODY$
DECLARE
    object mdl_workshopform_rubric%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_workshopform_rubric
		ORDER BY id ASC
    LOOP
		UPDATE mdl_workshopform_rubric 
		SET 
			description = '<p>Dsc'||counter||'</p>'
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

--update mdl_workshopform_rubric_levels
CREATE OR REPLACE FUNCTION updateWorkShopFormRubricLevels() 
RETURNS void AS $BODY$
DECLARE
    object mdl_workshopform_rubric_levels%rowtype;
	counter integer;
BEGIN
	counter := 0;
    FOR object IN
        SELECT id 
		FROM mdl_workshopform_rubric_levels
		ORDER BY id ASC
    LOOP
		UPDATE mdl_workshopform_rubric_levels 
		SET 
			grade = floor(random() * ( 100 - 0 + 1) + 0),
			definition = 'Def'||counter
		WHERE id = object.id;
		counter := counter + 1;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

-----------------------------------------------
----------       RUN FUNCTIONS   --------------
-----------------------------------------------
SELECT updateUsers();
SELECT deleteMessages();
SELECT updateAnswers();
SELECT updateAssigns();
SELECT updateQuices();
SELECT updateQuicesAttemptsSteps();
SELECT updateQuicesAttempts();
SELECT updateQuestionnaires();
SELECT updateQuestionsCategories();
SELECT updateQuestionsQuestionnaires();
SELECT updateQuestionsQuestionnairesChices();
SELECT updateQuestionsQuestionnairesTexts();
SELECT updateQuestionsQuestionnairesSurvey();
SELECT updateQuestions();
SELECT updateQuestionsDdimageortext1();
SELECT updateQuestionsDdimageortext2();
SELECT updateQuestionsDdmarker();
SELECT updateQuestionsKprime();
SELECT updateQuestionsMatch();
SELECT updatePilosAnswers();
SELECT updatePilosUsers();

SELECT updateAssignFeedBackComments();
SELECT updateAssignFeedBackPdfs();
SELECT updateAssignFeedBackPdfQuick();
SELECT updateAssignSubmission();
SELECT updateAttendanceSessions();
SELECT updateAttendanceStatuses();
SELECT updateAttendanceTempUsers();
SELECT updateBagde();
SELECT updateBagdeBackpack();
SELECT deleteConfigurableReports();
SELECT updateRssClient();
SELECT updateBlogExternal();
SELECT updateBook();
SELECT updateBookChapters();
SELECT updateChat();
SELECT updateCheckList();
SELECT updateCheckListItem();
SELECT updateChoice();
SELECT updateChoiceOption();
SELECT updateChoiceGroup();
SELECT updateCohort();
SELECT updateComments();
SELECT updateCompetencyEvidence();
SELECT updateCourse();
SELECT updateCourseCategories();
SELECT updateCourseSections();
SELECT updateData();
SELECT updateDataContent();
SELECT updateDeletedUsers();
SELECT deleteCoursesHasDeleted();
SELECT updateEvents();
SELECT updateEventsSuscriptions();
SELECT deleteExternalTokens();
SELECT updateFeedback();
SELECT updateFeedbackItem();
SELECT updateFeedbackTemplate();
SELECT updateFolder();
SELECT updateForum();
SELECT updateForumDiscussion();
SELECT updateForumPost();
SELECT updateGameQueries();
SELECT updateGlosary();
SELECT updateGlosaryAlias();
SELECT updateGlosaryCategories();
SELECT updateGlosaryEntries();
SELECT updateGradesHistory();
SELECT updateGradeImportNewitem();
SELECT updateGradeItems();
SELECT updateGradeItemsHistory();
SELECT updateGradeOutcomes();
SELECT updateGradeOutcomesHistory();
SELECT updateGradingDefinitions();
SELECT updateGradingFormGuideCriteria();
SELECT updateGradingFormRubricCriteria();
SELECT updateGrouping();
SELECT updateGroups();
SELECT updateHotpot();
SELECT updateHotpotCache();
SELECT updateHotpotQuestions();
SELECT updateHotpotStrings();
SELECT updateHvp();
SELECT updateHvpEvents();
SELECT updateJournal();
SELECT updateJournalEntries();
SELECT updateLabel();
SELECT updateLesson();
SELECT updateLessonAnswers();
SELECT updateLessonAttemps();
SELECT updateLessonPages();
SELECT updateLightBoxGallery();
SELECT updateLti();
SELECT updateMessage();
SELECT updateMessageRead();
SELECT updateNotifications();
SELECT deleteOauth2Issue();
SELECT updatePage();
SELECT updatePost();
SELECT updateQuestionAttempts();
SELECT updateQuestionSplitsetSub();
SELECT updateQuestionnaireSurvey();
SELECT updateQuizFeedback();
SELECT updateQuizSlotTags();
SELECT updateResource();
SELECT updateResourceOld();
SELECT updateScale();
SELECT updateScaleHistory();
SELECT updateScorm();
SELECT updateScormScoes();
SELECT deleteSessions();
SELECT updateSurvey();
SELECT updateTag();
SELECT updatePilosAcademicsData();
SELECT updatePilosRetiros();
SELECT updatePilosSeguimiento();
SELECT updateToolRecyclerCategory();
SELECT updateToolRecyclerCourse();
SELECT updateUrl();
SELECT deleteUserDevices();
SELECT updateWiki();
SELECT updateWikiLinks();
SELECT updateWikiPages();
SELECT updateWorkShop();
SELECT updateWorkShopAssesments();
SELECT updateWorkShopGrades();
SELECT updateWorkShopSubmissions();
SELECT updateWorkShopFormAcumulative();
SELECT updateWorkShopFormErrors();
SELECT updateWorkShopFormComments();
SELECT updateWorkShopFormRubric();
SELECT updateWorkShopFormRubricLevels();
-----------------------------------------------
----------       DROP FUNCTIONS   -------------
-----------------------------------------------
DROP FUNCTION IF EXISTS updateUsers();
DROP FUNCTION IF EXISTS updateAssigns();
DROP FUNCTION IF EXISTS updateQuices();
DROP FUNCTION IF EXISTS updateQuicesAttemptsSteps();
DROP FUNCTION IF EXISTS updateQuicesAttempts();
DROP FUNCTION IF EXISTS updateQuestionnaires();
DROP FUNCTION IF EXISTS updateQuestionsCategories();
DROP FUNCTION IF EXISTS updateQuestionsQuestionnaires();
DROP FUNCTION IF EXISTS updateQuestionsQuestionnairesChices();
DROP FUNCTION IF EXISTS updateQuestionsQuestionnairesTexts();
DROP FUNCTION IF EXISTS updateQuestionsQuestionnairesSurvey();
DROP FUNCTION IF EXISTS updateQuestions();
DROP FUNCTION IF EXISTS updateAnswers();
DROP FUNCTION IF EXISTS updateQuestionsDdimageortext1();
DROP FUNCTION IF EXISTS updateQuestionsDdimageortext2();
DROP FUNCTION IF EXISTS updateQuestionsDdmarker();
DROP FUNCTION IF EXISTS updateQuestionsKprime();
DROP FUNCTION IF EXISTS updateQuestionsMatch();
DROP FUNCTION IF EXISTS updatePilosAnswers();
DROP FUNCTION IF EXISTS updatePilosUsers();

DROP FUNCTION IF EXISTS updateAssignFeedBackComments();
DROP FUNCTION IF EXISTS updateAssignFeedBackPdfs();
DROP FUNCTION IF EXISTS updateAssignFeedBackPdfQuick();
DROP FUNCTION IF EXISTS updateAssignSubmission();
DROP FUNCTION IF EXISTS updateAttendanceSessions();
DROP FUNCTION IF EXISTS updateAttendanceStatuses();
DROP FUNCTION IF EXISTS updateAttendanceTempUsers();
DROP FUNCTION IF EXISTS updateBagde();
DROP FUNCTION IF EXISTS updateBagdeBackpack();
DROP FUNCTION IF EXISTS deleteConfigurableReports();
DROP FUNCTION IF EXISTS updateRssClient();
DROP FUNCTION IF EXISTS updateBlogExternal();
DROP FUNCTION IF EXISTS updateBook();
DROP FUNCTION IF EXISTS updateBookChapters();
DROP FUNCTION IF EXISTS updateChat();
DROP FUNCTION IF EXISTS updateCheckList();
DROP FUNCTION IF EXISTS updateCheckListItem();
DROP FUNCTION IF EXISTS updateChoice();
DROP FUNCTION IF EXISTS updateChoiceOption();
DROP FUNCTION IF EXISTS updateChoiceGroup();
DROP FUNCTION IF EXISTS updateCohort();
DROP FUNCTION IF EXISTS updateComments();
DROP FUNCTION IF EXISTS updateCompetencyEvidence();
DROP FUNCTION IF EXISTS updateCourse();
DROP FUNCTION IF EXISTS updateCourseCategories();
DROP FUNCTION IF EXISTS updateCourseSections();
DROP FUNCTION IF EXISTS updateData();
DROP FUNCTION IF EXISTS updateDataContent();
DROP FUNCTION IF EXISTS updateDeletedUsers();
DROP FUNCTION IF EXISTS deleteCoursesHasDeleted();
DROP FUNCTION IF EXISTS updateEvents();
DROP FUNCTION IF EXISTS updateEventsSuscriptions();
DROP FUNCTION IF EXISTS deleteExternalTokens();
DROP FUNCTION IF EXISTS updateFeedback();
DROP FUNCTION IF EXISTS updateFeedbackItem();
DROP FUNCTION IF EXISTS updateFeedbackTemplate();
DROP FUNCTION IF EXISTS updateFolder();
DROP FUNCTION IF EXISTS updateForum();
DROP FUNCTION IF EXISTS updateForumDiscussion();
DROP FUNCTION IF EXISTS updateForumPost();
DROP FUNCTION IF EXISTS updateGameQueries();
DROP FUNCTION IF EXISTS updateGlosary();
DROP FUNCTION IF EXISTS updateGlosaryAlias();
DROP FUNCTION IF EXISTS updateGlosaryCategories();
DROP FUNCTION IF EXISTS updateGlosaryEntries();
DROP FUNCTION IF EXISTS updateGradesHistory();
DROP FUNCTION IF EXISTS updateGradeImportNewitem();
DROP FUNCTION IF EXISTS updateGradeItems();
DROP FUNCTION IF EXISTS updateGradeItemsHistory();
DROP FUNCTION IF EXISTS updateGradeOutcomes();
DROP FUNCTION IF EXISTS updateGradeOutcomesHistory();
DROP FUNCTION IF EXISTS updateGradingDefinitions();
DROP FUNCTION IF EXISTS updateGradingFormGuideCriteria();
DROP FUNCTION IF EXISTS updateGradingFormRubricCriteria();
DROP FUNCTION IF EXISTS updateGrouping();
DROP FUNCTION IF EXISTS updateGroups();
DROP FUNCTION IF EXISTS updateHotpot();
DROP FUNCTION IF EXISTS updateHotpotCache();
DROP FUNCTION IF EXISTS updateHotpotQuestions();
DROP FUNCTION IF EXISTS updateHotpotStrings();
DROP FUNCTION IF EXISTS updateHvp();
DROP FUNCTION IF EXISTS updateHvpEvents();
DROP FUNCTION IF EXISTS updateJournal();
DROP FUNCTION IF EXISTS updateJournalEntries();
DROP FUNCTION IF EXISTS updateLabel();
DROP FUNCTION IF EXISTS updateLesson();
DROP FUNCTION IF EXISTS updateLessonAnswers();
DROP FUNCTION IF EXISTS updateLessonAttemps();
DROP FUNCTION IF EXISTS updateLessonPages();
DROP FUNCTION IF EXISTS updateLightBoxGallery();
DROP FUNCTION IF EXISTS updateLti();
DROP FUNCTION IF EXISTS updateMessage();
DROP FUNCTION IF EXISTS updateMessageRead();
DROP FUNCTION IF EXISTS updateNotifications();
DROP FUNCTION IF EXISTS deleteOauth2Issue();
DROP FUNCTION IF EXISTS updatePage();
DROP FUNCTION IF EXISTS updatePost();
DROP FUNCTION IF EXISTS updateQuestionAttempts();
DROP FUNCTION IF EXISTS updateQuestionSplitsetSub();
DROP FUNCTION IF EXISTS updateQuestionnaireSurvey();
DROP FUNCTION IF EXISTS updateQuizFeedback();
DROP FUNCTION IF EXISTS updateQuizSlotTags();
DROP FUNCTION IF EXISTS updateResource();
DROP FUNCTION IF EXISTS updateResourceOld();
DROP FUNCTION IF EXISTS updateScale();
DROP FUNCTION IF EXISTS updateScaleHistory();
DROP FUNCTION IF EXISTS updateScorm();
DROP FUNCTION IF EXISTS updateScormScoes();
DROP FUNCTION IF EXISTS deleteSessions();
DROP FUNCTION IF EXISTS updateSurvey();
DROP FUNCTION IF EXISTS updateTag();
DROP FUNCTION IF EXISTS updatePilosAcademicsData();
DROP FUNCTION IF EXISTS updatePilosRetiros();
DROP FUNCTION IF EXISTS updatePilosSeguimiento();
DROP FUNCTION IF EXISTS updateToolRecyclerCategory();
DROP FUNCTION IF EXISTS updateToolRecyclerCourse();
DROP FUNCTION IF EXISTS updateUrl();
DROP FUNCTION IF EXISTS deleteUserDevices();
DROP FUNCTION IF EXISTS updateWiki();
DROP FUNCTION IF EXISTS updateWikiLinks();
DROP FUNCTION IF EXISTS updateWikiPages();
DROP FUNCTION IF EXISTS updateWorkShop();
DROP FUNCTION IF EXISTS updateWorkShopAssesments();
DROP FUNCTION IF EXISTS updateWorkShopGrades();
DROP FUNCTION IF EXISTS updateWorkShopSubmissions();
DROP FUNCTION IF EXISTS updateWorkShopFormAcumulative();
DROP FUNCTION IF EXISTS updateWorkShopFormErrors();
DROP FUNCTION IF EXISTS updateWorkShopFormComments();
DROP FUNCTION IF EXISTS updateWorkShopFormRubric();
DROP FUNCTION IF EXISTS updateWorkShopFormRubricLevels();