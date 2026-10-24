module ApplicationHelper
  def viewport_meta_tag(content: "width=device-width, initial-scale=1")
    tag.meta name: "viewport", content: content
  end
end
