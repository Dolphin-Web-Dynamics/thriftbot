Rails.application.routes.draw do
  resource :session, only: %i[new create destroy]

  root "dashboard#index"

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
  resources :sales, only: [ :index, :show ]
  resources :brands, only: [ :index, :create ]
  resources :categories, only: [ :index, :create ] do
    resources :subcategories, only: [ :create ]
  end
  resources :sources, only: [ :index, :create ]
  resources :platforms, only: [ :index ]

  get "dashboard", to: "dashboard#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
