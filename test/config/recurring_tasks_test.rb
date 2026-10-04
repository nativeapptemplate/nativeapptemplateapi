require "test_helper"
require "fugit"

# Solid Queue keeps finished jobs (preserve_finished_jobs defaults to true), so
# without a recurring cleanup the queue database only grows.
#
# The test database has no queue tables, so SolidQueue::RecurringTask (an
# Active Record model) can't be built here. These checks mirror its validation
# instead: the schedule must parse as a Fugit::Cron and a command must be set.
class RecurringTasksTest < ActiveSupport::TestCase
  CONFIG = ActiveSupport::ConfigurationFile.parse(Rails.root.join("config/recurring.yml"))

  %w[production staging].each do |env|
    test "#{env} clears finished Solid Queue jobs" do
      options = CONFIG.dig(env, "clear_solid_queue_finished_jobs")
      assert options, "config/recurring.yml has no clear_solid_queue_finished_jobs task for #{env}"

      assert_equal "SolidQueue::Job.clear_finished_in_batches(sleep_between_batches: 0.3)", options["command"]
      assert_includes SolidQueue::Job.method(:clear_finished_in_batches).parameters, [:key, :sleep_between_batches]
    end
  end

  test "every recurring task has a command and a supported schedule" do
    CONFIG.each do |env, tasks|
      tasks.each do |key, options|
        assert options["command"].present? || options["class"].present?, "#{env}.#{key} needs a command or class"
        assert_instance_of Fugit::Cron, Fugit.parse(options["schedule"].to_s, multi: :fail), "#{env}.#{key} schedule"
      end
    end
  end
end
