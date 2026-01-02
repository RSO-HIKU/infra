project        = "hiku"
environment    = "test"
location       = "polandcentral"
location_short = "plc"
owner_tag      = "hiku-team"
node_vm_size   = "Standard_B2s"
node_count     = 1

services = {
  activity = { db_user = "activity_user", schema = "activity_service" }
  peaks_hikes = { db_user = "peaks_hikes_user", schema = "peaks_hikes_service" }
  badge = { db_user = "badge_user", schema = "badge_service"}
  notification = { db_user = "notification_user", schema = "notification_service"}
  scoreboards_challenges = { db_user = "scoreboards_challenges_user", schema = "scoreboards_challenges_service"}
  social_feed = { db_user = "social_feed_user", schema = "social_feed_service"}
  trail_import = { db_user = "trail_import_user", schema = "trail_import_service"}
  user = { db_user = "user_user", schema = "user_service"}
  weather = { db_user = "weather_user", schema = "weather_service"}
}