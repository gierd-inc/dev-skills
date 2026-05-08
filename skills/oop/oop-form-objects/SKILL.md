---
name: oop-form-objects
description: Use when a form creates or updates multiple models, when a form has virtual attributes that don't map directly to DB columns, or when you need form-level validations that don't belong on any one model. Load when working with ActiveModel::Model, multi-model forms, or wizard-style step forms.
---

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

- [oop-service-objects](../oop-service-objects/SKILL.md) — for the multi-step workflow a complex form might dispatch to
- [oop-presenters](../oop-presenters/SKILL.md) — the read-side complement: displaying data, vs. forms accepting data
- [rails-controllers](../../rails/rails-controllers/SKILL.md) — controller conventions for form-object workflows
- [rails-models](../../rails/rails-models/SKILL.md) — when to put validations on the model instead

See `references/examples.md` for annotated code samples.
