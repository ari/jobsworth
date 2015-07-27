if RUBY_PLATFORM == 'java'
  Cocaine::CommandLine.runner = Cocaine::CommandLine::BackticksRunner.new
end

