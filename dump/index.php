<?php

	/* filename: index.php
	   author: Chris Stegmaier
	   company: Corodyne Web Services
	   email: c.stegmaier@corodyne.com
	   date: 08/25/2008
	   purpose: this index file is tied to SQL_Export.php and is meant to export
	   		an entire account from a ClockingIT database, version 0.99.3
	*/
	
	/* Instructions
		1. create a folder in your webserver (ex. dbDump)
		2. copy this file and SQL_Export.php to that folder
		3. modify the database connection information below to match your ClockingIT installation
		4. Go to http://yoursite.com/yourfolder/index.php (ex. http://localhost/dbDump/index.php)
	*/
	
	// set initial value for $COMPANYID
	$COMPANYID = -1;
	
	// set the file to force a download of the sql file or display the output to the browser
	$DOWNLOAD = 1; // set to zero to display to the screen
	
	// database connection information (password must be in plain text)
	$server = "localhost:3306";	//Port is not really necessary
	$username = "root";		//Username for MySQL server
	$password = "";			//Password for MySQL server
	$db = "cit";			//Name of database

	//Connect to DB the old fashioned way and get the names of the tables on the server
	$cnx = mysql_connect($server, $username, $password) or die(mysql_error());
	mysql_set_charset('utf8', $cnx) or die(mysql_error());
	mysql_select_db($db, $cnx) or die(mysql_error() . "<p>Database selection problem...</p>");
	$tables = mysql_list_tables($db) or die(mysql_error() . "<p>Table listing problem...</p>");

	//Create a list of tables to be exported
	$table_list = array();
	while($t = mysql_fetch_array($tables))
	{
		// echo "case '{$t[0]}' : break; ".'<br>';
		array_push($table_list, $t[0]);
	}

	$uuid = mysql_real_escape_string($_REQUEST['uuid']);
	// attempt to grab the COMPANYID variable from the user's record in the DB
	if($_REQUEST['uuid']) {
		$result = mysql_query("SET NAMES utf8;",$cnx) or die(mysql_error());

		$query = "SELECT company_id FROM users WHERE uuid = '{$uuid}'";
		$result = mysql_query($query,$cnx) or die(mysql_error() . "<p>Query: $query</p>");
		
		$result_num_rows = mysql_num_rows($result);
		
		if($result_num_rows == 1) {  // only one result should be allowed
			$COMPANYID = mysql_result($result,0);
		} else {
			$COMPANYID = NULL;
		}
	}

	//Instantiate the SQL_Export class
	require("SQL_Export.php");
	$e = new SQL_Export($server, $username, $password, $db, $table_list);


	// if the user requested a download
	if($_REQUEST['uuid'] && $result_num_rows == 1) {	
		// run the export
		if($DOWNLOAD) {
			//Run the export (force a file download)
			$sqlFile = $e->export($COMPANYID);
			// option to create a custom filename here
			$DATE = date("Y-m-d");
			$filename = "ClockingIT-backup-$DATE.sql";
			force_download($sqlFile,"$filename");
		} else {
			//Run the export (to the browser)
			echo '<pre>'.$e->export($COMPANYID).'</pre>';	
		}
	} else {
		echo 'There was some information missing from your request to properly run the script.';
	}

	//Clean up the joint
	mysql_close($e->cnx);
	mysql_close($cnx);
	
//////////////////////////////////////////////////////////
// functions to facilitate the forced download of the data
function force_download ($data, $name) {
    
	// force values
	$mimetype='';
	$filesize=false;
	
	// File size not set?
    if ($filesize == false OR !is_numeric($filesize)) {
        $filesize = strlen($data);
    }

    // Mimetype not set?
    if (empty($mimetype)) {
        $mimetype = 'application/octet-stream';
    }

    // Make sure there's not anything else left
    ob_clean_all();

    // Start sending headers
    header("Pragma: public"); // required
    header("Expires: 0");
    header("Cache-Control: must-revalidate, post-check=0, pre-check=0");
    header("Cache-Control: private",false); // required for certain browsers
    header("Content-Transfer-Encoding: binary");
    header("Content-Type: " . $mimetype);
    header("Content-Length: " . $filesize);
    header("Content-Disposition: attachment; filename=\"" . $name . "\";" );

    // Send data
    echo $data;
    die();
}

function ob_clean_all () {
    $ob_active = ob_get_length () !== false;
    while($ob_active) {
        ob_end_clean();
        $ob_active = ob_get_length () !== false;
    }

    return true;
}

?>
