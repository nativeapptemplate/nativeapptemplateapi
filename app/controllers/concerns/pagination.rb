# Offset pagination for API index actions.
#
#   @page, @item_tags = paginate(@shop.item_tags.order(:position))
#   render json: ItemTagSerializer.new(@item_tags, meta: pagination_meta(@page)).serializable_hash
#
# The page number comes from params[:page]. Anything other than a positive
# whole number ("0", "-1", "2abc", page[x]=1) falls back to page 1. A page
# past the last one keeps its number and returns no records.
module Pagination
  DEFAULT_LIMIT = 20

  Page = Data.define(:number, :limit, :total_count) do
    def total_pages
      [(total_count.to_f / limit).ceil, 1].max
    end

    def offset
      (number - 1) * limit
    end

    def past_last_page?
      number > total_pages
    end
  end

  private

  def paginate(relation, limit: DEFAULT_LIMIT)
    page = Page.new(number: page_param, limit: limit, total_count: relation.count(:all))
    records = page.past_last_page? ? relation.none : relation.limit(limit).offset(page.offset)
    [page, records]
  end

  def pagination_meta(page)
    {
      current_page: page.number,
      total_pages: page.total_pages,
      total_count: page.total_count,
      limit: page.limit
    }
  end

  def page_param
    value = params[:page]
    (value.is_a?(String) && value.match?(/\A[1-9]\d*\z/)) ? value.to_i : 1
  end
end
