import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/editor_bloc.dart';
import '../bloc/editor_event.dart';
import '../bloc/editor_state.dart';

/// An utility Widget used when in `Lowder.editorMode`.
class EditWidget extends StatefulWidget {
  final String id;
  final Widget widget;

  const EditWidget(this.id, this.widget, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _EditWidget();
  }
}

class _EditWidget extends State<EditWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer(
      bloc: BlocProvider.of<EditorBloc>(context),
      // buildWhen: (prevState, currentState) {
      //   return currentState is SelectWidgetState && currentState.id == widget.id;
      // },
      builder: (context, state) {
        Widget child = widget.widget;
        if (state is SelectWidgetState && state.id == widget.id) {
          child = Container(
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                border: Border.all(
                  color: Color(int.parse("ffe5c519", radix: 16)),
                  // color: Color.fromARGB(125, 125, 125, 125),
                  width: 4,
                )),
            child: child,
          );
        }
        return GestureDetector(
          onTap: () => BlocProvider.of<EditorBloc>(context).add(SelectEvent(widget.id)),
          child: child,
        );
      },
      listener: (context, state) {},
    );
  }
}
