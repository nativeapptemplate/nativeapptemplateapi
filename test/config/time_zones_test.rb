require "test_helper"

# Shop#time_zone and Shopkeeper#time_zone accept only the names in
# ActiveSupport::TimeZone.all. The iOS app (TimeZoneData.swift, checked by
# TimeZoneDataTest) and the Android app (TimeZones.kt, checked by
# TimeZonesTest) embed this same list of names and labels for their time zone
# pickers, so a change here makes the apps send names the API rejects or miss
# new ones. When this test fails after a Rails or tzdata upgrade, update
# test/fixtures/files/rails_time_zones.tsv and both apps.
class TimeZonesTest < ActiveSupport::TestCase
  test "Rails time zones match the list the apps embed" do
    # name<TAB>label per line, generated from activesupport 8.1.4 with
    # ActiveSupport::TimeZone.all.map { |z| [z.name, z.to_s].join("\t") }
    expected = file_fixture("rails_time_zones.tsv").readlines(chomp: true).map { |line| line.split("\t") }

    assert_equal 152, expected.size
    assert_equal expected, ActiveSupport::TimeZone.all.map { |zone| [zone.name, zone.to_s] }
  end
end
