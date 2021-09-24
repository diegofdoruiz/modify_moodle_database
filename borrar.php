<?php 

	function connection1(){
		$dbconn = pg_connect("host=192.168.1.46 port=5432 dbname=moodle user=moodle password=moodle");  
		if (!$dbconn){  
			return NULL;  
		}else{  
			return $dbconn;
		} 
	}

	function connection2(){
		$dbconn = pg_connect("host=192.168.1.46 port=5432 dbname=moodle_ases user=moodle password=moodle");  
		if (!$dbconn){  
			return NULL;  
		}else{  
			return $dbconn;
		} 
	}


	function restoreCourses(){
		$conn1 = connection1();
		$conn2 = connection2();
		$old_courses = pg_query($conn1, "SELECT id, fullname, shortname, idnumber, summary FROM mdl_course ORDER BY id");
		if (!$old_courses) {  
			echo "Error al consultar usuarios.\n";  
			exit;  
		}

		while ($row = pg_fetch_row($old_courses)) {
			$data = [
				'fullname'	=> $row[1],
				'shortname'	=> $row[2],
				'idnumber'		=> $row[3], //desarrollo-ases
				'summary'	=> $row[4]
			];
			$cond = ['id'=>$row[0]];
			$result = pg_update($conn2, 'mdl_course', $data, $cond);
			if (!$result) {
				echo '-- NOT Updated course '.$row[0].' - '.$row[1].' '.$row[2].'<br>';
				die("PG Error: " . pg_result_error($result));
			}else{
				echo '-- Updated course '.$row[0].' - '.$row[1].' '.$row[2].'<br>';
			}
		}
	}

	restoreCourses();
?>