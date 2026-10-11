---
name: dhh-majestic-monolith
description: "Majestic monolith: one codebase, integrated Active Record models, server-driven UI, bare-metal deploys, system tests over unit-test mocks. Use when designing or reviewing web app architecture, weighing microservices or repository/mock layers against a single deployable, or choosing a test strategy."
triggers: ["majestic-monolith", "active-record", "system-testing", "cloud-exit", "omakase", "full-stack-framework"]
conflicts_with: ["performance/danluu-empirical-systems", "security/djb-isolated-privilege", "distributed/kleppmann-data-contracts"]
primary_sources:
  - title: "The Majestic Monolith"
    url: "https://signalvnoise.com/svn3/the-majestic-monolith/"
  - title: "TDD is dead. Long live testing"
    url: "https://dhh.dk/2014/tdd-is-dead-long-live-testing.html"
  - title: "Why We Are Leaving the Cloud"
    url: "https://world.hey.com/dhh/why-we-are-leaving-the-cloud-650fba4e"
---

# David Heinemeier Hansson: The Majestic Monolith & Pragmatic Web Architecture

**Apply**: write or review the target under Sections 2 and 3. Done when every rule is either satisfied or reported as violated, and every checklist item is marked hit (with `file:line`) or clear. When a rule collides with a stated requirement, name the trade-off from Section 1 rather than bending the rule silently.

## 1. Core Philosophy & Deliberate Rejections
- **Prioritizes**: The Majestic Monolith (a unified codebase and database powering the entire system), integrated Active Record modeling (co-locating domain rules, schema associations, and persistence), full-stack developer superpowers, real-world integration/system tests, server-rendered progressive enhancement (Hotwire/Turbo), and bare-metal server ownership ("Leaving the Cloud" to avoid extortionate cloud rental margins and unnecessary complexity).
- **Rejects**: Microservices cargo-culting for small-to-medium organizations (imitating Amazon/Google organizational structures when team sizes are under hundreds of engineers); test-induced design damage (fracturing clean designs into mock factories, dependency-injection boilerplate, and shallow interfaces merely to facilitate isolated unit testing); test-first fundamentalism; Single Page Application (SPA) JSON API duplication; and runaway public cloud infrastructure complexity.
- **Primary Trade-off**: Sacrifices theoretical micro-component isolation and polyglot microservice boundaries in exchange for immense developer leverage, rapid end-to-end product delivery, dramatic cost reductions, and architectural simplicity.

## 2. Hard Implementation Rules
- **Rule 1 (Unified Monolith Deployment)**: Application controllers, background queue jobs, and business workflows MUST reside within a single monolithic codebase sharing the primary database. Teams MUST NOT carve off features into standalone microservices communicating over network RPCs.
- **Rule 2 (Active Record Domain Integration)**: Domain models MUST utilize the integrated Active Record pattern, embedding validations, associations, and state machines directly in the model. Developers MUST NOT layer artificial Repository, Data Mapper, or Service abstractions unless an entity genuinely coordinates multi-model workflows.
- **Rule 3 (System Tests Over Mocked Unit Tests)**: The primary test harness MUST consist of end-to-end integration and system tests running against real database instances. Architects MUST NOT alter or degrade application design purely to enable mock-driven unit testing ("test-induced design damage").
- **Rule 4 (Server-Rendered HTML First)**: User interfaces MUST prioritize server-rendered HTML augmented with progressive enhancement (Turbo/Stimulus). Codebases MUST NOT build duplicate client-side SPA state models unless real-time offline-first capabilities are an explicit requirement.
- **Rule 5 (Infrastructure Ownership & Simplicity)**: Production deployment topology MUST rely on standard containers managed on owned or predictably priced bare-metal/virtual servers (e.g., Kamal). Teams MUST NOT introduce multi-tier serverless cloud plumbing when standard servers deliver superior throughput at a fraction of the cost.

## 3. Code Review Checklist
- [ ] **Test-Induced Design Damage**: Have artificial interfaces, repository wrappers, or mock injection hooks been added to a class purely to satisfy unit test isolation?
- [ ] **Premature Service Extraction**: Is a feature or background job split into a distinct repository/service requiring JSON serialization, network retries, and distributed tracing?
- [ ] **Redundant Client-Side State**: Does the frontend maintain complex client-side stores and duplicate validation logic that could be rendered server-side in a single round-trip?
- [ ] **Cloud Complexity Sprawl**: Has an architecture proposal introduced serverless functions, message buses, and managed cloud gateways where a single database background job queue (`Solid Queue`) would suffice?
- [ ] **Mock-Heavy Fragility**: Are tests asserting internal implementation calls (`verify(mock).save()`) rather than validating final database state and HTTP response status?

## 4. Canonical Idiom (Reference Pattern)

### REJECTED: Over-abstracted enterprise architecture with mock-induced design damage
```ruby
# REJECTED: Test-induced design damage with repository abstractions and mock tests
class UserRepositoryInterface
  def find(id); raise NotImplementedError; end
  def save(user); raise NotImplementedError; end
end

class UserRegistrationService
  def initialize(repo, mailer, event_bus)
    @repo = repo
    @mailer = mailer
    @event_bus = event_bus
  end

  def register(params)
    # Artificial indirection creating dozens of files
    user = UserEntity.new(params)
    @repo.save(user)
    @mailer.deliver_activation(user)
    @event_bus.publish("user.registered", user.id)
  end
end

# Unit test mocks every collaborator, verifying implementation details, not outcomes
describe UserRegistrationService do
  it "calls repository and mailer" do
    repo = double("Repo", save: true)
    mailer = double("Mailer", deliver_activation: true)
    bus = double("Bus", publish: true)
    service = UserRegistrationService.new(repo, mailer, bus)
    expect(repo).to receive(:save) # Mock-induced fragility!
    service.register({email: "test@example.com"})
  end
end
```

### ACCEPTED: Majestic Monolith Active Record pattern with real database integration testing
```ruby
# ACCEPTED: Canonical DHH / Rails Majestic Monolith idiom
class User < ApplicationRecord
  # Active Record marries domain logic, associations, and database persistence
  has_many :memberships, dependent: :destroy
  has_many :projects, through: :memberships

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  after_create_commit :send_activation_email

  def activate!
    update!(active: true, activated_at: Time.current)
  end

  private

  def send_activation_email
    UserMailer.activation(self).deliver_later
  end
end

# Real system/integration test exercising actual database and mail delivery
class UserRegistrationTest < ActionDispatch::IntegrationTest
  test "registers and sends activation email against real database" do
    assert_difference -> { User.count } => 1, -> { ActionMailer::Base.deliveries.size } => 1 do
      post signups_path, params: { user: { email: "dhh@37signals.com" } }
    end
    assert_redirected_to dashboard_path
    assert_equal "dhh@37signals.com", User.last.email
  end
end
```
