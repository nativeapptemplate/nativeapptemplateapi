Rails.application.routes.draw do
  draw :madmin

  require "admin_constraint"
  require "sidekiq/web"
  mount Sidekiq::Web => "/madmin/sidekiq", "constraints" => AdminConstraint.new

  if Rails.env.local?
    mount Mailbin::Engine, at: "/mailbin"
  end

  get "/admin_auth/sign_in", to: "admin_auth/sessions#new", as: "new_admin_session"
  post "/admin_auth/sign_in", to: "admin_auth/sessions#create", as: "admin_session"
  delete "/admin_auth/sign_out", to: "admin_auth/sessions#destroy", as: "destroy_admin_session"

  scope controller: :static do
    get :index
  end

  match "/404", via: :all, to: "errors#not_found"
  match "/500", via: :all, to: "errors#internal_server_error"

  mount_devise_token_auth_for "Shopkeeper",
    at: "shopkeeper_auth",
    skip: [:omniauth_callbacks],
    controllers: {
      registrations: "shopkeeper_auth/registrations",
      sessions: "shopkeeper_auth/sessions",
      passwords: "shopkeeper_auth/passwords",
      confirmations: "shopkeeper_auth/confirmations"
    }

  namespace :shopkeeper_auth do
    resource :reset_password, only: %i[new edit show]
    resource :confirmation_result, only: %i[show]
  end

  namespace :api, format: "json" do
    namespace :v1 do
      namespace :shopkeeper do
        resources :permissions, only: %i[index]
        resource :me, only: [], controller: :me do
          member do
            patch :update_confirmed_privacy_version
            patch :update_confirmed_terms_version
          end
        end

        namespace :account do
          resource :password, only: %i[update]
        end

        resources :shops

        resources :accounts do
          resources :accounts_shopkeepers, only: %i[index show update destroy], path: :members
          resources :accounts_invitations, path: :invitations, module: :accounts do
            member do
              post :resend
            end
          end
        end
        resources :accounts_invitations
      end
    end
  end

  root to: "static#index"
end
