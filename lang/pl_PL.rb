
Localization.define('pl_PL') do |l|

  # Main menu
  l.store "Overview", "Przegląd"
  l.store "Tutorial", "Tutorial"
  l.store "Browse", "Przeglądaj"
  l.store "Timeline", "Linia czasu"
  l.store "Files", "Pliki"
  l.store "Reports", "Raporty"
  l.store "Schedule", "Harmonogram"
  l.store "New Task", "Nowe zadanie"
  l.store "Preferences", "Ustawienia"
  l.store "Log Out", "Wyloguj"
  l.store "Clients", "Klienci"
  l.store "Client", "Klient"
  l.store 'Search', 'Szukaj'
  l.store 'Users', 'Użytkownicy'
  l.store 'User', 'Użytkownik'
  
  # Main layout
  l.store 'Hide', 'Ukryj'
  l.store 'Views', 'Widoki'
  l.store 'Open Tasks', 'Otwarte zadania'
  l.store 'My Open Tasks', 'Moje otwarte zadania'
  l.store 'My In Progress Tasks', 'Moje zadania w toku'
  l.store 'Unassigned Tasks', 'Nieprzypisane zadania'
  l.store 'Shared', 'Współdzielone'
  l.store 'Edit', 'Edytuj'
  l.store 'New', 'Nowy'
  l.store 'Chat', 'Czat'
  l.store 'Notes', 'Notatki'
  l.store 'Feedback? Suggestions? Ideas? Bugs?', 'Opinie? Sugestie? Pomysły? Błędy?'
  l.store 'Let me know', 'Powiadom mnie'
  l.store 'worked today', 'pracowano dzisiaj'
  l.store 'Online', 'Online'
  l.store 'Done working on <b>%s</b> for now.', 'Zakończ pracę nad <b>%s</b>' # %s = @task.name
  l.store '%s ago', '%s temu'  # X days ago -> Vor X Tagen
  
  # Application Helper
  l.store 'today','dziś'
  l.store 'tomorrow', 'jutro'
  l.store '%d day', ['dzień', '%d dni']
  l.store '%d week', ['tydzień', '%d tygodni']
  l.store '%d month', ['miesiąc', '%d miesięcy']
  l.store 'yesterday', 'wczoraj'
  l.store '%d day ago', ['dzień temu', '%d dni temu']
  l.store '%d week ago', ['tydzień temu', '%d tygodni temu']
  l.store '%d month ago', ['w zeszłym miesiącu', '%d miesięcy temu']
  
  # DateHelper
  l.store 'less than a minute', 'mniej niż minuta'
  l.store '%d minute', ['minuta', '%d minut']
  l.store 'less than %d seconds', 'mniej niż %d sekund'
  l.store 'half a minute', 'pół minuty'
  l.store 'about %d hour', ['około godziny', 'około %d godzin']
  
  
  # Activities
  l.store 'Top Tasks', 'Najważniejsze zadania'
  l.store 'Newest Tasks', 'Najnowsze zadania'
  l.store 'Recent Activities', 'Ostatnie działania'
  l.store 'Projects', 'Projekty'
  l.store 'Overall Progress', 'Całkowity postęp'
  l.store '%d completed milestone', ['jeden ukończony Krok', '%d ukończonych Kroków']
  l.store '%d completed project', ['jeden ukończony projekt', '%d ukończonych projektów']
  l.store 'Edit project <b>%s</b>', 'Edytuj projekt <b>%s</b> '
  l.store 'Edit milestone <b>%s</b>', 'Edytuj Krok <b>%s</b>'
  
  # Tasks
  l.store 'Tasks', 'Zadania'
  l.store '[Any Client]', '[Wszyscy klienci]'
  l.store '[Any Project]', '[Wszystkie projekty]'
  l.store '[Any User]', '[Wszyscy użytkownicy]'
  l.store '[Any Milestone]', '[Wszystkie kroki]'
  l.store '[Any Status]', '[Wszystkie statusy]'
  l.store '[Unassigned]','[Nieprzypisane]'
  l.store 'Open', 'Otwórz' # unclear: verb or adjective, here: verb
  l.store 'In Progress', 'W toku'
  l.store 'Closed', 'Zamknięty'
  l.store 'Won\'t Fix', 'Nie naprawiony'
  l.store 'Invalid', 'Nieprawidłowy'
  l.store 'Duplicate', 'Duplikat'
  l.store 'Archived', 'Zarchiwizowany'
  l.store 'Group Tags', 'Grupuj tagi'
  l.store '[Save as View]', '[Zapisz jako widok]'
  l.store 'Tags', 'Tagi'
  l.store '[All Tags]', '[Wszystkie tagi]'
  l.store 'Close <b>%s</b>', 'Zamknij <b>%s</b>'
  l.store "Stop working on <b>%s</b>.", 'Zakończ pracę nad <b>%s</b>.'
  l.store "Start working on <b>%s</b>. Click again when done.", 'Rozpocznij pracę nad <b>%s</b>. Naciśnij jeszcze raz kiedy skończysz.'
  l.store 'No one', 'Żaden'
  l.store "Revert <b>%s</b> to not completed status.", 'Przywróć status <b>%s</b> jako nieukończony.'
  l.store "Cancel working on <b>%s</b>.", 'Anuluj pracę nad <b>%s</b>.'
  l.store "Move <b>%s</b> to the Archive.", 'Przenieś <b>%s</b> do Archiwum'
  l.store "Restore <b>%s</b> from the Archive.", 'Przywróć <b>%s</b> z Archiwum.'
  l.store 'Information', 'Informacja'
  l.store 'Summary', 'Podsumowanie'
  l.store 'Description', 'Opis'
  l.store 'Comment', 'Komentarz'
  l.store 'Attach file', 'Dodaj plik'
  l.store 'Target', 'Cel'
  l.store 'Project', 'Projekt'
  l.store 'Milestone', 'Krok'
  l.store '[None]', '[Brak]'
  l.store 'Assigned To', 'Przypisany do'
  l.store 'Requested By', 'Żądany przez'
  l.store 'Attributes', 'Atrybuty'
  
  l.store 'Type', 'Typ'
  l.store 'Priority', 'Priorytet'
  l.store 'Severity', 'Krytyczność'
  l.store 'Time Estimate', 'Przybliżony czas'
  l.store 'Due Date', 'Data wykonania'
  l.store 'Show Calendar', 'Pokaż kalendarz'
  l.store 'Notification', 'Powiadomienie'
  l.store "Additional people to be notified on task changes<br />in addition to creator and asignee.<br/><br/>Ctrl-click to toggle.", 'Dodatkowe osoby do powiadomienia o zmianach zadania<br />nie licząc twórcy oraz osoby przypisanej do zadania.'
  l.store 'To:', 'Do:'
  l.store '[Delete]', '[Usuń]'
  l.store 'Really delete %s?', 'Na pewno usunąć %s?'
  l.store 'New Task', 'Nowe zadanie'
  l.store 'Create', 'Utwórz'
  l.store 'Send notification emails', 'Wysyłaj email z powiadomieniem'
  l.store 'Created', 'Utworzono'
  l.store 'by', 'przez' # Created by
  l.store 'Last Updated', 'Ostatnio zmodyfikowany'
  l.store 'Save', 'Zapisz'
  l.store 'and', 'i' # Save and ...
  
  l.store "Leave Open",'Pozostaw otwarty'
  l.store "Revert to Open",'Przywróć jako otwarty'
  l.store "Set in Progress",'Ustaw jako <i>W Toku</i>'
  l.store "Leave as in Progress",'Pozostaw <i>W Toku</i>'
  l.store "Close",'Zamknij'
  l.store "Leave Closed",'Pozostaw Zamknięte'
  l.store "Set as Won't Fix",'Ustaw jako Nie Do Naprawienia'
  l.store "Leave as Won't Fix",'Zapisz jako Nie Do Naprawienia'
  l.store "Set as Invalid",'Ustaw jako Nieprawidłowe'
  l.store "Leave as Invalid",'Pozostaw jako Nieprawidłowe'
  l.store "Set as Duplicate",'Ustaw jako Duplikat'
  l.store "Leave as Duplicate",'Pozostaw jako Duplikat'
  l.store 'History', 'Historia'
  l.store 'Edit Log Entry', 'Edytuj wpis logu'
  l.store 'Delete Log Entry', 'Usuń wpis logu'
  l.store 'Really delete this log entry?', 'Czy na pewno usunąć ten wpis ?'
  
  l.store 'Task', 'Zadanie'
  l.store 'New Feature', 'Nowa Cecha'
  l.store 'Defect', 'Problem'
  l.store 'Improvement', 'Poprawka'
  l.store 'Critical', 'Krytyczny'
  l.store 'Urgent', 'Pilny'
  l.store 'High', 'Wysoki'
  l.store 'Normal', 'Normalny'
  l.store 'Low', 'Niski'
  l.store 'Lowest', 'Najniższy'
  l.store 'Blocker', 'Blokujący' # Conditio sine qua non
  l.store 'Major', 'Duży'         # r.p.i.t.a
  l.store 'Minor', 'Mały'        # p.i.t.a
  l.store 'Trivial', 'Trywialny'
  
  l.store 'Start', 'Start'
  l.store 'Duration Worked', 'Czas pracy'
  
  # Timeline
  l.store '[All Time]', '[Wszystkie lata]'
  l.store 'This Week', 'Obecny tydzień'
  l.store 'Last Week', 'Ostatni tydzień'
  l.store 'This Month', 'Obecny miesiąc'
  l.store 'Last Month', 'Ostatni miesiąc'
  l.store 'This Year', 'Obecny rok'
  l.store 'Last Year', 'Ostatni rok'
  l.store '[Any Type]', '[Wszystkie typy]'
  l.store 'Work Log', 'Log pracy'
  l.store 'Status Change', 'Zmiana statusu'
  l.store 'Modified', 'Zmodyfikowany'
  l.store '[Prev]', '[Poprzednie]' # [Prev] 100 of 2000 entries [Next]
  l.store '[Next]', '[Następne]' # [Prev] 100 of 2000 entries [Next]
  l.store 'of', 'z' # 100 of 2000 entries
  l.store 'entries..', 'wpisów..' # 100 of 2000 entries
  
  # Project Files
  l.store 'Download', 'Pobierz'
  l.store 'Delete', 'Usuń'
  l.store '[New File]', '[Nowy plik]'
  l.store 'File', ['Plik', 'Pliki']
  l.store 'Upload New File', 'Wyślij nowy plik'
  l.store 'Name', 'Nazwa'
  l.store 'Upload', 'Wyślij'
  
  # Reports
  l.store 'Download CSV file of this report', 'Pobierz raport w formacie CSV.'
  l.store 'Total', 'Razem' # total in the sense of complete or sum of everything?
  l.store 'Report Configuration', 'Konfiguracja Raportu'
  l.store 'Report Type', 'Typ raportu'
  l.store 'Pivot', 'Oś'
  l.store 'Audit', 'Audyt'
  l.store 'Time Sheet', 'Arkusz czasu'
  l.store 'Time Range', 'Zakres czasu'
  l.store 'Custom', 'Własny'
  l.store 'Rows', 'Wiersze'
  l.store 'Columns', 'Kolumny'
  l.store "Milestones", 'Kroki'
  l.store "Date", 'Data'
  l.store 'Task Status', 'Status zadania'
  l.store "Task Type", 'Typ zadania'
  l.store "Task Priority", 'Priorytet zadania'
  l.store "Task Severity", 'Krytyczność zadania'
  l.store 'From', 'Od' # From Date
  l.store 'To', 'Do' # To Date
  l.store 'Sub-totals', '[Czas poszczególnych dni]'
  l.store 'Filter', 'Filtruj'
  l.store 'Advanced Options', 'Zaawansowane'
  l.store 'Status', 'Status'
  l.store 'Run Report', 'Pokaż raport'
  
  # Schedule
  
  # Search
  l.store 'Search Results', 'Wyniki wyszukiwania'
  l.store 'Activities', 'Działania'
  
  # Project list
  l.store 'Read', 'Odczyt'
  l.store 'Work', 'Praca'
  l.store 'Assign', 'Przypisanie'
  l.store 'Prioritize', 'Priorytet'
  l.store 'Grant', 'Zezwól'  #
  l.store "Remove all access for <b>%s</b>?", 'Usunąć całkiem dostęp dla <b>%s</b> ?'
  l.store "Grant %s access for <b>%s</b>?", 'Dodać prawo <i>%s</i> dla <b>%s</b>?'
  l.store "Can't remove <b>yourself</b> or the <b>project creator</b>!", 'Nie można usunąć <b>siebie</b> lub <b>Twórcy projektu</b> !'
  l.store "Grant access to <b>%s</b>?", 'Przypisać prawo do<b>%s</b>?'
  l.store 'Edit Project', 'Edytuj projekt'
  l.store 'Delete Project', 'Usuń projekt'
  l.store 'Complete Project', 'Ukończ projekt'
  l.store 'New Milestone', 'Nowy Krok'
  l.store 'Access To Project', 'Dostęp do projektu'
  l.store 'Completed', 'Ukończony'
  l.store 'Completed Projects', 'Ukończone projekty'
  l.store 'Revert', 'Przywróć'
  l.store 'Really revert %s?', 'Czy na pewno przywrócić %s ?'
  
  # Milestones
  l.store 'Owner', 'Właściciel'
  l.store 'Edit Milestone', 'Edytuj Krok'
  l.store 'Delete Milestone', 'Usuń Krok'
  l.store 'Complete Milestone', 'Ukończ Krok'
  l.store 'Completed Milestones', 'Ukończone Kroki'
  
  # Users
  l.store 'Email', 'E-Mail'
  l.store 'Last Login', 'Ostatnie logowanie'
  l.store 'Offline', 'Offline'
  l.store 'Are your sure?', 'Czy jesteś pewny?'
  l.store 'Company', 'Firma'
  l.store '[New User]', '[Nowy użytkownik]'
  l.store '[Previous page]', '[Poprzednia strona]'
  l.store '[Next page]', '[Następna strona]'
  l.store 'Edit User', 'Edycja użytkownika'
  
  l.store 'Options', 'Opcje'
  l.store 'Location', 'Położenie'
  l.store 'Administrator', 'Administrator'
  l.store 'Track Time', 'Czas śledzenia'
  l.store 'Use External Clients', 'Użyj zewnętrznych Klientów'
  l.store 'Show Calendar', 'Wyświetlanie kalendarza'
  l.store 'Show Tooltips', 'Wyświetlanie podpowiedzi'
  l.store 'Send Notifications', 'Wysyłanie powiadomień'
  l.store 'Receive Notifications', 'Odbieranie powiadomień'
  
  l.store 'User Information', 'Informacje o użytkowniku'
  l.store 'Username', 'Nazwa użytkownika'
  l.store 'Password', 'Hasło'
  
  # Preferences
  l.store 'Preferences', 'Preferencje'
  l.store 'Language', 'Język'
  l.store 'Time Format', 'Format godziny'
  l.store 'Date Format', 'Format daty'
  l.store 'Custom Logo', 'Własne logo'
  l.store 'Current logo', 'Obecne logo'
  l.store 'New logo', 'Nowe logo'
  l.store "(Won't be resized, 150x50px should look good. The logo will be shown up top instead of the ClockingIT one, and on your login page.)", "(Nie zostanie przeskalowane. Logo będzie widoczne zamiast logo ClockingIT i na stronie logowania.)"
  
  # Notes / Pages
  l.store 'Body', 'Treść'
  l.store 'Preview', 'Podgląd'
  l.store 'New Note', 'Nowa notatka'
  l.store 'Edit Note', 'Edytuj notatkę'
  
  # Views
  l.store 'New View', 'Nowy widok'
  l.store 'Edit View', 'Edytuj widok'
  l.store 'Delete View', 'Usuń widok'
  l.store '[Active Users]', '[Aktywni użytkownicy]'
  l.store 'Shared', 'Współdzielony'
  
  # Clients
  l.store 'Contact', 'Kontakt'
  l.store '[New Client]', '[Nowy Klient]'
  l.store 'Contact email', 'E-Mail'
  l.store 'Contact name', 'Nazwa'
  l.store 'Client CSS', 'Własny CSS'
  
  # Activities Controller
  l.store 'Tutorial completed. It will no longer be shown in the menu.', 'Tutorial ukończony, nie będzie więcej widoczny w menu.'
  l.store 'Tutorial hidden. It will no longer be shown in the menu.', 'Tutorial ukryty. Nie będzie więcej widoczny w menu.'
  
  # Customers Controller
  l.store 'Client was successfully created.', 'Klient został utworzony.'
  l.store 'Client was successfully updated.', 'Dane Klienta zaktualizowane.'
  l.store 'Please delete all projects for %s before deleting it.', 'Usuń wszystkie projekty przypisane do %s przed jego usunięciem.'
  l.store "You can't delete your own company.", 'Nie możesz usunąć własnej firmy!'
  l.store 'CSS successfully uploaded.', 'CSS załadowany.'
  l.store 'Logo successfully uploaded.', 'Logo załadowane.'
  
  # Milestones Controller
  l.store 'Milestone was successfully created.', 'Krok utworzony.'
  l.store 'Milestone was successfully updated.', 'Krok zaktualizowany.'
  l.store '%s / %s completed.', '%s / %s ukończony.' # Project name / Milestone name completed.
  l.store '%s / %s reverted.', '%s / %s przywrócony.' # Project name / Milestone name reverted.
  
  # Pages / Notes Controller
  l.store 'Note was successfully created.', 'Notatka utworzona.'
  l.store 'Note was successfully updated.', 'Notakta zaktualizowana.'
  
  # Project Files Controller
  l.store 'No file selected for upload.', 'Nie wybrano pliku do wysłania.'
  l.store 'File too big.', 'Plik jest zbyt duży!'
  l.store 'File successfully uploaded.', 'Plik pomyślnie wysłany.'
  
  # Projects Controller
  l.store 'Project was successfully created.', 'Projekt utworzony.'
  l.store 'Project was successfully created. Add users who need access to this project.', 'Projekt utworzony. Możesz przypisać do niego nowych użytkowników.'
  l.store 'Project was successfully updated.', 'Projekt zaktualizowany.'
  l.store 'Project was deleted.', 'Projekt usunięty.'
  l.store '%s completed.', '%s ukończony.'
  l.store '%s reverted.', '%s przywrócony.'
  
  # Reports Controller
  l.store "Empty report, log more work!", 'Pusty raport, loguj więcej prac!'
  
  # Tasks Controller
  l.store "You need to create a project to hold your tasks, or get access to create tasks in an existing project...", 'Aby zarządzać zadaniami musisz utworzyć nowy projekt lub uzyskać dostęp do tworzenia zadań w istniejącym projekcie.'
  l.store 'Invalid due date ignored.', 'Nieprawidłowa data wykonania.'
  l.store 'Task was successfully created.', 'Zadanie utworzone.'
  l.store 'Task was successfully updated.', 'Zadanie zaktualizowane.'
  l.store 'Log entry saved...', 'Wpis logu zapisany...'
  l.store "Unable to save log entry...", 'Nie można zapisać logu...'
  l.store "Log entry already saved from another browser instance.", 'Wpis utworzony z innej przeglądarki.'
  l.store 'Log entry deleted...', 'Wpis usunięty...'
  
  # Users Controller
  l.store 'User was successfully created. Remeber to give this user access to needed projects.', 'Użytkownik utworzony. Pamiętaj o nadaniu uprawnień do wybranych projektów.'
  l.store "Error sending creation email. Account still created.", 'Wystąpił błąd podczas wysyłania e-maila z informacją o utworzeniu konta.'
  l.store 'User was successfully updated.', 'Użytkownik utworzony.'
  l.store 'Preferences successfully updated.', 'Ustawienia zaktualizowane.'
  
  # Views Controller
  l.store "View '%s' was successfully created.", "Widok '%s' utworzony."
  l.store "View '%s' was successfully updated.", "Widok '%s' zaktualizowany."
  l.store "View '%s' was deleted.", " Widok '%s' usunięty."

  # Reports
  l.store 'Today','Dzisiaj'
  l.store 'Week', 'Tydzień'

  # Dates
  l.store 'January', 'Styczeń'
  l.store 'February', 'Luty'
  l.store 'March', 'Marzec'
  l.store 'April', 'Kwiecień'
  l.store 'May', 'Maj'
  l.store 'June', 'Czerwiec'
  l.store 'July', 'Lipiec'
  l.store 'August', 'Sierpień'
  l.store 'September', 'Wrzesień'
  l.store 'October', 'Październik'
  l.store 'November', 'Listopad'
  l.store 'December', 'Grudzień'

  l.store 'Jan', 'Sty'
  l.store 'Feb', 'Lut'
  l.store 'Mar', 'Mar'
  l.store 'Apr', 'Kwi'
  l.store 'May', 'Maj'
  l.store 'Jun', 'Cze'
  l.store 'Jul', 'Lip'
  l.store 'Aug', 'Sie'
  l.store 'Sep', 'Wrz'
  l.store 'Oct', 'Paź'
  l.store 'Nov', 'Lis'
  l.store 'Dec', 'Gru'

  l.store 'Sunday', 'Niedziela'
  l.store 'Monday', 'Poniedziałek'
  l.store 'Tuesday', 'Wtorek'
  l.store 'Wednesday', 'Środa'
  l.store 'Thursday', 'Czwartek'
  l.store 'Friday', 'Piątek'
  l.store 'Saturday', 'Sobota'

  l.store 'Sun', 'Ni'
  l.store 'Mon', 'Pn'
  l.store 'Tue', 'Wt'
  l.store 'Wed', 'Śr'
  l.store 'Thu', 'Cz'
  l.store 'Fri', 'Pt'
  l.store 'Sat', 'So'

  # worked_nice
  l.store '[wdhm]', '[tdgm]'
  l.store 'w', 't'
  l.store 'd', 'd'
  l.store 'h', 'g'
  l.store 'm', 'm'

  # Preferences
  l.store 'Duration Format', 'Format długości czasu'
  l.store 'Workday Length', 'Długość czasu pracy'

  # Tasks filter
  l.store '[Without Milestone]', '[Bez Kroków]'

  # Task tooltip
  l.store 'Progress', 'Postęp'

  # User Permissions
  l.store 'All', 'Wszystkie'

  # Reports filter
  l.store '[Any Priority]', '[Wszystkie priorytety]'
  l.store '[Any Severity]', '[Wszystkie]'

  # Preferences
  l.store '1w 2d 3h 4m', '1t 2d 3g 4m'
  l.store '1w2d3h4m', '1t2d3g4m'

  # Task
  l.store 'Attachments', 'Załączniki'
  l.store 'Dependencies', 'Zależności'
  l.store 'Add another dependency', "Dodaj zależność"
  l.store 'Remove dependency', 'Usuń zależność'
  l.store 'every', 'każdy' # every thursday
  l.store '[Any Task]', '[Wszystkie zadania]'

  l.store 'day', 'dzień' #every day
  l.store 'days', 'dni' #every 2 days
  l.store 'last', 'ostatni' #every last thursday

  l.store 'Hide Waiting Tasks', 'Ukryj oczekujące zadania'
  l.store 'Signup Message', 'Wiadomość po założeniu konta'
  l.store 'The message will be included in the signup email.', 'Wiadomość zostanie dołączona do emaila z rejestracją'
  l.store 'Depends on', 'Zależy od'

  # Activities
  l.store 'Subscribe to the recent activities RSS feed', 'Subskrybuj RSS z ostatnimi działaniami'

  # Project Files
  l.store '%d folder', ['%d folder', '%d foldery']
  l.store '%d file', ['%d plik', '%d pliki']
end 
