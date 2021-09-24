<?php 
	$file = fopen("usernames.txt", "r");
	if ($file) {
		$counter = 0;
	    while (($line = fgets($file)) !== false) {
	        echo "'".trim($line)."',";
	        $counter ++;
	    }

	    fclose($file);
	} else {
	    // error opening the file.
	}
?>