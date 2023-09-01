# Api::V1::ApplicationController is in the starter repository and isn't
# needed for this package's unit tests, but our CI tests will try to load this
# class because eager loading is set to `true` when CI=true.
# We wrap this class in an `if` statement to circumvent this issue.
if defined?(Api::V1::ApplicationController)
  class Api::V1::Scaffolding::CompletelyConcrete::TangibleThingsController < Api::V1::ApplicationController
    account_load_and_authorize_resource :tangible_thing, through: :absolutely_abstract_creative_concept, through_association: :completely_concrete_tangible_things

    # GET /api/v1/scaffolding/absolutely_abstract/creative_concepts/:absolutely_abstract_creative_concept_id/completely_concrete/tangible_things
    def index
    end

    # GET /api/v1/scaffolding/completely_concrete/tangible_things/:id
    def show
    end

    # POST /api/v1/scaffolding/absolutely_abstract/creative_concepts/:absolutely_abstract_creative_concept_id/completely_concrete/tangible_things
    def create
      if @tangible_thing.save
        render :show, status: :created, location: [:api, :v1, @tangible_thing]
      else
        render json: @tangible_thing.errors, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /api/v1/scaffolding/completely_concrete/tangible_things/:id
    def update
      if @tangible_thing.update(tangible_thing_params)
        render :show
      else
        render json: @tangible_thing.errors, status: :unprocessable_entity
      end
    end

    # DELETE /api/v1/scaffolding/completely_concrete/tangible_things/:id
    def destroy
      @tangible_thing.destroy
    end

    private

    module StrongParameters
      # Only allow a list of trusted parameters through.
      def tangible_thing_params
        strong_params = params.require(:scaffolding_completely_concrete_tangible_thing).permit(
          *permitted_fields,
          # 🚅 skip this section when scaffolding.
          :text_field_value,
          :action_text_value,
          :boolean_button_value,
          :button_value,
          :color_picker_value,
          :cloudinary_image_value,
          :date_field_value,
          :date_and_time_field_value,
          :email_field_value,
          :file_field_value,
          :file_field_value_removal,
          :option_value,
          :password_field_value,
          :phone_field_value,
          :super_select_value,
          :text_area_value,
          # 🚅 stop any skipping we're doing now.
          # 🚅 super scaffolding will insert new fields above this line.
          *permitted_arrays,
          # 🚅 skip this section when scaffolding.
          multiple_button_values: [],
          multiple_option_values: [],
          address_value_attributes: [
            :id,
            :address_one,
            :address_two,
            :city,
            :region_id,
            :region_name,
            :country_id,
            :postal_code
          ],
          multiple_super_select_values: []
          # 🚅 stop any skipping we're doing now.
          # 🚅 super scaffolding will insert new arrays above this line.
        )

        process_params(strong_params)

        strong_params
      end
    end

    include StrongParameters
  end
else
  class Api::V1::Scaffolding::CompletelyConcrete::TangibleThingsController
  end
end
