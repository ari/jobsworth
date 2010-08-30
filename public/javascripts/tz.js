//MES- We want to automatically detect what timezone a user is in.  In a web application,
// the timezone of the user is not easily available.  However, we do have a clue.
// The JavaScript function Date.getTimezoneOffset() returns the offset from UTC for 
// a given date (in minutes.)  If we ask for the offset for a number of different
// times, we can guess the timezone that the user is in.  This method is not perfect
// but should result in a timezone that is a pretty good guess.
// For our "probe" times, we get the offset for June 30, 2005 and for December 30, 2005.
// June 30 is likely to be affected by Daylight Savings Time for a user that is in a zone
// that has a DST offset, and December 30 is unlikely to be affected by DST (or the opposite
// in the southern hemisphere.)  Probing both of these times gives us a good guess as to 
// what the "normal" offset and DST offsets are for the timezone.
// Choosing recent dates (at the time of this writing) assures that we are up-to-date with
// regard to political decisions regarding the definitions of timezones (though this 
// information may well be out of date in the future.
//
// To convert the offsets to a timezone, we need a list of "standard" timezones.
// It'd be nice to run through a canonical list of timezones (such as
// TZInfo::Timezones.all_country_zones), and probe each for the offset for the above stated
// dates.  This has a couple of problems.  First, it could be quite slow, since calculating the
// offset for a timezone for a date can take some time.  Second, there will be repeat entries
// (i.e. multiple timezones that have the same offset for the two dates), and we want 
// a semi-intelligent way to differentiate between them.  Third, it's server-side.
//
// We deal with these problems by developing a separate canonical list, represented in 
// get_tz_name below.  It simply maps two numbers to a timezone name (well, it's
// actually an array of objects, each of which contains the offsets and the name.)
//
// The get_tz_name list was created via these steps:
// 1. Translate all items in TZInfo::Timezone.all into TZOffsetInfo objects (i.e. extract
//   the name, summer offset, and winter offset for the days mentioned above)
// 2. Order the items by offset (summer offset, then winter offset)
// 3. Calculate the "popularity" of each timezone.  When multiple timezones match
//   a given pair of offsets, we want to return the most likely match for the
//   user, which is assumed to be the most popular (i.e. widely used) timezone
//   that matches.  To assess popularity, a Google search is conducted for the
//   name of each timezone (or, more precisely, for the text 'zone "[timezone name]"').
//   The number of Google hits is assumed to roughly correlate to the popularity of
//   the timezone.
// 4. Among all timezones for an offset pair, choose the most popular timezone- this
//   will be the match for that offset pair.
//
// All of this logic was performed in Ruby code (see the additions to TZInfo::Timezone in 
// application_helper.rb), and then converted to JavaScript for use in the client.

function get_tz_name() {
	so = -1 * (new Date(Date.UTC(2005, 6, 30, 0, 0, 0, 0))).getTimezoneOffset();
	wo = -1 * (new Date(Date.UTC(2005, 12, 30, 0, 0, 0, 0))).getTimezoneOffset();
	
	if (-660 == so && -660 == wo) return 'Pacific/Midway';
	if (-600 == so && -600 == wo) return 'Pacific/Tahiti';
	if (-570 == so && -570 == wo) return 'Pacific/Marquesas';
	if (-540 == so && -600 == wo) return 'America/Adak';
	if (-540 == so && -540 == wo) return 'Pacific/Gambier';
	if (-480 == so && -540 == wo) return 'America/Anchorage';
	if (-480 == so && -480 == wo) return 'Pacific/Pitcairn';
	if (-420 == so && -480 == wo) return 'America/Los_Angeles';
	if (-420 == so && -420 == wo) return 'America/Phoenix';
	if (-360 == so && -420 == wo) return 'America/Denver';
	if (-360 == so && -360 == wo) return 'America/Guatemala';
	if (-360 == so && -300 == wo) return 'Pacific/Easter';
	if (-300 == so && -360 == wo) return 'America/Chicago';
	if (-300 == so && -300 == wo) return 'America/Panama';
	if (-240 == so && -300 == wo) return 'America/New_York';
	if (-240 == so && -240 == wo) return 'America/Guyana';
	if (-240 == so && -180 == wo) return 'America/Santiago';
	if (-180 == so && -240 == wo) return 'America/Halifax';
	if (-180 == so && -180 == wo) return 'America/Montevideo';
	if (-180 == so && -120 == wo) return 'America/Sao_Paulo';
	if (-150 == so && -210 == wo) return 'America/St_Johns';
	if (-120 == so && -180 == wo) return 'America/Godthab';
	if (-120 == so && -120 == wo) return 'America/Noronha';
	if (-60 == so && -60 == wo) return 'Atlantic/Cape_Verde';
	if (0 == so && -60 == wo) return 'Atlantic/Azores';
	if (0 == so && 0 == wo) return 'Africa/Bamako';
	if (60 == so && 0 == wo) return 'Europe/London';
	if (60 == so && 60 == wo) return 'Africa/Algiers';
	if (60 == so && 120 == wo) return 'Africa/Windhoek';
	if (120 == so && 60 == wo) return 'Europe/Amsterdam';
	if (120 == so && 120 == wo) return 'Africa/Johannesburg';
	if (180 == so && 120 == wo) return 'Asia/Beirut';
	if (180 == so && 180 == wo) return 'Africa/Nairobi';
	if (240 == so && 180 == wo) return 'Europe/Moscow';
	if (240 == so && 240 == wo) return 'Asia/Dubai';
	if (270 == so && 210 == wo) return 'Asia/Tehran';
	if (270 == so && 270 == wo) return 'Asia/Kabul';
	if (300 == so && 240 == wo) return 'Asia/Yerevan';
	if (300 == so && 300 == wo) return 'Asia/Tashkent';
	if (330 == so && 330 == wo) return 'Asia/Calcutta';
	if (345 == so && 345 == wo) return 'Asia/Katmandu';
	if (360 == so && 300 == wo) return 'Asia/Yekaterinburg';
	if (360 == so && 360 == wo) return 'Asia/Colombo';
	if (390 == so && 390 == wo) return 'Asia/Rangoon';
	if (420 == so && 360 == wo) return 'Asia/Novosibirsk';
	if (420 == so && 420 == wo) return 'Asia/Bangkok';
	if (480 == so && 420 == wo) return 'Asia/Krasnoyarsk';
	if (480 == so && 480 == wo) return 'Australia/Perth';
	if (540 == so && 480 == wo) return 'Asia/Irkutsk';
	if (540 == so && 540 == wo) return 'Asia/Tokyo';
	if (570 == so && 570 == wo) return 'Australia/Darwin';
	if (570 == so && 630 == wo) return 'Australia/Adelaide';
	if (600 == so && 540 == wo) return 'Asia/Yakutsk';
	if (600 == so && 600 == wo) return 'Australia/Brisbane';
	if (600 == so && 660 == wo) return 'Australia/Sydney';
	if (630 == so && 660 == wo) return 'Australia/Lord_Howe';
	if (660 == so && 600 == wo) return 'Asia/Vladivostok';
	if (660 == so && 660 == wo) return 'Pacific/Guadalcanal';
	if (690 == so && 690 == wo) return 'Pacific/Norfolk';
	if (720 == so && 660 == wo) return 'Asia/Magadan';
	if (720 == so && 720 == wo) return 'Pacific/Fiji';
	if (720 == so && 780 == wo) return 'Pacific/Auckland';
	if (765 == so && 825 == wo) return 'Pacific/Chatham';
	if (780 == so && 720 == wo) return 'Asia/Kamchatka';
	if (780 == so && 780 == wo) return 'Pacific/Enderbury';
	if (840 == so && 840 == wo) return 'Pacific/Kiritimati';
	
	return 'America/Los_Angeles';
}


// MES- set_select is a tiny helper that takes in the name of a select control
//	and the value of an item to be selected.  It looks for an option in the
//	select with the indicated value.  If found, it selects it and returns true.
//	If the item is not found, returns false.
function set_select(ctrl, val) {
	opts = $(ctrl).options;
	for (var i = 0; i < opts.length; i++) {
		if (val == opts[i].value) {
			opts[i].selected = true;
			return true;
		}
	}
	return false;
}




