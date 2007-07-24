# Defaults are en_US
#
# Mostly handle the pluralization cases

Localization.define('en_US') do |l|
  l.store '%d completed milestone', ['%d completed milestone', '%d completed milestones']
  l.store '%d completed project', ['%d completed project', '%d completed projects']

  l.store '%d day', ['%d day', '%d days']
  l.store '%d week', ['%d week', '%d weeks']
  l.store '%d month', ['%d month', '%d months']
  l.store '%d day ago', ['%d day ago', '%d days ago']
  l.store '%d week ago', ['%d week ago', '%d weeks ago']
  l.store '%d month ago', ['%d month ago', '%d months ago']

  l.store '%d minute', ['%d minute', '%d minutes']
  l.store 'about %d hour', ['about %d hour', 'about %d hours']

  l.store 'File', ['File', 'Files']
  l.store '%d folder', ['%d folder', '%d folders']
  l.store '%d file', ['%d file', '%d files']
end
