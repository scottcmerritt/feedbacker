json.extract! post, :id, :title, :details, :createdby, :is_public, :is_global, :approved, :approved_at, :approved_by, :removed, :removed_by, :removed_at, :created_at, :updated_at
json.url post_url(post, format: :json)
