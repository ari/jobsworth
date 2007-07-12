


Localization.define('pt_BR') do |l|

  # Main menu
  l.store "Overview", "Geral"
  l.store "Tutorial", "Tutorial"
  l.store "Browse", "Examinar" #review
  l.store "Timeline", "Histórico"
  l.store "Files", "Arquivos"
  l.store "Reports", "Relatórios"
  l.store "Schedule", "Agenda"
  l.store "New Task", "Nova Tarefa"
  l.store "Preferences", "Preferências"
  l.store "Log Out", "Sair"
  l.store "Clients", "Clientes"
  l.store "Client", "Cliente"
  l.store 'Search', 'Buscar'
  l.store 'Users', 'Usuários'
  l.store 'User', 'Usuário'

  # Main layout
  l.store 'Hide', 'Ocultar'
  l.store 'Views', 'Visualizações'
  l.store 'Open Tasks', 'Abrir tarefa'
  l.store 'My Open Tasks', 'Minhas Tarefas Abertas'
  l.store 'My In Progress Tasks', 'Minhas tarefas Correntes'
  l.store 'Unassigned Tasks', 'Tarefas Não Alocadas' #review
  l.store 'Shared', 'Compartilhar' #review
  l.store 'Edit', 'Editar'
  l.store 'New', 'Novo' #review
  l.store 'Chat', 'Chat'
  l.store 'Notes', 'Notas'
  l.store 'Feedback? Suggestions? Ideas? Bugs?', 'Feedback? Sugestões? Idéias? Bugs?'
  l.store 'Let me know', 'Conte-me'
  l.store 'worked today', 'trabalhado hoje' #review
  l.store 'Online', 'Conectado'
  l.store 'Done working on <b>%s</b> for now.', 'Trabalhando em <b>%s</b> por agora.' # %s = @task.name
  l.store '%s ago', '%s passado' #review

  # Application Helper
  l.store 'today','hoje'
  l.store 'tomorrow', 'amanhã'
  l.store '%d day', ['um dia', '%d dias']
  l.store '%d week', ['uma semana', '%d semanas']
  l.store '%d month', ['um mês', '%d meses']
  l.store 'yesterday', 'ontem'
  l.store '%d day ago', ['faz um dia', 'faz %d dias'] #review
  l.store '%d week ago', ['faz uma semana', 'faz %d semanas']
  l.store '%d month ago', ['faz um mês', 'faz %d meses']

  # DateHelper
  l.store 'less than a minute', 'menos de un minuto'
  l.store '%d minute', ['um minuto', '%d minutos']
  l.store 'less than %d seconds', ['menos de um segundo', 'menos de %d segundos']
  l.store 'half a minute', 'meio minuto'
  l.store 'less than a minute', 'menos de um minuto'
  l.store 'about %d hour', ['em torno de uma hora', 'em torno de %d horas']

  # Activities
  l.store 'Top Tasks', 'Principais Tarefas'
  l.store 'Newest Tasks', 'Novas Tarefas'
  l.store 'Recent Activities', 'Atividades Recentes'
  l.store 'Projects', 'Projetos'
  l.store 'Overall Progress', 'Progreso geral'
  l.store '%d completed milestone', ['um milestone finalizado', '%d milestones terminados']
  l.store '%d completed project', ['um projeto finalizado', '%d projetos finalizados']
  l.store 'Edit project <b>%s</b>', 'Editar projeto <b>%s</b>'
  l.store 'Edit milestone <b>%s</b>', 'Editar milestone <b>%s</b>'

  # Tasks
  l.store 'Tasks', 'Tarefas'
  l.store '[Any Client]', '[Qualquer Cliente]'
  l.store '[Any Project]', '[Qualquer Projeto]'
  l.store '[Any User]', '[Qualquer Usuário]'
  l.store '[Any Milestone]', '[Qualquer Milestone]'
  l.store '[Any Status]', '[Qualquer Status]'
  l.store '[Unassigned]','[Não Alocado]'
  l.store 'Open', 'Aberto' #review
  l.store 'In Progress', 'Em Progresso'
  l.store 'Closed', 'Fechado'
  l.store 'Won\'t Fix', 'Sem Solução'
  l.store 'Invalid', 'Inválida'
  l.store 'Duplicate', 'Duplicada'
  l.store 'Archived', 'Arquivada'
  l.store 'Group Tags', 'Agrupar Tags'
  l.store '[Save as View]', '[Salvar como Visualização]'
  l.store 'Tags', 'Tags'
  l.store '[All Tags]', '[Todas Tags]'
  l.store 'Close <b>%s</b>', 'Fechar <b>%s</b>'
  l.store "Stop working on <b>%s</b>.", 'Deixar de trabalhar em <b>%s</b>.'
  l.store "Start working on <b>%s</b>. Click again when done.", 'Começar a trabalhar em <b>%s</b>. Clique novamente quando finalizar.'
  l.store 'No one', 'Ninguém' #review
  l.store "Revert <b>%s</b> to not completed status.", 'Reverter <b>%s</b> como não finalizado.' #review
  l.store "Cancel working on <b>%s</b>.", 'Cancelar trabalho em <b>%s</b>.'
  l.store "Move <b>%s</b> to the Archive.", 'Mover <b>%s</b> para o Arquivo.'
  l.store "Restore <b>%s</b> from the Archive.", 'Restaurar <b>%s</b> do Arquivo.'
  l.store 'Information', 'Informação'
  l.store 'Summary', 'Resumo'
  l.store 'Description', 'Descrição'
  l.store 'Comment', 'Comentário'
  l.store 'Attach file', 'Anexar arquivo'
  l.store 'Target', 'Objetivo'
  l.store 'Project', 'Projeto'
  l.store 'Milestone', 'Milestone'
  l.store '[None]', '[Ninguém]' #review
  l.store 'Assigned To', 'Alocado para'
  l.store 'Requested By', 'Requisitado por'
  l.store 'Attributes', 'Atributos'

  l.store 'Type', 'Tipo'
  l.store 'Priority', 'Prioridade'
  l.store 'Severity', 'Importância'
  l.store 'Time Estimate', 'Tempo estimado'
  l.store 'Due Date', 'Prazo'
  l.store 'Show Calendar', 'Ver Calendário'
  l.store 'Notification', 'Notificação'
  l.store "Additional people to be notified on task changes<br />in addition to creator and asignee.<br/><br/>Ctrl-click to toggle.", 'Pessoas adicionais que serão notificadas das mudanças da tarefa, além de<br/>seu criador e as pessoas alocadas:<br/><br/>Ctrl-click para selecionar.' #verificar
  l.store 'To:', 'Para:'
  l.store '[Delete]', '[Remover]'
  l.store 'Really delete %s?', 'Realmente deseja remover %s?'
  l.store 'New Task', 'Nova Tarefa'
  l.store 'Create', 'Criar'
  l.store 'Send notification emails', 'Enviar notificações por e-mail'
  l.store 'Created', 'Criado'
  l.store 'by', 'por' # Created by
  l.store 'Last Updated', 'Última atualização'
  l.store 'Save', 'Salvar'
  l.store 'and', 'e' # Save and ...

  l.store "Leave Open",'Deixar aberta'
  l.store "Revert to Open",'Voltar a Abrir'
  l.store "Set in Progress",'Colocar em Progresso'
  l.store "Leave as in Progress",'Deixar em Progresso'
  l.store "Close",'Fechar'
  l.store "Leave Closed",'Deixar Fechada'
  l.store "Set as Won't Fix",'Colocar como Sem Solução'
  l.store "Leave as Won't Fix",'Deixar como Sem Solução'
  l.store "Set as Invalid",'Colocar como Inválida'
  l.store "Leave as Invalid",'Deixar como Inválida'
  l.store "Set as Duplicate",'Colocar como Duplicada'
  l.store "Leave as Duplicate",'Deixar como Duplicada'
  l.store 'History', 'Histórico'
  l.store 'Edit Log Entry', 'Editar entrada de histórico'
  l.store 'Delete Log Entry', 'Remover entrada de histórico'
  l.store 'Really delete this log entry?', 'Realmente deseja apagar esta entrada de histórico?'

  l.store 'Task', 'Tarefa'
  l.store 'New Feature', 'Nova característica'
  l.store 'Defect', 'Defeito'
  l.store 'Improvement', 'Melhoria'
  l.store 'Critical', 'Crítico'
  l.store 'Urgent', 'Urgente'
  l.store 'High', 'Alta'
  l.store 'Normal', 'Normal'
  l.store 'Low', 'Baixa'
  l.store 'Lowest', 'Muito Baixa'
  l.store 'Blocker', 'A Mais Alta' #review
  l.store 'Major', 'Principal' #review
  l.store 'Minor', 'Menor'
  l.store 'Trivial', 'Trivial'

  l.store 'Start', 'Início'
  l.store 'Duration Worked', 'Tempo Trabalhado'

  # Timeline
  l.store '[All Time]', '[Todo]'
  l.store 'This Week', 'Esta Semana'
  l.store 'Last Week', 'Semana Passada'
  l.store 'This Month', 'Este mês'
  l.store 'Last Month', 'Mês Passado'
  l.store 'This Year', 'Este Ano'
  l.store 'Last Year', 'Ano Passado'
  l.store '[Any Type]', '[Qualquer Tipo]'
  l.store 'Work Log', 'Histórico de trabalho'
  l.store 'Status Change', 'Troca de Status' #review
  l.store 'Modified', 'Modificações' #review
  l.store '[Prev]', '[Anterior]' # [Prev] 100 of 2000 entries [Next]
  l.store '[Next]', '[Próximo]' # [Prev] 100 of 2000 entries [Next]
  l.store 'of', 'de' # 100 of 2000 entries
  l.store 'entries..', 'entradas...' # 100 of 2000 entries

  # Project Files
  l.store 'Download', 'Baixar'
  l.store 'Delete', 'Apagar'
  l.store '[New File]', '[Novo Arquivo]'
  l.store 'File', ['Archivo', 'Arquivos']
  l.store 'Upload New File', 'Enviar Novo Arquivo'
  l.store 'Name', 'Nome'
  l.store 'Upload', 'Enviar'

  # Reports
  l.store 'Download CSV file of this report', 'Baixar arquivo CSV deste relatório.'
  l.store 'Total', 'Total'
  l.store 'Report Configuration', 'Configurar relatório'
  l.store 'Report Type', 'Tipo de relatório'
  l.store 'Pivot', 'Pivot' #review
  l.store 'Audit', 'Auditoria'
  l.store 'Time sheet', 'Planilha de Tempo' #review
  l.store 'Time Range', 'Intervalo de Tempo'
  l.store 'Custom', 'Personalizado'
  l.store 'Rows', 'Linhas'
  l.store 'Columns', 'Colunas'
  l.store "Milestones", 'Milestones'
  l.store "Date", 'Data' #review
  l.store 'Task Status', 'Status de Tarefa'
  l.store "Task Type", 'Tipo de Tarefa'
  l.store "Task Priority", 'Prioridade de Tarefa'
  l.store "Task Severity", 'Importância de Tarea'
  l.store 'From', 'De' # From Date
  l.store 'To', 'Até' # To Date
  l.store 'Sub-totals', 'Subtotals' #review
  l.store 'Filter', 'Filtro'
  l.store 'Advanced Options', 'Opções Avançadas'
  l.store 'Status', 'Status'
  l.store 'Run Report', 'Executar Relatório'
  # Schedule

  # Search
  l.store 'Search Results', 'Buscar em resultados'
  l.store 'Activities', 'Atividades'

  # Project list
  l.store 'Read', 'Ler'
  l.store 'Work', 'Trabalhar'
  l.store 'Assign', 'Alocar'
  l.store 'Prioritize', 'Priorizar'
  l.store 'Grant', 'Administrar'
  l.store "Remove all access for <b>%s</b>?", 'Remover todas permissões para <b>%s</b>?'
  l.store "Grant %s access for <b>%s</b>?", 'Dar permissões de %s a <b>%s</b>?'
  l.store "Can't remove <b>yourself</b> or the <b>project creator</b>!", 'Não pode eliminar <b>a si mesmo</b> ou o <b>criador do projeto</b>!'
  l.store "Grant access to <b>%s</b>?", 'Dar permissões a <b>%s</b>?'
  l.store 'Edit Project', 'Editar Projeto'
  l.store 'Delete Project', 'Remover Projeto'
  l.store 'Complete Project', 'Finalizar Projeto'
  l.store 'New Milestone', 'Novo Milestone'
  l.store 'Access To Project', 'Acessar O Projeto'
  l.store 'Completed', 'Finalizado'
  l.store 'Completed Projects', 'Projetos finalizados'
  l.store 'Revert', 'Reverter'
  l.store 'Really revert %s?', 'Realmente deseja reverter %s?'

  # Milestones
  l.store 'Owner', 'Propietário'
  l.store 'Edit Milestone', 'Editar Milestone'
  l.store 'Delete Milestone', 'Remover Milestone'
  l.store 'Complete Milestone', 'Finalizar Milestone'
  l.store 'Completed Milestones', 'Milestones finalizados'

  # Users
  l.store 'Email', 'Email'
  l.store 'Last Login', 'Último Acesso'
  l.store 'Offline', 'Desconectado'
  l.store 'Are your sure?', 'Certeza?'
  l.store 'Company', 'Companhia'
  l.store '[New User]', '[Novo Usuário]'
  l.store '[Previous page]', '[Página anterior]'
  l.store '[Next page]', '[Proxima aágina]'
  l.store 'Edit User', 'Editar Usuário'

  l.store 'Options', 'Opções'
  l.store 'Location', 'Local'
  l.store 'Administrator', 'Administrador'
  l.store 'Track Time', 'Acompanhamento do Tempo'
  l.store 'Use External Clients', 'Usar Clientes Externos'
  l.store 'Show Calendar', 'Ver Calendário'
  l.store 'Show Tooltips', 'Ver Ajudas'
  l.store 'Send Notifications', 'Enviar Notificações'
  l.store 'Receive Notifications', 'Receber Notificações'

  l.store 'User Information', 'Informação do Usuário'
  l.store 'Username', 'Nome de Usuário'
  l.store 'Password', 'Senha'

  # Preferences
  l.store 'Preferences', 'Preferências'
  l.store 'Language', 'Idioma'
  l.store 'Time Format', 'Formato de hora'
  l.store 'Date Format', 'Formato de data'
  l.store 'Custom Logo', 'Logo personalizado'
  l.store 'Current logo', 'Logo atual'
  l.store 'New logo', 'Novo logo'
  l.store "(250x50px should look good. The logo will be shown up top instead of the ClockingIT one, and on your login page.)", "(Se recomenda uma imagem de tamanho 250x50px. O logotipo será apresentado no cabeçalho, no lugar de ClockingIt, e na página de login.)"

  # Notes / Pages
  l.store 'Body', 'Conteúdo'
  l.store 'Preview', 'Pré-Visualização'
  l.store 'New Note', 'Nova Nota'
  l.store 'Edit Note', 'Editar Nota'

  # Views
  l.store 'New View', 'Nova Visualização'
  l.store 'Edit View', 'Editar Visualização'
  l.store 'Delete View', 'Remover Visualização'
  l.store '[Active User]', '[Usuário Conectado]'
  l.store 'Shared', 'Compartilhar'

  # Clients
  l.store 'Contact', 'Contato'
  l.store '[New Client]', '[Novo Cliente]'
  l.store 'Contact email', 'Email para contato'
  l.store 'Contact name', 'Nome para contato'
  l.store 'Client CSS', 'CSS do Cliente'

  # Activities Controller
  l.store 'Tutorial completed. It will no longer be shown in the menu.', 'Tutorial completado. Não será mais apresentado no menu.'
  l.store 'Tutorial hidden. It will no longer be shown in the menu.', 'Tutorial escondido. Não será mais apresentado no menu.'

  # Customers Controller
  l.store 'Client was successfully created.', 'Cliente criado com sucesso.'
  l.store 'Client was successfully updated.', 'Cliente atualizado com sucesso.'
  l.store 'Please delete all projects for %s before deleting it.', 'Por favor, elimine todos os projetos de %s antes de removê-lo.'
  l.store "You can't delete your own company.", 'Não pode remover sua própria companhia.'
  l.store 'CSS successfully uploaded.', 'CSS enviado com sucesso.'
  l.store 'Logo successfully uploaded.', 'Logo enviado com sucesso.'

  # Milestones Controller
  l.store 'Milestone was successfully created.', 'Milestone criado com sucesso.'
  l.store 'Milestone was successfully updated.', 'Milestone modificado com sucesso.'
  l.store '%s / %s completed.', '%s / %s finalizado.' # Project name / Milestone name completed.
  l.store '%s / %s reverted.', '%s / %s revertido.' # Project name / Milestone name reverted.

  # Pages / Notes Controller
  l.store 'Note was successfully created.', 'Nota criada com sucesso.'
  l.store 'Note was successfully updated.', 'Nota modificada  com sucesso.'

  # Project Files Controller
  l.store 'No file selected for upload.', 'Nenhum arquivo selecionado para envio.'
  l.store 'File too big.', 'Arquivo muito grande.'
  l.store 'File successfully uploaded.', 'Arquivo enviado com sucesso.'

  # Projects Controller
  l.store 'Project was successfully created.', 'Projeto criado com sucesso.'
  l.store 'Project was successfully created. Add users who need access to this project.', 'Projeto criado com sucesso. Adicione os usuários que terão acesso a este projeto.'
  l.store 'Project was successfully updated.', 'Projeto modificado com sucesso.'
  l.store 'Project was deleted.', 'Projeto removido.'
  l.store '%s completed.', '%s finalizado.'
  l.store '%s reverted.', '%s revertido.'

  # Reports Controller
  l.store "Empty report, log more work!", 'Relatório vazio!'

  # Tasks Controller
  l.store "You need to create a project to hold your tasks, or get access to create tasks in an existing project...", 'Deve criar um projeto para definir suas tarefas, ou receber permissão para criar tarefas em um projeto existente...'
  l.store 'Invalid due date ignored.', 'Prazo inválido ignorado.'
  l.store 'Task was successfully created.', 'Tarefa criada com sucesso.'
  l.store 'Task was successfully updated.', 'Tarefa modificada com sucesso.'
  l.store 'Log entry saved...', 'Entrada de histórico armazenada...'
  l.store "Unable to save log entry...", 'Impossível armazenar entrada de histórico...'
  l.store "Log entry already saved from another browser instance.", 'Entrada de histórico já armazenada a partir de outra fonte.'
  l.store 'Log entry deleted...', 'Entrada de histórico removida...'

  # Users Controller
  l.store 'User was successfully created. Remeber to give this user access to needed projects.', 'Usuário criado com sucesso. Lembre de dar acesso a este usuário aos projetos necessários.'
  l.store "Error sending creation email. Account still created.", 'Erro ao enviar email de criação. Conta criada.'
  l.store 'User was successfully updated.', 'Usuário modificado com sucesso.'
  l.store 'Preferences successfully updated.', 'Preferências modificadas com sucesso.'

  # Views Controller
  l.store "View '%s' was successfully created.", "Visualização '%s' criada com sucesso."
  l.store "View '%s' was successfully updated.", "Visualização '%s' modificada com sucesso."
  l.store "View '%s' was deleted.", "Visualização '%s' removida."

  # Reports
  l.store 'Today','Hoje'
  l.store 'Week', 'Semana'

  # Dates
  l.store 'January', 'Janeiro'
  l.store 'February', 'Fevereiro'
  l.store 'March', 'Março'
  l.store 'April', 'Abril'
  l.store 'May', 'Maio'
  l.store 'June', 'Junho'
  l.store 'July', 'Julho'
  l.store 'August', 'Agosto'
  l.store 'September', 'Setembro'
  l.store 'October', 'Outubro'
  l.store 'November', 'Novembro'
  l.store 'December', 'Dezembro'

  l.store 'Jan', 'Jan'
  l.store 'Feb', 'Fev'
  l.store 'Mar', 'Mar'
  l.store 'Apr', 'Abr'
  l.store 'May', 'Mai'
  l.store 'Jun', 'Jun'
  l.store 'Jul', 'Jul'
  l.store 'Aug', 'Ago'
  l.store 'Sep', 'Set'
  l.store 'Oct', 'Out'
  l.store 'Nov', 'Nov'
  l.store 'Dec', 'Dez'

  l.store 'Sunday', 'Domingo'
  l.store 'Monday', 'Segunda'
  l.store 'Tuesday', 'Terça'
  l.store 'Wednesday', 'Quarta'
  l.store 'Thursday', 'Quinta'
  l.store 'Friday', 'Sexta'
  l.store 'Saturday', 'Sábado'

  l.store 'Sun', 'Dom'
  l.store 'Mon', 'Seg'
  l.store 'Tue', 'Mar'
  l.store 'Wed', 'Qua'
  l.store 'Thu', 'Qui'
  l.store 'Fri', 'Sex'
  l.store 'Sat', 'Sáb'

  # worked_nice
  l.store '[wdhm]', '[sdhm]'
  l.store 'w', 's'
  l.store 'd', 'd'
  l.store 'h', 'h'
  l.store 'm', 'm'

  # Preferences
  l.store 'Duration Format', 'Duration Format'
  l.store 'Workday Length', 'Workday Length'
end
