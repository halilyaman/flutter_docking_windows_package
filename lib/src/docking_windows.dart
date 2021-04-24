part of docking_windows;

class DockingWindows extends StatefulWidget {
  final List<Window> windows;

  const DockingWindows({
    Key key,
    this.windows = const [],
  }) : super(key: key);

  @override
  _DockingWindowsState createState() => _DockingWindowsState();
}

class _DockingWindowsState extends State<DockingWindows> {

  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    _setWindowCallbacks();

    return SafeArea(
      child: Stack(
        children: widget.windows.map((window) => window).toList(),
      ),
    );
  }

  void _setWindowCallbacks() {
    widget.windows.forEach((window) {
      // set double tap callback function for window tab
      window.moveWindowToTop = () {
        final selectedWindow = window;
        widget.windows.remove(window);
        widget.windows.insert(widget.windows.length, selectedWindow);
        setState(() {});
      };
    });
  }
}
