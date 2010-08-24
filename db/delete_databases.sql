drop database clockingit;

REVOKE ALL ON clockingit.* FROM 'clockingit'@'localhost';

drop user 'clockingit'@'localhost';
