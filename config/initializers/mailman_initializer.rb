MAILMAN_BAD_SUBJECTS = YAML.load_file(File.join(Rails.root, 'config/bad_subjects.yml'))['bad_subject'].collect { |s| s.strip }
