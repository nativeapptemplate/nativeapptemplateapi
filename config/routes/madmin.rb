# Below are the routes for madmin
namespace :madmin do
  resources :roles_permissions
  resources :shops
  resources :terms_versions
  resources :permissions
  namespace :active_storage do
    resources :attachments
  end
  resources :privacy_versions
  resources :roles
  resources :admin_users
  namespace :active_storage do
    resources :blobs
  end
  resources :app_versions
  resources :accounts_invitations
  resources :accounts_shopkeepers
  resources :accounts
  resources :shopkeepers
  namespace :active_storage do
    resources :variant_records
  end
  root to: "dashboard#show"
end
