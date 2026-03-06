require "test_helper"

class PermissionSerializerTest < ActiveSupport::TestCase
  def setup
    @permission = Permission.first
  end

  test "should serialize basic attributes" do
    serializer = PermissionSerializer.new(@permission)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert_equal @permission.name, attributes[:name]
    assert_equal @permission.tag, attributes[:tag]
  end

  test "should serialize timestamps" do
    serializer = PermissionSerializer.new(@permission)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert attributes[:created_at]
    assert attributes[:updated_at]
  end

  test "should have correct type" do
    serializer = PermissionSerializer.new(@permission)
    serialized = serializer.serializable_hash

    assert_equal "permission", serialized[:data][:type].to_s
  end

  test "should have correct id" do
    serializer = PermissionSerializer.new(@permission)
    serialized = serializer.serializable_hash

    assert_equal @permission.id, serialized[:data][:id]
  end

  test "should not include position attribute" do
    serializer = PermissionSerializer.new(@permission)
    serialized = serializer.serializable_hash

    attributes = serialized[:data][:attributes]
    assert_nil attributes[:position]
  end
end
