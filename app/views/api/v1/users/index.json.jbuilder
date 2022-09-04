json.data do
  json.array! @users, partial: "api/v1/users/user", as: :user
end

render_pagination(json)
