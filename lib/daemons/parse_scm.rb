#!/usr/bin/env ruby

#You might want to change this
ENV["RAILS_ENV"] ||= "development"

require File.dirname(__FILE__) + "/../../config/environment"

$running = true;
Signal.trap("TERM") do
  $running = false
end

def handle_cvs_log( p, file, options )

  puts "#{file.name}: [#{options[:author]}] #{options[:revision]} - #{options[:date]}, state: #{options[:state]}"

  u = User.find(:first, :conditions => ["company_id = ? AND username = ?", p.company_id, options[:author]])


  set = ScmChangeset.find(:first, :conditions => ["project_id = ? AND commit_date < ? AND commit_date > ? AND author = ? AND message = ?", p.project_id, options[:date] + 30.seconds, options[:date] - 30.seconds, options[:author], options[:message]])
  if set.nil?
    set = ScmChangeset.new
    set.scm_project_id = p.id
    set.company_id = p.company_id
    set.project_id = p.project_id
    set.user_id = u.id unless u.nil?
    set.author = options[:author]
    set.commit_date = options[:date]
    set.message = options[:message]
    set.changeset_num = ScmChangeset.maximum('changeset_num', :conditions => ["company_id = ?", p.company_id]).to_i + 1
    set.save

    worklog = WorkLog.new
    worklog.user_id = u.id unless u.nil?
    worklog.company_id = p.company_id
    worklog.customer_id = p.project.customer_id
    worklog.project_id = p.project_id
    worklog.task = nil
    worklog.scm_changeset_id = set.id
    worklog.started_at = options[:date]
    worklog.duration = 0
    worklog.log_type = WorkLog::SCM_COMMIT
    worklog.body = options[:message]
    worklog.save

  end

  if file.commit_date.nil? || file.commit_date < options[:date]
    file.commit_date = options[:date]
    file.state = options[:state]
    file.save
  end

  if p.last_commit_date.nil? || p.last_commit_date < options[:date]
    p.last_commit_date = options[:date]
    p.save
  end

  rev = ScmRevision.new
  rev.company_id = p.company_id
  rev.project_id = p.project_id
  rev.scm_file = file
  rev.user_id = u.id unless u.nil?
  rev.scm_changeset = set
  rev.revision = options[:revision]
  rev.author = options[:author]
  rev.commit_date = options[:date]
  rev.state = options[:state]
  rev.save
end

def get_file_entry(p, filename)
  file = ScmFile.find(:first, :conditions => ["project_id = ? AND path = ?", p.project_id, filename])
  if file.nil?
    file = ScmFile.new
    file.project_id = p.project_id
    file.company_id = p.company_id
    file.name = filename.split('/').last
    file.path = filename

    file.save
  end
  file
end

def handle_cvs_entry(p,f)

  _, filename = /^Working file: (.*)$/.match(f.gets.chomp).to_a

  if filename


    line = f.gets.chomp
    while( line =~ /^[^-]+$/ )
      line = f.gets.chomp rescue begin
                                   puts "CVS EOF"
                                   return false
                                 end
    end

#   _, head = /^head: (.*)$/.match(f.gets.chomp).to_a
#   _, branch = /^branch: (.*)$/.match(f.gets.chomp).to_a
#   _, locks = /^locks: (.*)$/.match(f.gets.chomp).to_a
#   _, access_list = /^access list: (.*)$/.match(f.gets.chomp).to_a

#   _, keyword_substitution = /^keyword substitution: (.*)$/.match(f.gets.chomp).to_a
#   _, total_revisions, selected_revisions = /^total revisions: (.*);\s+selected revisions: (.*)/.match(f.gets.chomp).to_a
#   _, description = /^description: (.*)$/.match(f.gets.chomp).to_a
#    line = f.gets.chomp

#    if branch.nil?
      branch = "HEAD"
#    end


    revision = ""
    date = ""
    author = ""
    state = ""
    message = ""

    while line =~ /^[^=]+/
      line = f.gets.chomp
      if line =~ /^revision (.*)$/
        _,revision = /^revision (.*)$/.match(line).to_a
      elsif line =~ /^date: .*/
        _,date, author, state = /^date: (.*);\W+author: (.*);\W+state: (.*);.*$/.match(line).to_a

        unless date =~ / [-+]\d+^/
          date << " +0000"
        end

        date = Time.parse(date).utc #.strftime("%Y-%m-%d %H:%M:%S")
      elsif line =~ /^----------------------------$/
        file = get_file_entry(p, filename)
        handle_cvs_log( p, file, { :author => author, :state => state, :revision => revision, :date => date, :message => message} )
        message = ''
        next
      elsif line =~ /^=============================================================================$/
        file = get_file_entry(p, filename)
        handle_cvs_log( p, file, { :author => author, :state => state, :revision => revision, :date => date, :message => message} )
        next
      else
        message << line + "\n"
      end
    end

  end

  true
end

def handle_svn_entry( p, f )
  line = f.gets.chomp rescue begin
                               puts "SVN EOF"
                               return false
                             end
  comment = ''
  _, revision, author, date = /^r(\d+) \| (.*) \| (.*) \| .*$/.match(line).to_a

  u = User.find(:first, :conditions => ["company_id = ? AND username = ?", p.company_id, author]) unless author.nil?

  date = Time.parse(date).utc

  if revision.to_i > 0

    set = ScmChangeset.find(:first, :conditions => ["scm_project_id = ? AND changeset_rev = ?", p.id, revision])
    return false unless set.nil?

    puts "Found rev #{revision} - #{author} - #{date}"

    set = ScmChangeset.new
    set.scm_project_id = p.id
    set.company_id = p.company_id
    set.project_id = p.project_id
    set.user_id = u.id unless u.nil?
    set.author = author
    set.commit_date = date
    set.changeset_num = ScmChangeset.maximum('changeset_num', :conditions => ["company_id = ?", p.company_id]).to_i + 1
    set.changeset_rev = revision

    files = []
    line = f.gets.chomp
    if line =~ /^Changed paths:$/
      line = f.gets.chomp
      while( !line.empty? )
        _, filename = /^   [MDAR] (.*)$/.match(line).to_a
        return false if filename.nil?
        files << filename


        file = ScmFile.find(:first, :conditions => ["project_id = ? AND path = ?", p.project_id, filename])
        if file.nil?
          puts "Adding #{filename}"
          file = ScmFile.new
          file.project_id = p.project_id
          file.company_id = p.company_id
          file.name = filename.split('/').last
          file.path = filename

          file.save
        end
        line = f.gets.chomp
      end

      while( line != '------------------------------------------------------------------------' )
        comment << "\n" unless comment.empty?
        comment << line
        line = f.gets.chomp
      end

      set.message = comment
      set.save

      worklog = WorkLog.new
      worklog.user_id = u.id unless u.nil?
      worklog.company_id = p.company_id
      worklog.customer_id = p.project.customer_id
      worklog.project_id = p.project_id
      worklog.task = nil
      worklog.scm_changeset_id = set.id
      worklog.started_at = date
      worklog.duration = 0
      worklog.log_type = WorkLog::SCM_COMMIT
      worklog.body = comment
      worklog.save



      files.each do | filename |
        file = ScmFile.find(:first, :conditions => ["project_id = ? AND path = ?", p.project_id, filename])

        if file.commit_date.nil? || file.commit_date < date
          file.commit_date = date
#          file.state = state
          file.save
        end

        if p.last_commit_date.nil? || p.last_commit_date < date
          p.last_commit_date = date
          p.save
        end


        rev = ScmRevision.new
        rev.company_id = p.company_id
        rev.project_id = p.project_id
        rev.scm_file = file
        rev.user_id = u.id unless u.nil?
        rev.scm_changeset = set
        rev.revision = revision
        rev.author = author
        rev.commit_date = date
#        rev.state = options[:state]
        rev.save

      end

    end
    return true
  end

  false
end

while($running) do

#       ActiveRecord::Base.logger << "This daemon is still running at #{Time.now}.\n"


  scm_projects = ScmProject.find(:all)

  scm_projects.each do |p|

    puts "Checking #{p.company.name} / #{p.project.name}"

    p.last_update = Time.now
    p.save

    if p.scm_type == 'cvs'

      if p.last_checkout.nil?
        puts "Running cvs co #{p.location} #{p.module} in /scm/#{p.company_id}/#{p.project_id}/#{p.id}"
        Dir.mkdir(File.dirname(__FILE__) + "/../../scm/#{p.company_id}/") rescue 1
        Dir.mkdir(File.dirname(__FILE__) + "/../../scm/#{p.company_id}/#{p.project_id}/") rescue 1
        Dir.chdir(File.dirname(__FILE__) + "/../../scm/#{p.company_id}/#{p.project_id}/") {
          system("cvs -d #{p.location} co -d #{p.id} #{p.module}")
        } rescue puts "Something wrong on cvs co"

        p.last_checkout = Time.now
        p.save

        Dir.chdir(File.dirname(__FILE__) + "/../../scm/#{p.company_id}/#{p.project_id}/#{p.id}") {
          puts "Running cvs log in /scm/#{p.company_id}/#{p.project_id}/#{p.id}: cvs -q log -N > ../#{p.id}_cvslog"

          system("cvs -q log -N > ../#{p.id}_cvslog")
        } rescue puts "Something wrong on cvs log"
      else
        Dir.chdir(File.dirname(__FILE__) + "/../../scm/#{p.company_id}/#{p.project_id}/#{p.id}") {
          puts "Running cvs update in /scm/#{p.company_id}/#{p.project_id}/#{p.id}"
          system("cvs -q update -d")

          p.last_update = Time.now
          p.save
        } rescue puts "Something wrong on cvs update"

        Dir.chdir(File.dirname(__FILE__) + "/../../scm/#{p.company_id}/#{p.project_id}/#{p.id}") {
          puts "Running cvs log in /scm/#{p.company_id}/#{p.project_id}/#{p.id}: cvs -q log -N -d \">#{p.last_commit_date.strftime("%Y-%m-%d %H:%M:%S +0000")}\" > ../#{p.id}_cvslog"

          system("cvs -q log -N -d \">#{p.last_commit_date.strftime("%Y-%m-%d %H:%M:%S +0000")}\" > ../#{p.id}_cvslog")
        } rescue puts "Something wrong on cvs log"
      end


      puts "Parsing cvs log file..."

      f = File.open(File.dirname(__FILE__) + "/../../scm/#{p.company_id}/#{p.project_id}/#{p.id}_cvslog", "r");

      while line = f.gets
        line.chomp!

        # Ignore unknown files
        if line =~ /^\?/
          next
        end

        next if line.empty?

        next if handle_cvs_entry(p,f)
    end

    elsif p.scm_type == 'svn'

      if p.last_checkout.nil?
        puts "Making directories [scm/#{p.company_id}/#{p.project_id}/#{p.id}]"
        Dir.mkdir(File.dirname(__FILE__) + "/../../scm/#{p.company_id}/") rescue 1
        Dir.mkdir(File.dirname(__FILE__) + "/../../scm/#{p.company_id}/#{p.project_id}/") rescue 1

        p.last_checkout = Time.now
        p.last_update = Time.now
        p.save
        puts "Running svn log in [scm/#{p.company_id}/#{p.project_id}/#{p.id}]"
        system("svn -v log --non-interactive #{p.location} --revision 1:HEAD > " + File.dirname(__FILE__) + "/../../scm/#{p.company_id}/#{p.project_id}/#{p.id}_svnlog") rescue puts "Error on initial svn update."
      else
        Dir.chdir(File.dirname(__FILE__) + "/../../scm/#{p.company_id}/#{p.project_id}/") {
          p.last_update = Time.now
          p.save
          puts "Running svn log in [scm/#{p.company_id}/#{p.project_id}/#{p.id}]"
          system("svn -v log --non-interactive #{p.location} > #{p.id}_svnlog")
        } rescue puts "Something wrong on svn log"
      end

      puts "Parsing svn log file..."

      f = File.open(File.dirname(__FILE__) + "/../../scm/#{p.company_id}/#{p.project_id}/#{p.id}_svnlog", "r")
      line = f.gets
      while( handle_svn_entry(p,f) )
      end

#    File.delete(File.dirname(__FILE__) + "/../../scm/#{p.company_id}/#{p.project_id}/#{p.id}_svnlog")

    end

  end
  puts "Done..."
  sleep 10*60
end

