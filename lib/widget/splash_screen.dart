import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A demo splash screen used as the first Widget the app renders.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();

  Color getColor1(BuildContext context) => Theme.of(context).colorScheme.primary;
  Color getColor2(BuildContext context) => Theme.of(context).colorScheme.background;

  Widget getLogo(BuildContext context, Color foregroundColor, Color backgroundColor, int stage) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Directionality(textDirection: TextDirection.ltr, child: Icon(Icons.flutter_dash, color: foregroundColor, size: 128))
      ],
    );
  }

  Widget getActivityIndicator(BuildContext context, Color foregroundColor, Color backgroundColor) {
    return Center(child: CircularProgressIndicator(color: foregroundColor));
  }

  @protected
  Future<void> doWork() async {}

  @nonVirtual
  Future<void> onFinished(BuildContext context) async {
    await doWork();
    WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.of(context).maybePop());
  }
}

class SplashScreenState extends State<SplashScreen> {
  int stage = 0;

  @override
  void initState() {
    stage = 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final color1 = widget.getColor1(context);
    final color2 = widget.getColor2(context);
    var backgroundColor = color2;
    var foregroundColor = color1;
    Widget loader = Container();

    switch (stage) {
      case 0:
        backgroundColor = color1;
        foregroundColor = color2;
        Future.delayed(const Duration(milliseconds: 600), () => setState(() => stage++));
        break;
      case 1:
        Future.delayed(const Duration(milliseconds: 1500), () => setState(() => stage++));
        break;
      case 2:
        loader = widget.getActivityIndicator(context, foregroundColor, backgroundColor);
        Future.delayed(const Duration(milliseconds: 400), () async => await widget.onFinished(context));
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
              child: Hero(
                  tag: "splash_logo",
                  child: Material(
                      type: MaterialType.transparency,
                      child: widget.getLogo(context, foregroundColor, backgroundColor, stage)))),
          Expanded(child: loader),
        ],
      ),
    );
  }
}
