import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(title: 'Lost Ark event scheduler'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

GlobalKey globalKey = GlobalKey();

class _MyHomePageState extends State<MyHomePage> {
  DateTime datetime = DateTime.now();
  int weekday = DateTime.now().weekday;
  String dateTimeText = DateFormat('MM/dd/yyyy HH:mm').format(DateTime.now());
  List<Event> data;

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        child: Column(children: <Widget>[
          Text("現在時刻：$dateTimeText"),
          SizedBox(
            height: deviceHeight * 0.75,
            child: FutureBuilder(
              future: getCsvData(),
              builder:
                  (BuildContext context, AsyncSnapshot<List<Event>> snapshot) {
                if (!snapshot.hasData) {
                  return Text("データを取得中");
                }

                if (snapshot.data.length == 0) {
                  return Text("データが存在しませんでした。");
                }

                data = snapshot.data;

                return ScrollablePositionedList.builder(
                  padding: EdgeInsets.all(10.0),
                  itemCount: snapshot.data.length,
                  itemBuilder: (context, index) =>
                      _buildListView(snapshot.data[index]),
                  itemScrollController: itemScrollController,
                  itemPositionsListener: itemPositionsListener,
                );
              },
            ),
          ),
          Container(
            //margin: EdgeInsets.all(10),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  //リロードボタン
                  Container(
                    margin: EdgeInsets.only(
                      right: 30,
                    ),
                    child: RaisedButton(
                      child: const Text('Reload'),
                      onPressed: () {
                        scrollList();
                        setState(() {
                          datetime = DateTime.now();
                          weekday = DateTime.now().weekday;
                          dateTimeText = DateFormat('MM/dd/yyyy HH:mm')
                              .format(DateTime.now());
                        });
                      },
                      splashColor: Colors.blue,
                    ),
                  ),
                  RaisedButton(
                    child: const Text('通知設定(未実装)'),
                    onPressed: () {},
                    splashColor: Colors.blue,
                  ),
                ]),
          ),
        ]),
      ),
    );
  }

  // 一覧表示
  Widget _buildListView(Event data) {
    return Card(
      child: Row(children: <Widget>[
        Image.asset("images/" + data.icon + ".png"),
        Expanded(
          child: ListTile(
            title: Text(data.time),
            subtitle: Text(data.title),
          ),
        ),
      ]),
    );
  }

  Future<List<Event>> getCsvData() async {
    // 戻り値を生成
    List<Event> list = [];

    String path = "csv/schedule_" + weekday.toString() + ".csv";
    // csvデータを全て読み込む
    String csv = await rootBundle.loadString(path);

    // csvデータを1行ずつ処理する
    for (String line in csv.split("\r\n")) {
      // カンマ区切りで各列のデータを配列に格納
      List rows = line.split(','); // split by comma

      // csvデータを生成
      Event rowData = Event(time: rows[0], title: rows[1], icon: rows[2]);

      // csvデータをリストに格納
      list.add(rowData);
    }

    // リターン
    return list;
  }

  //時間に合わせて自動スクロール
  void scrollList() {
    int hour = DateTime.now().hour;
    String hourString = hour.toString();
    int index = 0;
    if (hour < 10) {
      hourString = "0" + hourString;
    }

    for (Event e in data) {
      if (e.time.substring(0, 2) == hourString) {
        break;
      }
      index++;
    }

    itemScrollController.scrollTo(
        index: index,
        duration: Duration(seconds: 2),
        curve: Curves.easeInOutCubic);
  }
}

class Event {
  String time;
  String title;
  String icon;

  // コンストラクタ
  Event({this.time, this.title, this.icon});
}
