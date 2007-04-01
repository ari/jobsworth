CREATE TABLE `binaries` (
  `id` int(11) NOT NULL auto_increment,
  `data` longblob,
  `project_file_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) TYPE=MyISAM;

CREATE TABLE `companies` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(200) NOT NULL default '',
  `contact_email` varchar(200) default NULL,
  `contact_name` varchar(200) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
) TYPE=MyISAM;

CREATE TABLE `customers` (
  `id` int(11) NOT NULL auto_increment,
  `company_id` int(11) NOT NULL default '0',
  `name` varchar(200) NOT NULL default '',
  `contact_email` varchar(200) default NULL,
  `contact_name` varchar(200) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) TYPE=MyISAM;

CREATE TABLE `milestones` (
  `id` int(11) NOT NULL auto_increment,
  `company_id` int(11) default NULL,
  `project_id` int(11) default NULL,
  `user_id` int(11) default NULL,
  `name` varchar(255) default NULL,
  `description` text,
  `due_at` datetime default NULL,
  `position` int(11) default NULL,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

CREATE TABLE `pages` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(200) NOT NULL default '',
  `body` text,
  `company_id` int(11) NOT NULL default '0',
  `user_id` int(11) NOT NULL default '0',
  `project_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `position` int(11) default NULL,
  PRIMARY KEY  (`id`)
) TYPE=MyISAM;

CREATE TABLE `project_files` (
  `id` int(11) NOT NULL auto_increment,
  `company_id` int(11) NOT NULL default '0',
  `project_id` int(11) NOT NULL default '0',
  `customer_id` int(11) NOT NULL default '0',
  `name` varchar(200) NOT NULL default '',
  `binary_id` int(11) NOT NULL default '0',
  `file_type` int(11) NOT NULL default '0',
  `created_at` datetime NOT NULL default '0000-00-00 00:00:00',
  `updated_at` datetime NOT NULL default '0000-00-00 00:00:00',
  `filename` varchar(200) NOT NULL default '',
  `thumbnail_id` int(11) default NULL,
  `file_size` int(11) default NULL,
  PRIMARY KEY  (`id`)
) TYPE=MyISAM;

CREATE TABLE `projects` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(200) NOT NULL default '',
  `user_id` int(11) NOT NULL default '0',
  `company_id` int(11) NOT NULL default '0',
  `customer_id` int(11) NOT NULL default '0',
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) TYPE=MyISAM;

CREATE TABLE `schema_info` (
  `version` int(11) default NULL
) TYPE=MyISAM;

CREATE TABLE `sheets` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) NOT NULL default '0',
  `task_id` int(11) NOT NULL default '0',
  `project_id` int(11) NOT NULL default '0',
  `created_at` datetime default NULL,
  `body` text,
  PRIMARY KEY  (`id`)
) TYPE=MyISAM;

CREATE TABLE `tasks` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(200) NOT NULL default '',
  `project_id` int(11) NOT NULL default '0',
  `user_id` int(11) default '0',
  `position` int(11) NOT NULL default '0',
  `created_at` datetime NOT NULL default '0000-00-00 00:00:00',
  `due_at` datetime default NULL,
  `updated_at` datetime NOT NULL default '0000-00-00 00:00:00',
  `completed_at` datetime default NULL,
  `duration` int(11) default '1',
  `hidden` int(11) default '0',
  `milestone_id` int(11) default NULL,
  `description` text,
  PRIMARY KEY  (`id`)
) TYPE=MyISAM;

CREATE TABLE `thumbnails` (
  `id` int(11) NOT NULL auto_increment,
  `data` blob,
  `project_file_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) TYPE=MyISAM;

CREATE TABLE `users` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(200) NOT NULL default '',
  `username` varchar(200) NOT NULL default '',
  `password` varchar(200) NOT NULL default '',
  `company_id` int(11) NOT NULL default '0',
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `email` varchar(200) default NULL,
  `last_login_at` datetime default NULL,
  `admin` int(11) default '0',
  PRIMARY KEY  (`id`)
) TYPE=MyISAM;

CREATE TABLE `work_logs` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) NOT NULL default '0',
  `task_id` int(11) NOT NULL default '0',
  `project_id` int(11) NOT NULL default '0',
  `company_id` int(11) NOT NULL default '0',
  `customer_id` int(11) NOT NULL default '0',
  `started_at` datetime NOT NULL default '0000-00-00 00:00:00',
  `duration` int(11) NOT NULL default '0',
  `body` text,
  PRIMARY KEY  (`id`)
) TYPE=MyISAM;

