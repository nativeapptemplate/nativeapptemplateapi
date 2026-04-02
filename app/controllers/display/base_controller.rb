module Display
  class BaseController < NonApiApplicationController
    include Pagy::Method
  end
end
