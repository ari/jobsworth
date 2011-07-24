require  File.join(File.dirname(__FILE__), 'performance_helper')
def list(s)
  measures=[]
  1.upto(100) do |i|
    measures<< Benchmark.measure {
      s.visit "/tasks"
    }
    raise Exception, s.current_url  unless s.current_url.include?("/tasks")
  end
  return measures
end
session = login()
session.driver.browser.javascript_enabled =false
puts "get tasks first time, without caching"
p Benchmark.measure {
      session.visit "/tasks"
  }
puts "get tasks 100 times, should be cached"
print_stats(list(session))
