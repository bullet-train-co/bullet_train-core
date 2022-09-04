json.data do
  json.array! @teams, partial: "api/v1/teams/team", as: :team
end

render_pagination(json)
