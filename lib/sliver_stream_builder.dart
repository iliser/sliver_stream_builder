library sliver_stream_builder;

import 'dart:async';
import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'sliver_stream_builder_localization.dart';

// TODO export to package, change name
class StreamSliverBuilder<T> extends StatefulWidget {
  /// Stream can't be changed later
  final Stream<T> stream;
  final Widget Function(BuildContext context, T v) builder;
  final Widget Function(BuildContext context)? progressBuilder;

  final Widget Function(BuildContext context)? emptyBuilder;

  /// Error processing.
  /// If component recieve error from stream, component request pause on stream and await while resume call
  final String Function(dynamic)? errorTextExtractor;
  final Widget? Function(dynamic err, void Function() resume)? errorBuilder;

  final StreamSliverBuilderLocalization? localization;

  StreamSliverBuilder({
    Key? key,
    required this.stream,
    required this.builder,
    this.progressBuilder,
    this.emptyBuilder,
    this.errorTextExtractor,
    this.errorBuilder,
    this.localization,
  }) : super(key: key);
  @override
  _StreamSliverBuilderState<T> createState() => _StreamSliverBuilderState<T>();
}

class _StreamSliverBuilderState<T> extends State<StreamSliverBuilder<T>> {
  List<T> data = [];
  dynamic? error;

  bool isDone = false;
  bool get isError => error != null;

  int lastVisible = 0;

  late StreamSubscription sub;

  late StreamSliverBuilderLocalization localization =
      widget.localization ?? StreamSliverBuilderLocalization.of(context);

  void addElement(T e) {
    error = null;
    data.add(e);
    // initiate rebuild only if added child in visible area.
    // else just add it to data list and wait until user scroll.
    // Then sliver call builder while has data and if data end builder return null.
    // After that sliver need to be forced to rebuild
    if (data.length <= lastVisible + 1) {
      setState(() {});
    } else {
      sub.pause();
    }
  }

  void onDone() {
    isDone = true;
    if (data.isEmpty) _currentBuilder = _emptyBuilder;
  }

  void onError(err, _) {
    error = err;
    sub.pause();
    setState(() {});
  }

  void _resumeAfterError() {
    error = null;
    sub.resume();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    sub = widget.stream.listen(
      addElement,
      onDone: onDone,
      onError: onError,
    );
  }

  @override
  void didUpdateWidget(covariant StreamSliverBuilder<T> oldWidget) {
    if (identical(oldWidget.stream, widget.stream) != true) {
      data = [];
      sub.cancel();
      sub = widget.stream.listen(
        addElement,
        onDone: onDone,
        onError: onError,
      );
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }

  Widget? _emptyBuilder(context, i) {
    return widget.emptyBuilder?.call(context);
  }

  Widget? Function(dynamic err, void Function() resume) get _errorBuilder =>
      widget.errorBuilder ?? _defaultErrorBuilder;

  Widget? _defaultErrorBuilder(dynamic err, void Function() resume) {
    // final locallization = StreamSliverBuilderLocalization.of(context);
    return Center(
      child: Column(
        children: [
          SizedBox(
            height: 8,
          ),
          Text(
            widget.errorTextExtractor?.call(error) ??
                localization.errorMessageDefaultText,
            style: TextStyle(color: Theme.of(context).errorColor),
          ),
          TextButton(
            onPressed: resume,
            child: Text(localization.errorRetryButtonText),
          )
        ],
      ),
    );
  }

  Widget? _builder(ctx, i) {
    lastVisible = max(lastVisible, i);

    if (i > data.length) {
      return null;
    }
    if (i == data.length) {
      if (isDone) return null;
      if (isError) return _errorBuilder(error, _resumeAfterError);

      sub.resume();
      return widget.progressBuilder?.call(context) ??
          Center(child: CircularProgressIndicator());
    }

    return widget.builder(ctx, data[i]);
  }

  late Widget? Function(BuildContext, int) _currentBuilder = _builder;

  @override
  Widget build(BuildContext context) {
    return SliverList(delegate: SliverChildBuilderDelegate(_currentBuilder));
  }
}
