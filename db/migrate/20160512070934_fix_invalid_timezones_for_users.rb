class FixInvalidTimezonesForUsers < ActiveRecord::Migration
  def change
    valid_zones = TZInfo::Timezone.all_identifiers
    User.where.not(time_zone:  valid_zones).update_all(time_zone: User::DEFAULT_TIMEZONE)
  end
end
