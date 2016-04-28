namespace :jobsworth do
  desc 'Set valid timezones for users'
  task set_valid_timezones: :environment do
    valid_zones = TZInfo::Timezone.all_identifiers
    User.where.not(time_zone:  valid_zones).update_all(time_zone: User::DEFAULT_TIMEZONE)
  end
end