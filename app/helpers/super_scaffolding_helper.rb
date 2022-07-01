module SuperScaffoldingHelper
  unless defined?(BulletTrain::ActionModels)
    def action_model_select_controller
      # TODO I don't know why if I just call `yield` I get duplicate content on the page.
      tag.div do
        yield
      end
    end
  end
end
