Localization.define('de_DE') do |l|

  # Main menu
  l.store "Overview", "Überblick"
  l.store "Tutorial", "Einführung"
  l.store "Browse", "Durchsuchen"
  l.store "Timeline", "Verlauf"
  l.store "Files", "Dateien"
  l.store "Reports", "Berichte"
  l.store "Schedule", "Plan"
  l.store "New Task", "Neue Aufgabe"
  l.store "Preferences", "Einstellungen"
  l.store "Log Out", "Verlassen"
  l.store "Clients", "Kunden"
  l.store "Client", "Kunde"
  l.store 'Search', 'Suche'
  l.store 'Users', 'Benutzer'
  l.store 'User', 'Benutzer'

  # Main layout
  l.store 'Hide', 'Verstecken'
  l.store 'Views', 'Ansichten'
  l.store 'Open Tasks', 'Unerledigte Aufgaben'
  l.store 'My Open Tasks', 'Meine unerledigten Aufgaben'
  l.store 'My In Progress Tasks', 'Meine im Moment bearbeiteten Aufgaben'
  l.store 'Unassigned Tasks', 'Nicht zugewiesene Aufgaben'
  l.store 'Shared', 'Geteilt'
  l.store 'Edit', 'Bearbeiten'
  l.store 'New', 'Neu'
  l.store 'Chat', 'Unterhaltung'
  l.store 'Notes', 'Bemerkungen'
  l.store 'Feedback? Suggestions? Ideas? Bugs?', 'Rückmeldungen? Vorschläge? Ideen? Fehler?'
  l.store 'Let me know', 'Laß es mich wissen'
  l.store 'worked today', 'heute gearbeitet'
  l.store 'Online', 'anwesend'
  l.store 'Done working on <b>%s</b> for now.', 'Momentan mit Bearbeitung von <b>%s</b> fertig ' # %s = @task.name
  l.store '%s ago', 'vor %s'  # X days ago -> Vor X Tagen

  # Application Helper
  l.store 'today','heute'
  l.store 'tomorrow', 'morgen'
  l.store '%d day', ['ein Tag', '%d Tagen']
  l.store '%d week', ['eine Woche', '%d Wochen']
  l.store '%d month', ['ein Monat', '%d Monate']
  l.store 'yesterday', 'gestern'
  l.store '%d day ago', ['vor einem Tag', 'vor %d Tagen']
  l.store '%d week ago', ['vor einer Woche', 'vor %d Wochen']
  l.store '%d month ago', ['vor einem Monat', 'vor %d Monaten']

  # DateHelper
  l.store 'less than a minute', 'weniger als eine Minute'
  l.store '%d minute', ['eine Minute', '%d Minuten']
  l.store 'less than %d seconds', 'weniger als %d Sekunden'
  l.store 'half a minute', 'eine halbe Minute'
  l.store 'about %d hour', ['zirka eine Stunde', 'zirka %d Stunden']


  # Activities
  l.store 'Top Tasks', 'Wichtigste Aufgaben'
  l.store 'Newest Tasks', 'Neueste Aufgaben'
  l.store 'Recent Activities', 'Jüngste Aktivitäten'
  l.store 'Projects', 'Projekte'
  l.store 'Overall Progress', 'Gesamtfortschritt'
  l.store '%d completed milestone', ['ein abgeschlossener Meilenstein', '%d abgeschlossene Meilensteine']
  l.store '%d completed project', ['ein abgeschlossenes Projekt', '%d abgeschlossene Projekte']
  l.store 'Edit project <b>%s</b>', 'Projekt <b>%s</b> bearbeiten'
  l.store 'Edit milestone <b>%s</b>', 'Meilenstein <b>%s</b> bearbeiten'

  # Tasks
  l.store 'Tasks', 'Aufgaben'
  l.store '[Any Client]', '[Alle Kunden]'
  l.store '[Any Project]', '[Alle Projekte]'
  l.store '[Any User]', '[Alle Benutzer]'
  l.store '[Any Milestone]', '[Alle Meilensteine]'
  l.store '[Any Status]', '[Alle Stati]'
  l.store '[Unassigned]','[Nicht zugewiesen]'
  l.store 'Open', 'Öffnen' # unclear: verb or adjective, here: verb
  l.store 'In Progress', 'In Bearbeitung'
  l.store 'Closed', 'Geschlossen'
  l.store 'Won\'t Fix', 'Wird nicht korrigiert'
  l.store 'Invalid', 'Ungültig'
  l.store 'Duplicate', 'Duplikat'
  l.store 'Archived', 'Archiviert'
  l.store 'Group Tags', 'Kennzeichen gruppieren'
  l.store '[Save as View]', '[Als Ansicht speichern]'
  l.store 'Tags', 'Kennzeichen'
  l.store '[All Tags]', '[Alle Kennzeichen]'
  l.store 'Close <b>%s</b>', '<b>%s</b> schließen'
  l.store "Stop working on <b>%s</b>.", 'Bearbeitung von <b>%s</b> beenden.'
  l.store "Start working on <b>%s</b>. Click again when done.", 'Bearbeitung von <b>%s</b> beginnen. Nochmals anklicken, wenn fertig.'
  l.store 'No one', 'Niemand'
  l.store "Revert <b>%s</b> to not completed status.", '<b>%s</b> auf Nicht Abgeschlossen zurückversetzen.'
  l.store "Cancel working on <b>%s</b>.", 'Bearbeitung von<b>%s</b> abbrechen.'
  l.store "Move <b>%s</b> to the Archive.", '<b>%s</b> im Archiv ablegen'
  l.store "Restore <b>%s</b> from the Archive.", '<b>%s</b> aus dem Archiv holen.'
  l.store 'Information', 'Information'
  l.store 'Summary', 'Zusammenfassung'
  l.store 'Description', 'Beschreibung'
  l.store 'Comment', 'Kommentar'
  l.store 'Attach file', 'Datei anhängen'
  l.store 'Target', 'Ziel'
  l.store 'Project', 'Projekt'
  l.store 'Milestone', 'Meilenstein'
  l.store '[None]', '[Kein]'
  l.store 'Assigned To', 'Zugewiesen an'
  l.store 'Requested By', 'Angefordert von'
  l.store 'Attributes', 'Attribute'

  l.store 'Type', 'Typ'
  l.store 'Priority', 'Priorität'
  l.store 'Severity', 'Schweregrad'
  l.store 'Time Estimate', 'Geschätzte Zeit'
  l.store 'Due Date', 'Abgabetermin'
  l.store 'Show Calendar', 'Kalender anzeigen'
  l.store 'Notification', 'Benachrichtigung'
  l.store "Additional people to be notified on task changes<br />in addition to creator and asignee.<br/><br/>Ctrl-click to toggle.", 'Andere über Änderungen an Aufgaben<br/>zusätzlich zu Urheber und Beauftragtem zu<br/>benachrichtigende Personen.<br/><br/>Strg-Mausklick zum Auswählen.'
  l.store 'To:', 'An:'
  l.store '[Delete]', '[Löschen]'
  l.store 'Really delete %s?', '%s? wirklich löschen?'
  l.store 'New Task', 'Neue Aufgabe'
  l.store 'Create', 'Anlegen'
  l.store 'Send notification emails', 'Benachrichtigungs-E-Mail verschicken'
  l.store 'Created', 'Angelegt'
  l.store 'by', 'von' # Created by
  l.store 'Last Updated', 'Zuletzt aktualisiert'
  l.store 'Save', 'Speichern'
  l.store 'and', 'und' # Save and ...

  l.store "Leave Open",'Offen lassen'
  l.store "Revert to Open",'Auf \'Offen\' zurückversetzen'
  l.store "Set in Progress",'\'In Bearbeitung\' versetzen'
  l.store "Leave as in Progress",'\'In Bearbeitung\' belassen'
  l.store "Close",'Abschließen'
  l.store "Leave Closed",'Abgeschlossen lassen'
  l.store "Set as Won't Fix",'Auf \'Wird nicht korrigiert\' setzen'
  l.store "Leave as Won't Fix",'Als \'Wird nicht korrigiert\' lassen'
  l.store "Set as Invalid",'Auf \'ungültig\' setzen'
  l.store "Leave as Invalid",'Als \'ungültig\' lassen'
  l.store "Set as Duplicate",'Auf \'Duplikat\' setzen'
  l.store "Leave as Duplicate",'Als \'Duplikat\' lassen'
  l.store 'History', 'Verlauf'
  l.store 'Edit Log Entry', 'Berichtseintrag bearbeiten'
  l.store 'Delete Log Entry', 'Berichtseintrag löschen'
  l.store 'Really delete this log entry?', 'Diesen Berichtseintrag wirklich löschen?'

  l.store 'Task', 'Aufgabe'
  l.store 'New Feature', 'Neue Funktionalität'
  l.store 'Defect', 'Fehler'
  l.store 'Improvement', 'Verbesserungsvorschlag'
  l.store 'Critical', 'Kritisch'
  l.store 'Urgent', 'Dringend'
  l.store 'High', 'Hoch'
  l.store 'Normal', 'Normal'
  l.store 'Low', 'Niedrig'
  l.store 'Lowest', 'Niedrigst'
  l.store 'Blocker', 'Blockierer' # Conditio sine qua non
  l.store 'Major', 'Größer'         # r.p.i.t.a
  l.store 'Minor', 'Kleiner'        # p.i.t.a
  l.store 'Trivial', 'Trivial'

  l.store 'Start', 'Start'
  l.store 'Duration Worked', 'Arbeitsdauer'

  # Timeline
  l.store '[All Time]', '[Ganze Zeit]'
  l.store 'This Week', 'Diese Woche'
  l.store 'Last Week', 'Letzte Woche'
  l.store 'This Month', 'Dieser Monat'
  l.store 'Last Month', 'Letzter Monat'
  l.store 'This Year', 'Dieses Jahr'
  l.store 'Last Year', 'Letztes Jahr'
  l.store '[Any Type]', '[Alle Typen]'
  l.store 'Work Log', 'Arbeitsprotokoll'
  l.store 'Status Change', 'Zustandswechsel'
  l.store 'Modified', 'Abgeändert'
  l.store '[Prev]', '[Vorherige]' # [Prev] 100 of 2000 entries [Next]
  l.store '[Next]', '[Nächste]' # [Prev] 100 of 2000 entries [Next]
  l.store 'of', 'von' # 100 of 2000 entries
  l.store 'entries..', 'Einträgen..' # 100 of 2000 entries

  # Project Files
  l.store 'Download', 'Herunterladen'
  l.store 'Delete', 'Löschen'
  l.store '[New File]', '[Neue Datei]'
  l.store 'File', ['Datei', 'Dateien']
  l.store 'Upload New File', 'Neue Datei hochladen'
  l.store 'Name', 'Name'
  l.store 'Upload', 'Hochladen'

  # Reports
  l.store 'Download CSV file of this report', 'CSV-Datei dieses Berichts herunterladen.'
  l.store 'Total', 'Gesamtsumme' # total in the sense of complete or sum of everything?
  l.store 'Report Configuration', 'Berichtseinstellungen'
  l.store 'Report Type', 'Berichtstyp'
  l.store 'Pivot', 'Pivot'  # Pivot means Drehpunkt, but there is no "Drehpunkttabelle" in German language.
  l.store 'Audit', 'Überprüfung'
  l.store 'Time Sheet', 'Arbeitszeitnachweis'
  l.store 'Time Range', 'Zeitfenster'
  l.store 'Custom', 'Selbstdefiniert'
  l.store 'Rows', 'Zeile'
  l.store 'Columns', 'Spalten'
  l.store "Milestones", 'Meilensteine'
  l.store "Date", 'Datum'
  l.store 'Task Status', 'Aufgabenstatus'
  l.store "Task Type", 'Aufgabentyp'
  l.store "Task Priority", 'Priorität der Aufgabe'
  l.store "Task Severity", 'Schweregrad der Aufgabe'
  l.store 'From', 'Von' # From Date
  l.store 'To', 'Bis' # To Date
  l.store 'Sub-totals', 'Zwischensummen'
  l.store 'Filter', 'Filtern'
  l.store 'Advanced Options', 'Erweiterte Einstellungen'
  l.store 'Status', 'Status'
  l.store 'Run Report', 'Bericht abrufen'

  # Schedule

  # Search
  l.store 'Search Results', 'Suchresultate'
  l.store 'Activities', 'Aktivitäten'

  # Project list
  l.store 'Read', 'Lesen'
  l.store 'Work', 'Arbeiten'
  l.store 'Assign', 'Zuweisen'
  l.store 'Prioritize', 'Priorisieren'
  l.store 'Grant', 'Gewähren'  #
  l.store "Remove all access for <b>%s</b>?", 'Gesamten Zugriff für <b>%s</b> entziehen?'
  l.store "Grant %s access for <b>%s</b>?", '%s Zugriff gewähren für <b>%s</b>?'
  l.store "Can't remove <b>yourself</b> or the <b>project creator</b>!", 'Man kann weder <b>sich selbst</b> noch <b>den Projekturheber</b> entfernen!'
  l.store "Grant access to <b>%s</b>?", 'Zugriff gewähren für <b>%s</b>?'
  l.store 'Edit Project', 'Projekt bearbeiten'
  l.store 'Delete Project', 'Projekt löschen'
  l.store 'Complete Project', 'Projekt abschließen'
  l.store 'New Milestone', 'Neuer Meilenstein'
  l.store 'Access To Project', 'Zugriff auf Projekt'
  l.store 'Completed', 'Abgeschlossen'
  l.store 'Completed Projects', 'Abgeschlossene Projekte'
  l.store 'Revert', 'Zurückversetzen'
  l.store 'Really revert %s?', '%s wirklich zurückversetzen?'

  # Milestones
  l.store 'Owner', 'Eigentümer'
  l.store 'Edit Milestone', 'Meilenstein bearbeiten'
  l.store 'Delete Milestone', 'Meilenstein löschen'
  l.store 'Complete Milestone', 'Meilenstein abschließen'
  l.store 'Completed Milestones', 'Abgeschlossene Meilensteine'

  # Users
  l.store 'Email', 'E-Mail'
  l.store 'Last Login', 'Letzte Anwesenheit'
  l.store 'Offline', 'Abwesend'
  l.store 'Are your sure?', 'Bist Du Dir sicher?'
  l.store 'Company', 'Firma'
  l.store '[New User]', '[Neuer Benutzer]'
  l.store '[Previous page]', '[Vorherige Seite]'
  l.store '[Next page]', '[Nächste Seite]'
  l.store 'Edit User', 'Benutzer bearbeiten'

  l.store 'Options', 'Optionen'
  l.store 'Location', 'Ort'
  l.store 'Administrator', 'Administrator'
  l.store 'Track Time', 'Zeit verfolgen'
  l.store 'Use External Clients', 'Externe Kunden benutzen'
  l.store 'Show Calendar', 'Kalender anzeigen'
  l.store 'Show Tooltips', 'Kurzinfos anzeigen'
  l.store 'Send Notifications', 'Benachrichtigungen versenden'
  l.store 'Receive Notifications', 'Benachrichtigungen empfangen'

  l.store 'User Information', 'Benutzerinformation'
  l.store 'Username', 'Benutzername'
  l.store 'Password', 'Passwort'

  # Preferences
  l.store 'Preferences', 'Einstellungen'
  l.store 'Language', 'Sprache'
  l.store 'Time Format', 'Zeitformat'
  l.store 'Date Format', 'Datumsformat'
  l.store 'Custom Logo', 'Selbstdefiniertes Markenzeichen'
  l.store 'Current logo', 'Gegenwärtiges Markenzeichen'
  l.store 'New logo', 'Neues Markenzeichen'
  l.store "(250x50px should look good. The logo will be shown up top instead of the ClockingIT one, and on your login page.)", "(250x50px sollte gut aussehen. Das Markenzeichen wird anstatt dem von clockingit.com zuoberst auf jeder Seite angezeigt.)"

  # Notes / Pages
  l.store 'Body', 'Inhalt'
  l.store 'Preview', 'Voransicht'
  l.store 'New Note', 'Neue Bemerkung'
  l.store 'Edit Note', 'Bemerkung bearbeiten'

  # Views
  l.store 'New View', 'Neue Ansicht'
  l.store 'Edit View', 'Ansicht bearbeiten'
  l.store 'Delete View', 'Ansicht löschen'
  l.store '[Active Users]', '[Aktive Benutzer]'
  l.store 'Shared', 'Geteilt'

  # Clients
  l.store 'Contact', 'Kontakt'
  l.store '[New Client]', '[Neuer Kunde]'
  l.store 'Contact email', 'E-Mail des Kontaktes'
  l.store 'Contact name', 'Name des Kontaktes'
  l.store 'Client CSS', 'Kunden-CSS'

  # Activities Controller
  l.store 'Tutorial completed. It will no longer be shown in the menu.', 'Einführung abgeschlossen. Sie wird nicht mehr im Menü angezeigt.'
  l.store 'Tutorial hidden. It will no longer be shown in the menu.', 'Einführung verborgen. Sie wird nicht mehr im Menü angezeigt.'

  # Customers Controller
  l.store 'Client was successfully created.', 'Kunde wurde erfolgreich angelegt.'
  l.store 'Client was successfully updated.', 'Kunde wurde erfolgreich aktualisiert.'
  l.store 'Please delete all projects for %s before deleting it.', 'Bitte vor dem Löschen von %s all dessen Projekte löschen.'
  l.store "You can't delete your own company.", 'Die eigene Firma kann nicht gelöscht werden.'
  l.store 'CSS successfully uploaded.', 'CSS erfolgreich hochgeladen.'
  l.store 'Logo successfully uploaded.', 'Markenzeichen erfolgreich hochgeladen.'

  # Milestones Controller
  l.store 'Milestone was successfully created.', 'Meilenstein erfolgreich angelegt.'
  l.store 'Milestone was successfully updated.', 'Meilenstein erfolgreich aktualisiert.'
  l.store '%s / %s completed.', '%s / %s abgeschlossen.' # Project name / Milestone name completed.
  l.store '%s / %s reverted.', '%s / %s zurückversetzt.' # Project name / Milestone name reverted.

  # Pages / Notes Controller
  l.store 'Note was successfully created.', 'Bemerkung wurde erfolgreich angelegt.'
  l.store 'Note was successfully updated.', 'Bemerkung wurde erfolgreich aktualisiert.'

  # Project Files Controller
  l.store 'No file selected for upload.', 'Keine Datei zum Hochladen ausgewählt.'
  l.store 'File too big.', 'Datei ist zu groß.'
  l.store 'File successfully uploaded.', 'Datei erfolgreich hochgeladen.'

  # Projects Controller
  l.store 'Project was successfully created.', 'Projekt wurde erfolgreich angelegt.'
  l.store 'Project was successfully created. Add users who need access to this project.', 'Projekt wurde erfolgreich angelegt. Füge Benutzer hinzu, die Zugriff auf dieses Projekt benötigen.'
  l.store 'Project was successfully updated.', 'Projekt wurde erfolgreich aktualisiert.'
  l.store 'Project was deleted.', 'Projekt wurde gelöscht.'
  l.store '%s completed.', '%s abgeschlossen.'
  l.store '%s reverted.', '%s zurückversetzt.'

  # Reports Controller
  l.store "Empty report, log more work!", 'Bericht ist leer, bitte mehr Arbeit aufschreiben!'

  # Tasks Controller
  l.store "You need to create a project to hold your tasks, or get access to create tasks in an existing project...", 'Du mußt ein Projekt anlegen, welches deine Aufgaben verwaltet, oder dich um Zugriff auf ein existierendes Projekt bemühen, um Aufgaben anzulegen...'
  l.store 'Invalid due date ignored.', 'Abgabetermin wurde wegen Ungültigkeit ignoriert.'
  l.store 'Task was successfully created.', 'Aufgabe wurde erfolgreich angelegt.'
  l.store 'Task was successfully updated.', 'Aufgabe wurde erfolgreich aktualisiert.'
  l.store 'Log entry saved...', 'Protokolleintrag wurde gespeichert...'
  l.store "Unable to save log entry...", 'Protokolleintrag wurde <b>nicht</b> gespeichert...'
  l.store "Log entry already saved from another browser instance.", 'Protokolleintrag wurde schon von einer anderen Browser-Instanz gespeichert.'
  l.store 'Log entry deleted...', 'Protokolleintrag wurde gelöscht...'

  # Users Controller
  l.store 'User was successfully created. Remeber to give this user access to needed projects.', 'Benutzer wurde erfolgreich angelegt. Bitte nicht vergessen, dem Benutzer Zugriff auf die gewünschten Projekte zu gewähren.'
  l.store "Error sending creation email. Account still created.", 'Fehler beim Versenden der Benutzeranlage-E-Mail. Der Benutzer wurde trotzdem angelegt.'
  l.store 'User was successfully updated.', 'Benutzer wurde erfolgreich aktualisiert.'
  l.store 'Preferences successfully updated.', 'Einstellungen wurden erfolgreich aktualisiert.'

  # Views Controller
  l.store "View '%s' was successfully created.", "Ansicht '%s' wurde erfolgreich angelegt."
  l.store "View '%s' was successfully updated.", "Ansicht '%s' wurde erfolgreich aktualisiert."
  l.store "View '%s' was deleted.", "Ansicht '%s' wurde gelöscht."

  # Reports
  l.store 'Today','Heute'
  l.store 'Week', 'Woche'

  # Dates
  l.store 'January', 'Januar'
  l.store 'February', 'Februar'
  l.store 'March', 'März'
  l.store 'April', 'April'
  l.store 'May', 'Mai'
  l.store 'June', 'Juni'
  l.store 'July', 'Juli'
  l.store 'August', 'August'
  l.store 'September', 'September'
  l.store 'October', 'Oktober'
  l.store 'November', 'November'
  l.store 'December', 'Dezember'

  l.store 'Jan', 'Jan'
  l.store 'Feb', 'Feb'
  l.store 'Mar', 'Mrz'
  l.store 'Apr', 'Apr'
  l.store 'May', 'Mai'
  l.store 'Jun', 'Jun'
  l.store 'Jul', 'Jul'
  l.store 'Aug', 'Aug'
  l.store 'Sep', 'Sep'
  l.store 'Oct', 'Okt'
  l.store 'Nov', 'Nov'
  l.store 'Dec', 'Dez'

  l.store 'Sunday', 'Sonntag'
  l.store 'Monday', 'Montag'
  l.store 'Tuesday', 'Dienstag'
  l.store 'Wednesday', 'Mittwoch'
  l.store 'Thursday', 'Donnerstag'
  l.store 'Friday', 'Freitag'
  l.store 'Saturday', 'Samstag'

  l.store 'Sun', 'So'
  l.store 'Mon', 'Mo'
  l.store 'Tue', 'Di'
  l.store 'Wed', 'Mi'
  l.store 'Thu', 'Do'
  l.store 'Fri', 'Fr'
  l.store 'Sat', 'Sa'

  # worked_nice
  l.store '[wdhm]', '[wtsm]'
  l.store 'w', 'w'
  l.store 'd', 't'
  l.store 'h', 's'
  l.store 'm', 'm'

  # Preferences
  l.store 'Duration Format', 'Zeitdauer-Format'
  l.store 'Workday Length', 'Arbeitstag-Länge'

  # Tasks filter
  l.store '[Without Milestone]', '[Ohne Meilenstein]'

  # Task tooltip
  l.store 'Progress', 'Fortschritt'

  # User Permissions
  l.store 'All', 'Alle'

  # Reports filter
  l.store '[Any Priority]', '[Alle Prioritäten]'
  l.store '[Any Severity]', '[Alle Schweregrade]'

  # Preferences
  l.store '1w 2d 3h 4m', '1w 2t 3s 4m'
  l.store '1w2d3h4m', '1w2t3s4m'

  # Task
  l.store 'Attachments', 'Anhänge'
  l.store 'Dependencies', 'Abhängigkeiten'
  l.store 'Add another dependency', "Weitere Abhängigkeit hinzufügen"
  l.store 'Remove dependency', 'Abhängigkeit entfernen'
  l.store 'every', 'jeden' # every thursday
  l.store '[Any Task]', '[Jede Aufgabe]'

  l.store 'day', 'Tag' #every day
  l.store 'days', 'Tage' #every 2 days
  l.store 'last', 'letzten' #every last thursday

  l.store 'Hide Waiting Tasks', 'Verstecke wartende Aufgaben'
  l.store 'Signup Message', 'Anmeldenachricht'
  l.store 'The message will be included in the signup email.', 'Diese Nachricht wird in die Anmelde-E-Mail eingefügt.'
  l.store 'Depends on', 'Hängt ab von'

  # Activities
  l.store 'Subscribe to the recent activities RSS feed', 'Abonniere RSS-Feed für neueste Aktivitäten'

  # Project Files
  l.store '%d folder', ['%d Verzeichnis, %d Verzeichnisse']
  l.store '%d file', ['%d Datei', '%d Dateien']
end
