# frozen_string_literal: true

Rails.application.routes.draw do
  get 'invoices/index'
  get 'invoices/show'
  root to: 'invoices#index'

  resources :invoices, only: [:index, :show]
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'landing_page#index'

  resources :patients do
    resources :immunizations
    resource :health_card do
      get "/chunks", to: "health_cards#chunks", as: :chunks, format: :json
    end
  end
  
  get "/Patient/:id", to: "patients#show", as: :fhir_patient, format: :fhir_json
  get "/Immunization/:id", to: "immunizations#show", as: :fhir_immunization, format: :fhir_json
  get "/.well-known/smart-configuration", to: "well_known#smart", as: :well_known_smart, format: :json
  get "/.well-known/jwks", to: "well_known#jwks", as: :well_known_jwks, format: :json
end
