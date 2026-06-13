# ExcaliDraw Offline Clone — Complete Architecture & Implementation Specification

> **Version:** 1.0.0
> **Status:** Architecture Document
> **Target:** Production-grade offline-first drawing application

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [System Architecture](#2-system-architecture)
3. [State Management](#3-state-management)
4. [Canvas Engine](#4-canvas-engine)
5. [Drawing Objects](#5-drawing-objects)
6. [Rough Rendering Engine](#6-rough-rendering-engine)
7. [Infinite Canvas & Camera System](#7-infinite-canvas--camera-system)
8. [Selection System](#8-selection-system)
9. [Layers](#9-layers)
10. [History System (Undo/Redo)](#10-history-system-undo-redo)
11. [Local Storage](#11-local-storage)
12. [Import System](#12-import-system)
13. [Export System](#13-export-system)
14. [Templates](#14-templates)
15. [UI/UX Architecture](#15-uiux-architecture)
16. [Keyboard Shortcuts](#16-keyboard-shortcuts)
17. [Performance Strategy](#17-performance-strategy)
18. [Security & Code Quality](#18-security--code-quality)
19. [Testing Strategy](#19-testing-strategy)
20. [Cross-Platform Considerations](#20-cross-platform-considerations)
21. [Development Roadmap](#21-development-roadmap)
22. [Git Workflow](#22-git-workflow)
23. [Production Checklist](#23-production-checklist)

---

## 1. Project Overview

### 1.1 Product Vision

A professional offline-first diagramming and whiteboard application that matches Excalidraw's feature set while operating entirely locally. No accounts, no cloud sync, no internet dependency. Every piece of data lives on the device.

### 1.2 Core Capabilities

- **Infinite Canvas** with smooth zoom/pan
- **Drawing Tools**: Rectangle, ellipse, diamond, triangle, line, arrow, freehand pencil, text, image
- **Rough Rendering**: Hand-drawn sketch aesthetic using algorithmic jitter
- **Selection System**: Single, multi, marquee with resize/rotation handles
- **Layer Management**: Reorder, hide, lock
- **History**: Undo/redo with command pattern, thousands of operations
- **Local Storage**: Projects persist via Isar database
- **Import**: JSON (Excalidraw-compatible), SVG
- **Export**: PNG, JPG, SVG, JSON
- **Templates**: Flowchart, UML, mind map, network diagram
- **Responsive UI**: Desktop, tablet, mobile with adaptive layout

### 1.3 Performance Targets

- 60 FPS minimum, 120 FPS preferred
- 10,000+ objects without perceptible lag
- Sub-10ms repaint for viewport changes
- Undo/redo for 10,000+ operations with constant-time rollback
- Export at up to 4x canvas resolution

---

## 2. System Architecture

### 2.1 Clean Architecture Layers

```
┌─────────────────────────────────────────────────┐
│                  Presentation                    │
│    (Widgets, Providers, Pages, Layouts)          │
├─────────────────────────────────────────────────┤
│                   Domain                         │
│   (Entities, Use Cases, Repository Interfaces)   │
├─────────────────────────────────────────────────┤
│                   Data                           │
│   (Repositories, Data Sources, Models, Mappers)  │
├─────────────────────────────────────────────────┤
│                   Core                           │
│   (Canvas Engine, Storage, DI, Theme, Utils)     │
└─────────────────────────────────────────────────┘
```

### 2.2 Feature-First Directory Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart          # App-wide magic numbers
│   │   ├── canvas_constants.dart       # Canvas limits, zoom bounds
│   │   ├── shape_constants.dart        # Default shape sizes, styles
│   │   └── keybord_shortcuts.dart      # Shortcut definitions
│   │
│   ├── errors/
│   │   ├── failures.dart               # Failure sealed class hierarchy
│   │   ├── exceptions.dart             # Custom exceptions
│   │   └── error_handler.dart          # Global error handler
│   │
│   ├── services/
│   │   ├── file_service.dart           # File I/O abstractions
│   │   ├── clipboard_service.dart      # System clipboard
│   │   └── share_service.dart          # Platform share sheet
│   │
│   ├── theme/
│   │   ├── app_theme.dart              # Light/dark theme definitions
│   │   ├── canvas_theme.dart           # Canvas-specific colors
│   │   └── typography.dart             # Text styles
│   │
│   ├── widgets/
│   │   ├── app_shell.dart              # Root app layout wrapper
│   │   ├── responsive_layout.dart      # Breakpoint-based layout
│   │   ├── tooltip_wrapper.dart        # Styled tooltips
│   │   └── loading_overlay.dart        # Loading state
│   │
│   ├── utils/
│   │   ├── math_utils.dart             # Vector math, interpolation
│   │   ├── geometry_utils.dart         # Point, rect, transform utils
│   │   ├── color_utils.dart            # Color conversion/manipulation
│   │   ├── uuid_generator.dart         # ID generation
│   │   └── debouncer.dart              # Debounce utility
│   │
│   ├── di/
│   │   ├── injection_container.dart    # Core DI registrations
│   │   └── module.dart                 # DI module interface
│   │
│   └── platform/
│       ├── platform_info.dart          # Platform detection
│       └── file_paths.dart             # Platform file paths
│
├── features/
│   ├── canvas/                         # Infinite canvas feature
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── canvas_state.dart
│   │   │   │   ├── canvas_transform.dart
│   │   │   │   └── viewport.dart
│   │   │   ├── repositories/
│   │   │   │   └── canvas_repository.dart  # Interface
│   │   │   └── use_cases/
│   │   │       ├── pan_canvas.dart
│   │   │       ├── zoom_canvas.dart
│   │   │       └── reset_viewport.dart
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── canvas_state_model.dart
│   │   │   │   └── canvas_state_mapper.dart
│   │   │   └── repositories/
│   │   │       └── canvas_repository_impl.dart
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   │   ├── canvas_provider.dart
│   │   │   │   ├── canvas_transform_provider.dart
│   │   │   │   └── viewport_provider.dart
│   │   │   ├── widgets/
│   │   │   │   ├── infinite_canvas.dart
│   │   │   │   ├── canvas_viewport.dart
│   │   │   │   └── canvas_gesture_handler.dart
│   │   │   └── pages/
│   │   │       └── canvas_page.dart
│   │   └── engine/
│   │       ├── canvas_engine.dart          # Core engine
│   │       ├── render_pipeline.dart        # Render stages
│   │       ├── hit_tester.dart             # Hit detection
│   │       ├── dirty_region_tracker.dart   # Repaint optimization
│   │       ├── object_cache.dart           # Shape cache
│   │       └── picture_recorder_manager.dart
│   │
│   ├── shapes/                         # Shape definitions & drawing
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── shape.dart              # Abstract base
│   │   │   │   ├── shape_type.dart         # Enum
│   │   │   │   ├── shape_properties.dart   # Shared properties
│   │   │   │   ├── point.dart              # Value object
│   │   │   │   ├── size.dart               # Value object
│   │   │   │   ├── rectangle_shape.dart
│   │   │   │   ├── ellipse_shape.dart
│   │   │   │   ├── diamond_shape.dart
│   │   │   │   ├── triangle_shape.dart
│   │   │   │   ├── line_shape.dart
│   │   │   │   ├── arrow_shape.dart
│   │   │   │   ├── freehand_shape.dart
│   │   │   │   ├── text_shape.dart
│   │   │   │   └── image_shape.dart
│   │   │   ├── value_objects/
│   │   │   │   ├── stroke_style.dart
│   │   │   │   ├── fill_style.dart
│   │   │   │   ├── roughness.dart
│   │   │   │   └── layer_info.dart
│   │   │   └── repositories/
│   │   │       └── shape_repository.dart   # Interface
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── shape_model.dart
│   │   │   │   ├── shape_model_mapper.dart
│   │   │   │   └── shape_dto.dart
│   │   │   └── repositories/
│   │   │       └── shape_repository_impl.dart
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   │   ├── shape_provider.dart
│   │   │   │   ├── active_tool_provider.dart
│   │   │   │   └── shape_style_provider.dart
│   │   │   └── widgets/
│   │   │       ├── shape_overlay.dart
│   │   │       └── shape_renderer.dart
│   │   └── engine/
│   │       ├── shape_factory.dart          # Create shapes from tool
│   │       ├── shape_painter.dart          # Paint each shape type
│   │       ├── rough_painter.dart          # Rough rendering engine
│   │       ├── freehand_interpolator.dart  # Smooth freehand paths
│   │       ├── text_painter.dart           # Text rendering
│   │       ├── image_painter.dart          # Image rendering
│   │       ├── arrow_head_painter.dart     # Arrow heads
│   │       └── bounding_box_calculator.dart
│   │
│   ├── selection/                      # Selection & manipulation
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── selection_state.dart
│   │   │   │   ├── selection_handle.dart
│   │   │   │   ├── resize_handle.dart
│   │   │   │   └── rotation_handle.dart
│   │   │   └── use_cases/
│   │   │       ├── select_shape.dart
│   │   │       ├── multi_select.dart
│   │   │       ├── marquee_select.dart
│   │   │       ├── resize_shape.dart
│   │   │       ├── rotate_shape.dart
│   │   │       └── move_shape.dart
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   │   ├── selection_provider.dart
│   │   │   │   └── manipulation_provider.dart
│   │   │   └── widgets/
│   │   │       ├── selection_overlay.dart
│   │   │       ├── resize_handles.dart
│   │   │       ├── rotation_handle.dart
│   │   │       ├── bounding_box.dart
│   │   │       └── marquee_rect.dart
│   │   └── engine/
│   │       ├── hit_tester.dart             # Shape hit testing
│   │       ├── handle_hit_tester.dart      # Handle hit testing
│   │       ├── marquee_calculator.dart
│   │       ├── snap_engine.dart            # Snap to grid/objects
│   │       └── transform_calculator.dart   # Resize/rotate math
│   │
│   ├── layers/                         # Layer management
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── layer.dart
│   │   │   │   └── layer_list.dart
│   │   │   └── use_cases/
│   │   │       ├── bring_to_front.dart
│   │   │       ├── send_to_back.dart
│   │   │       ├── move_layer_up.dart
│   │   │       ├── move_layer_down.dart
│   │   │       ├── toggle_layer_visibility.dart
│   │   │       └── toggle_layer_lock.dart
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   │   └── layer_provider.dart
│   │   │   └── widgets/
│   │   │       ├── layer_panel.dart
│   │   │       ├── layer_item.dart
│   │   │       └── layer_controls.dart
│   │   └── data/
│   │       └── repositories/
│   │           └── layer_repository_impl.dart
│   │
│   ├── history/                        # Undo/redo
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── history_state.dart
│   │   │   │   └── history_entry.dart
│   │   │   ├── commands/
│   │   │   │   ├── command.dart            # Abstract interface
│   │   │   │   ├── add_shape_command.dart
│   │   │   │   ├── remove_shape_command.dart
│   │   │   │   ├── modify_shape_command.dart
│   │   │   │   ├── move_shape_command.dart
│   │   │   │   ├── resize_shape_command.dart
│   │   │   │   ├── rotate_shape_command.dart
│   │   │   │   ├── reorder_shape_command.dart
│   │   │   │   └── composite_command.dart
│   │   │   └── repositories/
│   │   │       └── history_repository.dart
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── history_repository_impl.dart
│   │   └── presentation/
│   │       └── providers/
│   │           ├── history_provider.dart
│   │           └── can_undo_redo_provider.dart
│   │
│   ├── projects/                       # Local project management
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── project.dart
│   │   │   │   └── project_summary.dart
│   │   │   └── use_cases/
│   │   │       ├── create_project.dart
│   │   │       ├── open_project.dart
│   │   │       ├── save_project.dart
│   │   │       ├── delete_project.dart
│   │   │       ├── rename_project.dart
│   │   │       ├── list_projects.dart
│   │   │       └── duplicate_project.dart
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── project_local_datasource.dart
│   │   │   │   └── project_database.dart
│   │   │   ├── models/
│   │   │   │   ├── project_model.dart
│   │   │   │   └── project_mapper.dart
│   │   │   └── repositories/
│   │   │       └── project_repository_impl.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── project_list_provider.dart
│   │       │   └── active_project_provider.dart
│   │       ├── widgets/
│   │       │   ├── project_card.dart
│   │       │   ├── project_list.dart
│   │       │   └── project_create_dialog.dart
│   │       └── pages/
│   │           ├── project_list_page.dart
│   │           └── project_editor_page.dart
│   │
│   ├── export/                         # Export features
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── export_format.dart
│   │   │   │   └── export_options.dart
│   │   │   └── use_cases/
│   │   │       ├── export_png.dart
│   │   │       ├── export_jpg.dart
│   │   │       ├── export_svg.dart
│   │   │       └── export_json.dart
│   │   ├── data/
│   │   │   ├── services/
│   │   │   │   ├── png_exporter.dart
│   │   │   │   ├── jpg_exporter.dart
│   │   │   │   ├── svg_exporter.dart
│   │   │   │   └── json_exporter.dart
│   │   │   └── repositories/
│   │   │       └── export_repository_impl.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── export_provider.dart
│   │       └── widgets/
│   │           ├── export_dialog.dart
│   │           └── export_options_sheet.dart
│   │
│   ├── import/                         # Import features
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── import_format.dart
│   │   │   │   └── import_result.dart
│   │   │   └── use_cases/
│   │   │       ├── import_json.dart
│   │   │       └── import_svg.dart
│   │   ├── data/
│   │   │   ├── parsers/
│   │   │   │   ├── json_parser.dart
│   │   │   │   ├── svg_parser.dart
│   │   │   │   └── parser_interface.dart
│   │   │   ├── services/
│   │   │   │   └── file_picker_service.dart
│   │   │   └── repositories/
│   │   │       └── import_repository_impl.dart
│   │   └── presentation/
│   │       └── providers/
│   │           └── import_provider.dart
│   │
│   ├── settings/                       # App settings
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── app_settings.dart
│   │   │   └── use_cases/
│   │   │       ├── load_settings.dart
│   │   │       ├── save_settings.dart
│   │   │       ├── toggle_theme.dart
│   │   │       └── set_default_tool.dart
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── settings_datasource.dart
│   │   │   └── repositories/
│   │   │       └── settings_repository_impl.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── settings_provider.dart
│   │       ├── widgets/
│   │       │   ├── settings_panel.dart
│   │       │   └── settings_tile.dart
│   │       └── pages/
│   │           └── settings_page.dart
│   │
│   └── templates/                      # Templates
│       ├── domain/
│       │   ├── entities/
│       │   │   └── template.dart
│       │   └── use_cases/
│       │       ├── load_template.dart
│       │       ├── list_templates.dart
│       │       └── create_from_template.dart
│       ├── data/
│       │   ├── datasources/
│       │   │   └── template_datasource.dart
│       │   └── repositories/
│       │       └── template_repository_impl.dart
│       └── presentation/
│           ├── providers/
│           │   └── template_provider.dart
│           └── widgets/
│               ├── template_picker.dart
│               └── template_preview.dart
│
├── main.dart
└── app.dart
```

### 2.3 Layer Responsibilities

**Domain Layer (Innermost — No Dependencies)**
- Entities: Pure Dart objects with business logic. No framework imports. No serialization annotations.
- Use Cases: Single-responsibility classes that orchestrate domain logic. Each use case has a `call()` method.
- Repository Interfaces: Abstract contracts defined in domain. No implementation details.
- Commands: Encapsulate every user action for undo/redo.

**Data Layer (Implements Domain)**
- Repositories: Implement domain repository interfaces. Coordinate between local datasources and domain models.
- Models: JSON-serializable classes (with `toJson`/`fromJson` or Isar annotations). Separate from domain entities.
- Mappers: Convert between models and domain entities. Never expose models to presentation.
- Datasources: Raw persistence logic. Isar database operations, file system operations.
- Parsers: Import format parsers (JSON, SVG).
- Exporters: Export format generators (PNG, JPG, SVG, JSON).

**Presentation Layer (Consumes Domain)**
- Providers: Riverpod providers that expose state. Each feature has its own set of providers.
- Widgets: Composable, stateless where possible. Never contain business logic.
- Pages: Top-level route widgets that compose widgets and providers.
- State is consumed via `ref.watch()` and mutated via `ref.read()`.

**Core Layer (Shared Infrastructure)**
- Constants: Every named constant. Zero magic numbers.
- Utils: Pure utility functions (math, geometry, color).
- Services: Platform service abstractions (file, clipboard, share).
- Theme: App-wide visual definitions.
- DI: Dependency injection container setup.
- Platform: Platform detection and path resolution.
- Widgets: Shared reusable widgets.
- Errors: Failure types and exception handling.

### 2.4 Dependency Injection

Use **Riverpod's built-in dependency injection** (no GetIt).

```dart
// Core providers
final isarProvider = Provider<Isar>((ref) => throw UnimplementedError());
final fileServiceProvider = Provider<FileService>((ref) => FileServiceImpl());

// Repository providers
final shapeRepositoryProvider = Provider<ShapeRepository>(
  (ref) => ShapeRepositoryImpl(
    localDataSource: ref.watch(shapeLocalDataSourceProvider),
  ),
);

// Use case providers
final createShapeUseCaseProvider = Provider<CreateShape>(
  (ref) => CreateShape(
    repository: ref.watch(shapeRepositoryProvider),
    historyRepository: ref.watch(historyRepositoryProvider),
  ),
);
```

**Rules:**
- Only repositories and use cases are injected.
- No providers for entities (entities are pure data).
- Services are provided at the core level.
- Override providers in tests.

---

## 3. State Management

### 3.1 Why Riverpod over Bloc

| Factor | Riverpod | Bloc |
|--------|----------|------|
| Boilerplate | Minimal | High (events, states, bloc classes) |
| Canvas performance | Better for fine-grained rebuilds | Can cause over-rebuilds |
| Testability | `ProviderContainer` for isolated tests | Requires `blocTest` |
| Compile-time safety | All providers checked at compile time | Runtime event matching |
| Code generation | Optional | Required for modern Bloc |
| Learning curve | Moderate | Steep |

Riverpod is chosen because:
1. Canvas needs fine-grained reactivity (move one shape without rebuilding all shapes).
2. `StateNotifierProvider` + `family` providers give per-object reactivity.
3. No `BuildContext` needed for accessing state.
4. Autodispose for cleanup.
5. Provider overrides for testing without mocking frameworks.

### 3.2 Provider Architecture

```dart
// ── App-level providers ──
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(...);
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});

// ── Canvas providers ──
final canvasTransformProvider = StateNotifierProvider<CanvasTransformNotifier, CanvasTransform>(...);
final viewportProvider = Provider<Viewport>((ref) {
  final transform = ref.watch(canvasTransformProvider);
  return Viewport.fromTransform(transform, screenSize);
});

// ── Shape providers ──
// Each shape is individually reactive
final shapeListProvider = StateNotifierProvider<ShapeListNotifier, List<Shape>>(...);
final shapeByIdProvider = Provider.family<Shape?, String>((ref, id) {
  return ref.watch(shapeListProvider).firstWhereOrNull((s) => s.id == id);
});

// ── Selection providers ──
final selectionProvider = StateNotifierProvider<SelectionNotifier, SelectionState>(...);
final selectedShapesProvider = Provider<List<Shape>>((ref) {
  final selection = ref.watch(selectionProvider);
  final shapes = ref.watch(shapeListProvider);
  return shapes.where((s) => selection.ids.contains(s.id)).toList();
});

// ── History providers ──
final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>(...);
final canUndoProvider = Provider<bool>((ref) => ref.watch(historyProvider).canUndo);
final canRedoProvider = Provider<bool>((ref) => ref.watch(historyProvider).canRedo);

// ── Active tool provider ──
final activeToolProvider = StateProvider<DrawingTool>(...);
final activeStyleProvider = StateNotifierProvider<StyleNotifier, ShapeStyle>(...);
```

### 3.3 Notification Strategy

Minimize widget rebuilds:

```dart
// BAD: rebuilds everything watching shapeListProvider
// GOOD: rebuilds only the specific shape
Consumer(
  builder: (context, ref, child) {
    final shape = ref.watch(shapeByIdProvider(shapeId));
    return ShapeWidget(shape: shape);
  },
)
```

Use `select()` for derived state:

```dart
final zoomLevel = ref.watch(
  canvasTransformProvider.select((t) => t.zoom),
);
```

### 3.4 State Mutation Flow

```
User Gesture
    ↓
Gesture Handler (canvas_gesture_handler.dart)
    ↓
Use Case (e.g., MoveShape)
    ├── Validates input
    ├── Creates Command (MoveShapeCommand)
    ├── Command.execute() → updates ShapeListNotifier
    ├── Command stored in HistoryNotifier
    └── Returns result
    ↓
Provider notifies listeners
    ↓
Widget rebuilds affected region
```

---

## 4. Canvas Engine

### 4.1 Architecture Overview

The canvas engine is the heart of the application. It is composed of several subsystems that work together:

```
┌─────────────────────────────────────────────────────────────┐
│                    InteractiveViewer                         │
│  (handles zoom/pan via TransformationController)             │
├─────────────────────────────────────────────────────────────┤
│                    GestureDetector                            │
│  (handles tap, long-press, drag for drawing/selecting)       │
├─────────────────────────────────────────────────────────────┤
│                    CustomPaint                                │
│  (paints everything via CustomPainter)                       │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              CanvasEngine (CustomPainter)              │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐              │  │
│  │  │ Background│ │ Shapes   │ │ Overlays │              │  │
│  │  │ Paint     │ │ Paint    │ │ (selection│             │  │
│  │  │ Stage     │ │ Stage    │ │  handles)│              │  │
│  │  └──────────┘ └──────────┘ └──────────┘              │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Rendering Pipeline

The pipeline has 4 stages:

```
Stage 1: Background
    - Grid pattern
    - Canvas background color
    - Only repainted on zoom change

Stage 2: Culled Shapes
    - Iterate all shapes
    - Viewport culling: skip shapes outside visible rect
    - Sort by layer order (ascending)
    - Paint each visible shape

Stage 3: Selection Overlays
    - Bounding boxes for selected shapes
    - Resize handles (8 handles)
    - Rotation handle (1 handle)
    - Marquee selection rect

Stage 4: Active Drawing
    - Preview of shape being drawn
    - Snap indicators
    - Measurement guides
```

### 4.3 Repaint Optimization

```dart
class CanvasEngine extends CustomPainter {
  final List<Shape> shapes;
  final CanvasTransform transform;
  final SelectionState selection;
  final ShapeStyle? activeDrawingStyle;
  final Offset? activeDrawingStart;
  final Offset? activeDrawingEnd;

  @override
  void paint(Canvas canvas, Size size) {
    // Stage 1: Background
    _paintBackground(canvas, size, transform);

    // Stage 2: Culled Shapes
    final visibleShapes = _cullToViewport(shapes, transform, size);
    for (final shape in visibleShapes) {
      _paintShape(canvas, shape, transform);
    }

    // Stage 3: Selection Overlays
    if (selection.isNotEmpty) {
      _paintSelectionOverlay(canvas, selection, shapes, transform);
    }

    // Stage 4: Active Drawing
    if (activeDrawingStart != null && activeDrawingEnd != null) {
      _paintActiveShape(canvas, activeDrawingStart!, activeDrawingEnd!, activeDrawingStyle!);
    }
  }

  @override
  bool shouldRepaint(covariant CanvasEngine oldDelegate) {
    // Fine-grained repaint decision
    return oldDelegate.shapes != shapes ||
           oldDelegate.transform != transform ||
           oldDelegate.selection != selection ||
           oldDelegate.activeDrawingStart != activeDrawingStart ||
           oldDelegate.activeDrawingEnd != activeDrawingEnd;
  }
}
```

### 4.4 Dirty Region Tracking

Instead of repainting the entire canvas every frame, track dirty regions:

```dart
class DirtyRegionTracker {
  final Set<Rect> _dirtyRegions = {};
  Rect? _lastViewport;

  void markDirty(Rect region) {
    _dirtyRegions.add(region);
  }

  void markShapeDirty(Shape shape) {
    _dirtyRegions.add(shape.boundingBox);
  }

  List<Rect> flush() {
    final regions = _dirtyRegions.toList();
    _dirtyRegions.clear();
    return regions;
  }

  bool get hasDirtyRegions => _dirtyRegions.isNotEmpty;
}
```

However, Flutter's `CustomPainter` does not natively support partial repaints of a single `Canvas`. The optimization strategy is:

1. **Use `RepaintBoundary`** around the canvas widget.
2. **Use `PictureRecorder`** to cache the static background and shape layers.
3. **Layer composition**: Paint the cached picture, then paint only the dirty overlay (selection, active drawing).

```dart
class PictureRecorderManager {
  Picture? _cachedShapesPicture;
  bool _isDirty = true;

  Picture? get cachedPicture => _isDirty ? null : _cachedShapesPicture;

  void invalidate() => _isDirty = true;

  Picture recordShapes(List<Shape> visibleShapes, CanvasTransform transform) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    for (final shape in visibleShapes) {
      _paintShape(canvas, shape, transform);
    }
    _cachedShapesPicture = recorder.endRecording();
    _isDirty = false;
    return _cachedShapesPicture!;
  }
}
```

**Re-cache triggers:**
- Shape added, removed, or modified
- Zoom level changes `||`
- Layer order changes
- Selection does NOT invalidate cache (selection is overlay only)

### 4.5 Hit Testing

```dart
abstract class HitTester {
  /// Find the topmost shape at [point] in world coordinates
  Shape? hitTest(List<Shape> shapes, Offset point);

  /// Find all shapes inside [rect] in world coordinates
  List<Shape> hitTestRect(List<Shape> shapes, Rect rect);

  /// Check which handle is at [point]
  HandleType? hitTestHandle(SelectionState selection, Offset point);
}
```

Hit testing algorithms by shape type:

| Shape | Algorithm |
|-------|-----------|
| Rectangle | Point in rotated rect (inverse transform point, then AABB check) |
| Ellipse | Point in rotated ellipse (inverse transform, then `((x-h)²/a² + (y-k)²/b²) <= 1`) |
| Diamond | Point in rotated diamond (inverse transform, then 4 half-plane tests) |
| Triangle | Point in rotated triangle (barycentric coordinate check) |
| Line | Point within `distance <= threshold` from line segment |
| Arrow | Line check + arrow head bounds check |
| Freehand | Point within `distance <= threshold` from any segment in the path |
| Text | Point in rotated text bounding box |
| Image | Point in rotated image bounding box |

For rotated shapes, the hit test applies the inverse rotation to the point, then performs the axis-aligned check:

```dart
Offset worldToLocal(Shape shape, Offset worldPoint) {
  final center = shape.boundingBox.center;
  final translated = worldPoint - center;
  final rotated = Offset(
    translated.dx * cos(-shape.rotation) - translated.dy * sin(-shape.rotation),
    translated.dx * sin(-shape.rotation) + translated.dy * cos(-shape.rotation),
  );
  return rotated + center;
}
```

### 4.6 Viewport Culling

```dart
List<Shape> _cullToViewport(List<Shape> shapes, CanvasTransform transform, Size screenSize) {
  final viewportRect = transform.screenToWorld(Rect.fromLTWH(0, 0, screenSize.width, screenSize.height));
  // Add padding to avoid popping shapes at edges
  final paddedRect = viewportRect.inflate(100);
  return shapes.where((s) => paddedRect.overlaps(s.boundingBox)).toList();
}
```

---

## 5. Drawing Objects

### 5.1 Shape Base Class

```dart
abstract class Shape {
  final String id;
  final ShapeType type;
  final Rect boundingBox;          // Local coordinates (axis-aligned before rotation)
  final double rotation;           // Radians
  final ShapeStyle style;
  final LayerInfo layer;
  final bool isLocked;
  final bool isVisible;

  // Computed
  Offset get center => boundingBox.center;
  double get width => boundingBox.width;
  double get height => boundingBox.height;

  // Abstract
  bool hitTest(Offset point);
  Rect get rotatedBoundingBox;  // AABB that contains the rotated shape
  Shape copyWith({...});
}
```

### 5.2 Shape Types

| Shape | Properties | Rough Support |
|-------|-----------|---------------|
| `RectangleShape` | width, height, cornerRadius | Yes |
| `RoundedRectShape` | width, height, topLeft, topRight, bottomLeft, bottomRight radius | Yes |
| `EllipseShape` | width, height | Yes |
| `DiamondShape` | width, height | Yes |
| `TriangleShape` | width, height, direction (up/down/left/right) | Yes |
| `LineShape` | startPoint, endPoint | Yes |
| `ArrowShape` | startPoint, endPoint, arrowheadStyle (triangle, circle, diamond, none) | Yes |
| `FreehandShape` | points (List<Offset>), isClosed | Yes (built-in) |
| `TextShape` | text, fontFamily, fontSize, fontWeight, textAlign, color | No |
| `ImageShape` | imageBytes, originalSize | No |

### 5.3 Style Properties

```dart
class ShapeStyle {
  final Color strokeColor;
  final double strokeWidth;
  final StrokeStyle strokeStyle;    // solid, dashed, dotted
  final Color fillColor;
  final FillStyle fillStyle;        // solid, cross-hatch, diagonal-hatch, zigzag, none
  final Roughness roughness;        // architect, artist, cartoon, none
  final double opacity;             // 0.0 - 1.0
}
```

### 5.4 Shape Factory

```dart
class ShapeFactory {
  Shape createShape(
    ShapeType type,
    Offset startPoint,
    Offset endPoint,
    ShapeStyle style,
  ) {
    final rect = Rect.fromPoints(startPoint, endPoint);
    final id = UuidGenerator.generate();
    switch (type) {
      case ShapeType.rectangle:
        return RectangleShape(id: id, boundingBox: rect, style: style);
      case ShapeType.ellipse:
        return EllipseShape(id: id, boundingBox: rect, style: style);
      // ... etc
    }
  }
}
```

---

## 6. Rough Rendering Engine

### 6.1 Concept

Rough rendering simulates hand-drawn appearance by adding controlled random jitter to geometric primitives. Inspired by the [roughjs](https://roughjs.com/) library.

### 6.2 Algorithm

Each primitive is drawn as a series of slightly offset strokes:

```
For each geometric primitive:
  1. Generate N "rough" versions of the primitive
  2. Each version has:
     - Start/end points jittered randomly (amplitude = roughness level)
     - Control points jittered randomly
     - Slight rotation jitter
  3. Draw all versions with full opacity
  4. This creates the "sketchy" look of multiple overlapping strokes
```

```dart
class RoughPainter {
  final Random _random = Random(42); // Seed for deterministic roughness

  void drawRoughRect(Canvas canvas, Rect rect, ShapeStyle style) {
    final roughness = _getRoughnessValue(style.roughness);
    final iterations = _getIterations(style.roughness); // 1-3

    for (int i = 0; i < iterations; i++) {
      final jittered = _jitterRect(rect, roughness);
      _drawSingleRect(canvas, jittered, style.strokeColor, style.strokeWidth);
    }

    if (style.fillStyle != FillStyle.none) {
      _drawFill(canvas, rect, style);
    }
  }

  Rect _jitterRect(Rect rect, double roughness) {
    return Rect.fromLTRB(
      rect.left + _jitter(roughness),
      rect.top + _jitter(roughness),
      rect.right + _jitter(roughness),
      rect.bottom + _jitter(roughness),
    );
  }

  double _jitter(double roughness) {
    return (_random.nextDouble() - 0.5) * 2 * roughness;
  }
}
```

### 6.3 Fill Styles

| Fill Style | Algorithm |
|------------|-----------|
| `solid` | Standard fill paint |
| `cross-hatch` | Draw parallel lines in two perpendicular directions |
| `diagonal-hatch` | Draw parallel diagonal lines |
| `zigzag` | Draw zigzag pattern |
| `dotted` | Fill with scattered dots |
| `none` | No fill |

### 6.4 Stroke Styles

| Stroke Style | Algorithm |
|--------------|-----------|
| `solid` | Standard continuous line |
| `dashed` | `PathEffect.dash([10, 10])` |
| `dotted` | `PathEffect.dash([2, 6])` |

### 6.5 Roughness Levels

| Level | Jitter Amplitude | Iterations | Use Case |
|-------|-----------------|------------|----------|
| `none` | 0 | 1 | Precise diagrams |
| `architect` | 0.5 | 2 | Clean sketch |
| `artist` | 1.5 | 2 | Hand-drawn look |
| `cartoon` | 3.0 | 3 | Exaggerated sketch |

---

## 7. Infinite Canvas & Camera System

### 7.1 Coordinate Systems

```
World Coordinates (infinite)
    ↑
    |  Camera Transform (zoom + pan)
    ↓
Screen Coordinates (finite, device pixels)
```

### 7.2 Matrix Representation

```dart
class CanvasTransform {
  final double zoom;        // 0.1 to 10.0
  final Offset pan;         // World-space offset

  // Transform a point from screen to world
  Offset screenToWorld(Offset screenPoint) {
    return (screenPoint - pan) / zoom;
  }

  // Transform a point from world to screen
  Offset worldToScreen(Offset worldPoint) {
    return worldPoint * zoom + pan;
  }

  // Transform a rect from screen to world
  Rect screenToWorld(Rect screenRect) {
    return Rect.fromLTRB(
      (screenRect.left - pan.dx) / zoom,
      (screenRect.top - pan.dy) / zoom,
      (screenRect.right - pan.dx) / zoom,
      (screenRect.bottom - pan.dy) / zoom,
    );
  }

  // Get the visible world rect for a given screen size
  Rect getVisibleWorldRect(Size screenSize) {
    return screenToWorld(Rect.fromLTWH(0, 0, screenSize.width, screenSize.height));
  }
}
```

### 7.3 Zoom Implementation

```
zoom(min: 0.1, max: 10.0, default: 1.0, step: 0.1)

Zoom-to-point (mouse wheel):
  1. Get mouse position in screen coords
  2. Convert to world coords: worldPoint = screenToWorld(mousePos)
  3. Apply zoom change: newZoom = clamp(zoom * (1 + delta * 0.001))
  4. Adjust pan to keep worldPoint fixed:
     newPan = mousePos - worldPoint * newZoom
```

```dart
void zoomToPoint(Offset screenPoint, double zoomDelta) {
  final worldPoint = _transform.screenToWorld(screenPoint);
  _transform.zoom = (_transform.zoom * (1 + zoomDelta)).clamp(0.1, 10.0);
  _transform.pan = screenPoint - worldPoint * _transform.zoom;
}
```

### 7.4 Pan Implementation

```dart
void panBy(Offset delta) {
  _transform.pan += delta;
}
```

### 7.5 InteractiveViewer Configuration

```dart
InteractiveViewer(
  transformationController: _controller,
  minScale: 0.1,
  maxScale: 10.0,
  panEnabled: true,
  scaleEnabled: true,
  boundaryMargin: EdgeInsets.all(double.infinity), // Infinite canvas
  child: GestureDetector(
    onTapDown: _handleTapDown,
    onPanStart: _handlePanStart,  // Only for drawing
    onPanUpdate: _handlePanUpdate,
    onPanEnd: _handlePanEnd,
    child: CustomPaint(
      painter: CanvasEngine(...),
      size: Size.infinite,
    ),
  ),
)
```

**Important constraint:** `InteractiveViewer` consumes pan gestures for canvas navigation. Drawing gestures must be distinguished:

| Gesture | Action |
|---------|--------|
| Single finger drag (no tool selected) | Pan canvas |
| Single finger drag (drawing tool active) | Draw shape |
| Two finger pinch | Zoom |
| Two finger drag | Pan canvas |
| Mouse wheel | Zoom to point |
| Middle mouse drag | Pan canvas |
| Right click drag | Pan canvas |

Resolution: Use `InteractiveViewer.builder` + `onInteractionStart` to detect context:

```dart
InteractiveViewer.builder(
  onInteractionStart: (details) {
    if (_activeTool != DrawingTool.select) {
      // Drawing mode: start drawing
      _drawingStartPoint = _transform.screenToWorld(details.localFocalPoint);
    }
    // else: let InteractiveViewer handle pan/zoom
  },
  ...
)
```

---

## 8. Selection System

### 8.1 Selection State

```dart
class SelectionState {
  final Set<String> selectedIds;           // Multiple selection support
  final Rect? marqueeRect;                  // Current marquee (screen coords)
  final HandleType? activeHandle;           // Which handle is being dragged
  final Offset? dragStart;                  // Start of current drag operation
}
```

### 8.2 Selection Modes

```
Tap on shape         → Select single (deselect others)
Shift + Tap on shape → Toggle selection (multi-select)
Tap on empty space   → Deselect all
Drag from empty      → Marquee selection
Drag on selected     → Move selection
```

### 8.3 Bounding Box & Handles

```
┌─────────────────────────────────────┐
│  topLeft          topCenter       topRight    │
│  ●────────────────●────────────────●  │
│  │                                     │  │
│  │            ○ rotation               │  │
│  │                                     │  │
│  midLeft●                         ●midRight│
│  │                                     │  │
│  │                                     │  │
│  ●────────────────●────────────────●  │
│  bottomLeft    bottomCenter      bottomRight│
└─────────────────────────────────────┘
```

8 handles:
- 4 corner handles (resize proportionally if Shift held)
- 4 mid-side handles (resize in one axis)
- 1 rotation handle (above top center)

### 8.4 Hit Testing for Handles

```
For each selected shape:
  Compute handle positions in screen coords
  For each handle:
    If distance from touch to handle <= 12px → handle is active
```

### 8.5 Resize Algorithm

```dart
void resizeShape(Shape shape, HandleType handle, Offset delta, {bool proportional = false}) {
  final newRect = _computeResizedRect(shape.boundingBox, handle, delta, proportional);
  final newShape = shape.copyWith(boundingBox: newRect);
  _updateShape(newShape);
}
```

### 8.6 Rotation Algorithm

```dart
void rotateShape(Shape shape, Offset rotationHandlePos, Offset touchPoint) {
  final center = shape.boundingBox.center;
  final angle = atan2(touchPoint.dy - center.dy, touchPoint.dx - center.dx)
              - atan2(rotationHandlePos.dy - center.dy, rotationHandlePos.dx - center.dx);
  final newShape = shape.copyWith(rotation: shape.rotation + angle);
  _updateShape(newShape);
}
```

---

## 9. Layers

### 9.1 Layer Model

```dart
@collection
class Layer {
  @Id()
  int id;
  String name;
  int order;           // Sort key (lower = behind)
  bool isVisible;
  bool isLocked;
  String? color;       // Layer color tag
}
```

### 9.2 Layer Operations

| Operation | Implementation |
|-----------|---------------|
| Bring to front | Set layer order = max order + 1 |
| Send to back | Set layer order = min order - 1 |
| Move up | Swap order with layer above |
| Move down | Swap order with layer below |
| Toggle visibility | Flip `isVisible` flag → skip rendering hidden shapes |
| Toggle lock | Flip `isLocked` flag → prevent selection on locked shapes |

### 9.3 Rendering Order

Shapes are rendered in ascending layer order, then by creation order within the same layer:

```dart
shapes.sort((a, b) {
  final layerCompare = a.layer.order.compareTo(b.layer.order);
  if (layerCompare != 0) return layerCompare;
  return a.createdAt.compareTo(b.createdAt);
});
```

---

## 10. History System (Undo/Redo)

### 10.1 Command Pattern

```dart
abstract class Command {
  void execute();
  void undo();
  String get description;  // For UI display
}
```

### 10.2 Command Examples

```dart
class AddShapeCommand extends Command {
  final Shape shape;
  final ShapeRepository repository;

  void execute() => repository.addShape(shape);
  void undo() => repository.removeShape(shape.id);
}

class ModifyShapeCommand extends Command {
  final String shapeId;
  final Shape oldState;
  final Shape newState;

  void execute() => repository.updateShape(shapeId, newState);
  void undo() => repository.updateShape(shapeId, oldState);
}

class CompositeCommand extends Command {
  final List<Command> commands;

  void execute() => commands.forEach((c) => c.execute());
  void undo() => commands.reversed.forEach((c) => c.undo());
}
```

### 10.3 History State

```dart
class HistoryState {
  final List<Command> undoStack;
  final List<Command> redoStack;
  final int maxSize;  // Memory limit

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  void execute(Command command) {
    command.execute();
    undoStack.add(command);
    redoStack.clear();
    _trimStack();
  }

  void undo() {
    if (undoStack.isEmpty) return;
    final command = undoStack.removeLast();
    command.undo();
    redoStack.add(command);
  }

  void redo() {
    if (redoStack.isEmpty) return;
    final command = redoStack.removeLast();
    command.execute();
    undoStack.add(command);
  }

  void _trimStack() {
    while (undoStack.length > maxSize) {
      undoStack.removeAt(0);  // Remove oldest
    }
  }
}
```

### 10.4 Memory Optimization

- **Snapshots vs Commands:** Commands store only the delta (old + new state), not the entire canvas state.
- **Command merging:** Rapid consecutive moves of the same shape merge into a single `ModifyShapeCommand` with `{initialPosition, finalPosition}`.
- **Bounding:** Max 10,000 history entries. Oldest entries are evicted.
- **Deep copy strategy:** Use `copyWith()` on domain entities (immutable). Avoid `dart:io` serialization for undo stack.

### 10.5 Transactional Commands

For operations that affect multiple shapes (group move, delete multiple):

```dart
class MoveShapesCommand extends CompositeCommand {
  MoveShapesCommand(Map<Shape, Offset> shapeMoves) : super(
    commands: shapeMoves.entries.map((e) =>
      ModifyShapeCommand(e.key.id, e.key, e.key.copyWith(position: e.key.position + e.value))
    ).toList(),
  );
}
```

### 10.6 Integration with Providers

```dart
class HistoryNotifier extends StateNotifier<HistoryState> {
  void execute(Command command) {
    state.execute(command);
    ref.state = HistoryState(...); // New immutable state
  }
}
```

---

## 11. Local Storage

### 11.1 Why Isar

| Factor | Isar | Hive |
|--------|------|------|
| Type safety | Strong (code gen) | Weak (dynamic) |
| Relations | Yes (links, embedded) | No |
| Queries | Complex (where, sort, limit) | Basic |
| Performance | Very fast (native binary) | Fast |
| Migration | Schema versioning + migration | Manual |
| Flutter integration | First-class | First-class |

Isar is chosen for:
1. Strong typing via code generation.
2. Support for embedded objects (shapes in a project).
3. Query capabilities for filtering/sorting project lists.
4. Schema versioning with migration support.
5. Native binary format for performance.

### 11.2 Schema Design

```dart
@Collection()
class ProjectSchema {
  @Id()
  int id = Isar.autoIncrement;
  late String uuid;
  late String name;
  late DateTime createdAt;
  late DateTime updatedAt;
  late String thumbnailPath;
  final shapes = IsarLinks<ShapeSchema>();
}

@Collection()
class ShapeSchema {
  @Id()
  int id = Isar.autoIncrement;
  late String uuid;
  late String type;         // ShapeType enum as string
  late double x;
  late double y;
  late double width;
  late double height;
  late double rotation;
  late int layerOrder;
  late String styleJson;    // ShapeStyle serialized as JSON string

  // Text-specific
  String? text;
  String? fontFamily;
  double? fontSize;

  // Image-specific
  @Index()
  String? imageHash;
  Uint8List? imageBytes;

  // Freehand-specific
  String? pointsJson;       // List<Offset> as JSON
}
```

### 11.3 Serialization

```dart
// Domain entity → Isar schema
class ShapeMapper {
  static ShapeSchema toSchema(Shape shape) {
    return ShapeSchema()
      ..uuid = shape.id
      ..type = shape.type.name
      ..x = shape.boundingBox.left
      ..y = shape.boundingBox.top
      ..width = shape.boundingBox.width
      ..height = shape.boundingBox.height
      ..rotation = shape.rotation
      ..layerOrder = shape.layer.order
      ..styleJson = jsonEncode(StyleMapper.toMap(shape.style));

    // Type-specific mappings
    if (shape is TextShape) {
      schema.text = shape.text;
      schema.fontFamily = shape.fontFamily;
      schema.fontSize = shape.fontSize;
    }
    if (shape is ImageShape) {
      schema.imageHash = sha256.convert(shape.imageBytes).toString();
      schema.imageBytes = shape.imageBytes;
    }
    if (shape is FreehandShape) {
      schema.pointsJson = jsonEncode(shape.points.map((p) => {'x': p.dx, 'y': p.dy}).toList());
    }
  }

  static Shape toDomain(ShapeSchema schema) {
    final style = StyleMapper.fromMap(jsonDecode(schema.styleJson));
    final rect = Rect.fromLTWH(schema.x, schema.y, schema.width, schema.height);
    final layer = LayerInfo(order: schema.layerOrder);

    switch (schema.type) {
      case 'rectangle':
        return RectangleShape(
          id: schema.uuid, boundingBox: rect, rotation: schema.rotation,
          style: style, layer: layer,
        );
      case 'text':
        return TextShape(
          id: schema.uuid, boundingBox: rect, text: schema.text ?? '',
          fontFamily: schema.fontFamily ?? 'Roboto', fontSize: schema.fontSize ?? 16,
          style: style, layer: layer,
        );
      // ... etc
    }
  }
}
```

### 11.4 Database Versioning & Migrations

```dart
// Schema version 1 → 2 migration
isar.txn((isar) async {
  // Add new field
  await isar.shapeSchemas
    .where()
    .findAll()
    .then((shapes) => shapes.forEach((s) => s.opacity = 1.0));
  await isar.shapeSchemas.putAll(shapes);
});

// Version stored in Isar schema metadata
static const int currentSchemaVersion = 2;
```

### 11.5 Storage Strategy

```
Projects DB (projects.isar)
├── ProjectSchema (collection)
│   ├── name: String
│   ├── createdAt: DateTime
│   ├── updatedAt: DateTime
│   └── thumbnailPath: String
│
├── ShapeSchema (collection)
│   ├── uuid: String
│   ├── type: String
│   ├── geometry: x, y, width, height, rotation
│   ├── style: strokeColor, fillColor, strokeWidth, etc.
│   └── type-specific data: text, points, imageBytes
│
└── Relation: Project → Shapes (IsarLinks)

Settings DB (settings.isar)
└── SettingsSchema
    ├── themeMode: String
    ├── defaultTool: String
    ├── defaultStyle: String (JSON)
    └── lastOpenedProject: String

Templates DB (templates.isar)
└── TemplateSchema
    ├── name: String
    ├── category: String
    ├── thumbnailPath: String
    ├── shapesJson: String (JSON blob)
    └── isBuiltIn: bool
```

---

## 12. Import System

### 12.1 Architecture

```
User selects file
    ↓
FilePickerService → reads bytes
    ↓
ImportUseCase → detects format by extension/content
    ↓
FormatParser (JsonParser | SvgParser)
    ↓
List<Shape> → ShapeRepository → Project
```

### 12.2 Parser Interface

```dart
abstract class FormatParser {
  String get supportedExtension;
  bool canParse(Uint8List bytes);
  Future<List<Shape>> parse(Uint8List bytes, {String? fileName});
}
```

### 12.3 JSON Parser

Supports Excalidraw's JSON format:

```dart
class JsonParser implements FormatParser {
  Future<List<Shape>> parse(Uint8List bytes, {String? fileName}) async {
    final json = jsonDecode(utf8.decode(bytes));
    final elements = json['elements'] as List;
    return elements.map(_parseElement).toList();
  }

  Shape _parseElement(Map<String, dynamic> el) {
    switch (el['type']) {
      case 'rectangle': return _parseRect(el);
      case 'ellipse':   return _parseEllipse(el);
      case 'diamond':   return _parseDiamond(el);
      case 'text':      return _parseText(el);
      case 'freedraw':  return _parseFreehand(el);
      case 'arrow':     return _parseArrow(el);
      case 'line':      return _parseLine(el);
      default: throw UnsupportedFormatException('Unknown element type: ${el['type']}');
    }
  }
}
```

### 12.4 SVG Parser

SVG parsing strategy:

```dart
class SvgParser implements FormatParser {
  Future<List<Shape>> parse(Uint8List bytes, {String? fileName}) async {
    final svgString = utf8.decode(bytes);
    final svgRoot = await svg.fromSvgString(svgString, svgString);
    final shapes = <Shape>[];

    // Traverse SVG DOM
    _traverse(svgRoot, shapes);

    return shapes;
  }

  void _traverse(dynamic node, List<Shape> shapes) {
    if (node is RectElement) {
      shapes.add(RectangleShape(
        boundingBox: Rect.fromLTWH(node.x, node.y, node.width, node.height),
        style: _parseStyle(node),
      ));
    }
    // Handle circle, ellipse, path, line, polyline, polygon, text, image
    // For <path>, approximate curves as line segments, convert to FreehandShape
    // For complex SVGs, simplify to basic geometric shapes
  }
}
```

**SVG Limitations:**
- Complex embedded SVGs (gradients, filters, masks, clipping) are simplified.
- Only basic SVG elements are fully supported: `rect`, `circle`, `ellipse`, `line`, `polyline`, `polygon`, `path`, `text`, `image`.
- Gradients are approximated as solid colors (take dominant color).
- Text elements use system fonts.

### 12.5 Error Handling

```dart
sealed class ImportFailure {
  const ImportFailure();
}

class UnsupportedFormatFailure extends ImportFailure {
  final String extension;
}

class CorruptedFileFailure extends ImportFailure {
  final String message;
}

class UnsupportedFeatureFailure extends ImportFailure {
  final String feature;
}
```

---

## 13. Export System

### 13.1 Architecture

```
Export Dialog → User selects format + options
    ↓
ExportUseCase → ExportService
    ↓
ExportResult (Uint8List bytes + String mimeType)
    ↓
FileService.saveFile() or ShareService.share()
```

### 13.2 Export Options

```dart
class ExportOptions {
  final double scaleFactor;       // 1x, 2x, 3x, 4x
  final bool transparentBackground;
  final Color? backgroundColor;   // Only when !transparentBackground
  final BoxFit fit;               // contain, cover, fill
  final double quality;           // 0.0 - 1.0 (JPEG only)
}
```

### 13.3 PNG/JPG Export

```dart
class PngExporter {
  Future<Uint8List> export(Project project, ExportOptions options) async {
    final shapes = project.shapes;

    // 1. Calculate total bounding box of all shapes
    final totalBounds = _calculateTotalBounds(shapes);

    // 2. Create offscreen canvas at desired resolution
    final scaledSize = Size(
      totalBounds.width * options.scaleFactor,
      totalBounds.height * options.scaleFactor,
    );

    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder, Rect.fromLTWH(0, 0, scaledSize.width, scaledSize.height));

    // 3. Background
    if (!options.transparentBackground) {
      canvas.drawRect(Rect.fromLTWH(0, 0, scaledSize.width, scaledSize.height),
        Paint()..color = options.backgroundColor ?? Colors.white);
    }

    // 4. Scale canvas
    canvas.scale(options.scaleFactor);

    // 5. Translate to content bounds
    canvas.translate(-totalBounds.left, -totalBounds.top);

    // 6. Paint all shapes
    for (final shape in shapes) {
      _paintShape(canvas, shape, CanvasTransform(zoom: 1, pan: Offset.zero));
    }

    // 7. Render to image
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(scaledSize.width.toInt(), scaledSize.height.toInt());

    // 8. Convert to bytes
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
```

### 13.4 SVG Export

```dart
class SvgExporter {
  String export(Project project) {
    final buffer = StringBuffer();
    buffer.writeln('<svg xmlns="http://www.w3.org/2000/svg" ...>');

    for (final shape in project.shapes) {
      switch (shape.runtimeType) {
        case RectangleShape:
          buffer.writeln('<rect x="${r.x}" y="${r.y}" width="${r.width}" height="${r.height}" ... />');
        case EllipseShape:
          buffer.writeln('<ellipse cx="${e.center.dx}" cy="${e.center.dy}" rx="${e.width/2}" ry="${e.height/2}" ... />');
        case TextShape:
          buffer.writeln('<text x="${t.x}" y="${t.y}" font-family="${t.fontFamily}" font-size="${t.fontSize}">${t.text}</text>');
        // ... etc
      }
    }

    buffer.writeln('</svg>');
    return buffer.toString();
  }
}
```

### 13.5 JSON Export (Excalidraw Compatible)

```dart
class JsonExporter {
  String export(Project project) {
    final elements = project.shapes.map(_shapeToElement).toList();
    return jsonEncode({
      'type': 'excalidraw',
      'version': 2,
      'source': 'flutter-excalidraw-clone',
      'elements': elements,
      'appState': {...},
    });
  }
}
```

---

## 14. Templates

### 14.1 Template Structure

```dart
class Template {
  final String id;
  final String name;
  final String category;     // flowchart, uml, mindmap, network, blank
  final String? description;
  final List<Shape> shapes;
  final Uint8List? thumbnail;
  final bool isBuiltIn;
}
```

### 14.2 Template Categories

| Category | Default Shapes | Connectors |
|----------|---------------|------------|
| Flowchart | Process (rect), Decision (diamond), Terminator (rounded rect), Data (parallelogram) | Lines with arrows |
| UML Class | Class box (3-section rect), Interface, Relation | Lines with specific arrowheads |
| Mind Map | Central node, Branch nodes, Sub-nodes | Curved lines |
| Network Diagram | Server, Client, Database, Router, Switch | Lines |
| Blank Canvas | Empty | None |

### 14.3 Template Storage

Built-in templates are bundled as asset JSON files. User-created templates are stored in Isar.

```dart
// Built-in: assets/templates/flowchart.json
// User-created: stored in TemplateSchema collection

class TemplateDataSource {
  Future<List<Template>> loadBuiltInTemplates() async {
    // Load from assets bundle
    final manifest = jsonDecode(await rootBundle.loadString('assets/templates/manifest.json'));
    return Future.wait(manifest.map((entry) async {
      final json = jsonDecode(await rootBundle.loadString('assets/templates/${entry['file']}'));
      return TemplateMapper.fromJson(json);
    }));
  }
}
```

---

## 15. UI/UX Architecture

### 15.1 Layout Structure

```
┌─────────────────────────────────────────────────────────────────┐
│  Status Bar (title, share, export, undo/redo buttons)          │
├─────────────────────────────────────────────────────────────────┤
│  Toolbar (select, rectangle, ellipse, diamond, triangle,        │
│           line, arrow, freehand, text, image)                   │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────┐ ┌──────────────────────────────────┐ ┌──────────┐ │
│  │         │ │                                  │ │          │ │
│  │  Left   │ │        Infinite Canvas           │ │  Right   │ │
│  │  Panel  │ │                                  │ │  Panel   │ │
│  │ (layers)│ │                                  │ │(property)│ │
│  │         │ │                                  │ │  editor) │ │
│  │         │ │                                  │ │          │ │
│  │         │ │                                  │ │          │ │
│  └─────────┘ └──────────────────────────────────┘ └──────────┘ │
├─────────────────────────────────────────────────────────────────┤
│  Status Bar (zoom level, cursor position, object count)        │
└─────────────────────────────────────────────────────────────────┘
```

### 15.2 Responsive Breakpoints

| Breakpoint | Layout | Panels |
|------------|--------|--------|
| < 600px (mobile) | Left panel hidden, right panel as bottom sheet | Bottom sheet properties |
| 600-1024px (tablet) | Left panel collapsible, right panel as side drawer | Collapsible panels |
| > 1024px (desktop) | Full 3-column layout | Always visible |

### 15.3 Widget Tree

```dart
class CanvasEditorPage extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: TopToolbar(),
      body: Column(
        children: [
          DrawingToolbar(),
          Expanded(
            child: ResponsiveLayout(
              mobile: _buildMobileLayout(),
              tablet: _buildTabletLayout(),
              desktop: _buildDesktopLayout(),
            ),
          ),
          BottomStatusBar(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        LayerPanel(collapsible: false),
        Expanded(child: InfiniteCanvas()),
        PropertiesPanel(collapsible: false),
      ],
    );
  }
}
```

### 15.4 Toolbar Components

**Top Toolbar:**
- App logo/name
- Project title (editable)
- Undo button (disabled when canUndo == false)
- Redo button (disabled when canRedo == false)
- Zoom controls (zoom out, zoom percentage, zoom in, zoom to fit)
- Export button
- Import button
- Settings button

**Left Drawing Toolbar (vertical):**
- Select (V)
- Rectangle (R)
- Ellipse (O)
- Diamond (D)
- Triangle (T)
- Line (L)
- Arrow (A)
- Freehand (P)
- Text (TXT)
- Image (IMG)

**Right Properties Panel:**
- Stroke color picker
- Fill color picker
- Stroke width slider
- Stroke style dropdown (solid, dashed, dotted)
- Roughness dropdown (none, architect, artist, cartoon)
- Fill style dropdown (solid, cross-hatch, diagonal-hatch, zigzag, dotted, none)
- Opacity slider
- Font controls (when text selected)
- Image controls (when image selected)
- Layer position buttons (bring forward, send backward)
- Delete button
- Duplicate button

### 15.5 Color Picker

```dart
class ColorPicker extends StatelessWidget {
  // 40 preset colors grid (Excalidraw palette)
  // Custom color input via hex or RGB sliders
  // Recent colors section (last 10)
  // Eyedropper tool (on supported platforms)
}
```

### 15.6 Context Menu

Right-click on shape:

```
Bring to Front
Send to Back
─────────────
Cut          (Ctrl+X)
Copy         (Ctrl+C)
Delete       (Del)
─────────────
Duplicate    (Ctrl+D)
─────────────
Lock         (Ctrl+L)
```

---

## 16. Keyboard Shortcuts

### 16.1 Shortcut Definitions

```dart
// Navigation
'Ctrl+N'          → New project
'Ctrl+O'          → Open project
'Ctrl+S'          → Save project

// Edit
'Ctrl+Z'          → Undo
'Ctrl+Y'          → Redo
'Ctrl+C'          → Copy selected
'Ctrl+V'          → Paste
'Ctrl+X'          → Cut
'Ctrl+A'          → Select all
'Ctrl+D'          → Duplicate selected
'Delete'          → Delete selected
'Ctrl+L'          → Lock/unlock selected

// Tools
'V'               → Select tool
'R'               → Rectangle tool
'O'               → Ellipse tool
'D'               → Diamond tool
'T'               → Triangle tool / Text tool
'L'               → Line tool
'A'               → Arrow tool
'P'               → Freehand tool

// Selection
'Shift+Click'     → Toggle selection
'Ctrl+Click'      → Toggle selection
'Shift+Drag'      → Proportional resize
'Alt+Drag'        → Duplicate on drag
'Arrow Keys'      → Nudge selection 1px
'Shift+Arrows'    → Nudge selection 10px

// Layers
']'               → Bring forward
'['               → Send backward
'Shift+]'         → Bring to front
'Shift+['         → Send to back

// Zoom
'Ctrl++'          → Zoom in
'Ctrl+-'          → Zoom out
'Ctrl+0'          → Reset zoom
'Ctrl+1'          → Zoom to fit
'Ctrl+2'          → Zoom to selection

// View
'Ctrl+Shift+G'    → Toggle grid
'Ctrl+Shift+E'    → Toggle snapping
```

### 16.2 Implementation

```dart
class KeyboardShortcutHandler extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyZ, control: true): () =>
            ref.read(historyProvider.notifier).undo(),
        SingleActivator(LogicalKeyboardKey.keyY, control: true): () =>
            ref.read(historyProvider.notifier).redo(),
        // ... all bindings
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}
```

Use `SingleActivator` for Flutter 3.10+ or `LogicalKeySet` for older versions.

---

## 17. Performance Strategy

### 17.1 Rendering Pipeline Optimization

```
Frame Budget: 16.67ms (60 FPS) / 8.33ms (120 FPS)

1. Gesture Handling       → 0.5ms
2. State Update           → 0.5ms
3. Viewport Culling       → 1.0ms (10k shapes → O(n) scan)
4. Cached Picture Blit    → 0.5ms
5. Overlay Paint          → 1.0ms
6. Composition            → 0.5ms
                         ─────────
              Total       → 4.0ms (well within budget)
```

### 17.2 Object Caching

```dart
class ShapeRenderCache {
  final Map<String, Picture> _pictureCache = {};
  final Map<String, ui.Image> _imageCache = {};

  Picture? getCachedPicture(String shapeId, double zoom) {
    final key = '$shapeId@${zoom.toStringAsFixed(1)}';
    return _pictureCache[key];
  }

  void cachePicture(String shapeId, double zoom, Picture picture) {
    final key = '$shapeId@${zoom.toStringAsFixed(1)}';
    _pictureCache[key] = picture;
  }

  void invalidate(String shapeId) {
    _pictureCache.removeWhere((key, _) => key.startsWith(shapeId));
  }

  void trim(int maxEntries) {
    while (_pictureCache.length > maxEntries) {
      _pictureCache.remove(_pictureCache.keys.first);
    }
  }
}
```

### 17.3 Viewport Culling

- Pre-filter shapes using a **spatial index** for 10k+ objects.
- Grid-based spatial hash: divide world into 200x200px cells. Each shape is registered in all cells it overlaps.
- Only shapes in visible cells are candidates for rendering.

```dart
class SpatialHashGrid {
  final double cellSize = 200.0;
  final Map<String, Set<String>> _grid = {};  // 'cellX,cellY' → Set<shapeId>

  void insert(String shapeId, Rect bounds) {
    for (final cell in _getCells(bounds)) {
      _grid.putIfAbsent(cell, () => {}).add(shapeId);
    }
  }

  void remove(String shapeId, Rect bounds) {
    for (final cell in _getCells(bounds)) {
      _grid[cell]?.remove(shapeId);
    }
  }

  void move(String shapeId, Rect oldBounds, Rect newBounds) {
    remove(shapeId, oldBounds);
    insert(shapeId, newBounds);
  }

  Set<String> query(Rect viewportBounds) {
    final result = <String>{};
    for (final cell in _getCells(viewportBounds)) {
      result.addAll(_grid[cell] ?? {});
    }
    return result;
  }

  List<String> _getCells(Rect bounds) {
    final cells = <String>[];
    final minX = (bounds.left / cellSize).floor();
    final maxX = (bounds.right / cellSize).floor();
    final minY = (bounds.top / cellSize).floor();
    final maxY = (bounds.bottom / cellSize).floor();
    for (int x = minX; x <= maxX; x++) {
      for (int y = minY; y <= maxY; y++) {
        cells.add('$x,$y');
      }
    }
    return cells;
  }
}
```

### 17.4 Memory Optimization

- **Shape image data:** Store compressed `Uint8List` (JPEG for photos, PNG for screenshots). Decode only when rendering. Max pixel dimension: 2048px (limit image import size).
- **Freehand points:** Reduce point count with Ramer-Douglas-Peucker algorithm. Target: ~500 points per freehand shape max.
- **Picture cache:** Max 500 cached pictures. LRU eviction. Invalidate on shape edit.
- **Undo stack:** Store only diff (old/new property values), not full shape clones. Limit 10,000 entries.
- **Project thumbnails:** 256x256px max. Generated on save.

### 17.5 GPU Optimization

- Use `Canvas.clipRect()` to prevent painting outside viewport.
- Use `Paint.isAntiAlias = false` for grid lines (performance).
- Batch draw calls: group same-color strokes together.
- Avoid `Canvas.save()`/`restore()` in loops (cache restore state).
- Use `PictureRecorder` for static content.
- For shapes with opacity < 1.0, use `saveLayer()` → `restore()` only when necessary.
- For dashed/dotted lines, use `PathEffect` (GPU-accelerated) rather than manual dash drawing.

### 17.6 10k+ Object Strategy

| Bottleneck | Solution |
|-----------|----------|
| Hit testing O(n) | Spatial hash grid |
| Render O(n) | Viewport culling + picture cache |
| State diff O(n) | Per-shift provider (only notify changed shape) |
| Memory O(n) | LRU cache, compression, point reduction |
| Undo memory O(n) | Delta-based commands, 10k limit |

---

## 18. Security & Code Quality

### 18.1 Security Checklist

- [ ] No hardcoded API keys, tokens, or secrets
- [ ] No network requests (fully offline)
- [ ] Input sanitization for imported SVG/JSON files (prevent XXE in SVG)
- [ ] Image dimension limits (max 4096x4096px import)
- [ ] File size limits for imports (50MB max)
- [ ] No eval() or dynamic code execution
- [ ] Safe file paths (no directory traversal on export)
- [ ] No debug prints in release builds
- [ ] Flutter analyzer must pass with zero errors and zero warnings
- [ ] No `print()` statements in production code (use `debugPrint` with `kDebugMode` guard)

### 18.2 Code Quality Rules

| Rule | Enforcement |
|------|------------|
| No magic numbers | All numeric literals named in `*_constants.dart` |
| No `!` (null assertion) | Use pattern matching or `?.` with null-aware |
| No `as` casts | Use `is` checks with type promotion |
| No `dynamic` | Every variable typed |
| No `late` without initialization | Initialize in constructor or use `late final` |
| No `toStringAsFixed` for compare | Use `==` with epsilon for doubles |
| No empty catch blocks | Catch specific exceptions |
| No `List.from()` without type | Use `<Type>[]` literals |
| No overlong lines | Limit 80 characters |
| No unused imports | Analyzer flag |
| No unnecessary parentheses | Analyzer flag |
| No `var` for primitive types | Use `int`, `double`, `String` instead of `var` |
| All public APIs documented | Dart doc comments |

### 18.3 Lint Rules

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_declare_return_types
    - annotate_overrides
    - avoid_catches_without_on_clauses
    - avoid_dynamic_calls
    - avoid_empty_else
    - avoid_equals_and_hash_code_on_mutable_classes
    - avoid_init_to_null
    - avoid_null_checks_in_equality_operators
    - avoid_print
    - avoid_redundant_argument_values
    - avoid_relative_lib_imports
    - avoid_returning_null
    - avoid_shadowing_type_parameters
    - avoid_single_cascade_in_expression_statements
    - avoid_types_as_parameter_names
    - avoid_unnecessary_containers
    - avoid_unused_constructor_parameters
    - avoid_void_async
    - await_only_futures
    - camel_case_extensions
    - camel_case_types
    - cancel_subscriptions
    - constant_identifier_names
    - curly_braces_in_flow_control_structures
    - directives_ordering
    - empty_catches
    - empty_constructor_bodies
    - empty_statements
    - exhaustive_cases
    - file_names
    - hash_and_equals
    - implementation_imports
    - join_return_with_assignment
    - library_names
    - library_prefixes
    - no_duplicate_case_values
    - no_leading_underscores_for_library_prefixes
    - no_leading_underscores_for_local_identifiers
    - null_closures
    - overridden_fields
    - prefer_adjacent_string_concatenation
    - prefer_collection_literals
    - prefer_conditional_assignment
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_const_literals_to_create_immutables
    - prefer_contains
    - prefer_final_fields
    - prefer_final_locals
    - prefer_for_elements_to_map_fromIterable
    - prefer_generic_function_type_aliases
    - prefer_if_null_operators
    - prefer_initializing_formals
    - prefer_inlined_adds
    - prefer_interpolation_to_compose_strings
    - prefer_is_empty
    - prefer_is_not_empty
    - prefer_is_not_operator
    - prefer_iterable_whereType
    - prefer_null_aware_operators
    - prefer_single_quotes
    - prefer_spread_collections
    - prefer_typing_uninitialized_variables
    - provide_deprecation_message
    - recursive_getters
    - require_trailing_commas
    - sized_box_for_whitespace
    - slash_for_doc_comments
    - sort_child_properties_last
    - type_init_formals
    - unawaited_futures
    - unnecessary_brace_in_string_interps
    - unnecessary_const
    - unnecessary_getters_setters
    - unnecessary_late
    - unnecessary_new
    - unnecessary_null_aware_assignments
    - unnecessary_null_in_if_null_operators
    - unnecessary_nullable_for_final_variable_declarations
    - unnecessary_overrides
    - unnecessary_string_escapes
    - unnecessary_string_interpolations
    - unnecessary_this
    - unrelated_type_equality_checks
    - use_build_context_synchronously
    - use_full_hex_values_for_flutter_colors
    - use_function_type_syntax_for_parameters
    - use_key_in_widget_constructors
    - use_rethrow_when_possible
    - use_setters_to_change_properties
    - use_string_buffers
    - use_super_parameters
    - void_checks
```

---

## 19. Testing Strategy

### 19.1 Test Pyramid

```
        ╱╲
       ╱  ╲         Integration Tests (5%)
      ╱    ╲
     ╱────────╲
    ╱          ╲     Widget Tests (15%)
   ╱            ╲
  ╱────────────────╲
 ╱                  ╲  Unit Tests (80%)
╱────────────────────╲
```

### 19.2 Unit Tests

**Entities:**
```dart
void main() {
  group('RectangleShape', () {
    test('hitTest returns true for point inside rect', () {
      final rect = RectangleShape(
        id: '1',
        boundingBox: Rect.fromLTWH(0, 0, 100, 100),
        style: ShapeStyle.defaultStyle(),
      );
      expect(rect.hitTest(Offset(50, 50)), isTrue);
    });

    test('hitTest returns false for point outside rect', () {
      final rect = RectangleShape(...);
      expect(rect.hitTest(Offset(200, 200)), isFalse);
    });
  });
}
```

**Use Cases:**
```dart
void main() {
  group('CreateShape', () {
    test('executes command and adds to repository', () {
      final repo = MockShapeRepository();
      final historyRepo = MockHistoryRepository();
      final useCase = CreateShape(repo, historyRepo);

      useCase(ShapeType.rectangle, Offset.zero, Offset(100, 100));

      verify(repo.addShape(any)).called(1);
      verify(historyRepo.execute(any<Command>())).called(1);
    });
  });
}
```

**Commands:**
```dart
void main() {
  group('AddShapeCommand', () {
    test('execute adds shape, undo removes shape', () {
      final repo = MockShapeRepository();
      final shape = RectangleShape(...);
      final cmd = AddShapeCommand(shape, repo);

      cmd.execute();
      verify(repo.addShape(shape)).called(1);

      cmd.undo();
      verify(repo.removeShape(shape.id)).called(1);
    });
  });
}
```

### 19.3 Widget Tests

```dart
void main() {
  testWidgets('DrawingToolbar renders all tool buttons', (tester) async {
    await tester.pumpWidget(ProviderScope(child: MaterialApp(home: DrawingToolbar())));
    expect(find.byIcon(Icons.rectangle_outlined), findsOneWidget);
    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
    // ...
  });

  testWidgets('tap on select tool updates active tool provider', (tester) async {
    await tester.pumpWidget(ProviderScope(child: MaterialApp(home: DrawingToolbar())));
    await tester.tap(find.byIcon(Icons.pan_tool));
    await tester.pump();
    // Verify provider state changed
  });

  testWidgets('ColorPicker shows 40 preset colors', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ColorPicker(...)));
    expect(find.byType(ColorSwatch), findsNWidgets(40));
  });
}
```

### 19.4 Integration Tests

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Complete Drawing Workflow', () {
    testWidgets('draw rectangle, select, move, undo', (tester) async {
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: CanvasEditorPage())));

      // Select rectangle tool
      await tester.tap(find.byTooltip('Rectangle'));
      await tester.pump();

      // Draw rectangle
      await tester.timedDrag(
        find.byType(InfiniteCanvas),
        const Offset(200, 200),
        Duration(milliseconds: 100),
      );
      await tester.pump();

      // Verify shape exists
      expect(find.byType(RectangleShape), findsOneWidget);

      // Select shape
      await tester.tap(find.byType(RectangleShape));
      await tester.pump();

      // Move shape
      await tester.timedDrag(
        find.byType(SelectionOverlay),
        const Offset(50, 50),
        Duration(milliseconds: 100),
      );
      await tester.pump();

      // Undo
      await tester.tap(find.byTooltip('Undo'));
      await tester.pump();

      // Verify shape moved back
    });
  });

  group('Import/Export Workflow', () {
    testWidgets('export to JSON and re-import', (tester) async {
      // Create shapes
      // Export to JSON
      // Verify JSON output
      // Import JSON
      // Verify shapes match
    });
  });

  group('Undo/Redo Workflow', () {
    testWidgets('10 undo/redo cycles maintain state', (tester) async {
      // Create 10 shapes
      // Undo all 10
      // Redo all 10
      // Verify all 10 shapes present
    });
  });
}
```

### 19.5 Coverage Requirements

| Module | Target |
|--------|--------|
| Domain entities | 100% |
| Use cases | 100% |
| Commands | 100% |
| Repositories | 90% |
| Providers | 80% |
| Widgets (critical path) | 80% |
| Canvas engine | 90% |
| Import/Export | 100% |
| **Overall** | **80%+** |

---

## 20. Cross-Platform Considerations

### 20.1 Platform-Specific Code

```dart
// Platform detection
class PlatformInfo {
  static bool get isMobile => defaultTargetPlatform == TargetPlatform.android
      || defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isDesktop => defaultTargetPlatform == TargetPlatform.linux
      || defaultTargetPlatform == TargetPlatform.windows
      || defaultTargetPlatform == TargetPlatform.macOS;
  static bool get isWeb => kIsWeb;
}
```

### 20.2 Platform Adaptations

| Feature | Android | iOS | Linux | Windows | macOS |
|---------|---------|-----|-------|---------|-------|
| File picker | `file_picker` | `file_picker` | `file_picker` | `file_picker` | `file_picker` |
| File save | `path_provider` | `path_provider` | `path_provider` | `path_provider` | `path_provider` |
| Share sheet | `share_plus` | `share_plus` | N/A | N/A | N/A |
| Context menu | Long press | Long press | Right click | Right click | Right click |
| Copy/paste | Clipboard | Clipboard | Clipboard | Clipboard | Clipboard |
| Multi-touch | Yes | Yes | Limited | Limited | Yes |
| Keyboard | Software | Software | Hardware | Hardware | Hardware |
| Title bar | No | No | Yes | Yes | Yes |
| Window menu | No | No | Yes | Yes | Yes |

### 20.3 File Path Strategy

```dart
class AppFilePaths {
  static Future<String> get documentsDir async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  static Future<String> get projectsDir async {
    final dir = Directory('${await documentsDir}/projects');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> get exportsDir async {
    final dir = Directory('${await documentsDir}/exports');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }
}
```

---

## 21. Development Roadmap

### 21.1 Phase Breakdown

```
Phase 0: Project Setup & Architecture (1-2 days)
Phase 1: Core Domain & State (3-4 days)
Phase 2: Canvas Engine (4-5 days)
Phase 3: Shapes & Drawing (4-5 days)
Phase 4: Selection & Manipulation (2-3 days)
Phase 5: Rough Rendering (2-3 days)
Phase 6: Layers (1 day)
Phase 7: History System (2-3 days)
Phase 8: Local Storage (3-4 days)
Phase 9: Import/Export (3-4 days)
Phase 10: Templates (1-2 days)
Phase 11: UI/UX Polish (3-4 days)
Phase 12: Keyboard Shortcuts (1 day)
Phase 13: Performance Optimization (2-3 days)
Phase 14: Testing & Bug Fixing (3-4 days)
Phase 15: Cross-Platform Testing (2-3 days)
Phase 16: Production Preparation (1-2 days)
```

### 21.2 Commit Order (53 Commits)

```
─── Phase 0: Project Setup ──────────────────────────────────────

1.  feat(project): initialize flutter project with directory structure
2.  feat(core): add analysis_options.yaml with lint rules
3.  feat(core): create app constants and error types
4.  feat(core): setup dependency injection container
5.  feat(core): implement theme system (light/dark)
6.  feat(core): add utility classes (math, geometry, color, uuid)

─── Phase 1: Core Domain & State ────────────────────────────────

7.  feat(domain): add shape entity hierarchy
8.  feat(domain): add canvas transform entity
9.  feat(domain): add layer entity and value objects
10. feat(domain): add project entity
11. feat(domain): add settings entity
12. feat(state): setup riverpod providers for app state
13. feat(state): add canvas transform provider
14. feat(state): add active tool provider
15. feat(state): add shape style provider

─── Phase 2: Canvas Engine ──────────────────────────────────────

16. feat(canvas): implement infinite canvas with interactive viewer
17. feat(canvas): implement zoom and pan with coordinate transforms
18. feat(canvas): implement render pipeline with background
19. feat(canvas): add viewport culling for visible shapes
20. feat(canvas): implement picture recorder caching
21. feat(canvas): add dirty region tracking

─── Phase 3: Shapes & Drawing ───────────────────────────────────

22. feat(shapes): implement shape factory and creation flow
23. feat(shapes): add rectangle drawing tool
24. feat(shapes): add ellipse and diamond drawing tools
25. feat(shapes): add triangle drawing tool
26. feat(shapes): add line and arrow drawing tools
27. feat(shapes): add freehand pencil tool with point reduction
28. feat(shapes): add text shape with editing support
29. feat(shapes): add image shape with file picker support
30. feat(shapes): implement shape painter for all types

─── Phase 4: Selection & Manipulation ───────────────────────────

31. feat(selection): implement single tap selection
32. feat(selection): implement multi-select with shift
33. feat(selection): implement marquee selection
34. feat(selection): implement move shapes
35. feat(selection): implement resize with 8 handles
36. feat(selection): implement rotation
37. feat(selection): add hit tester for shapes and handles
38. feat(selection): add snap to grid engine

─── Phase 5: Rough Rendering ────────────────────────────────────

39. feat(rough): implement rough painter engine
40. feat(rough): add jitter algorithms for all shape types
41. feat(rough): implement fill styles (cross-hatch, diagonal, zigzag)
42. feat(rough): integrate roughness into shape painter

─── Phase 6: Layers ─────────────────────────────────────────────

43. feat(layers): implement layer entity and provider
44. feat(layers): add layer panel UI
45. feat(layers): implement layer operations (reorder, hide, lock)

─── Phase 7: History System ─────────────────────────────────────

46. feat(history): implement command pattern base
47. feat(history): add commands for all shape operations
48. feat(history): implement undo/redo with bound stack
49. feat(history): add command merging for rapid moves
50. feat(history): wire undo/redo to UI buttons

─── Phase 8: Local Storage ──────────────────────────────────────

51. feat(storage): setup isar database with schema
52. feat(storage): implement project datasource
53. feat(storage): implement shape serialization
54. feat(storage): implement project CRUD use cases
55. feat(storage): add project list screen
56. feat(storage): add save/load to editor
57. feat(storage): add settings persistence
58. feat(storage): implement database migrations

─── Phase 9: Import/Export ──────────────────────────────────────

59. feat(import): implement json parser (excalidraw compatible)
60. feat(import): implement svg parser for basic shapes
61. feat(export): implement png export with high-res
62. feat(export): implement jpg export
63. feat(export): implement svg export
64. feat(export): implement json export
65. feat(import): wire import dialog and file picker
66. feat(export): wire export dialog with options

─── Phase 10: Templates ─────────────────────────────────────────

67. feat(templates): add template entity and datasource
68. feat(templates): create built-in templates (flowchart, uml, mindmap, network)
69. feat(templates): add template picker dialog

─── Phase 11: UI/UX ─────────────────────────────────────────────

70. feat(ui): build responsive app shell
71. feat(ui): implement top toolbar
72. feat(ui): implement left drawing toolbar
73. feat(ui): implement right properties panel
74. feat(ui): implement color picker
75. feat(ui): implement context menus
76. feat(ui): add bottom status bar
77. feat(ui): implement responsive breakpoints (mobile, tablet, desktop)

─── Phase 12: Keyboard Shortcuts ────────────────────────────────

78. feat(shortcuts): implement keyboard shortcut handler
79. feat(shortcuts): add all tool shortcuts
80. feat(shortcuts): add edit shortcuts (copy, paste, undo, redo)
81. feat(shortcuts): add layer shortcuts

─── Phase 13: Performance ───────────────────────────────────────

82. perf(canvas): implement spatial hash grid for 10k+ objects
83. perf(canvas): add shape picture cache with LRU eviction
84. perf(canvas): optimize freehand point reduction
85. perf(history): optimize command memory usage
86. perf(storage): add project thumbnail caching

─── Phase 14: Testing ───────────────────────────────────────────

87. test(domain): add entity unit tests
88. test(domain): add use case unit tests
89. test(canvas): add canvas engine unit tests
90. test(state): add provider tests
91. test(shapes): add shape widget tests
92. test(ui): add toolbar widget tests
93. test(integration): add drawing workflow test
94. test(integration): add import/export workflow test
95. test(integration): add undo/redo workflow test

─── Phase 15: Cross-Platform ────────────────────────────────────

96. fix(android): test and fix android platform issues
97. fix(ios): test and fix ios platform issues
98. fix(linux): test and fix linux desktop issues
99. fix(windows): test and fix windows platform issues
100. fix(macos): test and fix macos platform issues
101. fix(web): optional web compatibility adjustments

─── Phase 16: Production ────────────────────────────────────────

102. chore: run full static analysis and fix all issues
103. chore: run full test suite and fix all failures
104. chore: verify 80% coverage minimum
105. chore: remove all debug code and prints
106. chore: final performance profiling
107. docs: update readme with setup and usage instructions
108. docs: add architecture documentation
109. release: v1.0.0
```

### 21.3 Dependency Installation Order

```bash
# Core dependencies
flutter pub add riverpod
flutter pub add flutter_riverpod
flutter pub add riverpod_annotation

# Canvas
flutter pub add flutter_svg               # SVG parsing
flutter pub add path_provider             # File paths
flutter pub add file_picker               # File selection
flutter pub add share_plus                # Share sheet

# Storage
flutter pub add isar
flutter pub add isar_flutter_libs
flutter pub dev add isar_generator
flutter pub dev add build_runner

# Utilities
flutter pub add uuid                      # ID generation
flutter pub add collection                # Additional collection types
flutter pub add equatable                 # Value equality
flutter pub add freezed_annotation        # Immutable classes
flutter pub dev add freezed               # Code generation
flutter pub add json_annotation            # JSON serialization
flutter pub dev add json_serializable      # JSON code gen

# Web (optional)
flutter pub add universal_html             # HTML canvas for web

# Testing
flutter pub dev add mocktail               # Mocking
flutter pub dev add integration_test       # Integration tests
flutter pub dev add flutter_test

# Linting
flutter pub dev add flutter_lints
```

### 21.4 Critical Milestones

| # | Milestone | Verification |
|---|-----------|-------------|
| M1 | Clean structure with DI | `flutter analyze` passes |
| M2 | Canvas renders, pans, zooms | Manual test on device |
| M3 | 2 shape types drawable | Automated widget test |
| M4 | Selection + move + resize | Manual + unit test |
| M5 | Rough rendering active | Visual comparison |
| M6 | Undo/redo for all ops | Integration test (10 cycles) |
| M7 | Project saves and loads | Integration test |
| M8 | JSON/SVG import works | File-based integration test |
| M9 | All export formats generate | File output verification |
| M10 | 10k objects at 60 FPS | Profiler trace |
| M11 | 80% coverage | `flutter test --coverage` |
| M12 | All platforms compile | CI matrix |

---

## 22. Git Workflow

### 22.1 Branch Strategy

```
main ← release-quality, always deployable
├── develop ← integration branch
│   ├── feat/canvas-engine
│   ├── feat/shapes-rectangle
│   ├── feat/selection-system
│   └── ...
└── hotfix/1.0.1 ← emergency fixes
```

### 22.2 Commit Convention

```
<type>(<scope>): <description>

Types:
  feat     → New feature
  fix      → Bug fix
  refactor → Code restructuring (no behavior change)
  perf     → Performance improvement
  test     → Adding or fixing tests
  docs     → Documentation only
  chore    → Build, CI, tooling
  style    → Formatting, linting (no logic change)
  release  → Release commit

Scope:
  project  → Project setup
  core     → Core infrastructure
  domain   → Domain entities
  state    → State management
  canvas   → Canvas engine
  shapes   → Drawing shapes
  rough    → Rough rendering
  selection→ Selection system
  layers   → Layer management
  history  → Undo/redo
  storage  → Local persistence
  import   → Import system
  export   → Export system
  templates→ Template system
  ui       → UI components
  shortcuts→ Keyboard shortcuts
  perf     → Performance
  test     → Testing
  docs     → Documentation
  release  → Release

Description: imperative, lowercase, no period, max 72 chars
```

### 22.3 Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

# 1. Run formatter
dart format --set-exit-if-changed lib/ test/

# 2. Run static analysis
flutter analyze --no-fatal-infos --no-fatal-warnings

# 3. Run tests
flutter test --no-pub

# 4. Check for debug prints
if grep -rn "print(" lib/ --include="*.dart" | grep -v "kDebugMode"; then
  echo "ERROR: Found print() statements. Use debugPrint with kDebugMode guard."
  exit 1
fi

# 5. Check for hardcoded values (example: check for TODO without ticket)
# if grep -rn "TODO" lib/ --include="*.dart"; then
#   echo "WARNING: Found TODO comments"
# fi

exit 0
```

### 22.4 Commit Message Examples

```bash
# Good commits (atomic, focused)
git commit -m "feat(canvas): implement infinite canvas with interactive viewer"
git commit -m "feat(shapes): add rectangle drawing tool"
git commit -m "feat(selection): implement single tap selection"
git commit -m "feat(history): implement undo redo with command pattern"
git commit -m "feat(storage): add isar local persistence for projects"
git commit -m "test(canvas): add viewport culling unit tests"
git commit -m "perf(canvas): implement spatial hash grid for 10k objects"
git commit -m "refactor(canvas): extract rough painter to separate class"
git commit -m "fix(shapes): correct ellipse hit test for rotated shapes"
git commit -m "chore: update dependencies to latest versions"

# Bad commits (too large, mixed concerns)
# git commit -m "add canvas and shapes and selection"         ← WRONG
# git commit -m "fix bugs"                                     ← WRONG
# git commit -m "wip"                                          ← WRONG
# git commit -m "lots of changes"                              ← WRONG
```

### 22.5 Commit Frequency Rules

1. **Every green test** → commit
2. **Every working feature** → commit
3. **Every refactor** → commit
4. **Every file rename/move** → commit (before editing content)
5. **Never commit broken code** → stash or fix first
6. **Never commit debug code** → remove before staging
7. **Never commit generated files** → add to `.gitignore`
8. **Rebase before push** → keep history linear

---

## 23. Production Checklist

### 23.1 Pre-Release Checklist

- [ ] `flutter analyze` passes with zero errors, zero warnings
- [ ] `dart format` applied to all files
- [ ] Full test suite passes: `flutter test`
- [ ] Coverage >= 80%: `flutter test --coverage && genhtml coverage/lcov.info`
- [ ] No `print()` statements in `lib/`
- [ ] No `debugPrint()` without `kDebugMode` guard
- [ ] No `TODO` without linked issue
- [ ] No commented-out code
- [ ] No `async*` or `sync*` without error handling
- [ ] All `Future`s are `await`ed or `unawaited` explicitly
- [ ] All `Stream` subscriptions are cancelled
- [ ] All controllers are disposed
- [ ] All `BuildContext` uses checked with `mounted`
- [ ] All `MediaQuery` accesses cached (not in build methods)
- [ ] No `OverflowBox`, `FittedBox`, or unbounded constraints in layouts
- [ ] App icon and splash screen configured per platform
- [ ] App name configured per platform
- [ ] Bundle identifiers configured
- [ ] Android: minimum SDK 21
- [ ] iOS: minimum deployment target 14
- [ ] Linux: snap/flatpak/AppImage packaging tested
- [ ] Windows: MSIX packaging tested
- [ ] macOS: notarization tested
- [ ] Web: PWA manifest configured (optional)
- [ ] `flutter build apk --release` succeeds
- [ ] `flutter build ios --release` succeeds (on macOS)
- [ ] `flutter build linux --release` succeeds
- [ ] `flutter build windows --release` succeeds
- [ ] `flutter build macos --release` succeeds (on macOS)
- [ ] Release build size < 50MB (APK), < 200MB (desktop/AppImage)
- [ ] App start time < 2 seconds on target devices
- [ ] 10,000 shapes at 60 FPS on target devices
- [ ] Memory usage < 500MB with 10,000 shapes
- [ ] Undo/redo 10,000 operations without crash

### 23.2 Performance Benchmarks

```dart
// Performance test
void main() {
  test('Canvas maintains 60 FPS with 10k shapes', () async {
    final engine = CanvasEngine();

    // Add 10,000 shapes
    for (int i = 0; i < 10000; i++) {
      engine.addShape(RectangleShape(
        boundingBox: Rect.fromLTWH(i % 100 * 50.0, i ~/ 100 * 50.0, 40, 40),
      ));
    }

    // Measure rendering time
    final stopwatch = Stopwatch()..start();
    engine.paint(canvas, viewportSize);
    stopwatch.stop();

    // Must complete within 16ms (60 FPS)
    expect(stopwatch.elapsedMilliseconds, lessThan(16));
  });
}
```

### 23.3 Bundle Size Targets

| Platform | Target Size | Max Acceptable |
|----------|-------------|----------------|
| Android APK | 25 MB | 50 MB |
| iOS IPA | 40 MB | 80 MB |
| Linux AppImage | 60 MB | 120 MB |
| Windows MSIX | 80 MB | 150 MB |
| macOS DMG | 60 MB | 120 MB |

### 23.4 Crash Reporting (Optional Offline)

Since the app is offline-first, consider adding **optional** Sentry or Crashlytics (requires user consent). If omitted, ensure:
- All async errors caught by `runZonedGuarded`
- All Flutter errors caught by `FlutterError.onError`
- Errors logged to local file for user to share
- Graceful degradation on all error paths

---

## Appendix: Mathematical Reference

### A.1 Coordinate Transformations

```dart
// Screen ↔ World
Offset screenToWorld(Offset screen, Offset pan, double zoom) {
  return (screen - pan) / zoom;
}

Offset worldToScreen(Offset world, Offset pan, double zoom) {
  return world * zoom + pan;
}

// Rotated shape hit testing
bool pointInRotatedRect(Offset point, Rect rect, double rotation) {
  final center = rect.center;
  final unrotated = rotatePoint(point, center, -rotation);
  return rect.contains(unrotated);
}

Offset rotatePoint(Offset point, Offset center, double angle) {
  final translated = point - center;
  final cosA = cos(angle);
  final sinA = sin(angle);
  return Offset(
    translated.dx * cosA - translated.dy * sinA + center.dx,
    translated.dx * sinA + translated.dy * cosA + center.dy,
  );
}
```

### A.2 Rough Jitter

```dart
double roughJitter(Random random, double amplitude) {
  return (random.nextDouble() - 0.5) * 2 * amplitude;
}

double roughGaussianJitter(Random random, double sigma) {
  // Box-Muller transform
  final u1 = random.nextDouble();
  final u2 = random.nextDouble();
  return sqrt(-2 * log(u1)) * cos(2 * pi * u2) * sigma;
}
```

### A.3 Freehand Point Reduction (Ramer-Douglas-Peucker)

```dart
List<Offset> simplifyPoints(List<Offset> points, double epsilon) {
  if (points.length <= 2) return points;

  var maxDistance = 0.0;
  var maxIndex = 0;

  for (var i = 1; i < points.length - 1; i++) {
    final distance = perpendicularDistance(points[i], points.first, points.last);
    if (distance > maxDistance) {
      maxDistance = distance;
      maxIndex = i;
    }
  }

  if (maxDistance > epsilon) {
    final left = simplifyPoints(points.sublist(0, maxIndex + 1), epsilon);
    final right = simplifyPoints(points.sublist(maxIndex), epsilon);
    return [...left.sublist(0, left.length - 1), ...right];
  }

  return [points.first, points.last];
}

double perpendicularDistance(Offset point, Offset lineStart, Offset lineEnd) {
  final dx = lineEnd.dx - lineStart.dx;
  final dy = lineEnd.dy - lineStart.dy;
  final mag = sqrt(dx * dx + dy * dy);
  if (mag == 0) return (point - lineStart).distance;
  final u = ((point.dx - lineStart.dx) * dx + (point.dy - lineStart.dy) * dy) / (mag * mag);
  final closest = Offset(lineStart.dx + u * dx, lineStart.dy + u * dy);
  return (point - closest).distance;
}
```

### A.4 Bounding Box of Rotated Shape

```dart
Rect computeRotatedBoundingBox(Rect localBounds, double rotation) {
  final center = localBounds.center;
  final corners = [
    localBounds.topLeft,
    localBounds.topRight,
    localBounds.bottomRight,
    localBounds.bottomLeft,
  ];

  final rotated = corners.map((c) => rotatePoint(c, center, rotation));
  final minX = rotated.map((p) => p.dx).reduce(min);
  final minY = rotated.map((p) => p.dy).reduce(min);
  final maxX = rotated.map((p) => p.dx).reduce(max);
  final maxY = rotated.map((p) => p.dy).reduce(max);

  return Rect.fromLTRB(minX, minY, maxX, maxY);
}
```

### A.5 Ellipse Hit Test

```dart
bool pointInEllipse(Offset point, Rect bounds, double rotation) {
  final local = rotatePoint(point, bounds.center, -rotation);
  final h = bounds.center.dx;
  final k = bounds.center.dy;
  final rx = bounds.width / 2;
  final ry = bounds.height / 2;
  return pow((local.dx - h) / rx, 2) + pow((local.dy - k) / ry, 2) <= 1.0;
}
```

### A.6 Diamond Hit Test

```dart
bool pointInDiamond(Offset point, Rect bounds, double rotation) {
  final local = rotatePoint(point, bounds.center, -rotation);
  final cx = bounds.center.dx;
  final cy = bounds.center.dy;
  final hw = bounds.width / 2;
  final hh = bounds.height / 2;
  final dx = (local.dx - cx).abs();
  final dy = (local.dy - cy).abs();
  return dx / hw + dy / hh <= 1.0;
}
```

### A.7 Triangle Hit Test (Barycentric)

```dart
bool pointInTriangle(Offset point, Offset v1, Offset v2, Offset v3) {
  final d1 = sign(point, v1, v2);
  final d2 = sign(point, v2, v3);
  final d3 = sign(point, v3, v1);
  final hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0);
  final hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0);
  return !(hasNeg && hasPos);
}

double sign(Offset p1, Offset p2, Offset p3) {
  return (p1.dx - p3.dx) * (p2.dy - p3.dy) - (p2.dx - p3.dx) * (p1.dy - p3.dy);
}
```

---

> **End of Architecture Specification**
>
> Version 1.0.0
>
> This document contains the complete architecture specification for the ExcaliDraw Offline Clone. It is intended to be used as the single source of truth for all development decisions. Every developer should read this document before writing any code.
