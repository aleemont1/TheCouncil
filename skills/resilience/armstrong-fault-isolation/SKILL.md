---
name: armstrong-fault-isolation
description: "Resilience engineering architecture founded on share-nothing process isolation, 'let it crash' fail-fast semantics, hierarchical supervisor trees, and asynchronous message passing."
triggers: ["let-it-crash", "actor-isolation", "supervisor-tree", "share-nothing", "erlang-otp", "fault-tolerance"]
conflicts_with: ["systems/stenberg-defensive-c"]
primary_sources:
  - title: "Making Reliable Distributed Systems in the Presence of Software Errors"
    url: "https://erlang.org/download/armstrong_thesis_2003.pdf"
  - title: "Systems That Run Forever"
    url: "https://web.archive.org/web/20210224190757/http://armstrongonsoftware.blogspot.com/2006/08/systems-that-run-forever-wishes-for.html"
---

# Joe Armstrong: Fault Isolation & Supervision Hierarchies

## 1. Core Philosophy & Deliberate Rejections
- **Prioritizes**: Share-nothing concurrency (isolated processes with independent heaps and garbage collectors), pure asynchronous message passing, fail-fast "let it crash" philosophy, absolute separation between normal-path code and error-recovery code, hierarchical supervisor trees (`one_for_one`, `one_for_all`, `rest_for_one`), and self-healing systems that run forever.
- **Rejects**: Defensive programming that attempts to fix corrupted local state inside the running worker (e.g., blanket `try/catch` blocks that swallow errors and limp forward in inconsistent states); shared mutable memory; lock-based multithreading; and mixing error recovery with domain execution in the same routine.
- **Primary Trade-off**: Sacrifices raw single-core computational efficiency and shared-memory pointer dereferencing (messages must be copied across process heap boundaries) to achieve near-infinite operational resilience (99.99999% availability), zero blast radius per failure, and clean software upgrades without downtime.

## 2. Hard Implementation Rules
- **Rule 1 (Share-Nothing Isolation)**: Processes MUST NOT share mutable memory, variables, or references. All cross-component communication MUST occur exclusively through immutable message passing.
- **Rule 2 (The Let It Crash Mandate)**: Worker routines MUST only code for the correct "normal case" using strict pattern matching. Workers MUST NOT catch general exceptions to perform local state patching. If an invariant is violated, the worker MUST crash immediately.
- **Rule 3 (Separation of Worker and Supervisor)**: Domain execution and fault handling MUST live in separate processes. Workers MUST execute domain logic; supervisors MUST monitor workers and execute recovery strategies. A supervisor MUST NOT do domain work; a worker MUST NOT supervise other processes.
- **Rule 4 (Bounded Supervision Strategies)**: Every supervisor MUST define a deterministic restart strategy (`one_for_one`, `one_for_all`, or `rest_for_one`) paired with maximum restart frequency thresholds (e.g., maximum 3 restarts in 5 seconds) to detect and escalate permanent structural failures.
- **Rule 5 (One Process per Real-World Concurrent Entity)**: The system MUST assign exactly one concurrent process to each distinct entity in the real world (e.g., one process per connected user, active call, or pipeline). Independent concurrent activities MUST NOT be multiplexed into a single monolithic state container.

## 3. Code Review Checklist
- [ ] **Defensive Error Masking**: Does a worker function catch broad exceptions or nil pointers and return fallback/dummy data, allowing corrupted state to persist?
- [ ] **Shared Mutable State**: Are processes accessing or mutating common data structures without passing messages over explicit communication channels?
- [ ] **Coupled Failure Domains**: Are multiple independent user sessions or background jobs grouped into a single worker process, causing one client's crash to terminate all other clients?
- [ ] **Supervisor Pollution**: Does a supervisor process perform heavy network I/O, database queries, or domain calculation instead of delegating to a worker child?
- [ ] **Missing Crash Limits**: Are restart policies configured with infinite retry loops, causing tight-loop CPU burn during permanent network partition or schema failure?

## 4. Canonical Idiom (Reference Pattern)

### REJECTED: Defensive error swallowing and state surgery in the same process
```erlang
%% REJECTED: Anti-pattern of masking errors and attempting local recovery
-module(worker_anti).
-export([handle_job/2]).

handle_job(State, Message) ->
    try
        %% Defensive programming clutters normal path
        case Message of
            {calculate, Val} when is_number(Val) ->
                NewVal = 100 / Val,
                {ok, State#state{val = NewVal}};
            _ ->
                %% Masking error and returning dirty corrupted state
                {ok, State#state{error_occurred = true}}
        end
    catch
        _:_ ->
            %% Swallowing failure: process remains alive in unpredictable state!
            {ok, State#state{val = 0}}
    end.
```

### ACCEPTED: Pure happy-path pattern matching with supervision crash isolation
```erlang
%% ACCEPTED: Canonical Armstrong / OTP idiom
-module(math_worker).
-behaviour(gen_server).
-export([start_link/0, calculate/2]).
-export([init/1, handle_call/3, handle_cast/2]).

start_link() ->
    gen_server:start_link(?MODULE, [], []).

calculate(Pid, Val) ->
    gen_server:call(Pid, {calculate, Val}).

init([]) ->
    {ok, #{val => 0}}.

%% Rule 2: Program ONLY the normal path!
%% If Val is 0 or not a number, process crashes immediately.
%% State is NOT corrupted; supervisor handles clean restart.
handle_call({calculate, Val}, _From, State) ->
    Result = 100 / Val, 
    {reply, Result, State#{val => Result}}.

handle_cast(_Msg, State) ->
    {noreply, State}.

%%% --- SUPERVISOR MODULE ---
-module(worker_sup).
-behaviour(supervisor).
-export([start_link/0, init/1]).

start_link() ->
    supervisor:start_link(?MODULE, []).

init([]) ->
    %% Rule 4: Explicit restart strategy and frequency boundaries
    SupFlags = #{strategy => one_for_one, intensity => 3, period => 5},
    ChildSpecs = [#{
        id => math_worker,
        start => {math_worker, start_link, []},
        restart => permanent,
        type => worker
    }],
    {ok, {SupFlags, ChildSpecs}}.
```
