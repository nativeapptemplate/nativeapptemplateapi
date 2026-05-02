namespace :item_tags do
  desc "Backfill position for existing item_tags grouped by shop, ordered by created_at"
  task backfill_position: :environment do
    ActsAsTenant.without_tenant do
      Shop.find_each do |shop|
        next_position = (shop.item_tags.maximum(:position) || 0) + 1

        shop.item_tags.where(position: nil).order(:created_at, :id).each do |item_tag|
          item_tag.update_columns(position: next_position)
          puts "Shop #{shop.id} - ItemTag #{item_tag.id}: position=#{next_position}"
          next_position += 1
        end
      end
    end

    puts "Done."
  end
end
