module ApplicationHelper
  def viewport_meta_tag(content: "width=device-width, initial-scale=1", turbo_native: "maximum-scale=1.0, user-scalable=0")
    full_content = [content].compact.join(", ")
    tag.meta name: "viewport", content: full_content
  end

  def item_tag_border_class(type_param:, item_tag_id_param:, item_tag_id:)
    (type_param == "customer" && item_tag_id_param == item_tag_id) ? "ring-4 ring-rose-500 ring-offset-2 ring-offset-rose-200" : ""
  end
end
