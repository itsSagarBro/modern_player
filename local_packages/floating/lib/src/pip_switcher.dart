part of floating;

/// Widget switching utility.
///
/// Depending on current PiP status will render [childWhenEnabled]
/// or [childWhenDisabled] widget.
class PiPSwitcher extends StatefulWidget {
  /// Child to render when PiP is enabled
  final Widget child;

  PiPSwitcher({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<PiPSwitcher> createState() => _PipAwareState();
}

class _PipAwareState extends State<PiPSwitcher> {
  @override
  Widget build(BuildContext context) => widget.child;
}
