## 1.1.0 - 2025-06-10

- Improved documentation (README tweaks and expanded quick start).
- Clarified `autoDispose`, `isAutoDispose`, and custom interval usage in docs.
- Minor internal refactor of `IsolateHelper` for better type safety.
- Updated example with more helpers for each operation.
- Fixed: exception details are now properly returned to callers when thrown in isolate.
- Improved changelog formatting and release notes.

## 1.0.0 - 2025-06-08

- Initial release.
- Provides `IsolateHelper` for easier Dart/Flutter isolate communication.
- Supports registering and handling multiple isolate operations.
- Example operations included: counting, summing, async delay, error simulation.
- Integrates with `dart_ui_isolate` and supports plugin extensions.
- Designed for extensibility and type safety in isolate task execution.