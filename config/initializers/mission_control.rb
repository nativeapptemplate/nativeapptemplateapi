# Disable built-in HTTP Basic authentication for MissionControl::Jobs.
# Access is protected by AdminConstraint in routes.rb instead.
Rails.application.config.mission_control.jobs.http_basic_auth_enabled = false
