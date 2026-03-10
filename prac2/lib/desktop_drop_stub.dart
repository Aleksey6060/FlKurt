import 'dart:typed_data';

import 'package:flutter/widgets.dart';

class DropDoneDetails {
  final List<DropFile> files;

  const DropDoneDetails({this.files = const []});
}

class DropFile {
  Future<Uint8List> readAsBytes() async => Uint8List(0);
}

class DropTarget extends StatelessWidget {
  final Widget child;
  final void Function(DropDoneDetails details)? onDragDone;
  final void Function(dynamic details)? onDragEntered;
  final void Function(dynamic details)? onDragExited;

  const DropTarget({
    super.key,
    required this.child,
    this.onDragDone,
    this.onDragEntered,
    this.onDragExited,
  });

  @override
  Widget build(BuildContext context) => child;
}
