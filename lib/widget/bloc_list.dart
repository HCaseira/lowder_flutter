import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/base_bloc.dart';
import '../bloc/base_state.dart';
import '../bloc/editor_bloc.dart';
import '../model/k_node.dart';
import '../util/extensions.dart';
import '../util/parser.dart';
import '../util/strings.dart';
import 'lowder.dart';

class BlocList extends BlocListBase {
  BlocList(super.spec, super.state, super.evaluatorContext, {super.key});

  Map? get childSpec => widgets["child"];

  @override
  Widget buildList(BuildContext context) {
    var count = mutable.lastState.fullData.length;
    if (mutable.lastState.hasMore) count++;

    Function? selectFunction;
    if (!EditorBloc.editMode) {
      selectFunction = Lowder.actions.getValueFunction(context, actions["onSelect"], state, evaluatorContext);
    }

    final axis = spec.buildProp("scrollDirection") ?? Axis.vertical;
    Widget? separatorWidget = Lowder.widgets.tryBuildWidget(context, widgets["separator"], state, null);

    return ListView(
      key: Lowder.properties.getKey(id),
      padding: Lowder.properties.getInsets(spec.props["padding"]),
      shrinkWrap: parseBool(props["shrinkWrap"]),
      reverse: parseBool(props["reverse"]),
      primary: tryParseBool(props["primary"]),
      controller: controller,
      scrollDirection: axis,
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
        if (separatorWidget != null && i < count - 1) {
          final children = [itemWidget, separatorWidget];
          itemWidget = axis == Axis.vertical
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)
              : Row(children: children);
        }
        return itemWidget;
      }),
    );
  }
}

class BlocGrid extends BlocListBase {
  BlocGrid(super.spec, super.state, super.evaluatorContext, {super.key});

  Map? get childSpec => widgets["child"];

  @override
  Widget buildList(BuildContext context) {
    var count = mutable.lastState.fullData.length;
    if (mutable.lastState.hasMore) count++;

    Function? selectFunction;
    if (!EditorBloc.editMode) {
      selectFunction = Lowder.actions.getValueFunction(context, actions["onSelect"], state, evaluatorContext);
    }

    return GridView.count(
      key: Lowder.properties.getKey(id),
      controller: controller,
      crossAxisCount: spec.buildProp("crossAxisCount") ?? 1,
      mainAxisSpacing: parseDouble(props["mainAxisSpacing"]),
      crossAxisSpacing: parseDouble(props["crossAxisSpacing"]),
      childAspectRatio: parseDouble(props["childAspectRatio"], defaultValue: 1.0),
      scrollDirection: spec.buildProp("scrollDirection") ?? Axis.vertical,
      reverse: parseBool(props["reverse"]),
      shrinkWrap: parseBool(props["shrinkWrap"]),
      padding: Lowder.properties.getInsets(spec.props["padding"]),
      primary: tryParseBool(props["primary"]),
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

class BlocPageView extends BlocListBase {
  BlocPageView(super.spec, super.state, super.evaluatorContext, {super.key});

  Map? get childSpec => widgets["child"];

  @override
  Widget buildList(BuildContext context) {
    var count = mutable.lastState.fullData.length;
    if (mutable.lastState.hasMore) count++;

    Function? selectFunction;
    Function? pageChangeFunction;
    if (!EditorBloc.editMode) {
      selectFunction = Lowder.actions.getValueFunction(context, actions["onSelect"], state, evaluatorContext);
      pageChangeFunction = Lowder.actions.getValueFunction<int?>(context, actions["onPageChanged"], state, evaluatorContext);
    }

    return PageView(
      key: Lowder.properties.getKey(id),
      pageSnapping: parseBool(props["pageSnapping"], defaultValue: true),
      padEnds: parseBool(props["padEnds"], defaultValue: true),
      scrollDirection: spec.buildProp("scrollDirection") ?? Axis.horizontal,
      reverse: parseBool(props["reverse"]),
      controller: PageController(
        initialPage: parseInt(props["initialPage"]),
        viewportFraction: parseDouble(props["viewportFraction"], defaultValue: 1.0),
        keepPage: parseBool(props["keepPage"], defaultValue: true),
      ),
      onPageChanged: (idx) {
        if (mutable.lastState.hasMore && idx == count - 1) {
          mutable.loadingPage = true;
          loadPage();
        }
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
      key: Lowder.properties.getKey(id),
      border: spec.buildProp("border"),
      textBaseline: spec.buildProp("textBaseline"),
      defaultVerticalAlignment: spec.buildProp("verticalAlignment") ?? TableCellVerticalAlignment.top,
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

  TableRow buildTableRow(BuildContext context, Map entry, Decoration? decoration, int i) {
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

    Widget widget = StatefulBuilder(builder: (context, setState) => buildDataTable(context, setState));

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
      selectFunction = Lowder.actions.getValueFunction<Map>(context, actions["onSelect"], state, evaluatorContext);
    }

    final alias = props["alias"] ?? id;
    final selectionType = props["selectionType"];
    final multiSelect = selectionType == "multiple";
    final selectable = multiSelect || selectionType == "single";
    final dataRowColor = tryParseColor(props["dataRowColor"]);
    final headingRowColor = tryParseColor(props["headingRowColor"]);

    return DataTable(
      key: Lowder.properties.getKey(id),
      showCheckboxColumn: selectable,
      decoration: spec.buildProp("decoration"),
      border: spec.buildProp("border"),
      dividerThickness: tryParseDouble(props["dividerThickness"]),
      columnSpacing: tryParseDouble(props["columnSpacing"]),
      checkboxHorizontalMargin: tryParseDouble(props["checkboxHorizontalMargin"]),
      horizontalMargin: tryParseDouble(props["horizontalMargin"]),
      showBottomBorder: parseBool(props["showBottomBorder"]),
      headingRowColor: headingRowColor != null ? MaterialStateColor.resolveWith((states) => headingRowColor) : null,
      headingRowHeight: tryParseDouble(props["headingRowHeight"]),
      headingTextStyle: spec.buildProp("headingTextStyle"),
      dataRowColor: dataRowColor != null ? MaterialStateColor.resolveWith((states) => dataRowColor) : null,
      dataRowMinHeight: tryParseDouble(props["dataRowHeight"]),
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
        (idx) => buildDataRow(context, idx, state[alias], multiSelect, selectFunction, setState),
      ),
    );
  }

  DataRow buildDataRow(BuildContext context, int idx, List<Map> selectionList, bool multiSelect, Function? selectFunction,
      StateSetter setState) {
    final entry = mutable.lastState.fullData[idx];
    final rowColor = tryParseColor(props["rowColor"]);
    final rowOddColor = tryParseColor(props["rowOddColor"]) ?? rowColor;
    final color = idx.isEven ? rowColor : rowOddColor;

    return DataRow(
      color: color != null ? MaterialStateColor.resolveWith((states) => color) : null,
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
      cells.add(DataCell(widget));
    }
    return cells;
  }

  List<DataColumn> buildDataColumns(BuildContext context, StateSetter setState) {
    final columns = <DataColumn>[];
    final columnsSpec = widgets["columns"];
    final childrenSpec = widgets["children"];
    final sortable = parseBool(props["sortable"]);

    if (columnsSpec != null && columnsSpec.length == childrenSpec?.length) {
      for (var childSpec in columnsSpec) {
        final widget = Lowder.widgets.buildWidget(context, childSpec, state, null);
        columns.add(buildDataColumn(context, childSpec, sortable, setState, widget));
      }
    } else {
      for (var childSpec in childrenSpec) {
        columns.add(buildDataColumn(context, childSpec, sortable, setState, null));
      }
    }
    return columns;
  }

  DataColumn buildDataColumn(BuildContext context, Map spec, bool sortable, StateSetter setState, Widget? labelWidget) {
    final props = spec["properties"] ?? {};
    final label = props["label"] ?? spec["name"] ?? "";
    final specAlias = props["alias"] ?? label;

    return DataColumn(
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

abstract class BlocListBase extends StatefulWidget {
  final Map state;
  final Map? evaluatorContext;
  final WidgetNodeSpec spec;
  final mutable = KListMutable();
  final controller = ScrollController();

  BlocListBase(this.spec, this.state, this.evaluatorContext, {super.key}) {
    controller.addListener(scrollListener);
  }

  String get id => spec.id;
  Map get props => spec.props;
  Map get actions => spec.actions;
  Map get widgets => spec.widgets;
  Map? get loadPageSpec => actions["loadPage"];

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
    if (!mutable.loadingPage && controller.position.maxScrollExtent == controller.offset) {
      mutable.loadingPage = true;
      loadPage();
    }
  }

  loadPage({int? page}) {
    page ??= mutable.lastState.page + 1;
    final data = page == 1 ? [] : mutable.lastState.fullData;

    Lowder.actions.executePageLoadAction(
      mutable.blocContext!,
      mutable.bloc!,
      page,
      50,
      data,
      loadPageSpec!,
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

    return Lowder.widgets.buildWidget(context, specClone, stateClone, {"entry": entry, "parent": state});
  }

  Widget getLoadingIndicator() {
    var loadingIndicatorSpec = props["loadingIndicator"] ?? {};
    return Center(
      child: Padding(
          padding: const EdgeInsets.all(10),
          child: CircularProgressIndicator(
            color: tryParseColor(loadingIndicatorSpec["color"]),
            backgroundColor: tryParseColor(loadingIndicatorSpec["backgroundColor"]),
            strokeWidth: parseDouble(loadingIndicatorSpec["strokeWidth"], defaultValue: 4.0),
          )),
    );
  }

  Widget getNoEntriesWidget(BuildContext context) {
    var noEntriesWidget = Lowder.widgets.tryBuildWidget(context, widgets["noEntriesWidget"], state, null);
    if (noEntriesWidget == null) {
      var message = Strings.getCapitalized(props["noEntriesMessage"] ?? "no_entries_message");
      noEntriesWidget = Text(message, style: spec.buildProp("noEntriesStyle"));
      noEntriesWidget = Center(child: Padding(padding: const EdgeInsets.all(10), child: noEntriesWidget));
    }
    return noEntriesWidget;
  }
}

class BlocListState extends State<BlocListBase> {
  ListBloc createBloc() {
    final bloc = widget.createBloc();
    widget.mutable.bloc = bloc;
    return bloc;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.widgets.isEmpty || widget.loadPageSpec == null) {
      return const Center(child: Text("No child provided."));
    }

    final listBuilder = BlocBuilder<ListBloc, BaseState>(
      buildWhen: (prev, next) {
        return prev != next && (next is InitialState || next is PageLoadedState);
      },
      builder: (context, state) {
        if (state is InitialState) {
          widget.mutable.blocContext = context;
          widget.loadPage(page: 1);
        } else if (state is PageLoadedState) {
          widget.mutable.loadingPage = false;
          if (state.fullData.isEmpty) {
            return widget.getNoEntriesWidget(context);
          }
          widget.mutable.lastState = state;
          return widget.buildList(context);
        }
        return widget.getLoadingIndicator();
      },
    );

    final globalBuilder = BlocBuilder<GlobalBloc, BaseState>(
      buildWhen: (prev, next) => prev != next && next is ReloadListState && next.listId == widget.id,
      builder: (context, state) => listBuilder,
    );

    return BlocProvider(create: (context) => createBloc(), child: globalBuilder);
  }

  @override
  void dispose() {
    widget.controller.removeListener(widget.scrollListener);
    super.dispose();
  }
}

class KListMutable {
  ListBloc? bloc;
  BuildContext? blocContext;
  bool loadingPage = false;
  PageLoadedState lastState = PageLoadedState(0, [], true);
}
