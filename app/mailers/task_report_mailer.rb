class TaskReportMailer < ActionMailer::Base
  default from: 'support@ish.com.au'

  def send_report(company)
    attachments.inline['report.html'] = File.read('tmp/report.html')
    mail(to: company, subject: 'Task Report')
  end
end
