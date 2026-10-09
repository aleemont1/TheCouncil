---
name: "types/king-type-driven-design"
description: "Type-driven software design discipline converting untyped data into rich compile-time types at boundaries ('Parse, Don't Validate'), making illegal states unrepresentable, and treating static types as generative axioms."
triggers: ["parse-dont-validate", "type-driven-design", "make-illegal-states-unrepresentable", "types-as-axioms", "algebraic-data-types", "compile-time-proofs"]
conflicts_with: ["systems/pike-unix-minimalism", "systems/antirez-pragmatic-c"]
primary_sources:
  - title: "Parse, Don't Validate"
    url: "https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/"
  - title: "Types as Axioms"
    url: "https://lexi-lambda.github.io/blog/2020/08/13/types-as-axioms-or-playing-god-with-ghc/"
---

# Alexis King: Type-Driven Correctness & "Parse, Don't Validate"

## 1. Core Philosophy & Deliberate Rejections
- **Prioritizes**: "Parse, don't validate" (transforming unstructured, untrusted data at the system boundary into precise, rich types that capture and preserve verified facts throughout the program); making illegal states unrepresentable using Algebraic Data Types (ADTs); treating types as generative axioms that define what valid states exist; total functions that can never fail at runtime; and pushing uncertainty to the system perimeter.
- **Rejects**: Traditional validation routines that inspect data and return booleans or throw exceptions while discarding the verified knowledge (leaving downstream code to operate on raw, untrusted primitives like `String` or `List`); "shotgun parsing" (scattering validation checks throughout domain logic); partial functions (such as `head` on potentially empty lists); stringly-typed architectures; and treating the typechecker as an adversary rather than an automated proof engine.
- **Primary Trade-off**: Sacrifices quick untyped prototype velocity and loose primitive-based flexibility in exchange for eliminating entire classes of runtime defects (null pointer exceptions, out-of-bounds errors, malformed payloads) at compile time.

## 2. Hard Implementation Rules
- **Rule 1 (Parse at Boundaries)**: Input validation MUST be structured as parsing: a function that receives raw, unverified data MUST return a refined, specialized type (e.g., `parseEmail(string) -> Result<EmailAddress>`) or fail. Functions MUST NOT validate data and then return raw untyped primitives.
- **Rule 2 (Make Illegal States Unrepresentable)**: Data structures MUST be designed so that invalid domain states cannot be constructed. Code MUST use sum types, non-empty collections (`NonEmptyList`), and discriminated unions rather than multi-boolean flags that allow contradictory states.
- **Rule 3 (No Downstream Defensive Re-Checking)**: Domain and business logic MUST accept only parsed, typed domain values. Inner functions MUST NOT re-verify preconditions or perform redundant null/empty checks on values whose types already guarantee validity.
- **Rule 4 (Total Functions Only)**: Public API functions MUST be total: they MUST produce a valid output for every conceivable input allowed by their type signature. Functions MUST NOT throw unchecked runtime errors or panics on legal type inhabitants (e.g., calling `head` on an empty list).
- **Rule 5 (Types as Axioms)**: Types MUST be modeled additively as domain axioms that specify permissible operations. Developers MUST NOT rely on runtime type assertions (`as`, `instanceof`, downcasting) to bypass static type checks.

## 3. Code Review Checklist
- [ ] **Validation Without Refinement Smell**: Does a function check if an argument is valid (e.g., `validateUser(user)`) and return `void` or `bool`, leaving the caller with the same raw unvalidated type?
- [ ] **Shotgun Parsing**: Are validation checks (e.g., string length, format regex, range checks) scattered throughout deep business logic rather than concentrated at the ingestion boundary?
- [ ] **Representable Illegal State**: Does a data structure contain fields that can contradict each other (e.g., `isLoggedIn: bool` alongside `userId: Option<string>`) instead of a unified tagged union?
- [ ] **Partial Function Warning**: Is there a method that throws an exception when called with valid types (e.g., popping an empty list, indexing an unverified array)?
- [ ] **Downstream Defensive Clutter**: Does internal domain code repeatedly check `if (value != null && value.length > 0)` instead of expecting a `NonEmptyList`?

## 4. Canonical Idiom (Reference Pattern)

### REJECTED: Validation pattern discarding verified knowledge and forcing defensive checks
```typescript
// REJECTED: "Validate" pattern - inspects condition, throws error, returns raw unrefined data
function validateNonEmpty(items: string[]): void {
    if (items.length === 0) {
        throw new Error("List cannot be empty");
    }
}

// Downstream code STILL receives raw string[] and must defensively handle empty lists!
function processItems(items: string[]): string {
    validateNonEmpty(items);
    
    // Partial function: items[0] could theoretically be undefined according to the type system!
    // Forces developers or linters to add redundant checks or non-null assertions (!)
    return items[0].toUpperCase(); 
}
```

### ACCEPTED: "Parse, Don't Validate" pattern capturing proofs in the type system
```typescript
// ACCEPTED: Canonical Alexis King "Parse, Don't Validate" idiom
// The type itself proves the list contains at least one element.
export type NonEmptyArray<T> = [T, ...T[]];

// Boundary Parser: transforms untrusted raw data into the refined type
export function parseNonEmpty<T>(items: T[]): NonEmptyArray<T> | null {
    if (items.length === 0) {
        return null; // Parsing fails cleanly at boundary
    }
    return [items[0], ...items.slice(1)];
}

// Downstream domain function is TOTAL: cannot fail at runtime, zero defensive checks needed!
export function processFirstItem(items: NonEmptyArray<string>): string {
    // items[0] is guaranteed to exist at compile time by the type axiom.
    // Illegal states (empty list) are completely UNREPRESENTABLE!
    return items[0].toUpperCase();
}
```
