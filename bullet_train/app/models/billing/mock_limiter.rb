class Billing::MockLimiter
  def initialize(team)
  end

  def broken_hard_limits_for(action, model, count: 1)
    []
  end

  def can?(action, model, count: 1)
    true
  end

  def exhausted?(model, enforcement = "hard")
    false
  end
end
