import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import '../bloc/base_bloc.dart';
import '../bloc/base_state.dart';
import '../bloc/editor_bloc.dart';
import '../factory/widget_factory.dart';
import '../model/node_spec.dart';
import '../util/extensions.dart';
import '../util/parser.dart';
import '../util/strings.dart';
import 'lowder.dart';
import 'screen.dart';

/// A ListView Widget using a `ListBloc` to handle page loads.
class BlocList extends BlocListBase {
  BlocList(super.spec, super.state, super.evaluatorContext, {super.key});

  Map? get childSpec => widgets["child"];

  @override
  Widget buildList(BuildContext context) {
    var count = mutable.lastState.fullData.length;
    if (mutable.lastState.hasMore) count++;

    Function? selectFunction;
    if (!EditorBloc.editMode) {
      selectFunction = Lowder.actions.getValueFunction(
          context, actions["onSelect"], state, evaluatorContext);
    }

    final axis = spec.buildProp("scrollDirection") ?? Axis.vertical;
    Widget? separatorWidget = Lowder.widgets
        .tryBuildWidget(context, widgets["separator"], state, null);

    return ListView(
      key: Key("${id}_list"),
      padding: Lowder.properties.getInsets(spec.props["padding"]),
      shrinkWrap: parseBool(props["shrinkWrap"]),
      reverse: parseBool(props["reverse"]),
      primary: tryParseBool(props["primary"]),
      controller: controller,
      scrollDirection: axis,
      semanticChildCount: count,
      keyboardDismissBehavior: spec.buildProp("keyboardDismissBehavior") ??
          ScrollViewKeyboardDismissBehavior.manual,
      children: List.generate(count, (i) {
        if (mutable.lastState.hasMore && i == count - 1) {
          return getLoadingIndicator();
        }

        var itemWidget = buildWidget(context, childSpec!, i);
        if (selectFunction != null) {
          itemWidget = InkWell(
            child: itemWidget,
            onTap: () => selectFunction!(mutable.lastState.fullData[i]),
          );
        }
        if (separatorWidget != null && i < count - 1) {
          final children = [itemWidget, separatorWidget];
          itemWidget = axis == Axis.vertical
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children)
              : Row(children: children);
        }
        return itemWidget;
      }),
    );
  }
}

class AnimatedBlocList extends BlocListBase {
  AnimatedBlocList(super.spec, super.state, super.evaluatorContext,
      {super.key});

  Map? get childSpec => widgets["child"];

  @override
  Widget buildList(BuildContext context) {
    var count = mutable.lastState.fullData.length;
    if (mutable.lastState.hasMore) count++;

    Function? selectFunction;
    if (!EditorBloc.editMode) {
      selectFunction = Lowder.actions.getValueFunction(
          context, actions["onSelect"], state, evaluatorContext);
    }

    final axis = spec.buildProp("scrollDirection") ?? Axis.vertical;
    Widget? separatorWidget = Lowder.widgets
        .tryBuildWidget(context, widgets["separator"], state, null);

    // ReorderableListView.builder

    return AnimatedList(
      key: Key("${id}_list"),
      padding: Lowder.properties.getInsets(spec.props["padding"]),
      shrinkWrap: parseBool(props["shrinkWrap"]),
      reverse: parseBool(props["reverse"]),
      primary: tryParseBool(props["primary"]),
      controller: controller,
      scrollDirection: axis,
      initialItemCount: count,
      itemBuilder: (context, i, animation) {
        if (mutable.lastState.hasMore && i == count - 1) {
          return getLoadingIndicator();
        }

        var itemWidget = buildWidget(context, childSpec!, i);
        if (selectFunction != null) {
          itemWidget = InkWell(
            child: itemWidget,
            onTap: () => selectFunction!(mutable.lastState.fullData[i]),
          );
        }
        if (separatorWidget != null && i < count - 1) {
          final children = [itemWidget, separatorWidget];
          itemWidget = axis == Axis.vertical
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children)
              : Row(children: children);
        }
        return FadeTransition(
          opacity: animation,
          child: itemWidget,
        );
      },
    );
  }
}

/// A Grid Widget using a `ListBloc` to handle page loads.
class BlocGrid extends BlocListBase {
  BlocGrid(super.spec, super.state, super.evaluatorContext, {super.key});

  Map? get childSpec => widgets["child"];

  @override
  Widget buildList(BuildContext context) {
    var count = mutable.lastState.fullData.length;
    if (mutable.lastState.hasMore) count++;

    Function? selectFunction;
    if (!EditorBloc.editMode) {
      selectFunction = Lowder.actions.getValueFunction(
          context, actions["onSelect"], state, evaluatorContext);
    }

    return GridView.count(
      key: Key("${id}_list"),
      controller: controller,
      crossAxisCount: spec.buildProp("crossAxisCount") ?? 1,
      mainAxisSpacing: parseDouble(props["mainAxisSpacing"]),
      crossAxisSpacing: parseDouble(props["crossAxisSpacing"]),
      childAspectRatio:
          parseDouble(props["childAspectRatio"], defaultValue: 1.0),
      scrollDirection: spec.buildProp("scrollDirection") ?? Axis.vertical,
      reverse: parseBool(props["reverse"]),
      shrinkWrap: parseBool(props["shrinkWrap"]),
      padding: Lowder.properties.getInsets(spec.props["padding"]),
      primary: tryParseBool(props["primary"]),
      keyboardDismissBehavior: spec.buildProp("keyboardDismissBehavior") ??
          ScrollViewKeyboardDismissBehavior.manual,
      semanticChildCount: count,
      children: List.generate(count, (i) {
        if (mutable.lastState.hasMore && i == count - 1) {
          return getLoadingIndicator();
        }

        var itemWidget = buildWidget(context, childSpec!, i);
        if (selectFunction != null) {
          itemWidget = InkWell(
            child: itemWidget,
            onTap: () => selectFunction!(mutable.lastState.fullData[i]),
          );
        }
        return itemWidget;
      }),
    );
  }
}

/// A PageView Widget using a `ListBloc` to handle page loads.
class BlocPageView extends BlocListBase {
  late final PageController pageController;

  BlocPageView(super.spec, super.state, super.evaluatorContext, {super.key}) {
    pageController = PageController(
      initialPage: parseInt(props["initialPage"]),
      viewportFraction:
          parseDouble(props["viewportFraction"], defaultValue: 1.0),
      keepPage: parseBool(props["keepPage"], defaultValue: true),
    );
  }

  Map? get childSpec => widgets["child"];

  void onPageChanged(int page, int count) {
    if (mutable.lastState.hasMore && page == count - 1) {
      mutable.loadingPage = true;
      loadPage();
    }
  }

  @override
  Widget buildList(BuildContext context) {
    var count = mutable.lastState.fullData.length;
    if (mutable.lastState.hasMore) count++;

    Function? selectFunction;
    Function? pageChangeFunction;
    if (!EditorBloc.editMode) {
      selectFunction = Lowder.actions.getValueFunction(
          context, actions["onSelect"], state, evaluatorContext);
      pageChangeFunction = Lowder.actions.getValueFunction<int?>(
          context, actions["onPageChanged"], state, evaluatorContext);
    }

    return PageView(
      key: Key("${id}_list"),
      pageSnapping: parseBool(props["pageSnapping"], defaultValue: true),
      padEnds: parseBool(props["padEnds"], defaultValue: true),
      scrollDirection: spec.buildProp("scrollDirection") ?? Axis.horizontal,
      reverse: parseBool(props["reverse"]),
      controller: pageController,
      onPageChanged: (idx) {
        onPageChanged(idx, count);
        if (pageChangeFunction != null) {
          pageChangeFunction(idx);
        }
      },
      children: List.generate(count, (i) {
        if (mutable.lastState.hasMore && i == count - 1) {
          return getLoadingIndicator();
        }

        var itemWidget = buildWidget(context, childSpec!, i);
        if (selectFunction != null) {
          itemWidget = InkWell(
            child: itemWidget,
            onTap: () => selectFunction!(mutable.lastState.fullData[i]),
          );
        }
        return itemWidget;
      }),
    );
  }
}

/// A Table Widget using a `ListBloc` to handle page loads.
class BlocTable extends BlocListBase {
  BlocTable(super.spec, super.state, super.evaluatorContext, {super.key});

  @override
  Widget buildList(BuildContext context) {
    final decoration = spec.buildProp("rowDecoration");
    final oddDecoration = spec.buildProp("rowOddDecoration") ?? decoration;

    final tableRows = <TableRow>[];
    for (var i = 0; i < mutable.lastState.fullData.length; i++) {
      tableRows.add(buildTableRow(
        context,
        mutable.lastState.fullData[i],
        i.isEven ? decoration : oddDecoration,
        i,
      ));
    }

    final table = Table(
      key: Key("${id}_list"),
      border: spec.buildProp("border"),
      textBaseline: spec.buildProp("textBaseline"),
      defaultVerticalAlignment:
          spec.buildProp("verticalAlignment") ?? TableCellVerticalAlignment.top,
      children: tableRows,
    );

    if (parseBool(props["shrinkWrap"])) {
      return table;
    } else {
      return SingleChildScrollView(
        controller: controller,
        child: table,
      );
    }
  }

  TableRow buildTableRow(
      BuildContext context, Map entry, Decoration? decoration, int i) {
    final children = <Widget>[];
    for (Map childSpec in widgets["children"]) {
      final child = buildWidget(context, childSpec, i);
      children.add(child);
    }

    return TableRow(
      decoration: decoration,
      children: children,
    );
  }
}

/// A DataTable Widget using a `ListBloc` to handle page loads.
class BlocDataTable extends BlocListBase {
  final sortState = {};

  BlocDataTable(super.spec, super.state, super.evaluatorContext, {super.key});

  @override
  Widget buildList(BuildContext context) {
    final alias = props["alias"] ?? id;
    state["${alias}_sort"] = sortState;
    if (!state.containsKey(alias)) {
      state[alias] = <Map>[];
    }

    Widget widget = StatefulBuilder(
        builder: (context, setState) => buildDataTable(context, setState));

    if (parseBool(props["shrinkWrap"])) {
      return widget;
    } else {
      return SingleChildScrollView(
        controller: controller,
        child: widget,
      );
    }
  }

  DataTable buildDataTable(BuildContext context, StateSetter setState) {
    Function? selectFunction;
    if (!EditorBloc.editMode) {
      selectFunction = Lowder.actions.getValueFunction<Map>(
          context, actions["onSelect"], state, evaluatorContext);
    }

    final alias = props["alias"] ?? id;
    final selectionType = props["selectionType"];
    final multiSelect = selectionType == "multiple";
    final selectable = multiSelect || selectionType == "single";
    final dataRowColor = tryParseColor(props["dataRowColor"]);
    final headingRowColor = tryParseColor(props["headingRowColor"]);

    return DataTable(
      key: Key("${id}_list"),
      showCheckboxColumn: selectable,
      decoration: spec.buildProp("decoration"),
      border: spec.buildProp("border"),
      dividerThickness: tryParseDouble(props["dividerThickness"]),
      columnSpacing: tryParseDouble(props["columnSpacing"]),
      checkboxHorizontalMargin:
          tryParseDouble(props["checkboxHorizontalMargin"]),
      horizontalMargin: tryParseDouble(props["horizontalMargin"]),
      showBottomBorder: parseBool(props["showBottomBorder"]),
      headingRowColor: headingRowColor != null
          ? WidgetStateColor.resolveWith((states) => headingRowColor)
          : null,
      headingRowHeight: tryParseDouble(props["headingRowHeight"]),
      headingTextStyle: spec.buildProp("headingTextStyle"),
      dataRowColor: dataRowColor != null
          ? WidgetStateColor.resolveWith((states) => dataRowColor)
          : null,
      dataRowMinHeight: tryParseDouble(props["dataRowHeight"]),
      dataRowMaxHeight: tryParseDouble(props["dataRowHeight"]),
      dataTextStyle: spec.buildProp("dataTextStyle"),
      onSelectAll: !multiSelect
          ? null
          : (val) => setState(() {
                state[alias].clear();
                if (val == true) {
                  state[alias].addAll(mutable.lastState.fullData);
                }
              }),
      sortColumnIndex: sortState["idx"],
      sortAscending: parseBool(sortState["asc"], defaultValue: true),
      columns: buildDataColumns(context, setState),
      rows: List<DataRow>.generate(
        mutable.lastState.fullData.length,
        (idx) => buildDataRow(
            context, idx, state[alias], multiSelect, selectFunction, setState),
      ),
    );
  }

  DataRow buildDataRow(BuildContext context, int idx, List<Map> selectionList,
      bool multiSelect, Function? selectFunction, StateSetter setState) {
    final entry = mutable.lastState.fullData[idx];
    final rowColor = tryParseColor(props["rowColor"]);
    final rowOddColor = tryParseColor(props["rowOddColor"]) ?? rowColor;
    final color = idx.isEven ? rowColor : rowOddColor;

    return DataRow(
      color: color != null
          ? WidgetStateColor.resolveWith((states) => color)
          : null,
      selected: selectionList.contains(entry),
      cells: buildDataCells(context, idx),
      onSelectChanged: (val) => setState(() {
        if (!multiSelect) {
          selectionList.clear();
        }
        if (val == true) {
          selectionList.add(entry);
        } else {
          selectionList.remove(entry);
        }
        if (selectFunction != null) {
          selectFunction(entry);
        }
      }),
    );
  }

  List<DataCell> buildDataCells(BuildContext context, int idx) {
    final cells = <DataCell>[];
    final childrenSpec = widgets["children"];
    for (var childSpec in childrenSpec) {
      var widget = buildWidget(context, childSpec, idx);
      if (widget is! NoWidget) {
        cells.add(DataCell(widget));
      }
    }
    return cells;
  }

  List<DataColumn> buildDataColumns(
      BuildContext context, StateSetter setState) {
    final columns = <DataColumn>[];
    final columnsSpec = widgets["columns"];
    final childrenSpec = widgets["children"];
    final sortable = parseBool(props["sortable"]);

    if (columnsSpec != null && columnsSpec.length == childrenSpec?.length) {
      for (var childSpec in columnsSpec) {
        final widget =
            Lowder.widgets.buildWidget(context, childSpec, state, null);
        if (widget is! NoWidget) {
          columns.add(
              buildDataColumn(context, childSpec, sortable, setState, widget));
        }
      }
    } else {
      for (var childSpec in childrenSpec) {
        columns
            .add(buildDataColumn(context, childSpec, sortable, setState, null));
      }
    }
    return columns;
  }

  DataColumn buildDataColumn(BuildContext context, Map spec, bool sortable,
      StateSetter setState, Widget? labelWidget) {
    final props = spec["properties"] ?? {};
    final label = props["label"] ?? spec["name"] ?? "";
    final specAlias = props["alias"] ?? label;
    TableColumnWidth? columnWidth;

    if (labelWidget is DataColumn) {
      return labelWidget as DataColumn;
    }
    if (labelWidget is Container &&
        (labelWidget.constraints?.maxWidth ?? 0) > 0) {
      columnWidth = FixedColumnWidth(labelWidget.constraints!.maxWidth);
    }

    return DataColumn(
      columnWidth: columnWidth,
      label: labelWidget ?? Text(Lowder.properties.getText(label, "title")),
      numeric: parseBool(props["numeric"]),
      tooltip: props["tooltip"],
      onSort: !parseBool(props["sortable"], defaultValue: sortable)
          ? null
          : (idx, asc) => setState(() {
                sortState["idx"] = idx;
                sortState["key"] = specAlias;
                sortState["asc"] = asc;
                sortState["ascKey"] = asc ? specAlias : null;
                sortState["descKey"] = asc ? null : specAlias;
                loadPage(page: 1);
              }),
    );
  }
}

/// The base class for using `ListBloc` to handle page loads.
abstract class BlocListBase extends StatefulWidget {
  static final Map<String, KListMutable> _listState = {};
  final log = Logger("BlocList");
  final Map state;
  final Map? evaluatorContext;
  final WidgetNodeSpec spec;
  final controller = ScrollController();

  BlocListBase(this.spec, this.state, this.evaluatorContext, {super.key}) {
    controller.addListener(scrollListener);
  }

  String get id => spec.id;
  Map get props => spec.props;
  Map get actions => spec.actions;
  Map get widgets => spec.widgets;
  Map? get loadPageSpec => actions["loadPage"];

  KListMutable get mutable {
    // Upon setState ocurrencies, multiple instances of the same list may exist.
    // We're keeping a static reference to the List's state so the transition between
    // instances can be smoother.
    if (!_listState.containsKey(id)) {
      _listState[id] = KListMutable();
    }
    _listState[id]!.timer?.cancel();
    return _listState[id]!;
  }

  ListBloc get bloc {
    if (mutable.bloc == null || mutable.bloc!.isClosed) {
      mutable.bloc = createBloc();
    }
    return mutable.bloc!;
  }

  @override
  State<StatefulWidget> createState() {
    return BlocListState();
  }

  @protected
  ListBloc createBloc() {
    return Lowder.actions.createListBloc();
  }

  scrollListener() {
    if (!mutable.lastState.hasMore) return;
    if (!mutable.loadingPage &&
        controller.position.maxScrollExtent == controller.offset) {
      mutable.loadingPage = true;
      loadPage();
    }
  }

  loadPage({int? page}) {
    if (mutable.blocContext == null) {
      log.warning(
          "Context not yet initialized while loading page '$page' on '${spec.name ?? spec.id}'.");
      return;
    }

    page ??= mutable.lastState.page + 1;
    final data = page == 1 ? [] : mutable.lastState.fullData;

    log.infoWithContext("Loading list data", loadPageSpec);

    Lowder.actions.executePageLoadAction(
      mutable.blocContext!,
      bloc,
      page,
      50,
      data,
      loadPageSpec!.clone(),
      state,
      evaluatorContext,
    );
  }

  Widget buildList(BuildContext context);

  Widget buildWidget(BuildContext context, Map widgetSpec, int i) {
    // To keep Widget Keys unique:
    final specClone = widgetSpec.clone();
    specClone["_id"] = "${widgetSpec["_id"]}_$i";

    // 'entry' keys must exist in the state in order for the 'alias' property to work
    final entry = mutable.lastState.fullData[i];
    final stateClone = state.clone();
    if (entry is Map) {
      stateClone.addAll(entry);
    }

    return Lowder.widgets.buildWidget(context, specClone, stateClone,
        {"entry": entry, "idx": i, "parent": state});
  }

  Widget getLoadingIndicator() {
    var loadingIndicatorSpec = props["loadingIndicator"] ?? {};
    return Center(
      child: Padding(
          padding: const EdgeInsets.all(10),
          child: CircularProgressIndicator(
            color: tryParseColor(loadingIndicatorSpec["color"]),
            backgroundColor:
                tryParseColor(loadingIndicatorSpec["backgroundColor"]),
            strokeWidth: parseDouble(loadingIndicatorSpec["strokeWidth"],
                defaultValue: 4.0),
          )),
    );
  }

  Widget getNoEntriesWidget(BuildContext context) {
    var noEntriesWidget = Lowder.widgets
        .tryBuildWidget(context, widgets["noEntriesWidget"], state, null);
    if (noEntriesWidget == null) {
      var message = Strings.getCapitalized(
          props["noEntriesMessage"] ?? "no_entries_message");
      noEntriesWidget = Text(message, style: spec.buildProp("noEntriesStyle"));
      noEntriesWidget = Center(
          child: Padding(
              padding: const EdgeInsets.all(10), child: noEntriesWidget));
    }
    return noEntriesWidget;
  }

  void dispose() {
    controller.removeListener(scrollListener);
    // Upon setState ocurrencies, multiple instances of the same list may exist.
    // We're delaying the disposal so a new instance can cancel it and use the same state
    // so the transition between instances can be smoother.
    mutable.timer = Timer(const Duration(milliseconds: 100), () {
      mutable.dispose();
      _listState.remove(id);
    });
  }
}

class BlocListState extends State<BlocListBase> {
  StreamSubscription<void>? reloadListener;

  @override
  Widget build(BuildContext context) {
    if (widget.widgets.isEmpty || widget.loadPageSpec == null) {
      return const Center(child: Text("No child provided."));
    }

    reloadListener ??= LowderScreen.of(context)
        ?.reload
        .listen((_) => widget.loadPage(page: 1));

    final listBuilder = BlocBuilder<ListBloc, BaseState>(
      key: Key("${widget.id}_blocBuilder"),
      bloc: widget.bloc,
      buildWhen: (prev, next) {
        return prev != next &&
            (next is InitialState || next is PageLoadedState);
      },
      builder: (context, state) {
        final mutable = widget.mutable;
        mutable.blocContext = context;
        if (state is PageLoadedState) {
          mutable.loadingPage = false;
          if (state.fullData.isEmpty) {
            return widget.getNoEntriesWidget(context);
          }
          mutable.lastState = state;
          return widget.buildList(context);
        } else if (state is InitialState) {
          widget.loadPage(page: 1);
          if (mutable.lastState.fullData.isNotEmpty) {
            return widget.buildList(context);
          }
        }
        return widget.getLoadingIndicator();
      },
    );

    final globalBuilder = BlocListener<GlobalBloc, BaseState>(
      key: Key("${widget.id}_global"),
      listenWhen: (prev, next) =>
          prev != next && next is ReloadListState && next.listId == widget.id,
      listener: (context, state) {
        if (state is ReloadListState) {
          widget.log
              .info("Reloading List '${widget.spec.name ?? widget.spec.id}'.");
          widget.loadPage(page: 1);
        }
      },
      child: listBuilder,
    );

    return BlocProvider(
      key: Key("${widget.id}_blocProvider"),
      create: (context) => widget.bloc,
      lazy: false,
      child: globalBuilder,
    );
  }

  @override
  void dispose() {
    widget.dispose();
    reloadListener?.cancel();
    super.dispose();
  }
}

class KListMutable {
  ListBloc? bloc;
  BuildContext? blocContext;
  bool loadingPage = false;
  PageLoadedState lastState = PageLoadedState(0, [], true);
  Timer? timer;

  void dispose() {
    bloc = null;
    blocContext = null;
    lastState = PageLoadedState(0, [], true);
    timer = null;
  }
}
