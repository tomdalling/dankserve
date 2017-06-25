Rails.application.routes.draw do
  root to: 'pages#index'
  get '/jeff', to: 'pages#jeff'
end
