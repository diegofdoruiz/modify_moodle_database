<?php
	
	/*
	 * Start database connection
	 * @return $dbconn
	 */
	function connection(){
		$dbconn = pg_connect("host=192.168.1.46 port=5432 dbname=moodle_ases user=moodle password=moodle");  
		if (!$dbconn){  
			return NULL;  
		}else{  
			return $dbconn;
		} 
	} 

	/*
	 * Update a register en a table
	 * @param String $table
	 * @param Array $data
	 * @param Array $cond
	 * @return boolean
	 */
	function updateOneRow($connection, $table, $data, $cond){
		$result = pg_update($connection, $table, $data, $cond);
		if (!$result) {
			die("PG Error: " . pg_result_error($result));
			return TRUE;
		}
		return FALSE;
	}

	/*
	 * Get a user and update its fields
	 * @return boolean
	 */
	function updateUsers(){
		$conn = connection();
		$users = pg_query($conn, "SELECT id, username, firstname, lastname FROM mdl_user ORDER BY id");
		if (!$users) {  
			echo "Error al consultar usuarios.\n";  
			exit;  
		}

		echo 'Update users has started <br>';
		$count = 0;
		while ($row = pg_fetch_row($users)) {  

			echo '-- Updating user '.$row[1].' - '.$row[2].' '.$row[3].'<br>';

			$username = 'username'.$count;
			if (strpos($row[1], '-') !== false) {
				$username = 'code'.$count.'-program'.$count;
			}

			$table = 'mdl_user';
			$data = [
				'username' 	=> $username,
				'firstname'	=> 'name'.$count,
				'lastname'	=> 'lastname'.$count,
				'email'		=> 'email'.$count.'@correounivalle.edu.co', //desarrollo-ases
				'password'	=> '$2y$10$LwvOW/um9fFEIrOhVT/W8OYzhOvv2sVvdr9bcndkhoJtJomOIhnBy',
				'picture'	=> 0,
				'idnumber'	=> $username,
				'yahoo'		=> '',
				'aim'		=> '',
				'msn'		=> '',
				'phone1' 	=> '',
				'phone2'	=> '',
				'lastip'	=> '',
				'description' => ''
			];
			$cond = ['id'=>$row[0]];
			updateOneRow($conn, $table, $data, $cond);
			$count ++;
		}
		pg_close($conn);

		echo 'Users updated <br>';
	}

	/*
	 * Get a question and update its fields
	 * @return boolean
	 */
	function updateQuestions(){
		$conn = connection();
		$questions = pg_query($conn, "SELECT id, name FROM mdl_question WHERE id > 862277 ORDER BY id");
		if (!$questions) {  
			echo "Error al consultar preguntas.\n";  
			exit;  
		}

		echo 'Update questions has started <br>';
		$count = 401761;
		while ($row = pg_fetch_row($questions)) {  

			echo '-- Updating question '.$row[1].'<br>';

			$table = 'mdl_question';
			$data = [
				'name' 	=> 'Question'.$count,
				'questiontext'	=> 'Statement of Question'.$count
			];
			$cond = ['id'=>$row[0]];
			updateOneRow($conn, $table, $data, $cond);
			$count ++;
		}
		pg_close($conn);

		echo 'Questions updated <br>';
	}

	//updateUsers();
	updateQuestions();

?>