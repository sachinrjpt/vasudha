import 'package:flutter/material.dart';
import 'auto_text.dart';

class AutoTextOverride extends StatelessWidget {
  final Widget child;

  const AutoTextOverride({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return _AutoTextReplacer(child: child);
  }
}

class _AutoTextReplacer extends StatelessWidget {
  final Widget child;

  const _AutoTextReplacer({required this.child});

  @override
  Widget build(BuildContext context) {
    return _replaceTextWidgets(child);
  }

  Widget _replaceTextWidgets(Widget widget) {
    if (widget is Text) {
      return AutoText(
        widget.data ?? "",
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
        textAlign: widget.textAlign,
        softWrap: widget.softWrap,
      );
    } else if (widget is RichText) {
      // Optionally handle RichText, else return as is
      return widget;
    } else if (widget is SingleChildRenderObjectWidget) {
      return widget.cloneWithChild(_replaceTextWidgets(widget.child!));
    } else if (widget is MultiChildRenderObjectWidget) {
      return widget.cloneWithChildren(
        widget.children.map(_replaceTextWidgets).toList(),
      );
    }
    return widget;
  }
}
