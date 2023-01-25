# module FactoryBot
#   def self.create_example(name, *traits_and_overrides)
#     ActiveRecord::Base.transaction do
#       instance = create(name, *traits_and_overrides)
#       # you can use instance.dup here or OpenStruct.new(instance.attributes)
#       raise ActiveRecord::Rollback
#     end
#   end
# end
#
# # module BulletTrain
# #   module Api
# #     module ExampleBot
# #       def example(model, **options)
# #         factory = "#{model}_example"
# #
# #         object = nil
# #         id = nil
# #
# #         ActiveRecord::Base.transaction do
# #           # begin
# #
# #           object = FactoryBot.create(factory, **options)
# #           id = object.id
# #
# #           puts ">>>ID1 #{object.id}"
# #           puts ">>>REFLECTIONS #{object.reflections}"
# #
# #           raise ActiveRecord::Rollback
# #
# #           puts ">>>ID2 #{object.id}"
# #
# #           # rescue ActiveRecord::Rollback
# #
# #           # end
# #         end
# #
# #         puts ">>>ID3 #{object.id}"
# #
# #         ActiveRecord::Base.connection.reset_pk_sequence!(model.to_s.pluralize)
# #
# #         object.id = id
# #
# #         puts ">>>ID4 #{object.id}"
# #         object
# #       end
# #
# #       def example_list(model, quantity, **options)
# #
# #       end
# #     end
# #
# #     extend ExampleBot
# #   end
# # end
# #
# #
