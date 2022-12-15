# i really, really wanted this controller in a namespace, but devise doesn't
# appear to support it. instead, i got the following error:
#
#   'Authentication::RegistrationsController' is not a supported controller name.
#   This can lead to potential routing problems.

class RegistrationsController < Devise::RegistrationsController
  include Registrations::ControllerBase
end
