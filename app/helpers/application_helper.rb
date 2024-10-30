module ApplicationHelper
  def viewport_meta_tag(content: "width=device-width, initial-scale=1", turbo_native: "maximum-scale=1.0, user-scalable=0")
    full_content = [content].compact.join(", ")
    tag.meta name: "viewport", content: full_content
  end
end
