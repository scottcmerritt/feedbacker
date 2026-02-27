# Workaround: Rails 6.1's sqlite3 adapter requires ~> 1.4, but we use 2.x on Ruby 3.3.
# Remove this when upgrading to Rails 7.2+.
module Sqlite3GemVersionPatch
  def gem(name, *requirements)
    return if name == "sqlite3" && requirements.any? { |r| r.to_s.include?("1.4") }
    super
  end
end
Object.prepend(Sqlite3GemVersionPatch)
