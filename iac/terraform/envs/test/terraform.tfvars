project        = "hiku"
environment    = "test"
location       = "polandcentral"
location_short = "plc"
owner_tag      = "hiku-team"
node_vm_size   = "Standard_B2s"
node_count     = 1

services = {
  activity               = { db_user = "activity-user", schema = "activity-service" }
  peaks-hikes            = { db_user = "peaks-hikes-user", schema = "peaks-hikes-service" }
  badge                  = { db_user = "badge-user", schema = "badge-service" }
  notification           = { db_user = "notification-user", schema = "notification-service" }
  scoreboards-challenges = { db_user = "scoreboards-challenges-user", schema = "scoreboards-challenges-service" }
  social-feed            = { db_user = "social-feed-user", schema = "social-feed-service" }
  trail-import           = { db_user = "trail-import-user", schema = "trail-import-service" }
  user                   = { db_user = "user-user", schema = "user-service" }
  weather                = { db_user = "weather-user", schema = "weather-service" }
}