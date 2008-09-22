<?php

/***************************************************************
 * SQL_Export class
 * Originally by Adam Globus-Hoenich, 2004 (adam@phenaproxima.net)
 * Modifications by Chris Stegmaier, 08/25/2008 (c.stegmaier@corodyne.com)
 	-- added the use of a specific COMPANYID for ClockingIT database
	-- modified the get_data() function to 'outsource' query building
	-- added the form_query() function to create specific queries for each of the ClockingIT tables
 * Purpose: This class is now specifically geared for exporting a ClockingIT (0.99.3) MySQL database.
 * Requirement: The only requirement is that the COMPANYID be passed to the export() function.  Without this information,
   the class will not run and will inform the user that a COMPANYID is required.
***************************************************************/

class SQL_Export
{
	var $cnx;
	var $db;
	var $server;
	var $port;
	var $user;
	var $password;
	var $table;
	var $tables;
	var $exported;

	function SQL_Export($server, $user, $password, $db, $tables)
	{
		$this->db = $db;
		$this->user = $user;
		$this->password = $password;
		
		$sa = explode(":", $server);
		$this->server = $sa[0];
		$this->port = $sa[1];
		unset($sa);

		$this->tables = $tables;

		$this->cnx = mysql_connect($this->server, $this->user, $this->password) or $this->error(mysql_error());
	        mysql_set_charset('utf8', $this->cnx) or die(mysql_error());
		$result = mysql_query("SET NAMES utf8;",$this->cnx) or die(mysql_error());
		mysql_select_db($this->db, $this->cnx) or $this->error(mysql_error());
	}


	function export($companyID = 0)
	{
		// throw the canned message at the top of the export
		$NOW = date("M d Y H:i");
		$this->exported =
		"# Target: MySQL\n# Syntax: mysql -u user -p db_name < filename.sql\n#\n# Date  : $NOW\n#\n/*!40101 SET NAMES utf8 */;\nSET character_set_client = utf8;\n\n";
		
		foreach($this->tables as $t)
		{
			$this->table = $t;
//			 echo "<p>$t</p>";
			$header = $this->create_header();
			// use the companyID here to get the specific data
			$data = $this->get_data($companyID);
//			echo "<pre>$data</pre>";
			$this->exported .= "###################\n# Dumping table $t\n###################\n\n" . $data . "\n";
		}
		
		return($this->exported);
	}

	function create_header()
	{
		$fields = mysql_list_fields($this->db, $this->table, $this->cnx);
		$h = "CREATE TABLE `" . $this->table . "` (";
		
		for($i=0; $i<mysql_num_fields($fields); $i++)
		{
			$name = mysql_field_name($fields, $i);
			$flags = mysql_field_flags($fields, $i);
			$len = mysql_field_len($fields, $i);
			$type = mysql_field_type($fields, $i);

			$h .= "`$name` $type($len) $flags,";

			if(strpos($flags, "primary_key")) {
				$pkey = " PRIMARY KEY (`$name`)";
			}
		}
		
		$h = substr($h, 0, strlen($d) - 1);
		$h .= "$pkey) TYPE=InnoDB;\n\n";
		
		// echo "<p>--- Table data<br>$h</p>";
		return($h);
	}

	function get_data($companyID = 0)
	{
		$d = null;	
		
		// use the $companyID here; set to zero if someone tries to use this function without entering a companyID
		$query = $this->form_query($this->table,$companyID);
		
		/* output the query for testing
		if($query != '')
			echo "<p>SQL Query: $query;</p>";
		*/
		
		// only run the query for data if the query was not empty
		if($query != '') {
			$data = mysql_query($query, $this->cnx) or $this->error(mysql_error() . "<p>Query: $query</p>");
			
			while($cr = mysql_fetch_array($data, MYSQL_NUM))
			{
				$d .= "INSERT INTO `" . $this->table . "` VALUES (";
	
				for($i=0; $i<sizeof($cr); $i++)
				{
					if($cr[$i] === null) {
						$d .= 'NULL,';
					} else {
						$d .= "'" . mysql_real_escape_string($cr[$i]) . "',";
					}
				}
	
				$d = substr($d, 0, strlen($d) - 1);
				$d .= ");\n";
			}
		}
		return($d);
	}

	function error($err)
	{
		die($err);
	}
	
	function form_query($tableName,$companyID) {
		$returnVal = '';
		
		// get the field names for this table
		$fields = mysql_list_fields($this->db, $tableName, $this->cnx);
		for($i=0; $i<mysql_num_fields($fields); $i++) {
			$name = mysql_field_name($fields, $i);
			$tempFields[] = "`$tableName`."."`$name`";
		}
		$fieldList = implode(',',$tempFields);
		// echo '<p>'.$fieldList.'</p>';
		
		// build the most common WHERE strings
		$userID_where = "`$tableName`.`user_id` = `users`.`id` AND `users`.`company_id` = `companies`.`id` AND `companies`.`id` = $companyID";
		$companyID_where = " `company_id` = $companyID";
		$all_where = " 1";
		
		// build the most common FROM strings
		$userID_from = " `$tableName`,`users`,`companies` ";
		$companyID_from = " `$tableName` ";
		$all_from = " `$tableName` ";	// sure it's a little redundant, but it keeps the convention above
		
		// assemble the most common queries
		$companyID_query = "SELECT $fieldList FROM $companyID_from WHERE $companyID_where";
		$userID_query = "SELECT $fieldList FROM $userID_from WHERE $userID_where";
		$all_query = "SELECT $fieldList FROM $all_from WHERE $all_where";
	        $none_query = "SELECT * FROM $all_from WHERE 1=2";	
		// return the appropriate query based on the table name
		// looked at each table and tried to determine whether it used user_id, company_id, or something unique
		switch($tableName) {
			case 'chats' : 				$returnVal = $userID_query; break;
			case 'chat_messages' :		$returnVal = $userID_query; break;
			case 'companies' : 			// unique query below for companyID
										$returnVal = "SELECT $fieldList FROM $all_from WHERE `id` = $companyID"; break;
			case 'customers' : 			$returnVal = $companyID_query; break;
			case 'dependencies' : 		// using the OR below could yield duplicate entries
										// using DISTINCT to prevent duplicate rows
										$returnVal = "SELECT DISTINCT $fieldList FROM `dependencies`,`tasks`
										              WHERE (`dependencies`.`task_id` = `tasks`.`id` AND `tasks`.`company_id` = $companyID)
													   OR (`dependencies`.`dependency_id` = `tasks`.`id` AND `tasks`.`company_id` = $companyID)"; break;
			case 'emails' : 			$returnVal = $companyID_query; break;
			case 'event_logs' : 		$returnVal = $companyID_query; break;
			case 'forums' : 			$returnVal = $companyID_query; break;
			case 'generated_reports' : 	$returnVal = ''; break;
			case 'ical_entries' : 		$returnVal = ''; break;
			case 'locales' : 	        $returnVal = ''; break;	
			case 'logged_exceptions' : 	$returnVal = $all_query; break;
			case 'milestones' : 		$returnVal = $companyID_query; break;
			case 'moderatorships' : 	$returnVal = $userID_query; break;
			case 'monitorships' : 		$returnVal = $userID_query; break;
			case 'news_items' : 		$returnVal = ''; break;
			case 'notifications' : 		$returnVal = $userID_query; break;
			case 'pages' : 				$returnVal = $companyID_query; break;
			case 'posts' : 			$returnVal = "SELECT $fieldList FROM `posts` LEFT JOIN `forums` ON `forums`.`id` = `posts`.`forum_id` WHERE `forums`.`company_id` = $companyID"; break;
			case 'project_files' : 		$returnVal = $companyID_query; break;
			case 'project_folders' : 	$returnVal = $companyID_query; break;
			case 'project_permissions' : $returnVal = $companyID_query; break;
			case 'projects' : 			$returnVal = $companyID_query; break;
			case 'schema_info' : 		$returnVal = ''; break;
			case 'scm_changesets' : 	$returnVal = $companyID_query; break;
			case 'scm_files' : 			$returnVal = $companyID_query; break;
			case 'scm_projects' : 		$returnVal = $companyID_query; break;
			case 'scm_revisions' : 		$returnVal = $companyID_query; break;
			case 'sessions' : 			$returnVal = ''; break;
			case 'sheets' : 			$returnVal = $userID_query; break;
			case 'shout_channel_subscriptions' : $returnVal = $userID_query; break;
			case 'shout_channels' : 	$returnVal = $companyID_query; break;
			case 'shouts' : 			$returnVal = $companyID_query; break;
			case 'tags' : 				$returnVal = $companyID_query; break;
			case 'task_owners' : 		$returnVal = $userID_query; break;
			case 'task_tags' : 			// Here's the logic below
										/* Tasks are created by companies and are only viewed by company 'employees'.  Since
										   it is only company employees creating tags on these tasks, the companyID in the tags table will
										   be the same as the companyID in the tasks table.  It is not neccessary to JOIN the tags table in
										   this query as it will be redundant */
										$returnVal = "SELECT $fieldList FROM `task_tags`,`tasks`
										              WHERE (`task_tags`.`task_id` = `tasks`.`id` AND `tasks`.`company_id` = $companyID)"; break;
			case 'tasks' : 				$returnVal = $companyID_query; break;
			case 'todos' : 				// todos has a creator_id and not a user_id, so we need a custom query here
										// that is, of course, if creator_id refers back to the users table
										$todos_where = "`$tableName`.`creator_id` = `users`.`id` 
														  AND `users`.`company_id` = `companies`.`id` AND `companies`.`id` = $companyID";
										$returnVal = "SELECT $fieldList FROM $userID_from WHERE $todos_where"; break;
			case 'topics' : 			$returnVal = "SELECT $fieldList FROM `topics` LEFT JOIN `forums` ON `forums`.`id` = `topics`.`forum_id` WHERE `forums`.`company_id` = $companyID";break;
			case 'users' : 				$returnVal = $companyID_query; break;
			case 'views' : 				$returnVal = $companyID_query; break;
			case 'widgets' : 			$returnVal = $companyID_query; break;
			case 'wiki_pages' : 		$returnVal = $companyID_query; break;
			case 'wiki_references' : 	// need unique query below
										$returnVal = "SELECT $fieldList FROM `wiki_references`,`wiki_pages`
										              WHERE (`wiki_references`.`wiki_page_id` = `wiki_pages`.`id` AND `wiki_pages`.`company_id` = $companyID)";
										break;
			case 'wiki_revisions' : 	$returnVal = $userID_query; break;
			case 'work_logs' : 			$returnVal = $companyID_query; break; 
		}
		
		// return the query for use
		return $returnVal;
			
	}
	// end of the form_query class
}

?>
