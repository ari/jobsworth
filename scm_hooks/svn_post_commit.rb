#!/usr/bin/ruby
require 'rubygems'
require 'time'
require 'net/http'
require 'json'
require 'net/https'


# You will need to change the following two lines
########################
jobsworth_url = "http://demo.getjobsworth.org"
key = "1fbb4b951f5f"
########################

receiver = jobsworth_url + "/api/scm/json/" + key


svnlook = "/usr/bin/svnlook"

if ARGV.size<2
  puts "Usage: post_commit.rb REPO REV"
  return 0
end
repository= ARGV[0]
revision= ARGV[1]
commit={ }
commit[:revision] = revision
commit[:message] = `#{svnlook} log #{repository} -r #{revision}`.strip
commit[:author] = `#{svnlook} author #{repository} -r #{revision}`.strip
commit[:timestamp] = Time.parse(`#{svnlook} date #{repository} -r #{revision}`.strip).to_i
changed = `#{svnlook} changed #{repository} -r #{revision}`.split(/\n/).collect{ |line| line.split(' ')}
commit[:path_count]=changed.size
commit[:modified]=[]
commit[:added]=[]
commit[:removed]=[]
changed.each do |line|
  case line[0]
    when 'A' then commit[:added]<< line[-1]
    when 'D' then commit[:removed]<< line[-1]
    else  commit[:modified]<< line[-1]
  end
end

uri=URI.parse(receiver)
if uri.scheme == 'https'
  http = Net::HTTP.new(uri.host, 443)
  http.use_ssl=true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
else
  http = Net::HTTP.new(uri.host)
end

req = Net::HTTP::Post.new(uri.path)
req.form_data =  {"payload"=>  { :revisions=>[commit] }.to_json}

http.request(req)
