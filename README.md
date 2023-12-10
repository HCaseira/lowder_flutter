# Flutter Lowder

## What

Flutter Lowder is a lightweight low-code development tool for Flutter.
Using the `Lowder Editor`, build your app's `model`, which this plugin will interpret and execute.

## How

Lowder is composed of an `editor` and an `interpreter`, and both work with a `model` file.
The `editor` is a visual interface where you can create your app's UI and logic.
The `model` is a json file containing the objects created in the `editor`.
The `interpreter` (this package) is a set of classes to load and execute the `model`.

## Why

* Gui: visually build your app with ease. 

* Speed: quickly create a new screen, update a form or simply fix a typo.

* Less coding: code your custom widgets and business logic when needed and use the `editor` to do the rest.

* Updates over-the-air: as the `model` is a file, you can modify it and deploy it somewhere, where the app can download and load it.

## Usage

Let's get started:

Open a terminal window in a folder of your choosing.

Create a new flutter project using the `flutter create` command.
```sh
flutter create lowder_hello
```

Navigate to the newly created `lowder_hello` folder.
```sh
cd lowder_hello
```

Add this package to the project ([need help?](https://pub.dev/packages/lowder/install)).
```sh
flutter pub add lowder
```

Setup assets in your `pubspec.yaml` file.
```yaml
flutter:
  # The following line ensures that the Material Icons font is
  # included with your application, so that you can use the icons in
  # the material Icons class.
  uses-material-design: true

  # To add assets to your application, add an assets section, like this:
  assets:
    - assets/
  #   - images/a_dot_burr.jpeg
  #   - images/a_dot_ham.jpeg
```

Now open the `main.dart` file from the `lib` folder with your favorite editor and replace the whole content with:

```dart
import 'package:flutter/widgets.dart';
import 'package:lowder/widget/lowder.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends Lowder {
  MyApp() : super("My App");

  @override
  List<SolutionSpec> get solutions => [
        SolutionSpec(
          "Hello",
          filePath: "assets/hello.low",
        ),
      ];
}
```

And we're done.

Now let's start the Lowder `editor`, executing the following command from the terminal window:
```sh
dart run lowder
```
It may take a few seconds, for it has to build a web version of the app.
You'll see an output like this:
```sh
Compiling lib\main.dart for the Web...                             47,0s
Serving at http://0.0.0.0:8787
Open Editor at http://localhost:8787/editor.html
```
When ready, open a browser and go to `http://localhost:8787/editor.html`.

![](https://github.com/HCaseira/lowder_flutter/raw/main/repo_files/images/editor_0.png)

So that is the `Lowder Editor`. Here you'll create screens for your app.

Let's start by creating a new Screen.
![](https://github.com/HCaseira/lowder_flutter/raw/main/repo_files/images/editor_1.png)
Name it `Hello Screen` and click `Ok`.
![](https://github.com/HCaseira/lowder_flutter/raw/main/repo_files/images/editor_2.png)

Next, select the root Widget for the new Screen. Let's pick `Material`.
![](https://github.com/HCaseira/lowder_flutter/raw/main/repo_files/images/editor_3.png)

Now click on the `+` to add a child to `Material` Widget.
![](https://github.com/HCaseira/lowder_flutter/raw/main/repo_files/images/editor_4.png)

Let's pick a `Center` Widget.
![](https://github.com/HCaseira/lowder_flutter/raw/main/repo_files/images/editor_5.png)

And add `Text` Widget to our `Center` Widget.
![](https://github.com/HCaseira/lowder_flutter/raw/main/repo_files/images/editor_6.png)

Now, select the `Text` Widget and on the `property panel` type "Hello Lowder" on the `value` property.
![](https://github.com/HCaseira/lowder_flutter/raw/main/repo_files/images/editor_7.png)

Let's increase the font size by expanding the `Style` property and set the `FontSize` to 20.
![](https://github.com/HCaseira/lowder_flutter/raw/main/repo_files/images/editor_8.png)

And that's it for now.
Explore the `Editor`, create other screens, play around with properties and don't forget to `save`.
Build and run your project as you would on any other flutter project.

Check out [examples](https://github.com/HCaseira/lowder_flutter/blob/main/example) to learn more about `Flutter Lowder`.
Have fun and let me know your thoughts and suggestions.


## Additional notes

Using `Flutter Lowder` doesn't mean you won't code, far from it. It's intended to be a starting point for your project, where you will add your own Widgets and Actions as needed, to add to the Lowder's preset of Widgets and Actions.
It will make it easier and faster to implement screens, navigation and business logic, or simply fix a label or a typo.
It doesn't intend to dictate what you should use, so it comes with the fewest dependencies possible, and avoid dependency resolving issues. So if you want to (and you will) use other packages, simply extend Lowder and make new Widgets and Actions available.