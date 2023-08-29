class Account::Scaffolding::CompletelyConcrete::TangibleThingsController < Account::ApplicationController
  account_load_and_authorize_resource :tangible_thing, through: :absolutely_abstract_creative_concept, through_association: :completely_concrete_tangible_things

  # GET /account/scaffolding/absolutely_abstract/creative_concepts/:absolutely_abstract_creative_concept_id/completely_concrete/tangible_things
  # GET /account/scaffolding/absolutely_abstract/creative_concepts/:absolutely_abstract_creative_concept_id/completely_concrete/tangible_things.json
  def index
    delegate_json_to_api
  end

  # GET /account/scaffolding/completely_concrete/tangible_things/:id
  # GET /account/scaffolding/completely_concrete/tangible_things/:id.json
  def show
    delegate_json_to_api
  end

  # GET /account/scaffolding/absolutely_abstract/creative_concepts/:absolutely_abstract_creative_concept_id/completely_concrete/tangible_things/new
  def new
    # 🚅 skip this section when scaffolding.
    @tangible_thing.address_value = Address.new
    # 🚅 stop any skipping we're doing now.
  end

  # GET /account/scaffolding/completely_concrete/tangible_things/:id/edit
  def edit
    # 🚅 skip this section when scaffolding.
    @tangible_thing.address_value ||= Address.new
    # 🚅 stop any skipping we're doing now.
  end

  # POST /account/scaffolding/absolutely_abstract/creative_concepts/:absolutely_abstract_creative_concept_id/completely_concrete/tangible_things
  # POST /account/scaffolding/absolutely_abstract/creative_concepts/:absolutely_abstract_creative_concept_id/completely_concrete/tangible_things.json
  def create
    respond_to do |format|
      if @tangible_thing.save
        format.html { redirect_to [:account, @tangible_thing], notice: I18n.t("scaffolding/completely_concrete/tangible_things.notifications.created") }
        format.json { render :show, status: :created, location: [:account, @tangible_thing] }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tangible_thing.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /account/scaffolding/completely_concrete/tangible_things/:id
  # PATCH/PUT /account/scaffolding/completely_concrete/tangible_things/:id.json
  def update
    respond_to do |format|
      if @tangible_thing.update(tangible_thing_params)
        format.html { redirect_to [:account, @tangible_thing], notice: I18n.t("scaffolding/completely_concrete/tangible_things.notifications.updated") }
        format.json { render :show, status: :ok, location: [:account, @tangible_thing] }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tangible_thing.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /account/scaffolding/completely_concrete/tangible_things/:id
  # DELETE /account/scaffolding/completely_concrete/tangible_things/:id.json
  def destroy
    @tangible_thing.destroy
    respond_to do |format|
      format.html { redirect_to [:account, @absolutely_abstract_creative_concept, :completely_concrete_tangible_things], notice: I18n.t("scaffolding/completely_concrete/tangible_things.notifications.destroyed") }
      format.json { head :no_content }
    end
  end

  private

  if defined?(Api::V1::ApplicationController)
    include strong_parameters_from_api
  end

  def process_params(strong_params)
    # 🚅 skip this section when scaffolding.
    assign_boolean(strong_params, :boolean_button_value)
    assign_checkboxes(strong_params, :multiple_button_values)
    assign_checkboxes(strong_params, :multiple_option_values)
    assign_select_options(strong_params, :multiple_super_select_values)
    # 🚅 stop any skipping we're doing now.
    # 🚅 super scaffolding will insert processing for new fields above this line.
  end
end
