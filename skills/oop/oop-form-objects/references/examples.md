# Form Object Examples

## Multi-model form: User + Organization

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

## Password change form (virtual attributes)

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

## Controller for password change

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

## Wizard step forms

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

## Minitest: multi-model form

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
