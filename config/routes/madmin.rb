# Below are the routes for madmin
namespace :madmin do
  resources :privacy_versions
  resources :roles
  resources :permissions
  resources :roles_permissions
  resources :shops
  resources :terms_versions
  resources :accounts
  namespace :active_storage do
    resources :attachments
  end
  namespace :active_storage do
    resources :blobs
  end
  resources :shopkeepers
  resources :accounts_invitations
  resources :accounts_shopkeepers
  resources :admin_users
  resources :app_versions
  namespace :active_storage do
    resources :variant_records
  end
  root to: "dashboard#show"
end
