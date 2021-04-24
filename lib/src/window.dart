part of docking_windows;

class WindowWidget extends StatefulWidget {
  final Window window;

  const WindowWidget({
    Key key,
    this.window,
  }) : super(key: key);

  @override
  _WindowWidgetState createState() => _WindowWidgetState();
}

class _WindowWidgetState extends State<WindowWidget> {
  double oldPosX;
  double oldPosY;
  double oldWidth;
  double oldHeight;
  bool inAction = false;
  var windowDecoration;
  var windowTabDecoration;

  @override
  Widget build(BuildContext context) {
    _setDecorations();
    _setPinnedLocations();

    return Positioned(
      top: widget.window.posY,
      left: widget.window.posX,
      child: Container(
        width: widget.window.width,
        height: widget.window.height + widget.window.windowBarHeight,
        child: Column(
          children: [
            GestureDetector(
              onLongPressMoveUpdate: _updateWindowLocation,
              onLongPressStart: _startWindowRelocation,
              onLongPressEnd: _setWindowLocation,
              onDoubleTap: widget.window.moveWindowToTop,
              child: Container(
                height: widget.window.windowBarHeight,
                decoration: windowTabDecoration,
                child: widget.window.windowBar,
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: windowDecoration,
                    child: widget.window.child,
                  ),
                  if (widget.window.enableResizing)
                    GestureDetector(
                      onLongPressMoveUpdate: _resizeWindow,
                      onLongPressEnd: _finishResizing,
                      onLongPressStart: _saveDimensionsBeforeMoving,
                      child: Icon(Icons.photo_size_select_small),
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setPinnedLocations() {
    for (var pinnedWindow in widget.window.pinnedWindows) {
      if (pinnedWindow.pinDock) {
        var dockLocation = pinnedWindow.dockLocation;
        if (dockLocation == DockLocation.top) {
          pinnedWindow.posX = widget.window.posX;
          pinnedWindow.posY = widget.window.posY - pinnedWindow.totalHeight;
          pinnedWindow.width = widget.window.width;
        }
        if (dockLocation == DockLocation.bottom) {
          pinnedWindow.posX = widget.window.posX;
          pinnedWindow.posY = widget.window.posY + widget.window.totalHeight;
          pinnedWindow.width = widget.window.width;
        }
        if (dockLocation == DockLocation.left) {
          pinnedWindow.posX = widget.window.posX - pinnedWindow.width;
          pinnedWindow.posY = widget.window.posY;
          pinnedWindow.height = widget.window.height;
        }
        if (dockLocation == DockLocation.right) {
          pinnedWindow.posX = widget.window.posX + widget.window.width;
          pinnedWindow.posY = widget.window.posY;
          pinnedWindow.height = widget.window.height;
        }
      }
    }
  }

  void _setDecorations() {
    // create default decoration for a window
    var defaultBorderSide = BorderSide(
      color: DockingWindowConstants.defaultWindowBorderColor,
      width: DockingWindowConstants.defaultWindowBorderWidth,
    );

    windowDecoration = BoxDecoration(
      color: Colors.white,
      border: Border(
        left: defaultBorderSide,
        bottom: defaultBorderSide,
        right: defaultBorderSide,
      ),
    );

    // set panel decoration if not null
    if (widget.window.windowDecoration != null) {
      windowDecoration = widget.window.windowDecoration;
    }

    // create default decoration for a window tab
    windowTabDecoration = BoxDecoration(
      color: DockingWindowConstants.defaultWindowBarColor,
      border: Border(
        left: defaultBorderSide,
        top: defaultBorderSide,
        right: defaultBorderSide,
      ),
    );

    if (widget.window.windowBarDecoration != null) {
      windowTabDecoration = widget.window.windowBarDecoration;
    }

    if (inAction) {
      defaultBorderSide = BorderSide(
        color: widget.window.windowBorderActionColor,
        width: DockingWindowConstants.defaultWindowBorderWidth,
      );

      windowDecoration = BoxDecoration(
        color: Colors.white,
        border: Border(
          left: defaultBorderSide,
          bottom: defaultBorderSide,
          right: defaultBorderSide,
        ),
      );

      windowTabDecoration = BoxDecoration(
        color: DockingWindowConstants.defaultWindowBarColor,
        border: Border(
          left: defaultBorderSide,
          top: defaultBorderSide,
          right: defaultBorderSide,
        ),
      );
    }
  }

  void _finishResizing(_) {
    setState(() {
      inAction = false;
    });
  }

  void _saveDimensionsBeforeMoving(_) {
    oldWidth = widget.window.width;
    oldHeight = widget.window.height;
    inAction = true;
    setState(() {});
  }

  void _resizeWindow(LongPressMoveUpdateDetails updateDetails) {
    final offset = updateDetails.localOffsetFromOrigin;
    final newHeight = oldHeight + offset.dy;
    final newWidth = oldWidth + offset.dx;

    if (newHeight > 0 && _bottomSafe(newHeight)) {
      widget.window.height = newHeight;
    }
    if (newWidth > 0 && _rightSafe(newWidth)) {
      widget.window.width = newWidth;
    }
    inAction = true;
    widget.window.resizeWindow();
    setState(() {});
  }

  void _startWindowRelocation(_) {
    oldPosX = widget.window.posX;
    oldPosY = widget.window.posY;
    inAction = true;
    widget.window.moveWindowToTop();
    setState(() {});
  }

  void _updateWindowLocation(LongPressMoveUpdateDetails updateDetails) {
    final screenSize = MediaQuery.of(context).size;
    final offset = updateDetails.localOffsetFromOrigin;

    // calculate new positions
    final newPosX = oldPosX + offset.dx;
    final newPosY = oldPosY + offset.dy;

    // check screen boundaries
    if (newPosX > DockingWindowConstants.windowPositionPadding
        && newPosX + widget.window.width < screenSize.width - DockingWindowConstants.windowPositionPadding) {
      widget.window.posX = newPosX;
    }
    if (newPosY > DockingWindowConstants.windowPositionPadding
        && newPosY + widget.window.height < screenSize.height - DockingWindowConstants.extraPaddingForBottom) {
      widget.window.posY = newPosY;
    }

    // notify window to make some changes on ui
    inAction = true;

    // send global position to DockingWindows class
    widget.window.changeWindowLocation(widget.window, updateDetails.globalPosition);

    setState(() {});
  }

  void _setWindowLocation(LongPressEndDetails dragEndDetails) {
    // if windows is outside of the range, set it to the nearest available location
    final screenSize = MediaQuery.of(context).size;
    // check left side of the screen
    if (widget.window.posX <= 0) {
      widget.window.posX = DockingWindowConstants.windowPositionPadding;
    }
    // check right side of the screen
    if (!_rightSafe(widget.window.width)) {
      widget.window.posX = screenSize.width -
          DockingWindowConstants.windowPositionPadding -
          widget.window.width;
    }
    // check top of the screen
    if (widget.window.posY < DockingWindowConstants.windowPositionPadding) {
      widget.window.posY = DockingWindowConstants.windowPositionPadding;
    }
    // check bottom of the screen
    if (!_bottomSafe(widget.window.height)) {
      widget.window.posY = screenSize.height -
          DockingWindowConstants.extraPaddingForBottom -
          DockingWindowConstants.windowPositionPadding -
          widget.window.height;
    }
    inAction = false;

    widget.window.setWindowLocation(widget.window);

    setState(() {});
  }

  bool _rightSafe(double width) {
    final screenSize = MediaQuery.of(context).size;
    return widget.window.posX + width <= screenSize.width - DockingWindowConstants.windowPositionPadding;
  }

  bool _bottomSafe(double height) {
    final screenSize = MediaQuery.of(context).size;
    return widget.window.posY + height <= screenSize.height - DockingWindowConstants.windowPositionPadding;
  }
}

class Window {
  double posX;
  double posY;
  double width;
  double height;
  DockLocation dockLocation;
  List<Window> pinnedWindows = [];
  bool pinDock = false;

  final Key key;
  final double windowBarHeight;
  final Widget child;
  final BoxDecoration windowDecoration;
  final BoxDecoration windowBarDecoration;
  final Widget windowBar;
  final bool enableResizing;
  final Color windowBorderActionColor;

  Function moveWindowToTop;
  Function changeWindowLocation;
  Function setWindowLocation;
  Function resizeWindow;

  Window({
    this.key,
    this.posX: DockingWindowConstants.initialPosX,
    this.posY: DockingWindowConstants.initialPosY,
    this.width: DockingWindowConstants.initialWindowWidth,
    this.height: DockingWindowConstants.initialWindowHeight,
    this.windowBarHeight: DockingWindowConstants.initialWindowBarHeight,
    this.child,
    this.windowDecoration,
    this.windowBarDecoration,
    this.windowBar,
    this.enableResizing = true,
    this.windowBorderActionColor: DockingWindowConstants.defaultBorderActionColor,
  }) : assert(key != null);

  double get totalHeight => height + windowBarHeight;
}
