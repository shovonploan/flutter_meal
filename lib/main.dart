import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'DB.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meal',
      themeMode: ThemeMode.light,
      darkTheme: ThemeData(brightness: Brightness.dark),
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: const MyHomePage(title: 'Meal'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late List<Meal> meals;
  bool isLoading = false;
  final formKey = GlobalKey<FormState>();
  late String amount;

  @override
  void initState() {
    super.initState();
    refreshMeal();
  }

  // @override
  // void dispose() {
  //   DB.instance.close();
  //   super.dispose();
  // }

  void refreshMeal() async {
    setState(() => isLoading = true);
    meals = await DB.instance.todayMeal();
    setState(() => isLoading = false);
  }

  Future showToast(String message) async {
    await Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.SNACKBAR,
      backgroundColor: Colors.transparent,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        backgroundColor: Colors.black38,
        body: Center(
            child: isLoading
                ? const CircularProgressIndicator()
                : meals.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No Meal Yet',
                            style: TextStyle(color: Colors.white, fontSize: 24),
                          ),
                          Image.asset('images/Nomeal.png',
                              height: 100.0, fit: BoxFit.cover)
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Number Of Meals Today:' + meals.length.toString(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 24),
                          ),
                          Image.asset('images/meal.png',
                              height: 100.0, fit: BoxFit.cover)
                        ],
                      )),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Padding(
          padding: const EdgeInsets.fromLTRB(20, 650, 20, 20),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                FloatingActionButton(
                  heroTag: "btn1",
                  onPressed: () async {
                    DB.instance.createMeal();
                    refreshMeal();
                    return showToast('Meal Added');
                  },
                  child: const Icon(Icons.plus_one),
                ),
                FloatingActionButton(
                  heroTag: "btn2",
                  onPressed: () => showDialog(
                    context: context,
                    builder: (BuildContext context) => Form(
                      key: formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: AlertDialog(
                        backgroundColor: const Color.fromRGBO(248, 223, 247, 1),
                        title: const Center(child: Text("Amount")),
                        content:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          TextFormField(
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Amount added for this month',
                                labelText: "Amount"),
                            validator: (value) {
                              return (value == null ||
                                      value.isEmpty ||
                                      int.parse(value) == 0)
                                  ? 'Empty Amount can be empty or zero'
                                  : null;
                            },
                            onSaved: (value) => setState(() {
                              amount = value!;
                              DB.instance.createAmount(int.parse(amount));
                              Navigator.of(context, rootNavigator: true).pop();
                            }),
                          )
                        ]),
                        actions: [
                          TextButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                formKey.currentState?.save();
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                        content: Text(
                                          amount +
                                              " BDT is added for this month",
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        backgroundColor: Colors.green));
                              }
                            },
                            child: const Text("Add"),
                          )
                        ],
                      ),
                    ),
                  ),
                  child: const Icon(Icons.money),
                ),
                SpeedDial(
                  heroTag: "btn3",
                  spacing: 15,
                  spaceBetweenChildren: 10,
                  overlayColor: Colors.black,
                  overlayOpacity: 0.5,
                  icon: Icons.history_outlined,
                  children: [
                    SpeedDialChild(
                      label: 'Meals',
                      child: const Icon(Icons.plus_one),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const HistoryMeal()),
                        );
                        refreshMeal();
                      },
                    ),
                    SpeedDialChild(
                      label: 'Amount',
                      child: const Icon(Icons.money),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const HistoryAmount()),
                        );
                      },
                    )
                  ],
                )
              ]),
        ));
  }
}

class HistoryMeal extends StatefulWidget {
  const HistoryMeal({Key? key}) : super(key: key);

  @override
  _HistoryMealState createState() => _HistoryMealState();
}

class _HistoryMealState extends State<HistoryMeal> {
  DateTime now = DateTime.now();
  int choice = 0;
  bool active = true;
  late List<Meal> meals = [];
  bool isLoading = false;
  late String today = "0", month = "0", year = "0", week = "0";

  @override
  void initState() {
    super.initState();
    refreshMeal();
    DB.instance.monthMeal().then((val) => setState(() {
          month = val.length.toString();
        }));
    DB.instance.todayMeal().then((val) => setState(() {
          today = val.length.toString();
        }));
    DB.instance.yearMeal().then((val) => setState(() {
          year = val.length.toString();
        }));
    DB.instance.weekMeal().then((val) => setState(() {
          week = val.length.toString();
        }));
  }

  // @override
  // void dispose() {
  //   DB.instance.close();
  //   super.dispose();
  // }

  void refreshMeal() async {
    setState(() => isLoading = true);
    if (choice == 0) {
      meals = await DB.instance.todayMeal();
    } else if (choice == 1) {
      meals = await DB.instance.weekMeal();
    } else if (choice == 2) {
      meals = await DB.instance.monthMeal();
    } else if (choice == 3) {
      meals = await DB.instance.yearMeal();
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Meals'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                onPrimary: Colors.white,
                primary: active ? Colors.white10 : const Color(0x38FA02EE),
                shape: const RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black, width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(20))),
              ),
              onPressed: () {
                setState(() {
                  active = true;
                });
              },
              child: const Text('All'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                onPrimary: Colors.white,
                primary: active ? const Color(0x38FA02EE) : Colors.white10,
                shape: const RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black, width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(20))),
              ),
              onPressed: () {
                setState(() {
                  active = false;
                });
              },
              child: const Text('Summary'),
            ),
          )
        ],
      ),
      backgroundColor: Colors.black,
      body: (active)
          ? (meals.isEmpty)
              ? const Center(
                  child: Text("No Meal Had Ever!",
                      style: TextStyle(color: Colors.white, fontSize: 24)))
              : ListView.builder(
                  itemCount: meals.length,
                  padding: const EdgeInsets.all(0),
                  itemBuilder: (BuildContext context, int index) {
                    final meal = meals[index];
                    return SizedBox(
                        height: 70,
                        child: Card(
                            color: Colors.white,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(meal.date,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      )),
                                ),
                                IconButton(
                                    onPressed: () async {
                                      await DB.instance.deleteMeal(meal);
                                      refreshMeal();
                                    },
                                    icon: const Icon(Icons.delete))
                              ],
                            )));
                  },
                )
          : Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
              child: Column(
                children: [
                  Center(
                      child: Text(
                    'Meals had in ${now.year}',
                    style: const TextStyle(color: Colors.white, fontSize: 30),
                  )),
                  const SizedBox(
                    height: 40,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Today:',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                            ),
                            Text(
                              today,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 40,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'In this week:',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                            ),
                            Text(
                              week,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 40,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'In this month:',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                            ),
                            Text(
                              month,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 40,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'In this year:',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                            ),
                            Text(
                              year,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: (active)
          ? Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SpeedDial(
                    heroTag: "btn4",
                    spacing: 10,
                    spaceBetweenChildren: 1,
                    animatedIcon: AnimatedIcons.ellipsis_search,
                    renderOverlay: false,
                    children: [
                      SpeedDialChild(
                          label: "Today",
                          child: const Icon(Icons.ac_unit_sharp),
                          onTap: () {
                            setState(() {
                              choice = 0;
                            });
                            refreshMeal();
                          }),
                      SpeedDialChild(
                          label: "Week",
                          child: const Icon(Icons.ac_unit_sharp),
                          onTap: () {
                            setState(() {
                              choice = 1;
                            });
                            refreshMeal();
                          }),
                      SpeedDialChild(
                          label: "Month",
                          child: const Icon(Icons.ac_unit_sharp),
                          onTap: () {
                            setState(() {
                              choice = 2;
                            });
                            refreshMeal();
                          }),
                      SpeedDialChild(
                          label: "Year",
                          child: const Icon(Icons.ac_unit_sharp),
                          onTap: () {
                            setState(() {
                              choice = 3;
                            });
                            refreshMeal();
                          }),
                    ],
                  ),
                ],
              ),
            )
          : null);
}

class HistoryAmount extends StatefulWidget {
  const HistoryAmount({Key? key}) : super(key: key);

  @override
  _HistoryAmountState createState() => _HistoryAmountState();
}

class _HistoryAmountState extends State<HistoryAmount> {
  DateTime now = DateTime.now();
  bool active = true;
  late List<Amount> amounts = [];
  bool isLoading = false;
  int choice = 0;
  late List<Amount> month = [], year = [];

  double cmonth = 0, cyear = 0;

  @override
  void initState() {
    super.initState();
    refreshAmount();
    DB.instance.monthAmountMoney().then((val) => setState(() {
          month = val;
        }));
    if (month.isEmpty) {
      DB.instance.monthMeal().then((val) => setState(() {
            if (month[0].amount != 0) cmonth = (month[0].amount) / val.length;
          }));
    }
    DB.instance.monthAmountYear().then((val) => setState(() {
          year = val;
        }));
    if (year.isEmpty) {
      DB.instance.yearMeal().then((val) => setState(() {
            if (year[0].amount != 0) cyear = (year[0].amount) / val.length;
          }));
    }
  }

  // @override
  // void dispose() {
  //   DB.instance.close();
  //   super.dispose();
  // }

  void refreshAmount() async {
    setState(() => isLoading = true);
    if (choice == 0) {
      amounts = await DB.instance.monthAmount();
    } else if (choice == 1) {
      amounts = await DB.instance.yearAmount();
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Amounts'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                onPrimary: Colors.white,
                primary: active ? Colors.white10 : const Color(0x38FA02EE),
                shape: const RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black, width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(20))),
              ),
              onPressed: () {
                setState(() {
                  active = true;
                });
              },
              child: const Text('All'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                onPrimary: Colors.white,
                primary: active ? const Color(0x38FA02EE) : Colors.white10,
                shape: const RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black, width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(20))),
              ),
              onPressed: () {
                setState(() {
                  active = false;
                });
              },
              child: const Text('Summary'),
            ),
          )
        ],
      ),
      backgroundColor: Colors.black,
      body: (active)
          ? (amounts.isEmpty)
              ? const Center(
                  child: Text("No Amount Had Ever!",
                      style: TextStyle(color: Colors.white, fontSize: 24)))
              : ListView.builder(
                  itemCount: amounts.length,
                  padding: const EdgeInsets.all(0),
                  itemBuilder: (BuildContext context, int index) {
                    final amount = amounts[index];
                    return SizedBox(
                        height: 70,
                        child: Card(
                            color: Colors.white,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                      amount.date +
                                          "- " +
                                          amount.amount.toString() +
                                          " BDT",
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      )),
                                ),
                                IconButton(
                                    onPressed: () async {
                                      await DB.instance.deleteAmount(amount);
                                      refreshAmount();
                                    },
                                    icon: const Icon(Icons.delete))
                              ],
                            )));
                  },
                )
          : Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
              child: Column(
                children: [
                  Center(
                    child: Text(
                      '${now.year}',
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Amount paid in this month',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        Text(
                          (month.isNotEmpty) ? month[0].amount.toString() : "0",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Month cost per meal',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        Text(
                          cmonth.toString(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Amount paid in this year',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        Text(
                          (year.isNotEmpty) ? year[0].amount.toString() : "0",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Year cost per meal',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        Text(
                          cyear.toString(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              )),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: (active)
          ? Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                SpeedDial(
                  heroTag: "btn5",
                  spacing: 10,
                  spaceBetweenChildren: 1,
                  animatedIcon: AnimatedIcons.ellipsis_search,
                  renderOverlay: false,
                  children: [
                    SpeedDialChild(
                        label: "Month",
                        child: const Icon(Icons.ac_unit_sharp),
                        onTap: () {
                          setState(() {
                            choice = 0;
                          });
                          refreshAmount();
                        }),
                    SpeedDialChild(
                        label: "Year",
                        child: const Icon(Icons.ac_unit_sharp),
                        onTap: () {
                          setState(() {
                            choice = 1;
                          });
                          refreshAmount();
                        }),
                  ],
                )
              ]))
          : null);
}
