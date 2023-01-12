class Account::TwoFactorsController < Account::ApplicationController
  before_action :authenticate_user!

  def verify
    puts "****************************************"
    render plain: "Hello"
  end

  def create
    @backup_codes = current_user.generate_otp_backup_codes!
    @user = current_user

    # todo next: 1. render something that prompts user to enter opt_code
    # 2. add a new controller action to recieve/verify the user entered opt_code
    # 3. move the below .update code to the new controller action if verified

    current_user.update(
      otp_secret: User.generate_otp_secret,
      otp_required_for_login: true
    )
  end

  def destroy
    @user = current_user
    current_user.update(otp_required_for_login: false)
  end
end
