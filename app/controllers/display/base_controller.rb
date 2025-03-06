module Display
  class BaseController < NonApiApplicationController
    include Pagy::Backend
  end
end
