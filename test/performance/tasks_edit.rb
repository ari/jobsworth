require File.join(File.dirname(__FILE__), 'performance_helper')

def task_edit(s)
  measures=[]
  1.upto(100) do |i|
    measures<< Benchmark.measure("task_num #{i}") {
      s.visit "/tasks/edit/#{i}"
    }
    raise Exception, s.current_url  unless s.current_url.include?("/tasks/edit/#{i}")
  end
  return measures
end
session=login()
puts "check task edit"
print_stats(task_edit(session))

puts 'check same task edit again, it should be cached'
print_stats(task_edit(session))
