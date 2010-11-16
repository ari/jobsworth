require 'rubygems'
require 'capybara'
require 'benchmark'

LOGIN='admin'
PASSWORD='password'

Capybara.default_selector = :css
Capybara.app_host = "jobsworth.localhost.my:3000"
Capybara.run_server = false

def login
  s=Capybara::Session.new(:celerity)
  s.visit('/login/login')
  s.fill_in 'password', :with=>PASSWORD
  s.fill_in 'username', :with => LOGIN
  s.click_button "submit_button"
  return s
end

def print_stats(measures)
  puts "max  real #{measures.max{ |m, x| m.real <=> x.real}}"
  puts "min  real #{measures.min{ |m, x| m.real <=> x.real}}"
  avg=measures.inject(0){ |sum, m| sum + m.real}/measures.size
  puts "avg  real #{avg}"
  GC.start
end
