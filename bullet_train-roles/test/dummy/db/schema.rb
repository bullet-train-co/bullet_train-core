# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2022_03_02_235728) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "documents", force: :cascade do |t|
    t.bigint "membership_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["membership_id"], name: "index_documents_on_membership_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.jsonb "role_ids"
    t.bigint "user_id", null: false
    t.bigint "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_memberships_on_team_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "scaffolding_absolutely_abstract_creative_concepts", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.bigint "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_scaffold_absolutely_abstract_creative_concept_on_team_id"
  end

  create_table "scaffolding_absolutely_abstract_creative_concepts_collaborators", force: :cascade do |t|
    t.jsonb "role_ids"
    t.bigint "creative_concept_id", null: false
    t.bigint "membership_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["creative_concept_id"], name: "index_creative_concepts_collaborators_on_creative_concept_id"
    t.index ["membership_id"], name: "index_creative_concepts_collaborators_on_membership_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.integer "current_team_id"
    t.jsonb "ability_cache"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "documents", "memberships"
  add_foreign_key "memberships", "teams"
  add_foreign_key "memberships", "users"
  add_foreign_key "scaffolding_absolutely_abstract_creative_concepts", "teams"
  add_foreign_key "scaffolding_absolutely_abstract_creative_concepts_collaborators", "scaffolding_absolutely_abstract_creative_concepts", column: "creative_concept_id"
end
