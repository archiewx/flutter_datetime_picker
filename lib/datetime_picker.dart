import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import './src/date_model.dart';
import './src/i18n_model.dart';
export './src/date_model.dart';
export './src/i18n_model.dart';

typedef DateChangedCallback(DateTime time);
typedef String StringAtIndexCallBack(int index);
const double _kDatePickerHeight = 164.0;
const double _kDatePickerItemHeight = 52.0;
const double _kDatePickerFontSize = 16.0;
const double _kDatePickerDiameterRatio = 10.0;

class DatePickerComponent extends StatefulWidget {
  DatePickerComponent({
    Key key,
    this.onChanged,
    locale,
    BasePickerModel pickerModel,
    double itemHeight,
    double diameterRatio,
    PickerModelMode mode,
  })  : this.locale = locale,
        this.mode = mode ?? PickerModelMode.YMD,
        this.pickerModel = pickerModel ?? DatePickerModel(locale: locale, mode: mode),
        this.itemHeight = itemHeight ?? _kDatePickerItemHeight,
        this.diameterRadio = diameterRatio ?? _kDatePickerDiameterRatio;

  final DateChangedCallback onChanged;

  final LocaleType locale;

  final BasePickerModel pickerModel;

  final double itemHeight;

  final double diameterRadio;

  final PickerModelMode mode;

  @override
  State<StatefulWidget> createState() {
    return _DatePickerComponentState();
  }
}

class _DatePickerComponentState extends State<DatePickerComponent> {
  FixedExtentScrollController leftScrollCtrl, middleScrollCtrl, rightScrollCtrl;

  @override
  void initState() {
    super.initState();
    refreshScrollOffset();
  }

  void refreshScrollOffset() {
    leftScrollCtrl =
        FixedExtentScrollController(initialItem: widget.pickerModel.currentLeftIndex());
    middleScrollCtrl =
        FixedExtentScrollController(initialItem: widget.pickerModel.currentMiddleIndex());
    rightScrollCtrl =
        FixedExtentScrollController(initialItem: widget.pickerModel.currentRightIndex());
  }

  @override
  void didUpdateWidget(DatePickerComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    refreshScrollOffset();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: ClipRect(
        child: CustomSingleChildLayout(
          delegate: _BottomPickerLayout(1),
          child: GestureDetector(
            child: Material(
              color: Colors.transparent,
              child: _renderPickerView(),
            ),
          ),
        ),
      ),
    );
  }

  void _notifyDateChanged() {
    if (widget.onChanged != null) {
      widget.onChanged(widget.pickerModel.finalTime());
    }
  }

  Widget _renderPickerView() {
    Widget itemView = _renderItemView();
    return itemView;
  }

  Widget _renderColumnView(
    StringAtIndexCallBack stringAtIndexCB,
    ScrollController scrollController,
    int layoutProportion,
    ValueChanged<int> selectedChangedWhenScrolling,
    ValueChanged<int> selectedChangedWhenScrollEnd,
  ) {
    return Expanded(
      flex: layoutProportion,
      child: Container(
        padding: EdgeInsets.all(8.0),
        height: _kDatePickerHeight,
        decoration: BoxDecoration(color: Colors.white),
        child: NotificationListener(
          onNotification: (ScrollNotification notification) {
            if (notification.depth == 0 &&
                selectedChangedWhenScrollEnd != null &&
                notification is ScrollEndNotification &&
                notification.metrics is FixedExtentMetrics) {
              final FixedExtentMetrics metrics = notification.metrics;
              final int currentItemIndex = metrics.itemIndex;
              selectedChangedWhenScrollEnd(currentItemIndex);
            }
            return false;
          },
          child: CupertinoPicker.builder(
              key: ValueKey(widget.pickerModel.currentMiddleIndex()),
              backgroundColor: Colors.white,
              scrollController: scrollController,
              itemExtent: widget.itemHeight,
              onSelectedItemChanged: (int index) {
                selectedChangedWhenScrolling(index);
              },
              diameterRatio: widget.diameterRadio,
              useMagnifier: true,
              itemBuilder: (BuildContext context, int index) {
                final content = stringAtIndexCB(index);
                if (content == null) {
                  return null;
                }
                return Container(
                  height: widget.itemHeight,
                  alignment: Alignment.center,
                  child: Text(
                    content,
                    style: TextStyle(color: Color(0xFF000046), fontSize: _kDatePickerFontSize),
                    textAlign: TextAlign.start,
                  ),
                );
              }),
        ),
      ),
    );
  }

  Widget _renderItemView() {
    List<Widget> children = [
      _renderColumnView(
        widget.pickerModel.leftStringAtIndex,
        leftScrollCtrl,
        widget.pickerModel.layoutProportions[0],
        (index) {
          setState(() {
            widget.pickerModel.setLeftIndex(index);
          });
          _notifyDateChanged();
        },
        null,
      ),
      Text(
        widget.pickerModel.leftDivider(),
        style: TextStyle(color: Color(0xFF000046), fontSize: _kDatePickerFontSize),
      ),
      _renderColumnView(
        widget.pickerModel.middleStringAtIndex,
        middleScrollCtrl,
        widget.pickerModel.layoutProportions[1],
        (index) {
          widget.pickerModel.setMiddleIndex(index);
        },
        (index) {
          setState(() {
            refreshScrollOffset();
          });
          _notifyDateChanged();
        },
      ),
    ];

    if (widget.mode == PickerModelMode.HMS || widget.mode == PickerModelMode.YMD) {
      children.addAll([
        Text(
          widget.pickerModel.rightDivider(),
          style: TextStyle(color: Color(0xFF000046), fontSize: _kDatePickerFontSize),
        ),
        _renderColumnView(
          widget.pickerModel.rightStringAtIndex,
          rightScrollCtrl,
          widget.pickerModel.layoutProportions[2],
          (index) {
            setState(() {
              widget.pickerModel.setRightIndex(index);
            });
            _notifyDateChanged();
          },
          null,
        ),
      ]);
    }

    return Container(
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: children,
      ),
    );
  }
}

class _BottomPickerLayout extends SingleChildLayoutDelegate {
  _BottomPickerLayout(this.progress);

  final double progress;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    double maxHeight = _kDatePickerHeight;
    return BoxConstraints(
        minWidth: constraints.maxWidth,
        maxWidth: constraints.maxWidth,
        minHeight: 0.0,
        maxHeight: maxHeight);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double height = size.height - childSize.height * progress;
    return Offset(0.0, height);
  }

  @override
  bool shouldRelayout(_BottomPickerLayout oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
