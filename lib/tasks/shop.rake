namespace :shop do
  desc "create default item_tags"
  task create_default_item_tags: :environment do
    p "shop:create_default_item_tags start: #{Time.current}"

    Shop.find_each do |shop|
      shop.create_default_item_tags!
    rescue => ex
      p "shop:create_default_item_tags error Shop ID: #{shop.id}"
      p ex
    end

    p "shop:create_default_item_tags end: #{Time.current}"
  end
end
