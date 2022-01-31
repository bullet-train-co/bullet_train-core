Rails.application.routes.draw do
  concern :sortable do
    collection do
      post :reorder
    end
  end
end
