


Localization.define('es_ES') do |l|

  # Main menu
  l.store "Overview", "General"
  l.store "Tutorial", "Tutorial"
  l.store "Browse", "Examinar" # In fact, Browse, in spanish, means like "browse the internet", or "take a look", but i think, due the page, is better "Views", because is the same page of opening a view. I THINK IS BETTER "EXAMINAR".
  l.store "Timeline", "Historial"
  l.store "Files", "Archivos"
  l.store "Reports", "Informes"
  l.store "Schedule", "Agenda"
  l.store "New Task", "Nueva tarea"
  l.store "Preferences", "Preferencias"
  l.store "Log Out", "Salir"
  l.store "Clients", "Clientes"
  l.store "Client", "Cliente"
  l.store 'Search', 'Buscar'
  l.store 'Users', 'Usuarios'
  l.store 'User', 'Usuario'

  # Main layout
  l.store 'Hide', 'Esconder'
  l.store 'Views', 'Vistas'
  l.store 'Open Tasks', 'Abrir tarea'# I THINK IS BETTER "ABRIR TAREA"
  l.store 'My Open Tasks', 'Mis tareas abiertas'
  l.store 'My In Progress Tasks', 'Mis tareas en curso'
  l.store 'Unassigned Tasks', 'Tareas no asignadas'
  l.store 'Shared', 'Compartida'
  l.store 'Edit', 'Editar'
  l.store 'New', 'Añadir'
  l.store 'Chat', 'Chat'
  l.store 'Notes', 'Notas'
  l.store 'Feedback? Suggestions? Ideas? Bugs?', '¿Comentarios? ¿Sugerencias? ¿Ideas? ¿Fallos?'
  l.store 'Let me know', 'Házmelo saber'
  l.store 'worked today', 'de trabajo hoy'
  l.store 'Online', 'En linea'
  l.store 'Done working on <b>%s</b> for now.', 'Trabajado en <b>%s</b> hasta el momento.' # %s = @task.name
  l.store '%s ago', 'Hace %s'

  # Application Helper
  l.store 'today','hoy'
  l.store 'tomorrow', 'mañana'
  l.store '%d day', ['un día', '%d días']
  l.store '%d week', ['una semana', '%d semanas']
  l.store '%d month', ['un mes', '%d meses']
  l.store 'yesterday', 'ayer'
  l.store '%d day ago', ['hace un día', 'hace %d días']
  l.store '%d week ago', ['hace una semana', 'hace %d semanas']
  l.store '%d month ago', ['hace un mes', 'hace %d meses']

  # DateHelper
  l.store 'less than a minute', 'menos de un minuto'
  l.store '%d minute', ['un minuto', '%d minutos']
  l.store 'less than %d seconds', ['menos de un segundo', 'menos de %d segundos']
  l.store 'half a minute', 'medio minuto'
  l.store 'about %d hour', ['alrededor de una hora', 'alrededor de %d horas']


  # Activities
  l.store 'Top Tasks', 'Tareas principales'
  l.store 'Newest Tasks', 'Nuevas tareas'
  l.store 'Recent Activities', 'Actividades recientes'
  l.store 'Projects', 'Proyectos'
  l.store 'Overall Progress', 'Progreso general'
  l.store '%d completed milestone', ['un hito terminado', '%d hitos terminados']
  l.store '%d completed project', ['un proyecto terminado', '%d proyectos terminados']
  l.store 'Edit project <b>%s</b>', 'Editar proyecto <b>%s</b>'
  l.store 'Edit milestone <b>%s</b>', 'Editar hito <b>%s</b>'

  # Tasks
  l.store 'Tasks', 'Tareas'
  l.store '[Any Client]', '[Cualquier cliente]'
  l.store '[Any Project]', '[Cualquier proyecto]'
  l.store '[Any User]', '[Cualquier usuario]'
  l.store '[Any Milestone]', '[Cualquier hito]'
  l.store '[Any Status]', '[Cualquier estado]'
  l.store '[Unassigned]','[Sin asignar]'
  l.store 'Open', 'Abierta'
  l.store 'In Progress', 'En progreso'
  l.store 'Closed', 'Cerrada'
  l.store 'Won\'t Fix', 'Sin solución'
  l.store 'Invalid', 'Inválida'
  l.store 'Duplicate', 'Duplicada'
  l.store 'Archived', 'Archivada'
  l.store 'Group Tags', 'Agrupar etiquetas'
  l.store 'Save as View', 'Grabar como vista'
  l.store 'Tags', 'Etiquetas'
  l.store '[All Tags]', '[Todas las etiquetas]'
  l.store 'Close <b>%s</b>', 'Cerrar <b>%s</b>'
  l.store "Stop working on <b>%s</b>.", 'Dejar de trabajar en <b>%s</b>.'
  l.store "Start working on <b>%s</b>. Click again when done.", 'Empezar a trabajar en <b>%s</b>. Pulse de nuevo para terminar.'
  l.store 'No one', 'Ninguno'
  l.store "Revert <b>%s</b> to not completed status.", 'Dejar <b>%s</b> como no terminado.'
  l.store "Cancel working on <b>%s</b>.", 'Cancelar trabajo en <b>%s</b>.'
  l.store "Move <b>%s</b> to the Archive.", 'Mover <b>%s</b> al Archivo.'
  l.store "Restore <b>%s</b> from the Archive.", 'Restaurar <b>%s</b> del Archivo.'
  l.store 'Information', 'Información'
  l.store 'Summary', 'Resumen'
  l.store 'Description', 'Descripción'
  l.store 'Comment', 'Comentario'
  l.store 'Attach file', 'Adjuntar archivo'
  l.store 'Target', 'Objetivo'
  l.store 'Project', 'Proyecto'
  l.store 'Milestone', 'Hito'
  l.store '[None]', '[Ninguno]'
  l.store 'Assigned To', 'Asignada a '
  l.store 'Requested By', 'Solicitada por' # I THINK IS BETTER "SOLICITADA POR"
  l.store 'Attributes', 'Atributos'

  l.store 'Type', 'Tipo'
  l.store 'Priority', 'Prioridad'
  l.store 'Severity', 'Importancia'
  l.store 'Time Estimate', 'Tiempo estimado'
  l.store 'Due Date', 'Fecha de entrega'
  l.store 'Show Calendar', 'Ver calendario'
  l.store 'Notification', 'Notificación'
  l.store "Additional people to be notified on task changes<br />in addition to creator and asignee.<br/><br/>Ctrl-click to toggle.", 'Los cambios en la tarea se notificarán, además de a<br/>su creador y a las personas asignadas a:<br/><br/>Ctrl-click para cambiar.'
  l.store 'To:', 'To:'
  l.store '[Delete]', '[Borrar]'
  l.store 'Really delete %s?', '¿De verdad desea borrar %s?'
  l.store 'New Task', 'Nueva tarea'
  l.store 'Create', 'Crear'
  l.store 'Send notification emails', 'Enviar notificación por e-mail'
  l.store 'Created', 'Creado'
  l.store 'by', 'por' # Created by
  l.store 'Last Updated', 'Última actualización'
  l.store 'Save', 'Grabar'
  l.store 'and', 'y' # Save and ...

  l.store "Leave Open",'Dejar abierta'
  l.store "Revert to Open",'Volver a abrir'
  l.store "Set in Progress",'Poner En Progreso'
  l.store "Leave as in Progress",'Dejar En Progreso'
  l.store "Close",'Cerrar'
  l.store "Leave Closed",'Dejar cerrada'
  l.store "Set as Won't Fix",'Poner como Sin Solución'
  l.store "Leave as Won't Fix",'Dejar como Sin Solución'
  l.store "Set as Invalid",'Poner como Inválida'
  l.store "Leave as Invalid",'Dejar como Inválida'
  l.store "Set as Duplicate",'Poner como Duplicada'
  l.store "Leave as Duplicate",'Dejar como Duplicada'
  l.store 'History', 'Histórico'
  l.store 'Edit Log Entry', 'Editar entrada de histórico'
  l.store 'Delete Log Entry', 'Borrar entrada de histórico'
  l.store 'Really delete this log entry?', '¿De verdad quiere borrar esta entrada del histórico?'

  l.store 'Task', 'Tarea'
  l.store 'New Feature', 'Nueva característica'
  l.store 'Defect', 'Fallo'
  l.store 'Improvement', 'Mejora'
  l.store 'Critical', 'Crítica'
  l.store 'Urgent', 'Urgente'
  l.store 'High', 'Alta'
  l.store 'Normal', 'Normal'
  l.store 'Low', 'Baja'
  l.store 'Lowest', 'Muy baja'
  l.store 'Blocker', 'La más alta'
  l.store 'Major', 'Mayor'
  l.store 'Minor', 'Menor'
  l.store 'Trivial', 'Mínima'

  l.store 'Start', 'Comienzo'
  l.store 'Duration Worked', 'Tiempo trabajado'

  # Timeline
  l.store '[All Time]', '[Todo]'
  l.store 'This Week', 'Esta semana'
  l.store 'Last Week', 'La semana pasada'
  l.store 'This Month', 'Este mes'
  l.store 'Last Month', 'El mes pasado'
  l.store 'This Year', 'Este año'
  l.store 'Last Year', 'El año pasado'
  l.store '[Any Type]', '[Cualquier acción]'
  l.store 'Work Log', 'Histórico de trabajo'
  l.store 'Status Change', 'Cambio de estado'
  l.store 'Modified', 'Modificaciones'
  l.store '[Prev]', '[Anterior]' # [Prev] 100 of 2000 entries [Next]
  l.store '[Next]', '[Siguiente]' # [Prev] 100 of 2000 entries [Next]
  l.store 'of', 'de' # 100 of 2000 entries
  l.store 'entries..', 'entradas...' # 100 of 2000 entries

  # Project Files
  l.store 'Download', 'Descargar'
  l.store 'Delete', 'Borrar'
  l.store '[New File]', '[Nuevo archivo]'
  l.store 'File', ['Archivo', 'Archivos']
  l.store 'Upload New File', 'Subir nuevo archivo'
  l.store 'Name', 'Nombre'
  l.store 'Upload', 'Subir'

  # Reports
  l.store 'Download CSV file of this report', 'Descargar archivo CSV de este informe.'
  l.store 'Total', 'Total'
  l.store 'Report Configuration', 'Configurar informe'
  l.store 'Report Type', 'Tipo de informe'
  l.store 'Pivot', 'Pivot'
  l.store 'Audit', 'Auditoría'
  l.store 'Time sheet', 'Hoja de tiempos'
  l.store 'Time Range', 'Intervalo de tiempo'
  l.store 'Custom', 'Personalizado'
  l.store 'Rows', 'Filas'
  l.store 'Columns', 'Columnas'
  l.store "Milestones", 'Hitos'
  l.store "Date", 'Fecha'
  l.store 'Task Status', 'Estado de tarea'
  l.store "Task Type", 'Tipo de tarea'
  l.store "Task Priority", 'Prioridad de tarea'
  l.store "Task Severity", 'Importancia de tarea'
  l.store 'From', 'Desde' # From Date
  l.store 'To', 'Hasta' # To Date
  l.store 'Sub-totals', 'Subtotales'
  l.store 'Filter', 'Filtro'
  l.store 'Advanced Options', 'Opciones avanzadas'
  l.store 'Status', 'Estado'
  l.store 'Run Report', 'Ver informe'

  # Schedule

  # Search
  l.store 'Search Results', 'Buscar en resultados'
  l.store 'Activities', 'Actividades'

  # Project list
  l.store 'Read', 'Lectura'
  l.store 'Work', 'Trabajar'
  l.store 'Assign', 'Asignar'
  l.store 'Prioritize', 'Priorizar'
  l.store 'Grant', 'Administrar'
  l.store "Remove all access for <b>%s</b>?", 'Quitar todos los permisos a <b>%s</b>?'
  l.store "Grant %s access for <b>%s</b>?", 'Dar permisos de %s a <b>%s</b>?'
  l.store "Can't remove <b>yourself</b> or the <b>project creator</b>!", '¡No se puede eliminar <b>a usted mismo</b> a al <b>creador del proyecto</b>!'
  l.store "Grant access to <b>%s</b>?", '¿Dar permisos a <b>%s</b>?'
  l.store 'Edit Project', 'Editar proyecto'
  l.store 'Delete Project', 'Borrar proyecto'
  l.store 'Complete Project', 'Terminar proyecto'
  l.store 'New Milestone', 'Nuevo hito'
  l.store 'Access To Project', 'Acceder al proyecto'
  l.store 'Completed', 'Completado'
  l.store 'Completed Projects', 'Proyectos terminados'
  l.store 'Revert', 'Volver a poner'
  l.store 'Really revert %s?', '¿De verdad quiere ponerlo de nuevo como %s?'

  # Milestones
  l.store 'Owner', 'Propietario'
  l.store 'Edit Milestone', 'Editar Hito'
  l.store 'Delete Milestone', 'Borrar Hito'
  l.store 'Complete Milestone', 'Completar Hito'
  l.store 'Completed Milestones', 'Hitos completados'

  # Users
  l.store 'Email', 'E-mail'
  l.store 'Last Login', 'Último acceso'
  l.store 'Offline', 'Desconectado'
  l.store 'Are your sure?', '¿Está seguro?'
  l.store 'Company', 'Compañía'
  l.store '[New User]', '[Nuevo usuario]'
  l.store '[Previous page]', '[Página anterior]'
  l.store '[Next page]', '[Página siguiente]'
  l.store 'Edit User', 'Editar usuario'

  l.store 'Options', 'Opciones'
  l.store 'Location', 'Ciudad'
  l.store 'Administrator', 'Administrador'
  l.store 'Track Time', 'Contrl de tiempos'
  l.store 'Use External Clients', 'Usar clientes externos'
  l.store 'Show Calendar', 'Ver calendario'
  l.store 'Show Tooltips', 'Ver ayudas'
  l.store 'Send Notifications', 'Enviar notificaciones'
  l.store 'Receive Notifications', 'Recibir notificaciones'

  l.store 'User Information', 'Información del usuario'
  l.store 'Username', 'Nombre de usuario'
  l.store 'Password', 'Contraseña'

  # Preferences
  l.store 'Preferences', 'Preferencias'
  l.store 'Language', 'Idioma'
  l.store 'Time Format', 'Formato de hora'
  l.store 'Date Format', 'Formato de fecha'
  l.store 'Custom Logo', 'Logo personalizado'
  l.store 'Current logo', 'Logo actual'
  l.store 'New logo', 'Nuevo logo'
  l.store "(250x50px should look good. The logo will be shown up top instead of the ClockingIT one, and on your login page.)", "(Se recomienda un tamaño de imagen de 250x50px. El logotipo se mostrará en la cabecera, en lugar del de ClockingIt, y en la página de inicio de sesión.)"

  # Notes / Pages
  l.store 'Body', 'Contenido'
  l.store 'Preview', 'Vista previa'
  l.store 'New Note', 'Nueva nota'
  l.store 'Edit Note', 'Editar nota'

  # Views
  l.store 'New View', 'Nueva vista'
  l.store 'Edit View', 'Editar vista'
  l.store 'Delete View', 'Borra vista'
  l.store '[Active User]', '[Usuario conectado]'
  l.store 'Shared', 'Compartir'

  # Clients
  l.store 'Contact', 'Contacto'
  l.store 'New Client', 'Nuevo cliente'
  l.store 'Contact email', 'E-mail de contacto'
  l.store 'Contact name', 'Nombre de contacto'
  l.store 'Client CSS', 'CSS del cliente'

  # Activities Controller
  l.store 'Tutorial completed. It will no longer be shown in the menu.', 'Tutorial completado. No se volverá a mostrar en el menú.'
  l.store 'Tutorial hidden. It will no longer be shown in the menu.', 'Tutorial escondido. No se volverá a mostrar en el menú.'

  # Customers Controller
  l.store 'Client was successfully created.', 'El cliente fue creado satisfactoriamente.'
  l.store 'Client was successfully updated.', 'El cliente fue modificado satisfactoriamente.'
  l.store 'Please delete all projects for %s before deleting it.', 'Por favor, elimine todos los proyectos de %s antes de borrarlo.'
  l.store "You can't delete your own company.", 'No puede borrar su propia compañia.'
  l.store 'CSS successfully uploaded.', 'CSS subido satisfactoriamente.'
  l.store 'Logo successfully uploaded.', 'Logo subido satisfactoriamente.'

  # Milestones Controller
  l.store 'Milestone was successfully created.', 'Hito creado satisfactoriamente.'
  l.store 'Milestone was successfully updated.', 'Hito modificado satisfactoriamente.'
  l.store '%s / %s completed.', '%s / %s completado.' # Project name / Milestone name completed.
  l.store '%s / %s reverted.', '%s / %s se ha vuelto a renombrar.' # Project name / Milestone name reverted.

  # Pages / Notes Controller
  l.store 'Note was successfully created.', 'Nota creada satisfactoriamente.'
  l.store 'Note was successfully updated.', 'Nota modificada satisfactoriamente.'

  # Project Files Controller
  l.store 'No file selected for upload.', 'Ningún archivo seleccionado para subir.'
  l.store 'File too big.', 'Archivo demasiado grande.'
  l.store 'File successfully uploaded.', 'Fichero subido satisfactoriamente.'

  # Projects Controller
  l.store 'Project was successfully created.', 'Proyecto creado satisfactoriamente.'
  l.store 'Project was successfully created. Add users who need access to this project.', 'Proyecto creado satisfactoriamente. Añada los usuarios que necesiten tener acceso a este proyecto.'
  l.store 'Project was successfully updated.', 'Proyecto modificado satisfactoriamente.'
  l.store 'Project was deleted.', 'El proyecto fue eliminado.'
  l.store '%s completed.', '%s completado.'
  l.store '%s reverted.', '%s se ha rehecho.'

  # Reports Controller
  l.store "Empty report, log more work!", 'Informe vacío, ¡Cree más entradas de trabajo!'

  # Tasks Controller
  l.store "You need to create a project to hold your tasks, or get access to create tasks in an existing project...", 'Debe crear un proyecto para asignar sus tareas, o tener permiso para crear tareas en un proyecto existente...'
  l.store 'Invalid due date ignored.', 'Fecha de entraga inválida ignorada.'
  l.store 'Task was successfully created.', 'Tarea creada satisfactoriamente.'
  l.store 'Task was successfully updated.', 'Tarea modificada satisfactoriamente.'
  l.store 'Log entry saved...', 'Entrada de histórico guardada...'
  l.store "Unable to save log entry...", 'Imposible guardar entrada de histórico...'
  l.store "Log entry already saved from another browser instance.", 'Entrada de histórico ya grabada desde otra ventana.'
  l.store 'Log entry deleted...', 'Entrada de histórico eliminada...'

  # Users Controller
  l.store 'User was successfully created. Remember to give this user access to needed projects.', 'Usuario creado satisfactoriamente. Recuerde dar acceso a este usuario a los proyectos que necesite.'
  l.store "Error sending creation email. Account still created.", 'Error al enviar e-mail de creación. La cuanta ya fue creada.'
  l.store 'User was successfully updated.', 'Usuario modificado satisfactoriamente.'
  l.store 'Preferences successfully updated.', 'Preferencia modificadas satisfactoriamente.'

  # Views Controller
  l.store "View '%s' was successfully created.", "Vista '%s' creada satisfactoriamente."
  l.store "View '%s' was successfully updated.", "Vista '%s' modificada satisfactoriamente."
  l.store "View '%s' was deleted.", "Vista '%s' eliminada."

  # Wiki
  l.store 'Quick Reference', 'Referencia rápida'
  l.store 'Full Reference', 'Referencia completa'
  l.store 'or', 'o'
  l.store 'Under revision by', 'Está siendo revisado por'
  l.store 'Revision', 'Revisión'
  l.store 'Linked from', 'Referenciado desde' # Linked from in the way of href link ???

  # Reports
  l.store 'Today', 'Hoy'
  l.store 'Week', 'Semana'

  # Dates
  l.store 'January', 'Enero'
  l.store 'February', 'Febrero'
  l.store 'March', 'Marzo'
  l.store 'April', 'Abril'
  l.store 'May', 'Mayo'
  l.store 'June', 'Junio'
  l.store 'July', 'Julio'
  l.store 'August', 'Agosto'
  l.store 'September', 'Septiembre'
  l.store 'October', 'Octubre'
  l.store 'November', 'Noviembre'
  l.store 'December', 'Diciembre'

  l.store 'Jan', 'Ene'
  l.store 'Feb', 'Feb'
  l.store 'Mar', 'Mar'
  l.store 'Apr', 'Abr'
  l.store 'May', 'May'
  l.store 'Jun', 'Jun'
  l.store 'Jul', 'Jul'
  l.store 'Aug', 'Ago'
  l.store 'Sep', 'Sep'
  l.store 'Oct', 'Oct'
  l.store 'Nov', 'Nov'
  l.store 'Dec', 'Dic'

  l.store 'Sunday', 'Domingo'
  l.store 'Monday', 'Lunes'
  l.store 'Tuesday', 'Martes'
  l.store 'Wednesday', 'Miércoles'
  l.store 'Thursday', 'Jueves'
  l.store 'Friday', 'Viernes'
  l.store 'Saturday', 'Sábado'

  l.store 'Sun', 'Dom'
  l.store 'Mon', 'Lun'
  l.store 'Tue', 'Mar'
  l.store 'Wed', 'Mie'
  l.store 'Thu', 'Jue'
  l.store 'Fri', 'Vie'
  l.store 'Sat', 'Sáb'

  # worked_nice
  l.store '[wdhm]', '[sdhm]'
  l.store 'w', 's'
  l.store 'd', 'd'
  l.store 'h', 'h'
  l.store 'm', 'm'

  # Preferences
  l.store 'Duration Format', 'Formato de duración'
  l.store 'Workday Length', 'Workday Length'

  # Tasks filter
  l.store '[Without Milestone]', '[Without Milestone]'

  # Task tooltip
  l.store 'Progress', 'Progress'

  # User Permissions
  l.store 'All', 'All'

  # Reports filter
  l.store '[Any Priority]', '[Any Priority]'
  l.store '[Any Severity]', '[Any Severity]'

  # Preferences
  l.store '1w 2d 3h 4m', '1s 2d 3h 4m'
  l.store '1w2d3h4m', '1s2d3h4m'

  # Task
  l.store 'Attachments', 'Attachments'
  l.store 'Dependencies', 'Dependencies'
  l.store 'Add another dependency', "Add another dependency"
  l.store 'Remove dependency', 'Remove dependency'
  l.store 'every', 'every' # every thursday
  l.store '[Any Task]', '[Any Task]'

  l.store 'day', 'day' #every day
  l.store 'days', 'days' #every 2 days
  l.store 'last', 'last' #every last thursday

  l.store 'Hide Waiting Tasks', 'Hide Waiting Tasks'
  l.store 'Signup Message', 'Signup Message'
  l.store 'The message will be included in the signup email.', 'The message will be included in the signup email.'
  l.store 'Depends on', 'Depends on'

  # Activities
  l.store 'Subscribe to the recent activities RSS feed', 'Subscribe to the recent activities RSS feed'

  # Project Files
  l.store '%d folder', ['%d folder, %d folders']
  l.store '%d file', ['%d file', '%d files']
end
