module SuperScaffoldingHelper
  unless defined?(BulletTrain::ActionModels)
    # action_model_select_controller is originally a method
    # in the Action Models package, but we can't simply
    # remove this method from Super Scaffolded index partials
    # when the package isn't present. Since we keep
    # action_model_select_controller in our views, we need
    # this method so we don't get a NoMethodError.
    def action_model_select_controller
      yield
    end
  end
end
