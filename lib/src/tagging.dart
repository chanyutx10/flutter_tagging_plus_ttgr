// Copyright 2019 Sarbagya Dhaubanjar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'configurations.dart';
import 'taggable.dart';

///
class FlutterTagging<T extends Taggable> extends StatefulWidget {
  final ValueChanged<List<T>> onChanged;
  final TextFieldConfiguration textFieldConfiguration;
  final FutureOr<List<T>> Function(String) findSuggestions;
  final ChipConfiguration Function(T) configureChip;
  final SuggestionConfiguration Function(T) configureSuggestion;
  final WrapConfiguration wrapConfiguration;
  final T Function(String) additionCallback;
  final FutureOr<T> Function(T) onAdded;
  final Widget Function(BuildContext) loadingBuilder;
  final Widget Function(BuildContext) emptyBuilder;
  final Widget Function(BuildContext, Object) errorBuilder;
  final dynamic Function(BuildContext, Widget, AnimationController)
      transitionBuilder;
  final SuggestionsBoxConfiguration suggestionsBoxConfiguration;

  /// The duration that [transitionBuilder] animation takes.
  ///
  /// This argument is best used with [transitionBuilder] and [animationStart]
  /// to fully control the animation.
  ///
  /// Defaults to 500 milliseconds.
  final Duration animationDuration;

  /// The value at which the [transitionBuilder] animation starts.
  ///
  /// This argument is best used with [transitionBuilder] and [animationDuration]
  /// to fully control the animation.
  ///
  /// Defaults to 0.25.
  final double animationStart;

  /// If set to true, no loading box will be shown while suggestions are
  /// being fetched. [loadingBuilder] will also be ignored.
  ///
  /// Defaults to false.
  final bool hideOnLoading;

  /// If set to true, nothing will be shown if there are no results.
  /// [emptyBuilder] will also be ignored.
  ///
  /// Defaults to false.
  final bool hideOnEmpty;

  /// If set to true, nothing will be shown if there is an error.
  /// [errorBuilder] will also be ignored.
  ///
  /// Defaults to false.
  final bool hideOnError;

  /// The duration to wait after the user stops typing before calling
  /// [findSuggestions].
  ///
  /// This is useful, because, if not set, a request for suggestions will be
  /// sent for every character that the user types.
  ///
  /// This duration is set by default to 300 milliseconds.
  final Duration debounceDuration;

  /// If set to true, suggestions will be fetched immediately when the field is
  /// added to the view.
  ///
  /// But the suggestions box will only be shown when the field receives focus.
  /// To make the field receive focus immediately, you can set the `autofocus`
  /// property in the [textFieldConfiguration] to true.
  ///
  /// Defaults to false.
  final bool enableImmediateSuggestion;

  /// Creates a [FlutterTagging] widget.
  FlutterTagging({
    @required this.onChanged,
    @required this.findSuggestions,
    @required this.configureChip,
    @required this.configureSuggestion,
    this.additionCallback,
    this.enableImmediateSuggestion = false,
    this.errorBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.wrapConfiguration = const WrapConfiguration(),
    this.textFieldConfiguration = const TextFieldConfiguration(),
    this.suggestionsBoxConfiguration = const SuggestionsBoxConfiguration(),
    this.transitionBuilder,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.hideOnEmpty = false,
    this.hideOnError = false,
    this.hideOnLoading = false,
    this.animationDuration = const Duration(milliseconds: 500),
    this.animationStart = 0.25,
    this.onAdded,
  })  : assert(findSuggestions != null),
        assert(configureChip != null),
        assert(configureSuggestion != null);

  @override
  _FlutterTaggingState<T> createState() => _FlutterTaggingState<T>();
}

class _FlutterTaggingState<T extends Taggable>
    extends State<FlutterTagging<T>> {
  final List<T> _selectedValues = [];

  TextEditingController _textController;
  FocusNode _focusNode;
  T _additionItem;

  @override
  void initState() {
    super.initState();
    _textController =
        widget.textFieldConfiguration.controller ?? TextEditingController();
    _focusNode = widget.textFieldConfiguration.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        TypeAheadField<T>(
          getImmediateSuggestions: widget.enableImmediateSuggestion,
          debounceDuration: widget.debounceDuration,
          hideOnEmpty: widget.hideOnEmpty,
          hideOnError: widget.hideOnError,
          hideOnLoading: widget.hideOnLoading,
          animationStart: widget.animationStart,
          animationDuration: widget.animationDuration,
          autoFlipDirection:
              widget.suggestionsBoxConfiguration.autoFlipDirection,
          direction: widget.suggestionsBoxConfiguration.direction,
          hideSuggestionsOnKeyboardHide:
              widget.suggestionsBoxConfiguration.hideSuggestionsOnKeyboardHide,
          keepSuggestionsOnLoading:
              widget.suggestionsBoxConfiguration.keepSuggestionsOnLoading,
          keepSuggestionsOnSuggestionSelected: widget
              .suggestionsBoxConfiguration.keepSuggestionsOnSuggestionSelected,
          suggestionsBoxController:
              widget.suggestionsBoxConfiguration.suggestionsBoxController,
          suggestionsBoxDecoration:
              widget.suggestionsBoxConfiguration.suggestionsBoxDecoration,
          suggestionsBoxVerticalOffset:
              widget.suggestionsBoxConfiguration.suggestionsBoxVerticalOffset,
          errorBuilder: widget.errorBuilder,
          transitionBuilder: widget.transitionBuilder,
          loadingBuilder: (context) =>
              widget.loadingBuilder ??
              SizedBox(
                height: 3.0,
                child: LinearProgressIndicator(),
              ),
          noItemsFoundBuilder: widget.emptyBuilder,
          textFieldConfiguration: widget.textFieldConfiguration.copyWith(
            focusNode: _focusNode,
            controller: _textController,
            enabled: widget.textFieldConfiguration.enabled &&
                widget.onChanged != null,
          ),
          suggestionsCallback: (query) async {
            var suggestions = await widget.findSuggestions(query);
            suggestions.removeWhere(_selectedValues.contains);
            if (widget.additionCallback != null && query.isNotEmpty) {
              var additionItem = widget.additionCallback(query);
              if (!suggestions.contains(additionItem) &&
                  !_selectedValues.contains(additionItem)) {
                _additionItem = additionItem;
                suggestions.insert(0, additionItem);
              } else {
                _additionItem = null;
              }
            }
            return suggestions;
          },
          itemBuilder: (context, item) {
            var conf = widget.configureSuggestion(item);
            return ListTile(
              key: ObjectKey(item),
              title: conf.title,
              subtitle: conf.subtitle,
              leading: conf.leading,
              trailing: InkWell(
                splashColor: conf.splashColor ?? Theme.of(context).splashColor,
                borderRadius: conf.splashRadius,
                onTap: () async {
                  if (widget.onAdded != null) {
                    _selectedValues.add(await widget.onAdded(item));
                  } else {
                    _selectedValues.add(item);
                  }
                  setState(() {});
                  widget.onChanged(_selectedValues);
                  _textController.clear();
                  _focusNode.unfocus();
                },
                child: Builder(
                  builder: (context) {
                    if (_additionItem != null && _additionItem == item) {
                      return conf.additionWidget;
                    } else {
                      return SizedBox(width: 0);
                    }
                  },
                ),
              ),
            );
          },
          onSuggestionSelected: (suggestion) {
            if (_additionItem != suggestion) {
              setState(() {
                _selectedValues.add(suggestion);
              });
              widget.onChanged(_selectedValues);
              _textController.clear();
            }
          },
        ),
        Wrap(
          alignment: widget.wrapConfiguration.alignment,
          crossAxisAlignment: widget.wrapConfiguration.crossAxisAlignment,
          runAlignment: widget.wrapConfiguration.runAlignment,
          runSpacing: widget.wrapConfiguration.runSpacing,
          spacing: widget.wrapConfiguration.spacing,
          direction: widget.wrapConfiguration.direction,
          textDirection: widget.wrapConfiguration.textDirection,
          verticalDirection: widget.wrapConfiguration.verticalDirection,
          children: _selectedValues.map<Widget>((item) {
            var conf = widget.configureChip(item);
            return Chip(
              label: conf.label,
              shape: conf.shape,
              avatar: conf.avatar,
              backgroundColor: conf.backgroundColor,
              clipBehavior: conf.clipBehavior,
              deleteButtonTooltipMessage: conf.deleteButtonTooltipMessage,
              deleteIcon: conf.deleteIcon,
              deleteIconColor: conf.deleteIconColor,
              elevation: conf.elevation,
              labelPadding: conf.labelPadding,
              labelStyle: conf.labelStyle,
              materialTapTargetSize: conf.materialTapTargetSize,
              padding: conf.padding,
              shadowColor: conf.shadowColor,
              onDeleted: () {
                setState(() {
                  _selectedValues.remove(item);
                });
                widget.onChanged(_selectedValues);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
