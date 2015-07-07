if RUBY_PLATFORM == 'java'
  require 'image_resizer'

  Cocaine::CommandLine.runner = Cocaine::CommandLine::BackticksRunner.new

  Paperclip::Processor.module_eval do
    def convert_with_java arguments = "", local_options = {}
      arguments =~ /resize "([0-9]+)x([0-9]+)"/
      width, height = $1, $2
      source = local_options[:source].gsub(/\[0\]$/, '')
      dest = local_options[:dest]
      ImageResizer.resize(source, width.to_i, height.to_i, dest)
    end
    alias_method_chain :convert, :java
  end
end

