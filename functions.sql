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
			description	= ''
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
BEGIN
    FOR usuario IN
        SELECT * 
		FROM mdl_talentospilos_usuario
		ORDER BY id ASC
		LIMIT 10
    LOOP
		UPDATE mdl_talentospilos_usuario 
		SET 
			num_doc = md5(usuario.num_doc), 
			num_doc_ini = md5(usuario.num_doc_ini), 
			dir_ini='999',  
			tel_ini='888', 
			direccion_res= '777', 
			tel_res='666', 
			celular='555', 
			emailpilos ='pruebaPilos@correo.com', 
			tel_acudiente='444'
		WHERE id = usuario.id;
    END LOOP;
    RETURN;
END;
$BODY$
LANGUAGE plpgsql;

-----------------------------------------------
----------       RUN FUNCTIONS   --------------
-----------------------------------------------
DO $$ BEGIN
    PERFORM updateUsers();
END $$;

DO $$ BEGIN
    PERFORM deleteMessages();
END $$;

DO $$ BEGIN
    PERFORM updateAnswers();
END $$;

DO $$ BEGIN
    PERFORM updateAssigns();
END $$;

DO $$ BEGIN
    PERFORM updateQuices();
END $$;

DO $$ BEGIN
    PERFORM updateQuicesAttemptsSteps();
END $$;

DO $$ BEGIN
    PERFORM updateQuestionnaires();
END $$;

DO $$ BEGIN
    PERFORM updateQuestionsCategories();
END $$;

DO $$ BEGIN
    PERFORM updateQuestionsQuestionnaires();
END $$;

DO $$ BEGIN
    PERFORM updateQuestionsQuestionnairesChices();
END $$;

DO $$ BEGIN
    PERFORM updateQuestionsQuestionnairesTexts();
END $$;

DO $$ BEGIN
    PERFORM updateQuestionsQuestionnairesSurvey();
END $$;

DO $$ BEGIN
    PERFORM updateQuestions();
END $$;

DO $$ BEGIN
    PERFORM updateQuestionsDdimageortext1();
    PERFORM updateQuestionsDdimageortext2();
END $$;

DO $$ BEGIN
    PERFORM updateQuestionsDdmarker();
END $$;

DO $$ BEGIN
    PERFORM updateQuestionsKprime();
END $$;

DO $$ BEGIN
    PERFORM updateQuestionsMatch();
END $$;

DO $$ BEGIN
    PERFORM updatePilosAnswers();
END $$;

DO $$ BEGIN
    PERFORM updatePilosUsers();
END $$;

-----------------------------------------------
----------       DROP FUNCTIONS   -------------
-----------------------------------------------
DROP FUNCTION IF EXISTS updateUsers();
DROP FUNCTION IF EXISTS updateAssigns();
DROP FUNCTION IF EXISTS updateQuices();
DROP FUNCTION IF EXISTS updateQuicesAttemptsSteps();
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