class Api::V1::Scaffolding::AbsolutelyAbstract::CreativeConceptsController < Api::V1::ApplicationController
  account_load_and_authorize_resource :creative_concept, through: :team, through_association: :scaffolding_absolutely_abstract_creative_concepts

  # GET /api/v1/teams/:team_id/absolutely_abstract/creative_concepts
  def index
  end

  # GET /api/v1/scaffolding/absolutely_abstract/creative_concepts/:id
  def show
  end

  # POST /api/v1/teams/:team_id/absolutely_abstract/creative_concepts
  def create
    if @creative_concept.save
      render :show, status: :created, location: [:api, :v1, @creative_concept]
    else
      render json: @creative_concept.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/scaffolding/absolutely_abstract/creative_concepts/:id
  def update
    if @creative_concept.update(creative_concept_params)
      render :show
    else
      render json: @creative_concept.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/scaffolding/absolutely_abstract/creative_concepts/:id
  def destroy
    @creative_concept.destroy
  end

  private

  module StrongParameters
    # Only allow a list of trusted parameters through.
    def creative_concept_params
      strong_params = params.require(:scaffolding_absolutely_abstract_creative_concept).permit(
        *permitted_fields,
        :name,
        :description,
        *permitted_arrays
      )

      process_params(strong_params)

      strong_params
    end
  end

  include StrongParameters
end
