module BundleAssets
  # Automatically compiles assets if yarn build commands aren't running

  extend ActiveSupport::Concern

  included do
    before_action :ensure_assets_bundled, if: -> { Rails.env.development? }
  end

  private

  def ensure_assets_bundled
    if ["application.js", "application.css"].any? { |path| !Rails.application.asset_precompiled?(path) }
      system("bin/yarn run build && bin/yarn run build:css")
    end
  end
end
