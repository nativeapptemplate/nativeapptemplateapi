require "test_helper"

class AdminUserTest < ActiveSupport::TestCase
  def valid_attributes
    {
      name: "Admin",
      email: "admin@example.com",
      password: "password"
    }
  end

  test "should be valid with valid attributes" do
    admin_user = AdminUser.new(valid_attributes)
    assert admin_user.valid?
  end

  test "should require email" do
    admin_user = AdminUser.new(valid_attributes.merge(email: nil))
    assert_not admin_user.valid?
    assert_includes admin_user.errors[:email], "can't be blank"
  end

  test "should require unique email" do
    AdminUser.create!(valid_attributes)
    duplicate = AdminUser.new(valid_attributes)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "should reject invalid email format" do
    admin_user = AdminUser.new(valid_attributes.merge(email: "not-an-email"))
    assert_not admin_user.valid?
    assert_not_empty admin_user.errors[:email]
  end

  test "should hash password using has_secure_password" do
    admin_user = AdminUser.create!(valid_attributes)
    assert_not_nil admin_user.password_digest
    assert_not_equal "password", admin_user.password_digest
  end

  test "authenticate returns admin_user when password matches" do
    admin_user = AdminUser.create!(valid_attributes)
    assert_equal admin_user, admin_user.authenticate("password")
  end

  test "authenticate returns false when password does not match" do
    admin_user = AdminUser.create!(valid_attributes)
    assert_equal false, admin_user.authenticate("wrong-password")
  end
end
