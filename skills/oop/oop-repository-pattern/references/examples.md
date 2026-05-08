# Repository Pattern Examples

## External API-backed repository

```ruby
# app/repositories/github_repository_repo.rb
# Scenario: fetching GitHub repositories through a unified interface
# that the rest of the app treats like any other collection.

class GithubRepositoryRepo
  def initialize(client: Octokit::Client.new(access_token: ENV["GITHUB_TOKEN"]))
    @client = client
  end

  def find(full_name)
    raw = @client.repository(full_name)
    to_domain(raw)
  rescue Octokit::NotFound
    nil
  end

  def all_for_org(org)
    @client.org_repos(org).map { |r| to_domain(r) }
  end

  private

  def to_domain(raw)
    GithubRepo.new(
      full_name:    raw.full_name,
      description:  raw.description,
      stars:        raw.stargazers_count,
      url:          raw.html_url
    )
  end
end

# Domain object (no AR dependency):
GithubRepo = Data.define(:full_name, :description, :stars, :url)
```

## In-memory repository for testing

```ruby
# test/support/in_memory_repositories.rb
class InMemoryGithubRepoRepo
  def initialize(repos = [])
    @repos = repos
  end

  def find(full_name)
    @repos.find { |r| r.full_name == full_name }
  end

  def all_for_org(org)
    @repos.select { |r| r.full_name.start_with?("#{org}/") }
  end
end
```

## Service using injected repository

```ruby
# app/services/org_stats.rb
class OrgStats
  def initialize(org:, repos: GithubRepositoryRepo.new)
    @org = org
    @repos = repos
  end

  def total_stars
    @repos.all_for_org(@org).sum(&:stars)
  end

  def most_starred
    @repos.all_for_org(@org).max_by(&:stars)
  end
end
```

## Service test using the in-memory repo

```ruby
# test/services/org_stats_test.rb
class OrgStatsTest < ActiveSupport::TestCase
  setup do
    repos = [
      GithubRepo.new(full_name: "acme/alpha", description: nil, stars: 100, url: ""),
      GithubRepo.new(full_name: "acme/beta",  description: nil, stars: 250, url: ""),
      GithubRepo.new(full_name: "other/thing", description: nil, stars: 999, url: "")
    ]
    fake_repo = InMemoryGithubRepoRepo.new(repos)
    @service = OrgStats.new(org: "acme", repos: fake_repo)
  end

  test "total_stars counts only org repos" do
    assert_equal 350, @service.total_stars
  end

  test "most_starred returns the right repo" do
    assert_equal "acme/beta", @service.most_starred.full_name
  end
end
```

## Comparison: AR repository vs. plain scopes

```ruby
# Without repository (idiomatic Rails — correct for 99% of apps):
class ProjectsController < ApplicationController
  def index
    @projects = current_user.projects.active.order(:name)
  end
end

# With repository (only justified if you must swap the backend):
class ProjectRepository
  def active_for_user(user)
    Project.where(owner: user).active.order(:name)
  end
end

class ProjectsController < ApplicationController
  def initialize
    @project_repo = ProjectRepository.new
    super
  end

  def index
    @projects = @project_repo.active_for_user(current_user)
  end
end
# The second version is 2x the code for zero benefit if you never swap the backend.
```
