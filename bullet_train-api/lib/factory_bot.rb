module FactoryBot
  def self.create_example(name, *traits_and_overrides)
    ActiveRecord::Base.transaction do
      instance = create(name, *traits_and_overrides)
      # you can use instance.dup here or OpenStruct.new(instance.attributes)
      raise ActiveRecord::Rollback
    end
  end
end
