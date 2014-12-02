Rails.application.routes.draw do
  root to: 'home#index'

  resources :users do
    collection do
      get :connect
      get :confirm
      get :deauthorize
    end
    member do
      post :pay
      post :subscribe
    end
  end

  resource :sessions do
    member do
      get :destroy, as: 'destroy'
    end
  end

  post '/hooks/stripe' => 'hooks#stripe'
end
