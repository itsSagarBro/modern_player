String getFormattedDuration(Duration duration) {
  return "${duration.inHours > 0 ? "${(duration.inHours % 24).toString().padLeft(2, '0')}:" : ""}${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
}
