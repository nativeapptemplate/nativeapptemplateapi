require "test_helper"

# The previews at /rails/mailers (development) are how to look at the mails;
# add ?locale=ja for Japanese. They build their records in memory, so they
# render on an empty database and never save anything
class Shopkeeper::NotificationMailerPreviewTest < ActionMailer::TestCase
  %i[en ja].each do |locale|
    %w[invited confirmation_instructions reset_password_instructions].each do |email|
      test "the #{email} preview renders in #{locale}" do
        preview = ActionMailer::Preview.find("shopkeeper/notification_mailer")
        assert preview, "test/mailers/previews/shopkeeper/notification_mailer_preview.rb is missing"

        assert_no_difference %w[Shopkeeper.count Account.count AccountsInvitation.count] do
          I18n.with_locale(locale) do
            mail = preview.call(email)

            assert mail.subject.present?
            assert_includes mail.html_part.body.decoded, %(<html lang="#{locale}">)
          end
        end
      end
    end
  end
end
