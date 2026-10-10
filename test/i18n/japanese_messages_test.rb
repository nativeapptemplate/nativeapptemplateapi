require "test_helper"

# Composed Japanese messages that a translation review found broken. Expected
# strings are errors.format "%{attribute}%{message}" applied to the attribute
# name and message in config/locales/ja.yml / rails.ja.yml.
class JapaneseMessagesTest < ActiveSupport::TestCase
  setup do
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
  end

  def ja(&) = I18n.with_locale(:ja, &)

  # Bug: support.array was missing, so joined errors read "A, B, and C"
  test "joins several errors with Japanese commas" do
    assert_equal "A、B、C", ja { %w[A B C].to_sentence }
    assert_equal "A、B", ja { %w[A B].to_sentence }
  end

  # Bug: current_platform prints only its message (format "%{message}"), and
  # only blank was overridden, so an unknown platform read "は一覧にありません"
  test "an unknown platform gets the spam-protection message" do
    shopkeeper = Shopkeeper.new(current_platform: "web")
    ja { shopkeeper.valid? }
    assert_equal ["入力データが正しくありません。"], ja { shopkeeper.errors.full_messages_for(:current_platform) }

    shopkeeper.valid?
    assert_equal ["Your input data is wrong."], shopkeeper.errors.full_messages_for(:current_platform)
  end

  # Bug: accepting an invitation as an existing member showed "ユーザーはすでに存在します"
  test "an existing member is told they already belong to the organization" do
    member = AccountsShopkeeper.new(account: @account, shopkeeper: @shopkeeper, member: true)

    ja { member.valid? }
    assert_equal ["ユーザーはすでにこの組織のメンバーです"], ja { member.errors.full_messages }
    member.valid?
    assert_equal ["User is already a member of this organization"], member.errors.full_messages
  end

  # Bug: an invalid reset link read "Reset password tokenは不正な値です"
  test "an invalid password reset link reads as Japanese" do
    shopkeeper = Shopkeeper.reset_password_by_token(reset_password_token: "no-such-token", password: "password1", password_confirmation: "password1")

    assert_equal ["パスワード再設定用のリンクが無効か、有効期限が切れています。もう一度パスワードの再設定をリクエストしてください"],
      ja { shopkeeper.errors.full_messages }
  end

  # Roles are chosen, not typed
  test "a missing role asks to choose one" do
    invitation = AccountsInvitation.new(account: @account, name: "x", email: "x@example.com")

    ja { invitation.valid? }
    assert_equal ["権限を選択してください"], ja { invitation.errors.full_messages_for(:roles) }
  end
end
