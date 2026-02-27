# Feedbacker

A Rails engine gem that adds feedback, commenting, messaging, translations, and admin tooling to a host Rails app. The gem is hosted at **feedbacker.git** and is intended to be used as a dependency by an application.

## Summary

- **Purpose:** Facilitates feedback, threaded comments, posts, private messaging (rooms/conversations), tagging, translations/i18n, and admin dashboards.
- **Stack:** Rails 6.1+, Devise, `acts_as_commentable_with_threading`, Kaminari, Diffy.
- **Namespace:** `Feedbacker` (isolated engine).

## Installation

Add to your application's Gemfile:

```ruby
gem 'feedbacker', git: 'https://path-to-your-server/feedbacker.git'
# or
gem 'feedbacker', path: '../gems_code/feedbacker'
```

Then:

```bash
bundle install
```

## Mounting in the host app

In the host app's `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount Feedbacker::Engine => "/feedbacker"
end
```

All engine routes are then under `/feedbacker` (e.g. `/feedbacker`, `/feedbacker/admin`, `/feedbacker/conversations`).

## Database setup

Copy and run the engine migrations from the host app:

```bash
rails feedbacker:install:migrations
rails db:migrate
```

Migrations create tables such as: `comments`, `translates`, `translate_keys`, `posts`, `data_logs`, `archives`, `tags`, `rooms`, `room_messages`, `room_users`, `user_conversations`, and optionally `orgs` / `org_users`.

## Host app integration

- **User model:** The engine expects a `User` model (typically from Devise) in the host app. Controllers use concerns such as `FeedbackerUsersController`, `UserInfo`, etc.
- **Optional generators:** To copy controller templates into the host app:
  ```bash
  rails g feedbacker:initializer comments_controller
  ```
  This copies `comments_controller.rb` and `posts_controller.rb` into the host app.

## Configuration

The engine is configurable via `Feedbacker.configure`:

- **Languages:** `languages`, `default_language` (e.g. `["en","es"]`, `"en"`).
- **Engage actions:** `engage_keys` (e.g. flag, like, love, agree) and `engage_icons` for UI.
- **UI:** `default_list_ui` (`"list"` or `"table"`), `theme`.
- **ORM:** `orm` (default `"active_record"`).

Example in the host app (e.g. `config/initializers/feedbacker.rb`):

```ruby
Feedbacker.configure do |config|
  config.languages = ["en", "es"]
  config.default_language = "en"
  config.use_defaults  # optional: reset to gem defaults
end
```

## Main features and routes (under mount path)

| Area | Examples |
|------|----------|
| **Home** | `GET /feedbacker` (root) |
| **Comments** | `resources :comments` |
| **Posts** | Via posts controller (and generators) |
| **Messaging** | `/feedbacker/conversations`, `/feedbacker/conversation/:id`, `/feedbacker/add/conversation` |
| **Rooms** | `resources :rooms`, `room_messages` |
| **Connect/engage** | `/feedbacker/engage/:otype/:id/:scope`, `/feedbacker/add/connection/:otype/:id` |
| **Tags** | `/feedbacker/tag/search`, `/feedbacker/tag/add`, `/feedbacker/tag/remove`, etc. |
| **Translations** | `resources :translates`, `translate_keys`, `/feedbacker/admin/about/translations`, `/feedbacker/admin/cms`, etc. |
| **Admin** | `/feedbacker/admin`, `/feedbacker/admin/users`, `/feedbacker/admin/visits`, `/feedbacker/admin/page/ideas`, `/feedbacker/admin/db`, `/feedbacker/admin/analytics`, etc. |
| **Demo** | `/feedbacker/demo` |

## Project structure (high level)

- `app/` — Controllers, models, views (Feedbacker namespace).
- `config/` — Routes, locales, initializers (e.g. Simple Form).
- `db/migrate/` — Engine migrations (comments, translates, posts, rooms, tags, etc.).
- `lib/` — Engine definition (`feedbacker.rb`, `engine.rb`), configuration (`configure.rb`), concerns, generators, tasks.

## Testing

The repo includes a `test/dummy` Rails app that mounts the engine at `/feedbacker`. Run tests from the gem root:

```bash
bundle exec rake test
# or
cd test/dummy && bundle install && rails db:migrate
```

## License

MIT.
