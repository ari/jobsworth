require  File.join(File.dirname(__FILE__), 'performance_helper')
def list(s)
  measures=[]
  1.upto(100) do |i|
    measures<< Benchmark.measure {
      s.visit "/tasks/list"
    }
    raise Exception, s.current_url  unless s.current_url.include?("/tasks/list")
  end
  return measures
end
session = login()
session.driver.browser.javascript_enabled =false
puts "get tasks/list first time, without caching"
p Benchmark.measure {
      session.visit "/tasks/list"
  }
puts "get tasks/list 100 times, should be cached"
print_stats(list(session))
