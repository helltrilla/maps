# Architecture

## 1. Overview

The project follows a pragmatic Clean Architecture approach.

The main goal is to keep:

- UI;
- application coordination;
- business logic;
- data access;
- external APIs;
- persistent storage

separated from each other.

The architecture should remain simple.

Do not introduce additional abstraction layers unless they solve a real problem.

---

# 2. High-Level Architecture

The general dependency flow is:

```text
┌─────────────────────────────┐
│            UI               │
│   Screens / Widgets / UX    │
└──────────────┬──────────────┘
               │
               ↓
┌─────────────────────────────┐
│      Application Layer      │
│ Coordination / State / Flow │
└──────────────┬──────────────┘
               │
               ↓
┌─────────────────────────────┐
│       Service Layer         │
│ Business operations / APIs  │
└──────────────┬──────────────┘
               │
               ↓
┌─────────────────────────────┐
│      Data / External        │
│ APIs / Storage / Platform   │
└─────────────────────────────┘
```

Models are shared between the relevant layers and represent structured application data.

The exact implementation may vary by feature, but the direction of dependencies should remain predictable.

---

# 3. Project Structure

The main source structure is:

```text
lib/
├── main.dart
├── main_screen.dart
├── app_theme.dart
│
├── models/
│
├── services/
│
└── widgets/
```

## `main.dart`

Application entry point.

Responsibilities:

- initialize the application;
- configure the root widget;
- perform only necessary startup configuration.

Do not place feature-specific business logic here.

---

## `main_screen.dart`

Main application coordinator.

It is responsible for coordinating the primary screen and connecting major UI components.

It may coordinate:

- map state;
- user interactions;
- search;
- selected places;
- routes;
- bottom sheets;
- location state;
- map controls.

However, complex business logic should not accumulate here.

If a piece of logic can be independently represented as a service or reusable widget, move it there.

---

# 4. Models

Models represent structured application data.

Current examples include:

```text
models/
├── map_tile_style.dart
├── place.dart
├── place_review.dart
├── route_info.dart
├── saved_marker.dart
└── search_result.dart
```

The README identifies these as immutable data models.

Models should primarily describe data and its basic transformations.

Avoid putting:

- network requests;
- UI logic;
- navigation;
- platform-specific behavior;

inside models.

A model should not need to know which widget displays it.

---

# 5. Services

Services contain operations that should not belong directly to UI widgets.

Current services include:

```text
services/
├── location_service.dart
├── marker_storage.dart
├── place_details_service.dart
├── places_service.dart
├── routing_service.dart
└── search_service.dart
```

These services cover GPS, persistent marker storage, place enrichment, place discovery, routing, and geocoding/search.

## Service responsibilities

A service should have a clear responsibility.

Examples:

```text
LocationService
    ↓
Location and permissions

PlacesService
    ↓
Places / POI retrieval

RoutingService
    ↓
Route calculation

SearchService
    ↓
Geocoding / search

MarkerStorage
    ↓
Persistent saved markers

PlaceDetailsService
    ↓
Additional place information
```

Avoid creating a single "god service" that handles unrelated operations.

---

# 6. Widgets

Reusable UI components live in:

```text
widgets/
```

Current components include:

```text
bottom_panel.dart
layer_switcher_dialog.dart
map_marker_widgets.dart
place_details_sheet.dart
route_header_card.dart
route_planner_sheet.dart
search_bar_widget.dart
```

These components represent reusable parts of the application's UI.

Widgets should primarily be responsible for:

- rendering;
- user interaction;
- local UI state;
- communicating user actions upward.

Widgets should not directly implement complex API workflows.

Prefer:

```text
Widget
   ↓
Service / application logic
   ↓
External API
```

over:

```text
Widget
   ↓
HTTP request
   ↓
JSON parsing
   ↓
Business logic
```

---

# 7. Dependency Direction

Dependencies should generally flow toward lower-level functionality.

Preferred:

```text
Widget
  ↓
Application coordination
  ↓
Service
  ↓
External system
```

Avoid circular dependencies.

For example:

```text
Service → Widget
```

should generally not exist.

A service should not depend on a specific UI component.

Similarly, models should remain independent of UI implementation.

---

# 8. UI vs Business Logic

A useful rule:

> If the logic can be described without mentioning a widget, it probably does not belong inside the widget.

For example, this belongs outside UI:

```text
Find nearby places
Sort results by distance
Calculate route
Save marker
Load cached data
Handle API fallback
```

While this belongs to UI:

```text
Show loading indicator
Display search results
Animate a panel
Respond to a tap
Display an error message
```

---

# 9. External APIs

External services should be accessed through dedicated services.

The project currently integrates with:

```text
OpenStreetMap
OSRM
Overpass API
Photon API
```

The README defines these as the map, routing, POI, and geocoding infrastructure.

UI code should not contain raw API implementation unless there is a strong reason.

Instead:

```text
UI
 ↓
Service
 ↓
API
```

This makes external integrations easier to:

- replace;
- test;
- cache;
- retry;
- mock;
- debug.

---

# 10. API Failure Handling

External APIs are unreliable by nature.

Services should account for:

- connection failures;
- timeouts;
- HTTP errors;
- malformed responses;
- empty responses;
- rate limits;
- temporary service unavailability.

Failure handling should happen as close as possible to the integration layer.

The UI should receive a meaningful result or error state rather than needing to understand HTTP implementation details.

---

# 11. Caching

Caching belongs close to the data/integration layer.

The project uses local tile and HTTP caching through:

```text
flutter_map_cache
dio_cache_interceptor
```

according to the project documentation.

Caching should not leak implementation details into unrelated UI components.

A widget should request data.

It should not need to know whether that data came from:

```text
network
cache
fallback
local storage
```

unless that information is specifically relevant to the UI.

---

# 12. Location

Location access belongs to the location service.

The current project uses a dedicated:

```text
LocationService
```

for GPS and permissions.

UI components should consume location state rather than directly duplicating permission and GPS logic.

If another feature requires location:

```text
Feature
   ↓
LocationService
```

Do not create a second independent location implementation.

---

# 13. Persistent Storage

Persistent data should be isolated from UI.

The project currently uses:

```text
MarkerStorage
```

for saved markers and `shared_preferences` as the underlying storage mechanism.

Preferred flow:

```text
Widget
   ↓
Application logic
   ↓
Storage service
   ↓
Persistent storage
```

The UI should not directly manage serialization formats or storage keys unless the existing architecture explicitly requires it.

---

# 14. Map Responsibilities

Map-related functionality should remain separated by responsibility.

Conceptually:

```text
Map UI
   │
   ├── Tile configuration
   ├── Markers
   ├── Location
   ├── Search
   ├── Routes
   └── User interactions
```

Do not put all map functionality into one class.

For example:

```text
Tile configuration
→ map tile model/configuration

Location
→ LocationService

Places
→ PlacesService

Routing
→ RoutingService

Search
→ SearchService

Saved markers
→ MarkerStorage

UI representation
→ widgets
```

---

# 15. Search Flow

Search should follow a layered flow.

Conceptually:

```text
User input
    ↓
Search UI
    ↓
Search coordination
    ↓
SearchService
    ↓
Photon / external provider
    ↓
SearchResult
    ↓
UI
```

Search-specific presentation logic belongs in the UI.

Search/network logic belongs in the service.

Search result structure belongs in the model.

---

# 16. Place Details Flow

Place details may require multiple data sources.

The conceptual flow is:

```text
Selected place
      ↓
Place details coordination
      ↓
PlaceDetailsService
      ↓
External data sources
      ↓
Place / Review / Media data
      ↓
PlaceDetailsSheet
```

The details UI should not need to understand how additional information was retrieved.

---

# 17. Routing Flow

Routing follows:

```text
Start point
      +
Destination
      ↓
RoutingService
      ↓
OSRM
      ↓
RouteInfo
      ↓
Map / Route UI
```

The routing service is responsible for communication with the routing provider and converting the response into application data.

The UI is responsible for presenting the route.

---

# 18. State Management

State should have a clear owner.

Before adding new state, determine:

```text
Who owns this state?
Who modifies it?
Who reads it?
How long should it live?
```

Do not duplicate the same state across multiple widgets without a reason.

Avoid global mutable state unless the application architecture explicitly requires it.

Prefer keeping state as close as possible to the component that owns the behavior.

If state is shared by multiple independent components, move it to an appropriate coordination layer.

---

# 19. Adding a New Feature

When implementing a new feature, follow:

```text
1. Understand the feature
        ↓
2. Identify existing models
        ↓
3. Identify existing services
        ↓
4. Reuse existing functionality
        ↓
5. Add or modify model if required
        ↓
6. Add service logic if required
        ↓
7. Add UI components
        ↓
8. Connect everything through the appropriate coordinator
        ↓
9. Add tests
        ↓
10. Verify
```

Do not start by modifying the largest screen.

Start by identifying where the new responsibility belongs.

---

# 20. Adding a New Service

Create a new service when:

- a responsibility is clearly distinct;
- the functionality is reusable;
- the logic interacts with an external system;
- the logic is complex enough to require independent testing;
- keeping it in the current component would reduce maintainability.

Do not create a service merely to move a few lines of trivial code.

A service should have one clear purpose.

---

# 21. Adding a New Model

Create a model when data has:

- multiple fields;
- defined semantics;
- serialization/deserialization;
- repeated use;
- independent validation or transformation.

Prefer structured models over passing untyped maps throughout the application.

---

# 22. Adding a New Widget

Create a reusable widget when:

- a UI component is used more than once;
- a component has meaningful independent behavior;
- a screen becomes too complex;
- a component can be tested or reasoned about independently.

Do not extract every three lines of UI into a separate widget.

The goal is clarity, not maximum fragmentation.

---

# 23. Testing Architecture

Tests should exist at the appropriate layer.

## Models

Test:

- serialization;
- deserialization;
- formatting;
- validation;
- edge cases.

## Services

Test:

- successful responses;
- failures;
- empty results;
- transformations;
- fallback behavior.

## Widgets

Test:

- important rendering states;
- user interactions;
- loading;
- empty states;
- errors.

The project already contains tests for models and services such as `RouteInfo`, `SavedMarker`, `MapTileStyle`, `Place`, and `PlaceDetailsService`.

---

# 24. Error Boundaries

Errors should be handled at the layer that understands them.

Example:

```text
HTTP error
    ↓
Service understands network failure
    ↓
Application layer decides what it means
    ↓
UI displays appropriate state
```

Avoid leaking low-level errors directly into presentation code.

At the same time, do not hide useful diagnostic information.

---

# 25. Performance Boundaries

Performance-sensitive operations should not unnecessarily block UI work.

Pay particular attention to:

- network requests;
- large JSON responses;
- map rendering;
- marker generation;
- image loading;
- repeated rebuilds;
- disk operations;
- expensive calculations.

Optimize based on an actual problem or clear architectural requirement.

Do not sacrifice readability for speculative optimization.

---

# 26. Architecture Rules for AI Agents

When modifying the project, an AI agent must:

1. Inspect the existing architecture first.
2. Reuse existing services and models.
3. Avoid creating duplicate functionality.
4. Keep UI and business logic separated.
5. Keep external API logic inside services.
6. Preserve existing public behavior unless the task requires a change.
7. Avoid unrelated refactoring.
8. Prefer the smallest architectural change that solves the problem.
9. Add tests for meaningful new behavior.
10. Verify the result before reporting completion.

---

# 27. Architectural Red Flags

Stop and reconsider if a change introduces:

```text
Widget
  ↓
HTTP request
```

or:

```text
Widget
  ↓
Database
```

or:

```text
Model
  ↓
Widget
```

or:

```text
One giant service
  ├── search
  ├── routing
  ├── storage
  ├── location
  ├── authentication
  └── unrelated business logic
```

These patterns usually indicate that responsibilities are being mixed.

---

# 28. When Architecture May Be Changed

Architecture can be changed when:

- the current structure prevents the required feature;
- responsibilities are clearly mixed;
- a dependency direction is fundamentally wrong;
- the current design creates a measurable maintenance or reliability problem;
- the project requirements have materially changed.

Architectural changes should be:

- intentional;
- scoped;
- documented when significant;
- tested;
- reviewed separately from unrelated feature work.

Do not perform architectural changes solely for stylistic reasons.

---

# 29. Decision Rule

When deciding where new code belongs, use this order:

```text
Is it UI?
    ↓ yes
Widget

Is it structured data?
    ↓ yes
Model

Is it external communication or reusable business operation?
    ↓ yes
Service

Is it application-level coordination/state?
    ↓ yes
Coordinator / appropriate application layer

Otherwise:
    ↓
Inspect existing architecture before creating a new layer.
```

Do not create a new architectural layer simply because the existing categories are imperfect.

---

# 30. Architectural Goal

The goal of this architecture is not to achieve theoretical purity.

The goal is to make the codebase:

```text
Easy to understand
        ↓
Easy to change
        ↓
Easy to test
        ↓
Hard to accidentally break
```

Every architectural decision should move the project toward these properties.

---

# 31. Source of Truth

`README.md` describes what the project is, its capabilities, setup, and high-level structure.

`ARCHITECTURE.md` describes how the code should be structured and extended.

`AGENTS.md` describes how an AI/software engineering agent should work within the repository.

When modifying the project:

```text
AGENTS.md
    ↓
How to work

ARCHITECTURE.md
    ↓
How to structure code

README.md
    ↓
What the project is and how to use it
```

These documents should complement each other rather than duplicate each other.
