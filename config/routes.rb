Rails.application.routes.draw do
  resource :session, only: %i[new create destroy]
  resource :password, only: %i[edit update]
  resource :registration, only: %i[new create]

  resource :subscription, only: %i[new create] do
    post :portal, on: :member
  end

  namespace :webhooks do
    post "stripe", to: "stripe#create"
  end

  namespace :admin do
    root "dashboard#index"
    resources :users, only: [ :index, :show, :edit, :update ] do
      member do
        patch :grant_free_access
        patch :change_plan
      end
    end
    resources :coupons, only: [ :index, :new, :create ]
    resource :settings, only: [ :show ]
  end

  root "pages#home"

  resources :items do
    member do
      post :generate_ai_content
      patch :update_ai_content
      post :record_sale
    end
    resources :listings, only: [ :new, :create, :edit, :update, :destroy ] do
      member do
        patch :delist
      end
    end
  end

  resources :csv_imports, only: [ :index, :new, :create, :destroy ]
  resources :sales, only: [ :index, :show, :edit, :update ]
  resources :brands, only: [ :index, :create ]
  resources :categories, only: [ :index, :create ] do
    resources :subcategories, only: [ :create ]
  end
  resources :sources, only: [ :index, :create ]
  resources :platforms, only: [ :index ]

  get "dashboard", to: "dashboard#index"

  namespace :api do
    namespace :v1 do
      resources :items, only: [ :index, :show ] do
        member do
          patch :mark_listed
        end
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
