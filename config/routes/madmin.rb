# Below are the routes for madmin
namespace :madmin do
  resources :admin_users
  resources :shopkeepers
  resources :accounts
  resources :accounts_invitations
  resources :accounts_shopkeepers
  resources :shops
  resources :item_tags
  resources :roles
  resources :permissions
  resources :roles_permissions
  resources :terms_versions
  resources :privacy_versions
  resources :app_versions
  namespace :active_storage do
    resources :variant_records
  end
  namespace :active_storage do
    resources :attachments
  end
  namespace :active_storage do
    resources :blobs
  end
  root to: "dashboard#show"
end
