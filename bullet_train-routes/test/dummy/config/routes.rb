Rails.application.routes.draw do
  # Exercises the DSL while the app boots, so the test suite fails loudly if `model` isn't
  # available by the time routes are drawn.
  model "Project" do
    model "Projects::Deliverable" do
      model "Objective"
    end
  end

  namespace :account do
    model "Form" do
      model "Forms::FieldSet"
    end
  end
end
