require "test_helper"

# Shop#time_zone and Shopkeeper#time_zone accept only the names in
# ActiveSupport::TimeZone.all. The iOS app (TimeZoneData.swift, checked by
# TimeZoneDataTest) and the Android app (TimeZones.kt, checked by
# TimeZonesTest) embed this same list of names and labels for their time zone
# pickers, so a change here makes the apps send names the API rejects or miss
# new ones. Only the names are compared: the API stores and accepts the name, and
# the "(GMT+01:00)" labels and their order follow the tzdata in use (tzinfo-data
# 1.2026.6 moved Dublin from +00:00 to +01:00), so they are the apps' display
# text, not part of the contract. When this test fails after a Rails upgrade, a
# zone was added or removed: update test/fixtures/files/rails_time_zones.tsv and
# both apps.
class TimeZonesTest < ActiveSupport::TestCase
  test "Rails time zones match the list the apps embed" do
    # name<TAB>label per line, generated from activesupport 8.1.4 with
    # ActiveSupport::TimeZone.all.map { |z| [z.name, z.to_s].join("\t") }
    expected = file_fixture("rails_time_zones.tsv").readlines(chomp: true).map { |line| line.split("\t") }

    assert_equal 152, expected.size
    assert_equal expected.map(&:first).sort, ActiveSupport::TimeZone.all.map(&:name).sort
  end
end
