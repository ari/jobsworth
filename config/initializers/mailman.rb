BAD_SUBJECTS = YAML.load_file(File.join(Rails.root, 'config/bad_subjects.yml'))['bad_subject']
MAX_ATTACHMENT_SIZE = 5*1024*1024
MAX_ATTACHMENT_SIZE_HUMAN = "5MB"
