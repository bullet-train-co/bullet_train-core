class Account::Platform::AccessTokensController < Account::ApplicationController
  account_load_and_authorize_resource :access_token, through: :application, through_association: :access_tokens

  # GET /account/platform/applications/:application_id/access_tokens
  # GET /account/platform/applications/:application_id/access_tokens.json
  def index
    delegate_json_to_api do
      redirect_to [:account, @application]
    end
  end

  # GET /account/platform/access_tokens/:id
  # GET /account/platform/access_tokens/:id.json
  def show
    delegate_json_to_api do
      redirect_to [:account, @application]
    end
  end

  # GET /account/platform/applications/:application_id/access_tokens/new
  def new
  end

  # GET /account/platform/access_tokens/:id/edit
  def edit
  end

  # POST /account/platform/applications/:application_id/access_tokens
  # POST /account/platform/applications/:application_id/access_tokens.json
  def create
    @access_token.provisioned = true

    respond_to do |format|
      if @access_token.save
        format.html { redirect_to [:account, @application, :access_tokens], notice: I18n.t("platform/access_tokens.notifications.created") }
        format.json { render :show, status: :created, location: [:account, @access_token] }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @access_token.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /account/platform/access_tokens/:id
  # PATCH/PUT /account/platform/access_tokens/:id.json
  def update
    respond_to do |format|
      if @access_token.update(access_token_params)
        format.html { redirect_to [:account, @access_token], notice: I18n.t("platform/access_tokens.notifications.updated") }
        format.json { render :show, status: :ok, location: [:account, @access_token] }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @access_token.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /account/platform/access_tokens/:id
  # DELETE /account/platform/access_tokens/:id.json
  def destroy
    @access_token.destroy
    respond_to do |format|
      format.html { redirect_to [:account, @application, :access_tokens], notice: I18n.t("platform/access_tokens.notifications.destroyed") }
      format.json { head :no_content }
    end
  end

  private

  include strong_parameters_from_api

  def process_params(strong_params)
    # 🚅 super scaffolding will insert processing for new fields above this line.
  end
end
