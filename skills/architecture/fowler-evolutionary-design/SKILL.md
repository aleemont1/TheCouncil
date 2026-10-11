---
name: fowler-evolutionary-design
description: "Evolutionary design: continuous refactoring under automated tests, YAGNI, MonolithFirst, enterprise data patterns. Use when deciding how much architecture to build up front, whether to split a service, or how to sequence a refactor safely."
triggers: ["evolutionary-architecture", "refactoring", "monolith-first", "poeaa-patterns", "yagni", "bounded-context"]
conflicts_with: ["performance/muratori-data-oriented", "architecture/ousterhout-deep-modules", "performance/carmack-inlined-execution"]
primary_sources:
  - title: "Catalog of Enterprise Architecture Patterns"
    url: "https://martinfowler.com/eaaCatalog/"
  - title: "MonolithFirst Pattern"
    url: "https://martinfowler.com/bliki/MonolithFirst.html"
---

# Martin Fowler: Evolutionary Design & Refactoring Discipline

**Apply**: write or review the target under Sections 2 and 3. Done when every rule is either satisfied or reported as violated, and every checklist item is marked hit (with `file:line`) or clear. When a rule collides with a stated requirement, name the trade-off from Section 1 rather than bending the rule silently.

## 1. Core Philosophy & Deliberate Rejections
- **Prioritizes**: Evolutionary architecture (growing software via continuous refactoring in small, behavior-preserving steps), comprehensive automated testing as a design safety harness, the MonolithFirst pattern ("start with a monolith first, even if you think it's likely you will benefit from microservices later on"), YAGNI ("You Aren't Gonna Need It"), and domain-driven enterprise abstractions (Repository, Data Mapper, Unit of Work, Strangler Fig).
- **Rejects**: Big Design Up Front (BDUF); premature distributed systems and microservices from day one (which incur a heavy "Microservice Premium" of network latency, distributed transactions, and organizational overhead before bounded contexts are clear); refactoring without automated test coverage; and speculative frameworks built for hypothetical future requirements.
- **Primary Trade-off**: Sacrifices raw hardware-level execution speed and zero-cost abstraction purity (domain models and repositories add object allocations and indirection) in exchange for high team velocity, business agility, safe refactorability, and long-term maintainability.

## 2. Hard Implementation Rules
- **Rule 1 (MonolithFirst Invariant)**: New systems MUST begin as a modular monolith. Teams MUST NOT partition a system into distributed microservices until the domain model has stabilized in production and performance/organizational pressure makes the Microservice Premium worthwhile.
- **Rule 2 (Test-Guarded Refactoring)**: Every code refactoring MUST be conducted in small, discrete steps verified by an automated test suite. Refactoring MUST NOT be attempted on code paths lacking automated test verification.
- **Rule 3 (Strict YAGNI Enforcement)**: Code MUST implement only currently required features and domain capabilities. Developers MUST NOT add speculative extensibility hooks, unused generic parameters, or anticipatory configuration layers.
- **Rule 4 (Separation of Domain and Persistence)**: Business domain models MUST remain decoupled from database schemas and external transport mechanisms using Enterprise Patterns (Repository, Data Mapper, Unit of Work). Domain entities MUST NOT embed direct SQL queries or database-specific driver calls.
- **Rule 5 (Strangler Fig for Modernization)**: Legacy systems MUST be modernized incrementally by routing new functionality around the perimeter using the Strangler Fig pattern. Teams MUST NOT undertake all-or-nothing "big bang" rewrites.

## 3. Code Review Checklist
- [ ] **Premature Microservices Smell**: Is a brand new application being decomposed into multi-repo distributed services across network boundaries before domain boundaries are proven?
- [ ] **Untested Structural Refactoring**: Are methods, classes, or module boundaries being rearranged without automated unit or integration tests verifying that behavior remains unchanged?
- [ ] **Speculative Complexity (YAGNI)**: Are there generic interfaces, factory classes, or abstraction hooks that have only a single implementation and serve no current user need?
- [ ] **SQL Leaking into Domain Logic**: Are SQL strings, ORM query builders, or HTTP request handlers intertwined inside core domain entities?
- [ ] **Big-Bang Rewrite Proposal**: Is there an architectural proposal to scrap a working production monolith in favor of a rewrite from scratch instead of applying Strangler Fig migration?

## 4. Canonical Idiom (Reference Pattern)

### REJECTED: Premature microservice RPC sprawl with scattered business logic
```python
# REJECTED: Premature microservice RPC calls and leaked database queries
import requests

class OrderServiceController:
    def checkout(self, user_id, item_id, db_conn):
        # Leaking SQL directly into controller
        cursor = db_conn.cursor()
        cursor.execute("SELECT price FROM items WHERE id = %s", (item_id,))
        item = cursor.fetchone()

        # Distributed network calls for trivial coordination: Microservice Premium!
        inv_res = requests.post(f"http://inventory-service/reserve", json={"item": item_id})
        if inv_res.status_code != 200:
            return {"error": "Out of stock"}

        pay_res = requests.post(f"http://payment-service/charge", json={"user": user_id, "amount": item[0]})
        return {"status": "completed"}
```

### ACCEPTED: Modular monolith domain model with Repository pattern and Unit of Work
```python
# ACCEPTED: Canonical Fowler Enterprise Pattern (Repository + Domain Model)
from typing import Protocol, List
from dataclasses import dataclass

@dataclass
class OrderLine:
    item_id: str
    price: float

class Order:
    """Rich domain model encapsulating business invariants."""
    def __init__(self, order_id: str, customer_id: str):
        self.order_id = order_id
        self.customer_id = customer_id
        self.lines: List[OrderLine] = []

    def add_line(self, item_id: str, price: float, available_stock: int) -> None:
        if available_stock <= 0:
            raise ValueError("Item out of stock")
        self.lines.append(OrderLine(item_id=item_id, price=price))

    @property
    def total(self) -> float:
        return sum(line.price for line in self.lines)

class OrderRepository(Protocol):
    """Repository interface decoupling domain logic from persistence."""
    def save(self, order: Order) -> None: ...
    def get_by_id(self, order_id: str) -> Order: ...

class CheckoutUseCase:
    """Application service coordinating domain entities and repositories in-process."""
    def __init__(self, orders: OrderRepository):
        self.orders = orders

    def execute(self, order_id: str, customer_id: str, item_id: str, price: float, stock: int) -> Order:
        order = Order(order_id=order_id, customer_id=customer_id)
        order.add_line(item_id, price, available_stock=stock)
        self.orders.save(order)
        return order
```
