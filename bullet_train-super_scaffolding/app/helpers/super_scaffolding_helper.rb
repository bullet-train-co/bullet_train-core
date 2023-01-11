module SuperScaffoldingHelper
  unless defined?(BulletTrain::ActionModels)
    def action_model_select_controller(&block)
      capture(&block)
    end
  end
end
