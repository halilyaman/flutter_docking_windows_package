part of docking_windows;

// ignore: must_be_immutable
class Window extends StatefulWidget {
  final double height;
  final double width;
  final double windowBarHeight;
  final double initialPosX;
  final double initialPosY;
  final Widget child;
  final BoxDecoration windowDecoration;
  final BoxDecoration windowBarDecoration;
  final Widget windowBar;
  Function moveWindowToTop;
  final bool enableResizing;

  Window({
    Key key,
    this.height = DockingWindowConstants.initialWindowHeight,
    this.width = DockingWindowConstants.initialWindowWidth,
    this.windowBarHeight = DockingWindowConstants.initialWindowBarHeight,
    this.initialPosX = DockingWindowConstants.initialPosX,
    this.initialPosY = DockingWindowConstants.initialPosY,
    this.child,
    this.windowDecoration,
    this.windowBarDecoration,
    this.windowBar,
    this.enableResizing = true,
  }) : assert(key != null), super(key: key);

  @override
  _WindowState createState() => _WindowState();
}

class _WindowState extends State<Window> {
  double posX;
  double posY;
  double width;
  double height;
  Offset panStartLocalePos;

  double oldWidth;
  double oldHeight;

  @override
  void initState() {
    super.initState();

    // initialize state variables
    posX = widget.initialPosX;
    posY = widget.initialPosY;
    width = widget.width;
    height = widget.height;
  }

  @override
  Widget build(BuildContext context) {
    // create default decoration for a window
    final defaultBorderSide = BorderSide(
        color: Colors.black,
        width: DockingWindowConstants.defaultWindowBorderWidth
    );

    BoxDecoration windowDecoration = BoxDecoration(
      color: Colors.white,
      border: Border(
        left: defaultBorderSide,
        bottom: defaultBorderSide,
        right: defaultBorderSide,
      ),
    );

    // set panel decoration if not null
    if (widget.windowDecoration != null) {
      windowDecoration = widget.windowDecoration;
    }

    // create default decoration for a window tab
    BoxDecoration windowTabDecoration = BoxDecoration(
      color: DockingWindowConstants.defaultWindowBarColor,
      border: Border(
        left: defaultBorderSide,
        top: defaultBorderSide,
        right: defaultBorderSide,
      ),
    );

    if (widget.windowBarDecoration != null) {
      windowTabDecoration = widget.windowBarDecoration;
    }

    return Positioned(
      top: posY,
      left: posX,
      child: Column(
        children: [
          GestureDetector(
            onPanUpdate: _updateWindowLocation,
            onPanStart: _onPanStart,
            onPanEnd: _onPanEnd,
            onDoubleTap: widget.moveWindowToTop,
            child: Container(
              height: widget.windowBarHeight,
              width: width,
              decoration: windowTabDecoration,
              child: widget.windowBar,
            ),
          ),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                height: height,
                width: width,
                decoration: windowDecoration,
                child: widget.child,
              ),
              if (widget.enableResizing)
                GestureDetector(
                  onLongPressMoveUpdate: _resizeWindow,
                  onLongPressStart: _saveDimensionsBeforeMove,
                  child: Icon(Icons.photo_size_select_small),
                )
            ],
          ),
        ],
      ),
    );
  }

  void _saveDimensionsBeforeMove(_) {
    oldWidth = width;
    oldHeight = height;
  }

  void _resizeWindow(LongPressMoveUpdateDetails updateDetails) {
    final offset = updateDetails.localOffsetFromOrigin;
    final newHeight = oldHeight + offset.dy;
    final newWidth = oldWidth + offset.dx;

    if (newHeight > 0) {
      height = newHeight;
    }
    if (newWidth > 0) {
      width = newWidth;
    }
    setState(() {});
  }

  void _onPanStart(DragStartDetails dragStartDetails) {
    panStartLocalePos = dragStartDetails.localPosition;
  }

  void _onPanEnd(DragEndDetails dragEndDetails) {
    // if windows is outside of the range, set it to the nearest available location
    final screenSize = MediaQuery.of(context).size;
    // check left side of the screen
    if (posX <= 0) {
      posX = DockingWindowConstants.windowPositionPadding;
    }
    // check right side of the screen
    if (posX + width > screenSize.width - DockingWindowConstants.windowPositionPadding) {
      posX = screenSize.width - DockingWindowConstants.windowPositionPadding - width;
    }
    // check top of the screen
    if (posY < DockingWindowConstants.windowPositionPadding) {
      posY = DockingWindowConstants.windowPositionPadding;
    }
    // check bottom of the screen
    if (posY + height > screenSize.height - DockingWindowConstants.windowPositionPadding) {
      posY = screenSize.height - DockingWindowConstants.extraPaddingForBottom
          - DockingWindowConstants.windowPositionPadding - height;
    }
    setState(() {});
  }

  void _updateWindowLocation(DragUpdateDetails dragUpdateDetails) {
    final screenSize = MediaQuery.of(context).size;
    final dx = dragUpdateDetails.delta.dx;
    final dy = dragUpdateDetails.delta.dy;
    final globalPos = dragUpdateDetails.globalPosition;

    // calculate distances to screen sides
    final leftDist = globalPos.dx - panStartLocalePos.dx;
    final rightDist = globalPos.dx + (width - panStartLocalePos.dx);
    final topDist = globalPos.dy - panStartLocalePos.dy;
    final bottomDist = globalPos.dy + (height + widget.windowBarHeight - panStartLocalePos.dy);

    // update window position if it is in range of screen dimensions
    if (leftDist > DockingWindowConstants.windowPositionPadding
        && rightDist < (screenSize.width - DockingWindowConstants.windowPositionPadding)) {
      posX += dx;
    }
    if (topDist > DockingWindowConstants.windowPositionPadding 
        && bottomDist < (screenSize.height - DockingWindowConstants.windowPositionPadding)) {
      posY += dy;
    }
    setState(() {});
  }
}