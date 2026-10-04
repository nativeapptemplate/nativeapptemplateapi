require "test_helper"

class MadminTest < ActionDispatch::IntegrationTest
  READONLY_RESOURCES = [ActiveStorage::BlobResource, ActiveStorage::VariantRecordResource].freeze

  setup do
    @admin_user = AdminUser.create!(name: "Admin", email: "admin@example.com", password: "password")

    @shopkeeper = shopkeepers(:one)
    @shopkeeper.create_default_account
    @account = @shopkeeper.accounts.first
    @shop = @shopkeeper.created_shops.first

    ActsAsTenant.with_tenant(@account) do
      AccountsInvitation.create!(account: @account, name: "Invitee", email: "invitee@example.com", invited_by: @shopkeeper, member: true)
      ItemTagNotifier.with(record: @shop.item_tags.first).deliver(@shopkeeper)
    end
    ApplicationPushDevice.create!(owner: @shopkeeper, platform: "apple", token: "madmin-test-token")

    @blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("hello"), filename: "hello.txt", content_type: "text/plain")
    ActiveStorage::Attachment.create!(name: "file", record: @shop, blob: @blob)
    ActiveStorage::VariantRecord.create!(blob: @blob, variation_digest: "madmin-test")
  end

  test "redirects guests away from the dashboard" do
    get madmin_root_path
    assert_redirected_to "/"
  end

  test "renders the dashboard" do
    sign_in_admin
    get madmin_root_path
    assert_response :success
  end

  test "renders index, show and edit for every resource" do
    sign_in_admin

    Madmin.resources.each do |resource|
      get resource.index_path
      assert_response :success, "#{resource} index"

      record = resource.model.first
      assert record, "#{resource} needs a record in setup so its show page is covered"

      get resource.show_path(record)
      assert_response :success, "#{resource} show"

      next if resource.readonly?

      get resource.edit_path(record)
      assert_response :success, "#{resource} edit"
    end
  end

  test "updates a record" do
    sign_in_admin

    patch madmin_shop_path(@shop), params: {shop: {name: "Renamed by admin"}}
    assert_redirected_to madmin_shop_path(@shop)
    assert_equal "Renamed by admin", @shop.reload.name
  end

  test "blobs and variant records hide write actions" do
    sign_in_admin

    READONLY_RESOURCES.each do |resource|
      assert resource.readonly?, "#{resource} should be read only"

      get resource.index_path
      assert_response :success
      assert_select "a[href$='/new']", {count: 0}, "#{resource} index shows a New link"

      record = resource.model.first
      get resource.show_path(record)
      assert_response :success
      assert_select "a[href$='/edit']", {count: 0}, "#{resource} show has an Edit link"
    end
  end

  test "blobs and variant records have no write routes" do
    sign_in_admin

    # Only index and show are drawn, so the write paths fall through to show
    # with id "new" or to no route at all
    get "/madmin/active_storage/blobs/new"
    assert_response :not_found

    assert_no_difference "ActiveStorage::Blob.count" do
      delete "/madmin/active_storage/blobs/#{@blob.id}"
    end
    assert_response :not_found

    assert_no_difference "ActiveStorage::VariantRecord.count" do
      delete "/madmin/active_storage/variant_records/#{ActiveStorage::VariantRecord.first.id}"
    end
    assert_response :not_found
  end

  private

  def sign_in_admin
    post admin_session_path, params: {email: @admin_user.email, password: "password"}
  end
end
