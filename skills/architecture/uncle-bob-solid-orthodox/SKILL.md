---
name: uncle-bob-solid-orthodox
description: "Orthodox software craftsmanship paradigm enforcing The Dependency Rule, concentric architectural layers, strict SOLID principles, dynamic polymorphism for boundary crossing, and Red-Green-Refactor TDD cycles."
triggers: ["clean-architecture", "the-dependency-rule", "solid-principles", "cycles-of-tdd", "use-cases-interactors", "craftsmanship"]
conflicts_with: ["performance/muratori-data-oriented", "architecture/ousterhout-deep-modules", "architecture/dhh-majestic-monolith", "performance/carmack-inlined-execution"]
primary_sources:
  - title: "Clean Architecture (The Clean Code Blog)"
    url: "https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html"
  - title: "The Cycles of TDD"
    url: "https://blog.cleancoder.com/uncle-bob/2014/12/17/TheCyclesOfTDD.html"
---

# Robert C. Martin (Uncle Bob): Orthodox Clean Architecture & Craftsmanship

## 1. Core Philosophy & Deliberate Rejections
- **Prioritizes**: *The Dependency Rule* (source code dependencies MUST point strictly inwards: Entities $\leftarrow$ Use Cases $\leftarrow$ Interface Adapters $\leftarrow$ Frameworks/Drivers); decoupling core business rules from databases, UI, and external frameworks; Dependency Inversion Principle (DIP) via dynamic polymorphism; the Three Laws of Test-Driven Development (Red-Green-Refactor cycles); single-responsibility methods and classes; and passing plain Data Transfer Objects (DTOs) across architectural boundaries.
- **Rejects**: Inward dependencies on databases or web frameworks; leaking ORM entities, SQL schemas, or HTTP request objects into business logic; writing production code before writing a failing unit test; switch statements and procedural dispatch where polymorphism provides open-closed extensibility; and "fat" classes that mix presentation, domain rules, and persistence.
- **Primary Trade-off**: Sacrifices hardware-level execution speed, L1/L2 cache locality, and code minimalism (introducing numerous interface boundaries, factory abstractions, and DTO transformations) in exchange for complete framework agnosticism, maximum unit-test coverage, and business domain rules that endure for decades unchanged.

## 2. Hard Implementation Rules
- **Rule 1 (The Dependency Rule)**: Source code dependencies MUST point strictly inwards toward high-level policies. Code within an inner layer (Entities, Use Cases) MUST NOT import or name any class, function, variable, or format declared in an outer layer (Controllers, Repositories, Frameworks).
- **Rule 2 (Boundary Crossing via Inversion)**: When control flow must travel from an inner layer to an outer layer (e.g., a Use Case calling a database or presenter), the boundary MUST be crossed using Dependency Inversion. The inner layer MUST declare an interface (an Output Port or Gateway); the outer layer MUST implement it.
- **Rule 3 (The Three Laws of TDD)**: Developers MUST NOT write production code without first writing a failing unit test. Developers MUST write only enough test code to fail, and only enough production code to pass that single failing test, repeating in seconds-to-minutes Red-Green-Refactor cycles.
- **Rule 4 (Decoupled Boundary DTOs)**: Data crossing architectural boundaries MUST be simple, inert Data Transfer Objects (DTOs) or primitive structures. Entities or ORM-mapped records MUST NOT be returned directly across the Use Case boundary to UI controllers or API views.
- **Rule 5 (Single Responsibility & Polymorphic Extension)**: Classes and functions MUST have only one reason to change (SRP). Variant business behaviors MUST be extended through polymorphism (subclasses or interface implementations) rather than expanding conditionals or `switch` statements (OCP).

## 3. Code Review Checklist
- [ ] **Dependency Rule Violation**: Does a domain Entity or Use Case import a database driver, HTTP library, web framework, or UI class?
- [ ] **Production Code Ahead of Tests**: Was production logic written or committed without corresponding unit tests verifying each behavior test-first?
- [ ] **Leaking Persistence Entities**: Are Active Record or ORM models passed directly into templates, controllers, or external API responses?
- [ ] **Missing Inversion Port**: Does an application service instantiate a concrete database repository or HTTP client directly with `new` rather than injecting an interface?
- [ ] **Mixed Responsibilities (SRP Smell)**: Does a single class calculate domain fees, format HTML/JSON strings, and write database rows?

## 4. Canonical Idiom (Reference Pattern)

### REJECTED: Tightly coupled procedural architecture coupling business logic to DB and HTTP
```csharp
// REJECTED: Business logic tightly coupled to external frameworks and databases
using Microsoft.AspNetCore.Mvc;
using System.Data.SqlClient;

public class OrderController : ControllerBase {
    [HttpPost("/orders")]
    public IActionResult CreateOrder([FromBody] OrderRequest req) {
        // FATAL: Leaking database connection and SQL directly into controller!
        using var conn = new SqlConnection("Server=myServer;Database=myDB;");
        conn.Open();
        
        // Business logic mixed with database queries: cannot be tested without live DB!
        decimal total = req.Quantity * req.UnitPrice;
        if (req.Quantity > 10) total *= 0.9m; // Discount logic trapped in controller

        var cmd = new SqlCommand("INSERT INTO Orders (Total) VALUES (@Total)", conn);
        cmd.Parameters.AddWithValue("@Total", total);
        cmd.ExecuteNonQuery();

        return Ok(new { Total = total });
    }
}
```

### ACCEPTED: Clean Architecture with Dependency Inversion, Use Case Interactor, and boundary DTOs
```csharp
// ACCEPTED: Canonical Uncle Bob Clean Architecture idiom
namespace Enterprise.Domain {
    // 1. Entities: Enterprise Business Rules (Independent of everything)
    public class Order {
        public decimal Quantity { get; }
        public decimal UnitPrice { get; }

        public Order(decimal quantity, decimal unitPrice) {
            Quantity = quantity;
            UnitPrice = unitPrice;
        }

        public decimal CalculateTotal() {
            decimal total = Quantity * UnitPrice;
            if (Quantity > 10) total *= 0.9m; // Pure domain rule
            return total;
        }
    }
}

namespace Enterprise.UseCases {
    using Enterprise.Domain;

    // Boundary DTOs: Plain data structures crossing boundaries
    public record CreateOrderInput(decimal Quantity, decimal UnitPrice);
    public record CreateOrderOutput(decimal Total);

    // Inverted Output Port (Interface defined by Use Case, implemented by outer layer)
    public interface IOrderDatabaseGateway {
        void PersistOrder(decimal total);
    }

    // 2. Use Case Interactor: Application Business Rules
    public class CreateOrderUseCase {
        private readonly IOrderDatabaseGateway _gateway;

        public CreateOrderUseCase(IOrderDatabaseGateway gateway) {
            _gateway = gateway; // Injected via Dependency Inversion
        }

        public CreateOrderOutput Execute(CreateOrderInput input) {
            var order = new Order(input.Quantity, input.UnitPrice);
            decimal total = order.CalculateTotal();
            _gateway.PersistOrder(total);
            return new CreateOrderOutput(total);
        }
    }
}
```
