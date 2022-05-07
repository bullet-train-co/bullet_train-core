class Api::V1::MeEndpoint < Api::V1::Root
  resource :me, desc: Api.title(:actions) do
    desc Api.title(:show), &Api.show_desc
    oauth2
    get do
      render current_user, include: [:teams, :memberships], serializer: "Api::V1::UserSerializer", adapter: :attributes
    end
  end
end
