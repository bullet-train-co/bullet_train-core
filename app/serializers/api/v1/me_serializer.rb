# TODO This serializer only needs to exist because of a limitation in `Api.show_desc` that we use in
# `app/controllers/api/v1/me_endpoint.rb`. This is the easiest solution at the moment, but we can revisit later.
class Api::V1::MeSerializer < Api::V1::UserSerializer
end
