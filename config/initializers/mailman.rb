BAD_SUBJECTS = YAML.load_file(File.join(Rails.root, 'config/bad_subjects.yml'))['bad_subject'].collect { |s| s.strip }
MAX_ATTACHMENT_SIZE = 5*1024*1024
