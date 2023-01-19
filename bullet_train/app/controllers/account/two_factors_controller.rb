class Account::TwoFactorsController < Account::ApplicationController
  before_action :authenticate_user!

  def verify
    @user = current_user
    otp_code = params["user"]["otp_attempt"]

    # validate_and_consume_otp! from Devise::Models::TwoFactorAuthenticatable here:
    # https://github.com/tinfoil/devise-two-factor/blob/7e03c6fbef4c949352f43f0f2fcbac66185a0940/lib/devise_two_factor/models/two_factor_authenticatable.rb#L36

    @verified = current_user.validate_and_consume_otp!(otp_code)
    
    if @verified
      current_user.update(otp_required_for_login: true)     
    else
      current_user.update(
        otp_required_for_login: false,
        otp_secret: nil
      )
    end
  end

  def create
    @backup_codes = current_user.generate_otp_backup_codes!
    @user = current_user

    current_user.update(otp_secret: User.generate_otp_secret)
  end

  def destroy
    @user = current_user
    current_user.update(
      otp_required_for_login: false,
      otp_secret: nil
    )
  end

end
