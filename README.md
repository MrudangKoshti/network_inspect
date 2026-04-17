# network_inspect

`network_inspect` is a debug-only Flutter network inspector package with:
- draggable floating overlay switch
- live API log console (bottom sheet)
- tap-to-open detailed request/response viewer
- one-tap copy for every detail section

The UI only appears in `kDebugMode`.

## Features

- Live network log timeline
- Status-aware request cards (`2xx`, `4xx`, `5xx`)
- Detailed view for:
  - request headers
  - request body
  - response headers
  - response body
  - raw request/response blocks
- Copy button for each section
- Draggable floating toggle
- Resizable main console and detail sheet (top drag handle)

## Installation

### From pub.dev

Add dependency:

```yaml
dependencies:
  network_inspect: ^0.1.0
```

Then run:

```bash
flutter pub get
```

### Local path (during development)

```yaml
dependencies:
  network_inspect:
    path: ../network_inspect
```

## Usage

### 1. Import package

```dart
import 'package:network_inspect/network_inspect.dart';
```

### 2. Wrap your app root

```dart
return NetworkMonitorOverlayHost(
  child: MaterialApp(
    home: const MyHomePage(),
  ),
);
```

### 3. Optional manual logging (if you want custom logs)

```dart
NetworkMonitorFacade.instance.log(
  method: 'POST',
  url: 'https://api.example.com/v1/orders',
  requestBody: '{"pickup":"A","drop":"B"}',
  responseBody: '{"success":true}',
  statusCode: 200,
  durationMs: 120,
);
```

## Behavior Notes

- The inspector is intended for debug builds only.
- In release/profile, overlay UI is not rendered.
- If your app already prints structured HTTP logs via `debugPrint`, `network_inspect` can capture those logs automatically when the overlay host is mounted.

## Recommended Integration Pattern

- Place `NetworkMonitorOverlayHost` as high as possible in your app tree.
- Keep your production logging policy unchanged; this package is for local QA/debug workflows.

## Example

A minimal runnable example is available under [`example/`](example).

## License

This package is distributed under the MIT License. See [LICENSE](LICENSE).
