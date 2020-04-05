import 'package:flutter/material.dart';
import 'package:flutter_common_utils/lcfarm_size.dart';
import 'package:flutterdialogmanager/sencond_page.dart';

import 'dialog_bean.dart';
import 'dialog_manager.dart';
import 'dialog_util.dart';
import 'my_navigator_observers.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [MyNavigatorObserver()],
      home: MyHomePage(title: 'Flutter Demo Home Page'),
      routes: {
        //这里不能传递参数
        SecondPage.routerName: (context) => SecondPage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    LcfarmSize.getInstance().init(context);
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
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Padding(
              padding:
                  const EdgeInsets.only(left: 10.0, top: 10.0, right: 10.0),
              child: new RaisedButton(
                  textColor: Colors.black,
                  child: new Text('多个弹窗按顺序弹出'),
                  onPressed: () {
                    DialogManager()
                      ..add(DialogBean(
                        dialogPriority: DialogPriority.high,
                        createDialogWidget: () =>
                            DialogUtil.createTipWidget(context, "测试弹窗\n 换行"),
                      ))
                      ..add(DialogBean(
                        createDialogWidget: () =>
                            DialogUtil.createTipWidget(context, "测试弹窗"),
                      ))
                      ..show(context);
                  }),
            ),
            new Padding(
              padding:
                  const EdgeInsets.only(left: 10.0, top: 10.0, right: 10.0),
              child: new RaisedButton(
                  textColor: Colors.black,
                  child: new Text('相同的弹窗是否去重'),
                  onPressed: () {
                    DialogManager()
                      ..add(DialogBean(
                        createDialogWidget: () =>
                            DialogUtil.createTipWidget(context, "测试弹窗"),
                      ))
                      ..add(DialogBean(
                        createDialogWidget: () =>
                            DialogUtil.createTipWidget(context, "测试弹窗"),
                      ))
                      ..show(context);
                  }),
            ),
            new Padding(
              padding:
                  const EdgeInsets.only(left: 10.0, top: 10.0, right: 10.0),
              child: new RaisedButton(
                  textColor: Colors.black,
                  child: new Text('已弹出低优先级弹窗，显示高优先级弹窗，是否可以回收显示'),
                  onPressed: () {
                    DialogManager()
                      ..add(DialogBean(
                        createDialogWidget: () => DialogUtil.createTipWidget(
                          context,
                          "测试弹窗\n 换行",
                        ),
                      ))
                      ..show(context);
                    Future.delayed(Duration(seconds: 1), () {
                      DialogManager()
                        ..add(DialogBean(
                          dialogPriority: DialogPriority.high,
                          createDialogWidget: () =>
                              DialogUtil.createTipWidget(context, "测试弹窗"),
                        ))
                        ..show(context);
                    });
                  }),
            ),
            new Padding(
              padding:
                  const EdgeInsets.only(left: 10.0, top: 10.0, right: 10.0),
              child: new RaisedButton(
                  textColor: Colors.black,
                  child: new Text('已弹出低优先级弹窗，显示高优先级并清除其它的弹窗'),
                  onPressed: () {
                    DialogManager()
                      ..add(DialogBean(
                        createDialogWidget: () =>
                            DialogUtil.createTipWidget(context, "测试弹窗\n 换行"),
                      ))
                      ..show(context);
                    Future.delayed(Duration(seconds: 1), () {
                      DialogManager()
                        ..add(DialogBean(
                          dialogPriority: DialogPriority.highClear,
                          createDialogWidget: () =>
                              DialogUtil.createTipWidget(context, "测试弹窗"),
                        ))
                        ..show(context);
                    });
                  }),
            ),
            new Padding(
              padding:
                  const EdgeInsets.only(left: 10.0, top: 10.0, right: 10.0),
              child: new RaisedButton(
                  textColor: Colors.black,
                  child: new Text('指定弹窗在指定页面显示'),
                  onPressed: () {
                    DialogManager()
                      ..add(DialogBean(
                        pageRouter: SecondPage.routerName,
                        createDialogWidget: () =>
                            DialogUtil.createTipWidget(context, "测试弹窗"),
                      ))
                      ..show(context);
                    Navigator.pushNamed(context, SecondPage.routerName);
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
