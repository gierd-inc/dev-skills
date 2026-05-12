# Form Objects

## What it is

A Form Object is a plain Ruby class that includes `ActiveModel::Model` (and optionally `ActiveModel::Attributes`). It accepts form input, validates it, and on success dispatches to the appropriate models or services to persist. To Rails forms, views, and validations it looks and behaves like an ActiveRecord model.

Form objects are the right tool for:
- Forms that create/update multiple models atomically
- Virtual attributes (computed fields, confirmations, acceptance checkboxes) that have no DB column
- Wizard/multi-step forms where each step is validated independently
- Registration/signup flows where you don't want to add a callback or validation to `User` for one context

## Would a fat model do?

Add attributes and validations to the model directly if the form is simple and single-model. Extract a form object when:

- The form writes to 2+ models (e.g. `User` + `Profile` + `Organization`)
- There are virtual attributes (`password_confirmation`, `terms_accepted`) that shouldn't exist on the model
- The validation rules differ by context (sign-up has different rules than account settings)

## When NOT to

- Single-model CRUD — Rails handles this perfectly with `form_with(model: @post)`
- Adding one virtual attribute — use `attr_accessor` on the model and `validates :field, on: :context`
- When the logic is simple enough that a before-action in the controller handles it cleanly

## Shape

```ruby
# app/forms/registration_form.rb
class RegistrationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :email, :string
  attribute :password, :string
  attribute :terms_accepted, :boolean, default: false

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }
  validates :terms_accepted, acceptance: true

  def save
    return false unless valid?

    User.transaction do
      @user = User.create!(name: name, email: email, password: password)
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    e.record.errors.each { |error| errors.add(error.attribute, error.message) }
    false
  end

  def user
    @user
  end
end
```

## Controller usage

```ruby
# app/controllers/registrations_controller.rb
class RegistrationsController < ApplicationController
  def new
    @form = RegistrationForm.new
  end

  def create
    @form = RegistrationForm.new(registration_params)
    if @form.save
      sign_in @form.user
      redirect_to root_path, notice: "Welcome!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:registration_form).permit(:name, :email, :password, :terms_accepted)
  end
end
```

## View usage

```erb
<%# app/views/registrations/new.html.erb %>
<%= form_with model: @form, url: registrations_path do |f| %>
  <%= f.text_field :name %>
  <%= f.email_field :email %>
  <%= f.password_field :password %>
  <%= f.check_box :terms_accepted %>
  <%= f.label :terms_accepted, "I accept the terms of service" %>
  <%= f.submit "Create account" %>
<% end %>
```

## Naming & location

- `app/forms/registration_form.rb` → `RegistrationForm`
- `app/forms/users/password_change_form.rb` → `Users::PasswordChangeForm`
- `app/forms/checkout/address_form.rb` → `Checkout::AddressForm`
- Name with the action + domain: `RegistrationForm`, `PasswordChangeForm`, `CheckoutForm`
- Never name after the model: `UserForm` is too vague — name what the form *does*

## Multi-step wizard

```ruby
# app/forms/onboarding/step1_form.rb
module Onboarding
  class Step1Form
    include ActiveModel::Model

    attr_accessor :company_name, :company_size

    validates :company_name, presence: true
    validates :company_size, inclusion: { in: %w[1-10 11-50 51-200 201+] }

    def save(organization)
      return false unless valid?
      organization.update!(name: company_name, size: company_size)
    end
  end
end
```

## Testing (Minitest)

```ruby
# test/forms/registration_form_test.rb
class RegistrationFormTest < ActiveSupport::TestCase
  def valid_params
    { name: "Ryan", email: "ryan@example.com", password: "secret123", terms_accepted: true }
  end

  test "valid with required attributes" do
    assert RegistrationForm.new(valid_params).valid?
  end

  test "invalid without email" do
    form = RegistrationForm.new(valid_params.merge(email: ""))
    refute form.valid?
    assert form.errors[:email].present?
  end

  test "invalid without terms acceptance" do
    form = RegistrationForm.new(valid_params.merge(terms_accepted: false))
    refute form.valid?
    assert form.errors[:terms_accepted].present?
  end

  test "save creates a user and returns true" do
    form = RegistrationForm.new(valid_params)
    assert_difference "User.count", 1 do
      assert form.save
    end
    assert_equal "Ryan", form.user.name
  end

  test "save returns false if invalid" do
    form = RegistrationForm.new(valid_params.merge(email: ""))
    assert_no_difference "User.count" do
      refute form.save
    end
  end
end
```

## Common smells

- **Form object that calls itself from the model** — the model should not know about the form; dependency is one-way
- **Form object that does too much** — if `save` runs a 40-line workflow, extract a service object and call it from the form
- **Duplicated validations** — form validations should supplement (not replace) model validations; the model is the last line of defense
- **Wrong name** — `UserForm` says nothing; `RegistrationForm` says exactly what context it handles

## See also

- [service-objects.md](./service-objects.md) — for the multi-step workflow a complex form might dispatch to
- [presenters.md](./presenters.md) — the read-side complement: displaying data, vs. forms accepting data
- [rails-controllers](../../rails/rails-controllers/SKILL.md) — controller conventions for form-object workflows
- [rails-models](../../rails/rails-models/SKILL.md) — when to put validations on the model instead

## Examples

### Multi-model form: User + Organization

```ruby
# app/forms/team_registration_form.rb
class TeamRegistrationForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :user_name, :string
  attribute :user_email, :string
  attribute :user_password, :string
  attribute :org_name, :string
  attribute :org_subdomain, :string

  validates :user_name, presence: true
  validates :user_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :user_password, presence: true, length: { minimum: 8 }
  validates :org_name, presence: true
  validates :org_subdomain,
    presence: true,
    format: { with: /\A[a-z0-9\-]+\z/, message: "only letters, numbers, and dashes" },
    exclusion: { in: %w[www admin api] }

  attr_reader :user, :organization

  def save
    return false unless valid?

    ApplicationRecord.transaction do
      @organization = Organization.create!(
        name: org_name,
        subdomain: org_subdomain
      )
      @user = User.create!(
        name: user_name,
        email: user_email,
        password: user_password,
        organization: @organization,
        role: :admin
      )
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    promote_errors(e.record.errors)
    false
  end

  private

  def promote_errors(model_errors)
    model_errors.each do |error|
      errors.add(:base, "#{error.attribute.to_s.humanize} #{error.message}")
    end
  end
end
```

### Password change form (virtual attributes)

```ruby
# app/forms/users/password_change_form.rb
module Users
  class PasswordChangeForm
    include ActiveModel::Model

    attr_accessor :current_password, :password, :password_confirmation, :user

    validates :current_password, presence: true
    validates :password, presence: true, length: { minimum: 8 }, confirmation: true
    validate :current_password_correct

    def save
      return false unless valid?
      user.update!(password: password)
    end

    private

    def current_password_correct
      return if user.nil?
      unless user.authenticate(current_password)
        errors.add(:current_password, "is incorrect")
      end
    end
  end
end
```

### Controller for password change

```ruby
# app/controllers/users/passwords_controller.rb
class Users::PasswordsController < ApplicationController
  before_action :require_authentication

  def edit
    @form = Users::PasswordChangeForm.new(user: current_user)
  end

  def update
    @form = Users::PasswordChangeForm.new(
      password_change_params.merge(user: current_user)
    )
    if @form.save
      redirect_to account_path, notice: "Password updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_change_params
    params.require(:users_password_change_form).permit(
      :current_password, :password, :password_confirmation
    )
  end
end
```

### Wizard step forms

```ruby
# app/forms/onboarding/company_step.rb
module Onboarding
  class CompanyStep
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :name, :string
    attribute :size, :string
    attribute :industry, :string

    SIZES = %w[1-10 11-50 51-200 201-500 500+].freeze
    INDUSTRIES = %w[technology finance healthcare education other].freeze

    validates :name, presence: true
    validates :size, inclusion: { in: SIZES }
    validates :industry, inclusion: { in: INDUSTRIES }

    def save(organization)
      return false unless valid?
      organization.update!(name: name, size: size, industry: industry)
    end
  end
end
```

### Minitest: multi-model form

```ruby
# test/forms/team_registration_form_test.rb
class TeamRegistrationFormTest < ActiveSupport::TestCase
  def valid_attrs
    {
      user_name: "Ryan",
      user_email: "ryan@example.com",
      user_password: "password123",
      org_name: "Acme Corp",
      org_subdomain: "acme"
    }
  end

  test "creates both user and organization" do
    form = TeamRegistrationForm.new(valid_attrs)
    assert_difference ["User.count", "Organization.count"], 1 do
      assert form.save
    end
  end

  test "rolls back if user is invalid" do
    form = TeamRegistrationForm.new(valid_attrs.merge(user_email: "bad"))
    assert_no_difference ["User.count", "Organization.count"] do
      refute form.save
    end
  end

  test "blocks reserved subdomains" do
    form = TeamRegistrationForm.new(valid_attrs.merge(org_subdomain: "www"))
    refute form.valid?
    assert_includes form.errors[:org_subdomain], "is reserved"
  end
end
```
