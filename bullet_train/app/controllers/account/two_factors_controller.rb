class Account::TwoFactorsController < Account::ApplicationController
  before_action :authenticate_user!

  def verify
    @user = current_user

    otp_code = params["user"]["otp_attempt"]
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
