require "test_helper"

# No model aborts its own destroy today, but if a before_destroy guard is
# added later, a halted destroy must not be reported as a success.
class DestroyFailureTest < ActionDispatch::IntegrationTest
  setup do
    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @headers = @shopkeeper.create_new_auth_token
    @account = Account.create!(name: "Team", owner: @shopkeeper, personal: false)
    AccountsShopkeeper.create!(account: @account, shopkeeper: @shopkeeper, admin: true)
  end

  test "each destroy endpoint answers 422 and keeps the record when the destroy is halted" do
    other = shopkeepers(:two)
    member = AccountsShopkeeper.create!(account: @account, shopkeeper: other, member: true)
    invitation = AccountsInvitation.create!(account: @account, name: "Invitee", email: "invitee@example.com", member: true)
    shop = ActsAsTenant.without_tenant { @account.shops.first }
    item_tag = ActsAsTenant.without_tenant { shop.item_tags.first }
    device = ApplicationPushDevice.create!(owner: @shopkeeper, platform: "apple", token: "halted-destroy")
    prefix = "/#{@account.id}/api/v1/shopkeeper"

    {
      @account => "#{prefix}/accounts/#{@account.id}",
      shop => "#{prefix}/shops/#{shop.id}",
      item_tag => "#{prefix}/item_tags/#{item_tag.id}",
      member => "#{prefix}/accounts/#{@account.id}/members/#{member.id}",
      invitation => "#{prefix}/accounts/#{@account.id}/invitations/#{invitation.token}",
      device => "#{prefix}/devices/#{device.id}"
    }.each do |record, path|
      halting_destroy_of(record.class) { delete path, headers: @headers }

      assert_response :unprocessable_entity, path
      assert_equal 422, response.parsed_body["code"], path
      assert response.parsed_body["error_message"].present?, path
      assert ActsAsTenant.without_tenant { record.class.exists?(record.id) }, "#{record.class} was deleted"
    end
  end

  private

  def halting_destroy_of(model)
    halt = -> { throw :abort }
    model.before_destroy(halt, prepend: true)
    yield
  ensure
    model.skip_callback(:destroy, :before, halt)
  end
end
