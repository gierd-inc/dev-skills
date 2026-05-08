# Policy Object Examples

## ApplicationPolicy base (Pundit-style)

```ruby
# app/policies/application_policy.rb
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index? = false
  def show? = false
  def create? = false
  def new? = create?
  def update? = false
  def edit? = update?
  def destroy? = false

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "#{self.class} must implement #resolve"
    end

    private

    attr_reader :user, :scope
  end
end
```

## OrganizationPolicy with roles

```ruby
# app/policies/organization_policy.rb
class OrganizationPolicy < ApplicationPolicy
  def show?
    member?
  end

  def update?
    owner? || user.admin?
  end

  def destroy?
    owner? && user.admin?  # must be both org owner and system admin
  end

  def invite_members?
    owner?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.joins(:memberships).where(memberships: { user: user })
      end
    end
  end

  private

  def member?
    user.admin? || record.memberships.exists?(user: user)
  end

  def owner?
    record.owner_id == user.id
  end
end
```

## Controller with Pundit

```ruby
# app/controllers/organizations_controller.rb
class OrganizationsController < ApplicationController
  include Pundit::Authorization

  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  def index
    @organizations = policy_scope(Organization)
  end

  def show
    @organization = Organization.find(params[:id])
    authorize @organization
  end

  def update
    @organization = Organization.find(params[:id])
    authorize @organization

    if @organization.update(organization_params)
      redirect_to @organization
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
```

## View with policy helpers

```erb
<%# app/views/organizations/show.html.erb %>
<h1><%= @organization.name %></h1>

<% if policy(@organization).update? %>
  <%= link_to "Settings", edit_organization_path(@organization) %>
<% end %>

<% if policy(@organization).invite_members? %>
  <%= link_to "Invite people", new_organization_invitation_path(@organization) %>
<% end %>

<% if policy(@organization).destroy? %>
  <%= button_to "Delete organization", @organization,
      method: :delete,
      data: { turbo_confirm: "This is irreversible. Are you sure?" } %>
<% end %>
```

## Minitest: comprehensive policy test

```ruby
# test/policies/organization_policy_test.rb
class OrganizationPolicyTest < ActiveSupport::TestCase
  setup do
    @org   = organizations(:acme)
    @owner = users(:ryan)          # owner of :acme
    @member = users(:member)       # member but not owner
    @admin = users(:admin)         # system admin
    @stranger = users(:stranger)   # no relation to :acme
  end

  # show?
  test "members can view the org" do
    assert OrganizationPolicy.new(@member, @org).show?
  end

  test "strangers cannot view the org" do
    refute OrganizationPolicy.new(@stranger, @org).show?
  end

  # update?
  test "owner can update" do
    assert OrganizationPolicy.new(@owner, @org).update?
  end

  test "member cannot update" do
    refute OrganizationPolicy.new(@member, @org).update?
  end

  # Scope
  test "scope returns only orgs the user belongs to" do
    scope = OrganizationPolicy::Scope.new(@member, Organization.all).resolve
    assert_includes scope, @org
    refute_includes scope, organizations(:other_org)
  end

  test "admin scope returns all orgs" do
    scope = OrganizationPolicy::Scope.new(@admin, Organization.all).resolve
    assert_equal Organization.count, scope.count
  end
end
```
