module JobsworthInitializer
  extend self

  ::Setting = Rails.application.config.jobsworth
  REQUIRED_DEFAULTS = {
    store_root:       Rails.root.join("store").to_s,
    from:             'fromnotset',
    domain:           'example.org',
    receiving_emails: { :secret => SecureRandom.hex(8) }
  }

  def init
    ensure_required_defaults
    load_version             if ENV['CI']
  end

private
  # Some settings are required, assign them default values if not already present
  def ensure_required_defaults
    REQUIRED_DEFAULTS.each do |key, value|
      next if Setting.key?(key)

      Setting[key] = value
      puts "WARNING: Could not find setting #{key.inspect} for #{Rails.env} environment in config/application.yml"
      puts "         Defaulting #{key.inspect} to #{Setting[key].inspect}"
    end
  end

  # Read jenkins build version if it exists
  def load_version
    version_file = Rails.root.join("config", "jenkins.build")
    Setting.version = File.read(version_file) if File.exists? version_file
  end

end

JobsworthInitializer.init
