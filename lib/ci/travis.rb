namespace :ci do

  desc "Prepare for CI and run entire test suite"
  task :build do
    # Rake::Task['assets:precompile'].invoke

    run_tasks 'test:units',
              'test:functionals',
              'test:integration',
              'spec',
              'cucumber:all'
  end

  def run_tasks(*tasks)
    tasks.each do |task|
      puts "\nRunning: #{task}"

      prepare_tests
      Rake::Task[task].prerequisites.clear
      Rake::Task[task].invoke
    end
  end

  def prepare_tests
    puts "Prepare database"
    silence do
      Rake::Task['db:schema:load'].reenable
      Rake::Task['db:schema:load'].invoke
      Rake::Task['db:migrate'].reenable
      Rake::Task['db:migrate'].invoke
    end
  end

  def silence
    orig_stderr = $stderr.clone
    orig_stdout = $stdout.clone

    $stderr.reopen File.new('/dev/null', 'w')
    $stdout.reopen File.new('/dev/null', 'w')

    yield
  rescue Exception => e
    $stdout.reopen orig_stdout
    $stderr.reopen orig_stderr
    raise e
  ensure
    $stdout.reopen orig_stdout
    $stderr.reopen orig_stderr
  end

end
