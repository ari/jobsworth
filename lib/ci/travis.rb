namespace :ci do

  desc "Prepare for CI and run entire test suite"
  task :build do
    Rake::Task['db:schema:load'].invoke
    Rake::Task['db:migrate'].invoke
    # Rake::Task['assets:precompile'].invoke

    run_tasks 'test:units',
              'test:functionals',
              'test:integration',
              'spec'
  end

  def run_tasks(*tasks)
    tasks.each do |task|
      puts "\nRunning: #{task}"
      Rake::Task[task].prerequisites.clear
      Rake::Task[task].invoke
    end
  end

end
