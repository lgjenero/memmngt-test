import 'package:flutter/material.dart';
import 'package:memmngt/model.dart';

import 'context.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Deinit demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _step = 14;

  late Model a;
  late Model b;
  late Model c;
  late Model d;
  late Model e;
  late Model f;
  late Model g;
  late Model h;
  late Model i;

  final List<Model> objects = [];

  String status = '';

  @override
  void initState() {
    super.initState();
    _initModels();
  }

  void _initModels() {
    a = Model('a', () => Future.delayed(const Duration(milliseconds: 100)), () => null);
    b = Model('b', () => Future.delayed(const Duration(milliseconds: 100)), () => null);
    c = Model('c', () => Future.delayed(const Duration(milliseconds: 100)), () => null);
    d = Model('d', () => Future.delayed(const Duration(milliseconds: 100)), () => null);
    e = Model('e', () => Future.delayed(const Duration(milliseconds: 100)), () => null);
    f = Model('f', () => Future.delayed(const Duration(milliseconds: 100)), () => null);
    g = Model('g', () => Future.delayed(const Duration(milliseconds: 100)), () => null);
    h = Model('h', () => Future.delayed(const Duration(milliseconds: 100)), () => null);
    i = Model('i', () => Future.delayed(const Duration(milliseconds: 100)), () => null);

    a.addChildren([b]);
    b.addChildren([c]);
    c.addChildren([a]);
    d.addChildren([b]);
    e.addChildren([c]);
    f.addChildren([e]);
    g.addChildren([h]);
    h.addChildren([i, d]);
    i.addChildren([g]);

    objects.clear();
    objects.addAll([a, b, c, d, e, f, g, h, i]);
  }

  void _nextStep() async {
    // final currentContext = tryGetContext<ModelContext>();
    // print('currentContext --> $currentContext');

    switch (_step) {
      case 0:
        await a.init();
        break;
      case 1:
        await a.deInit();
        break;
      case 2:
        _initModels();
        await a.init();
        await d.init();
        break;
      case 3:
        await d.deInit();
        break;
      case 4:
        await a.deInit();
        break;
      case 5:
        _initModels();
        await a.init();
        await d.init();
        break;
      case 6:
        await a.deInit();
        break;
      case 7:
        await d.deInit();
        break;
      case 8:
        _initModels();
        await a.init();
        await f.init();
        break;
      case 9:
        await f.deInit();
        break;
      case 10:
        await a.deInit();
        break;
      case 11:
        _initModels();
        await a.init();
        await f.init();
        break;
      case 12:
        await a.deInit();
        break;
      case 13:
        await f.deInit();
        break;
      case 14:
        _initModels();
        await a.init();
        await g.init();
        break;
      case 15:
        await g.deInit();
        break;
      case 16:
        await a.deInit();
        break;
      case 17:
        _initModels();
        await a.init();
        await g.init();
        break;
      case 18:
        await a.deInit();
        break;
      case 19:
        await g.deInit();
        break;
    }

    _step++;

    _printRefCounts(objects);
  }

  void _printRefCounts(List<Model> models) {
    String status = '';
    for (final model in models) {
      status +=
          '${model.id} --> refCount: ${model.initCount} | refs: ${model.referencing} | childs: ${model.children}\n';
    }
    setState(() {
      this.status = status;
    });
  }

  String get _stateString {
    switch (_step) {
      case 1:
        return 'A initilised';
      case 2:
        return 'A de-initilised';
      case 3:
        return 'A and D initilised';
      case 4:
        return 'A initialised and D de-initilised';
      case 5:
        return 'A and D de-initilised';
      case 6:
        return 'A and D initilised';
      case 7:
        return 'A de-initialised and D initilised';
      case 8:
        return 'A and D de-initilised';
      case 9:
        return 'A and F initilised';
      case 10:
        return 'A initialised and F de-initilised';
      case 11:
        return 'A and F de-initilised';
      case 12:
        return 'A and F initilised';
      case 13:
        return 'A de-initialised and F initilised';
      case 14:
        return 'A and F de-initilised';
      case 15:
        return 'A and G initilised';
      case 16:
        return 'A initialised and G de-initilised';
      case 17:
        return 'A and G de-initilised';
      case 18:
        return 'A and g initilised';
      case 19:
        return 'A de-initialised and G initilised';
      case 20:
        return 'A and G de-initilised';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text('Status:\n$_stateString'),
            const SizedBox(height: 10),
            Text(status),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _nextStep,
        tooltip: 'Next Step',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
