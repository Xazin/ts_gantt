import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:linked_scroll_controller/linked_scroll_controller.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: const GanttView(),
    ),
  );
}

const _dayWidth = 35;
const _itemHeight = 35;

class GanttView extends StatefulWidget {
  const GanttView({super.key});

  @override
  State<GanttView> createState() => _GanttViewState();
}

class _GanttViewState extends State<GanttView> {
  late List<DateTime> _days;
  late List<GanttItem> _items;
  late final ScrollController _dateScrollController;
  final Map<String, ScrollController> _itemScrollControllers = {};
  late final LinkedScrollControllerGroup _controllers;
  final today = DateTime.now();

  bool _isScrollReady = false;
  // DragStartDetails? _dragStartDetails;

  @override
  void initState() {
    super.initState();

    // add 20 days before today, and 50 days after today
    _days = List.generate(80, (index) {
      return today.add(Duration(days: index - 30));
    });

    _items = [
      GanttItem(
        id: '1',
        start: today.add(
          const Duration(days: 1),
        ),
        end: today.add(
          const Duration(days: 5),
        ),
        title: 'T',
      ),
      GanttItem(
        id: '2',
        start: today.add(
          const Duration(days: -15),
        ),
        end: today.add(
          const Duration(days: -10),
        ),
        title: 'Task 2',
      ),
      GanttItem(
        id: '3',
        start: today.add(
          const Duration(days: -9),
        ),
        end: today.add(
          const Duration(days: -2),
        ),
        title: 'Task 3',
      ),
      GanttItem(
        id: '4',
        start: today.add(
          const Duration(days: 50),
        ),
        end: today.add(
          const Duration(days: 52),
        ),
        title: 'Task 4',
      ),
    ];

    _controllers = LinkedScrollControllerGroup();

    _dateScrollController = _controllers.addAndGet();

    for (final item in _items) {
      _itemScrollControllers[item.id] = _controllers.addAndGet();
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _controllers.jumpTo(25.0 * _dayWidth);
      _controllers.addOffsetChangedListener(_onScrollChanged);
      setState(() {
        _isScrollReady = true;
      });
    });
  }

  void _onScrollChanged() => setState(() {});

  @override
  void dispose() {
    _controllers.removeOffsetChangedListener(_onScrollChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DefaultHeader(
              goToToday: () {
                _controllers.jumpTo(25.0 * _dayWidth);
              },
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: SizedBox(
                height: 50,
                child: ListView.builder(
                  controller: _dateScrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: _days.length,
                  itemBuilder: (_, index) => _DefaultDayWidget(
                    date: _days[index],
                    today: today,
                  ),
                ),
              ),
            ),
            Stack(
              children: [
                Column(
                  children: [
                    for (final item in _items)
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          scrollDirection: Axis.horizontal,
                          controller: _itemScrollControllers[item.id],
                          itemCount: 1,
                          itemBuilder: (_, __) =>
                              GanttItemRender(days: _days, item: item),
                        ),
                      ),
                  ],
                ),
                if (_isScrollReady) ...[
                  for (final (index, item) in _items.indexed)
                    Positioned(
                      left: 0,
                      top: (index) * 40.0,
                      child: AnimatedOpacity(
                        opacity: _itemScrollControllers.values.isNotEmpty &&
                                _itemScrollControllers.values.first.offset >
                                    (_dayWidth *
                                        item.end
                                            .difference(_days.first)
                                            .inDays
                                            .toDouble())
                            ? 1
                            : 0,
                        duration: const Duration(milliseconds: 200),
                        child: GestureDetector(
                          onTap: () {
                            _controllers.jumpTo(item.start
                                    .difference(_days.first)
                                    .inDays
                                    .toDouble() *
                                _dayWidth);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            height: 36,
                            child: const Center(child: Icon(Icons.arrow_left)),
                          ),
                        ),
                      ),
                    ),
                  for (final (index, item) in _items.indexed)
                    Positioned(
                      right: 0,
                      top: (index) * 40.0,
                      child: AnimatedOpacity(
                        opacity: _itemScrollControllers.values.isNotEmpty &&
                                _itemScrollControllers.values.first.offset <
                                    (_dayWidth *
                                            item.start
                                                .difference(_days.first)
                                                .inDays
                                                .toDouble() -
                                        constraints.maxWidth)
                            ? 1
                            : 0,
                        duration: const Duration(milliseconds: 200),
                        child: GestureDetector(
                          onTap: () {
                            _controllers.jumpTo(item.start
                                    .difference(_days.first)
                                    .inDays
                                    .toDouble() *
                                _dayWidth);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            height: 36,
                            child: const Center(child: Icon(Icons.arrow_right)),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GanttItemRender extends StatefulWidget {
  const GanttItemRender({
    super.key,
    required List<DateTime> days,
    required this.item,
  }) : _days = days;

  final List<DateTime> _days;
  final GanttItem item;

  @override
  State<GanttItemRender> createState() => _GanttItemRenderState();
}

class _GanttItemRenderState extends State<GanttItemRender> {
  DragStartDetails? _dragStartDetails;

  late GanttItem _item = widget.item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (_dayWidth * widget._days.length).toDouble(),
      child: Stack(
        children: [
          Positioned(
            left: _dayWidth *
                widget._days
                    .indexWhere((d) => d.isSameDay(_item.start))
                    .toDouble(),
            top: 0,
            width: _dayWidth * (_item.end.difference(_item.start).inDays + 1),
            height: _itemHeight.toDouble(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                children: [
                  Text(
                    _item.title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          // Left draggable line to expand to left
          Positioned(
            left: _dayWidth *
                widget._days
                    .indexWhere((d) => d.isSameDay(_item.start))
                    .toDouble(),
            top: 0,
            width: 3,
            height: _itemHeight.toDouble(),
            child: GestureDetector(
              onHorizontalDragStart: (details) => _dragStartDetails = details,
              onHorizontalDragUpdate: (details) {
                if (_dragStartDetails != null) {
                  final dx = details.globalPosition.dx -
                      _dragStartDetails!.globalPosition.dx;
                  final days = (dx / _dayWidth).round();

                  final newStart = widget.item.start.add(Duration(days: days));
                  if (newStart
                      .isBefore(widget.item.end.add(const Duration(days: 1)))) {
                    setState(() => _item = _item.copyWith(start: newStart));
                  }
                }
              },
              onHorizontalDragEnd: (_) =>
                  setState(() => _dragStartDetails = null),
              child: const ExpandableIndicator(),
            ),
          ),
          // Right draggable to expand to the right
          Positioned(
            left: _dayWidth *
                    widget._days
                        .indexWhere((d) => d.isSameDay(_item.end))
                        .toDouble() +
                _dayWidth -
                3,
            top: 0,
            width: 3,
            height: _itemHeight.toDouble(),
            child: GestureDetector(
              onHorizontalDragStart: (details) => _dragStartDetails = details,
              onHorizontalDragUpdate: (details) {
                if (_dragStartDetails != null) {
                  final dx = details.globalPosition.dx -
                      _dragStartDetails!.globalPosition.dx;
                  final days = (dx / _dayWidth).round();

                  final newEnd = widget.item.end.add(Duration(days: days));
                  if (newEnd.isAfter(
                      widget.item.start.subtract(const Duration(days: 1)))) {
                    setState(() => _item = _item.copyWith(end: newEnd));
                  }
                }
              },
              onHorizontalDragEnd: (_) =>
                  setState(() => _dragStartDetails = null),
              child: const ExpandableIndicator(),
            ),
          ),
        ],
      ),
    );
  }
}

class ExpandableIndicator extends StatefulWidget {
  const ExpandableIndicator({super.key});

  @override
  State<ExpandableIndicator> createState() => ExpandableIndicatorState();
}

class ExpandableIndicatorState extends State<ExpandableIndicator> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      onEnter: (event) => setState(() => _isHovered = true),
      onExit: (event) => setState(() => _isHovered = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isHovered ? 1 : 0,
        child: Center(
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

typedef DayBuilder = Widget Function(BuildContext context, DateTime today);

class _DefaultDayWidget extends StatelessWidget {
  const _DefaultDayWidget({required this.date, required this.today});

  final DateTime date;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 25,
      width: 25,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: today.isSameDay(date) ? Colors.orange : Colors.transparent,
      ),
      child: Center(
        child: Text(
          date.day.toString(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: today.isSameDay(date) ? Colors.white : Colors.grey,
              ),
        ),
      ),
    );
  }
}

extension SameDay on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

class GanttItem {
  GanttItem({
    required this.id,
    required this.start,
    required this.end,
    required this.title,
  });

  final String id;
  final DateTime start;
  final DateTime end;
  final String title;

  GanttItem copyWith({
    DateTime? start,
    DateTime? end,
    String? title,
  }) {
    return GanttItem(
      id: id,
      start: start ?? this.start,
      end: end ?? this.end,
      title: title ?? this.title,
    );
  }
}

typedef HeaderBuilder = Widget Function(
  BuildContext context,
  ToTodayCallback goToToday,
);

typedef ToTodayCallback = VoidCallback;

class _DefaultHeader extends StatelessWidget {
  const _DefaultHeader({
    required this.goToToday,
  });

  final ToTodayCallback goToToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        GestureDetector(
          onTap: goToToday,
          child: const Text('Today'),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
