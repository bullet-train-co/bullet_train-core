module Api::V1::Teams::EndpointBase
  extend ActiveSupport::Concern

  included do
    helpers do
      params :id do
        requires :id, type: Integer, allow_blank: false, desc: Api.heading(:id)
      end

      params :team do
        optional :name, type: String, allow_blank: false, desc: Api.heading(:name)
        optional :locale, type: String, desc: Api.heading(:locale)

        # TODO I don't like this, but I can't figure out a better way to accomplish the same thing. I'm open to any
        # suggestions on this. I don't know why `@api.class` returns `Class` but `@api.to_s` returns e.g.
        # `Api::V1::TeamsEndpoint`, but since we can get the latter, we'll use that to fetch whatever proc is defined
        # in ADDITIONAL_PARAMS.
        if defined?(@api.to_s.constantize::PARAMS)
          instance_eval(&@api.to_s.constantize::PARAMS)
        end
      end
    end

    resource :teams, desc: Api.title(:actions) do
      after_validation do
        load_and_authorize_api_resource Team
      end

      desc Api.title(:index), &Api.index_desc
      oauth2
      paginate per_page: 100
      get "/" do
        @paginated_teams = paginate @teams
        render @paginated_teams, serializer: Api.serializer, adapter: :attributes
      end

      desc Api.title(:show), &Api.show_desc
      params do
        use :id
      end
      oauth2
      route_param :id do
        get do
          render @team, serializer: Api.serializer
        end
      end

      desc Api.title(:create), &Api.create_desc
      params do
        use :team
      end
      route_setting :api_resource_options, permission: :create
      oauth2 "write"
      post "/" do
        if @team.save
          # sets the team creator as the default admin
          @team.memberships.create(user: current_user, roles: [Role.admin])

          current_user.current_team = @team
          current_user.former_user = false
          current_user.save

          render @team, serializer: Api.serializer
        else
          record_not_saved @team
        end
      end

      desc Api.title(:update), &Api.update_desc
      params do
        use :id
        use :team
      end
      route_setting :api_resource_options, permission: :update
      oauth2 "write"
      route_param :id do
        put do
          if @team.update(declared(params, include_missing: false))
            render @team, serializer: Api.serializer
          else
            record_not_saved @team
          end
        end
      end
    end
  end
end
