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

  # The edit form sends every field it shows, not just the one the admin changed, so
  # empty token fields arrive as "". Ported from myturntagapi, where in production
  # (2026-10-17) saving a shopkeeper whose reset_password_token was nil failed with
  # PG::UniqueViolation on index_shopkeepers_on_reset_password_token,
  # "Key (reset_password_token)=() already exists", because an earlier save had
  # stored "" on another shopkeeper.
  test "saves the shopkeeper edit form as the browser submits it" do
    shopkeepers(:two).update_columns(reset_password_token: "", confirmation_token: "")
    @shopkeeper.update_columns(reset_password_token: nil, confirmation_token: nil)
    sign_in_admin
    get ShopkeeperResource.edit_path(@shopkeeper)
    assert_response :success

    form = Nokogiri::HTML(response.body).at_css("form[action$='/shopkeepers/#{@shopkeeper.id}']")
    fields = form_fields(form).map do |name, value|
      (name == "shopkeeper[name]") ? [name, "Renamed by admin"] : [name, value]
    end

    patch madmin_shopkeeper_path(@shopkeeper), params: URI.encode_www_form(fields),
      headers: {"CONTENT_TYPE" => "application/x-www-form-urlencoded"}
    assert_redirected_to madmin_shopkeeper_path(@shopkeeper)
    assert_equal "Renamed by admin", @shopkeeper.reload.name
  end

  # The only way to grant the full feature access override; the apps cannot set it
  test "sets feature_access_state from the shopkeeper edit form" do
    assert_predicate @shopkeeper, :normal_feature_access?
    sign_in_admin
    get ShopkeeperResource.edit_path(@shopkeeper)
    assert_response :success

    form = Nokogiri::HTML(response.body).at_css("form[action$='/shopkeepers/#{@shopkeeper.id}']")
    fields = form_fields(form)
    assert fields.any? { |name, _| name == "shopkeeper[feature_access_state]" }, "the edit form has no feature_access_state field"
    fields = fields.map do |name, value|
      (name == "shopkeeper[feature_access_state]") ? [name, "all_feature_access"] : [name, value]
    end

    patch madmin_shopkeeper_path(@shopkeeper), params: URI.encode_www_form(fields),
      headers: {"CONTENT_TYPE" => "application/x-www-form-urlencoded"}
    assert_redirected_to madmin_shopkeeper_path(@shopkeeper)
    assert_predicate @shopkeeper.reload, :all_feature_access?
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

  # [name, value] pairs a browser sends for the form: filled inputs and textareas,
  # checked boxes and the selected options of each select
  def form_fields(form)
    form.css("input, textarea, select").flat_map do |field|
      name = field["name"]
      next [] if name.blank? || field["disabled"] || %w[submit button].include?(field["type"])

      case field.name
      when "select" then field.css("option[selected]").map { |option| [name, option["value"] || option.text] }
      when "textarea" then [[name, field.text]]
      else
        next [] if %w[checkbox radio].include?(field["type"]) && !field["checked"]
        [[name, field["value"].to_s]]
      end
    end
  end

  def sign_in_admin
    post admin_session_path, params: {email: @admin_user.email, password: "password"}
  end
end
