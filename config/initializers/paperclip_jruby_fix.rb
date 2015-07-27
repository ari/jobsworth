if RUBY_PLATFORM == 'java'
  require 'image_resizer'

  Cocaine::CommandLine.runner = Cocaine::CommandLine::BackticksRunner.new
end

