part of docking_windows;

class DockingWindows extends StatefulWidget {
  final List<Window> windows;
  final bool disableDocking;

  const DockingWindows({
    Key key,
    this.windows = const [],
    this.disableDocking = false,
  }) : super(key: key);

  @override
  _DockingWindowsState createState() => _DockingWindowsState();
}

class _DockingWindowsState extends State<DockingWindows> {
  List<Window> windows;

  @override
  void initState() {
    windows = widget.windows;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _setCallbacks();

    return SafeArea(
      child: Stack(
        children: windows.map((window) {
          return WindowWidget(
            key: window.key,
            window: window,
          );
        }).toList(),
      ),
    );
  }

  void _setCallbacks() {
    windows.forEach((window) {
      // set double tap callback function for window tab
      window.moveWindowToTop = () {
        final selectedWindow = window;
        windows.remove(window);
        windows.insert(windows.length, selectedWindow);
        setState(() {});
      };

      // used for getting location data while moving around
      window.changeWindowLocation = (Window selectedWindow, Offset globalPosition) {
        windows.forEach((window) {
          if (window.key == selectedWindow.key) {
            return;
          }
          window.pinnedWindows.remove(selectedWindow);
        });
        if (!widget.disableDocking) {
          _checkOverlapping(selectedWindow, globalPosition);
        }
      };

      window.setWindowLocation = (Window window) {
        setState(() {
          window.pinDock = true;
        });
      };

      window.resizeWindow = () {
        setState(() {});
      };
    });
  }

  void _checkOverlapping(Window selectedWindow, Offset globalPosition) {
    windows.forEach((window) {
      if (window.key == selectedWindow.key) {
        return;
      }

      final dockLocation = _checkOverlap(globalPosition, window);

      if (dockLocation != null) {
        selectedWindow.dockLocation = dockLocation;
        if (!window.pinnedWindows.contains(selectedWindow)) {
          window.pinnedWindows.add(selectedWindow);
        }
      } else {
        selectedWindow.pinDock = false;
      }
      setState(() {});
    });
  }

  DockLocation _checkOverlap(Offset globalPosition, Window window) {
    final windowEndHorizontal = window.posX + window.width;
    final windowEndVertical = window.posY + window.totalHeight;

    if (globalPosition.dx >= window.posX + window.width / 3
        && globalPosition.dx <= windowEndHorizontal - window.width / 3
        && globalPosition.dy >= window.posY
        && globalPosition.dy <= windowEndVertical - 2 * (window.totalHeight / 3)) {
      return DockLocation.top;
    }

    if (globalPosition.dx >= window.posX + window.width / 3
        && globalPosition.dx <= windowEndHorizontal - window.width / 3
        && globalPosition.dy >= window.posY + 2 * (window.totalHeight / 3)
        && globalPosition.dy <= windowEndVertical) {
      return DockLocation.bottom;
    }

    if (globalPosition.dx >= window.posX
        && globalPosition.dx <= windowEndHorizontal - 2 * window.width / 3
        && globalPosition.dy >= window.posY + (window.totalHeight / 3)
        && globalPosition.dy <= windowEndVertical - (window.totalHeight / 3)) {
      return DockLocation.left;
    }

    if (globalPosition.dx >= window.posX + 2 * (window.width / 3)
        && globalPosition.dx <= windowEndHorizontal
        && globalPosition.dy >= window.posY + (window.totalHeight / 3)
        && globalPosition.dy <= windowEndVertical - (window.totalHeight / 3)) {
      return DockLocation.right;
    }

    return null;
  }
}

enum DockLocation {
  top, bottom, right, left
}
