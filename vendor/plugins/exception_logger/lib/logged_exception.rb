class LoggedException < ActiveRecord::Base
  class << self
    def create_from_exception(controller, exception)
      create! \
        :exception_class => exception.class.name,
        :controller_name => controller.controller_name,
        :action_name     => controller.action_name,
        :message         => exception.message.inspect,
        :backtrace       => exception.backtrace,
        :request         => controller.request
    end
    
    def find_exception_class_names
      connection.select_values "SELECT DISTINCT exception_class FROM #{table_name} ORDER BY exception_class"
    end
    
    def find_exception_controllers_and_actions
      find(:all, :select => "DISTINCT controller_name, action_name", :order => "controller_name, action_name").collect(&:controller_action)
    end
    
    def host_name
      `hostname -s`.chomp
    end
  end

  def backtrace=(backtrace)
    if backtrace.is_a?(String)
      write_attribute :backtrace, backtrace
    else
      re = Regexp.new(/^#{Regexp.escape(rails_root)}/)
      write_attribute(:backtrace, backtrace.collect { |line| Pathname.new(line.gsub(re, "[RAILS_ROOT]")).cleanpath.to_s } * "\n")
    end
  end

  def request=(request)
    if request.is_a?(String)
      write_attribute :request, request
    else
      max = request.env.keys.max { |a,b| a.length <=> b.length }
      env = request.env.keys.sort.inject [] do |env, key|
        env << '* ' + ("%*-s: %s" % [max.length, key, request.env[key].to_s.strip])
      end
      write_attribute(:environment, (env << "* Process: #{$$}" << "* Server : #{self.class.host_name}") * "\n")
      
      write_attribute(:request, [
        "* URL: #{request.protocol}#{request.env["HTTP_HOST"]}#{request.request_uri}",
        "* Parameters: #{request.parameters.inspect}",
        "* Rails Root: #{rails_root}"
      ] * "\n")
    end
  end

  def controller_action
    "#{controller_name.camelcase}/#{action_name}"
  end

  private
    def sanitize_backtrace(trace)
      re = Regexp.new(/^#{Regexp.escape(rails_root)}/)
      trace.map { |line| Pathname.new(line.gsub(re, "[RAILS_ROOT]")).cleanpath.to_s }
    end

    def rails_root
      @rails_root ||= Pathname.new(RAILS_ROOT).cleanpath.to_s
    end
end