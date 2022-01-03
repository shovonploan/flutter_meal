import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'package:week_of_year/week_of_year.dart';

const String tableMeal = 'meal';
const String tableAmount = 'amount';

class MealFields {
  static final List<String> values = [id, date, week];
  static const String id = '_id';
  static const String date = "date";
  static const String week = "week";
}

class AmountFields {
  static final List<String> values = [id, date, amount];
  static const String id = '_id';
  static const String date = "date";
  static const String amount = "amount";
}

class Meal {
  final int? id;
  final String date;
  final String week;

  const Meal({this.id, required this.date, required this.week});

  Meal copy({int? id, String? date}) =>
      Meal(id: id ?? this.id, date: date ?? this.date, week: week);

  static Meal fromJson(Map<String, Object?> json) => Meal(
      id: json[MealFields.id] as int?,
      date: json[MealFields.date] as String,
      week: json[MealFields.week] as String);

  Map<String, Object?> toJson() => {
        MealFields.id: id,
        MealFields.date: date,
        MealFields.week: week,
      };
}

class Amount {
  final int? id;
  final String date;
  final int amount;

  const Amount({this.id, required this.date, required this.amount});

  Amount copy({int? id, String? date, int? amount}) => Amount(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount);

  static Amount fromJson(Map<String, Object?> json) {
    if (json[AmountFields.date] == null) {
      return const Amount(id: 0, date: "0", amount: 0);
    }
    return Amount(
        id: json[AmountFields.id] as int?,
        date: json[AmountFields.date] as String,
        amount: json[AmountFields.amount] as int);
  }

  Map<String, Object?> toJson() => {
        AmountFields.id: id,
        AmountFields.date: date,
        AmountFields.amount: amount
      };
}

class DB {
  static final DB instance = DB._();
  static Database? _database;

  DB._();

  Future<Database?> get database async {
    if (_database != null) {
      return _database;
    }
    _database = await _initDB('database.db');
    return _database;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: createTables);
  }

  Future deleteDB() async {
    String path = join(await getDatabasesPath(), 'database.db');
    await deleteDatabase(path);
  }

  FutureOr createTables(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''CREATE TABLE IF NOT EXISTS $tableMeal(
      ${MealFields.id} $idType,
      ${MealFields.date} $textType,
      ${MealFields.week} $textType
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS $tableAmount(
      ${AmountFields.id} $idType,
      ${AmountFields.date} $textType,
      ${AmountFields.amount} $integerType
    )''');
  }

  Future<Meal> createMeal() async {
    DateTime now = DateTime.now();
    String str = DateFormat('yyyy-MM-dd hh:mm')
        .format(DateTime(now.year, now.month, now.day, now.hour, now.minute));
    Meal m = Meal(date: str, week: now.weekOfYear.toString());
    final db = await instance.database;
    final id = await db!.insert(tableMeal, m.toJson());
    return m.copy(id: id);
  }

  Future<Amount> createAmount(int amount) async {
    DateTime now = DateTime.now();
    String str = DateFormat('yyyy-MM-dd hh:mm')
        .format(DateTime(now.year, now.month, now.day, now.hour, now.minute));
    Amount a = Amount(date: str, amount: amount);
    final db = await instance.database;
    final id = await db!.insert(tableAmount, a.toJson());
    return a.copy(id: id);
  }

  Future<List<Meal>> readAllMeal() async {
    final db = await instance.database;
    const orderBy = '${MealFields.date} DESC';
    final result = await db!.query(
      tableMeal,
      orderBy: orderBy,
    );
    return result.map((json) => Meal.fromJson(json)).toList();
  }

  Future<List<Amount>> readAllAmount() async {
    final db = await instance.database;
    const orderBy = '${AmountFields.date} DESC';
    final result = await db!.query(
      tableAmount,
      orderBy: orderBy,
    );
    return result.map((json) => Amount.fromJson(json)).toList();
  }

  Future<List<Meal>> todayMeal() async {
    DateTime now = DateTime.now();
    String str =
        DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, now.day));
    str += '%';
    final db = await instance.database;
    const orderBy = '_id DESC';
    final result = await db!.rawQuery(
        'SELECT * FROM meal WHERE date LIKE ? ORDER BY ?', [str, orderBy]);
    return result.map((json) => Meal.fromJson(json)).toList();
  }

  Future<List<Meal>> monthMeal() async {
    DateTime now = DateTime.now();
    String str =
        DateFormat('yyyy-MM').format(DateTime(now.year, now.month, now.day));
    str += '%';
    final db = await instance.database;
    const orderBy = '_id DESC';
    final result = await db!.rawQuery(
        'SELECT * FROM meal WHERE date LIKE ? ORDER BY ?', [str, orderBy]);
    return result.map((json) => Meal.fromJson(json)).toList();
  }

  Future<List<Amount>> monthAmount() async {
    DateTime now = DateTime.now();
    String str =
        DateFormat('yyyy-MM').format(DateTime(now.year, now.month, now.day));
    str += '%';
    final db = await instance.database;
    const orderBy = '_id DESC';
    final result = await db!.rawQuery(
        'SELECT * FROM amount WHERE date LIKE ? ORDER BY ?', [str, orderBy]);
    return result.map((json) => Amount.fromJson(json)).toList();
  }

  Future<List<Meal>> yearMeal() async {
    DateTime now = DateTime.now();
    String str =
        DateFormat('yyyy').format(DateTime(now.year, now.month, now.day));
    str += '%';
    final db = await instance.database;
    const orderBy = '_id DESC';
    final result = await db!.rawQuery(
        'SELECT * FROM meal WHERE date LIKE ? ORDER BY ?', [str, orderBy]);
    return result.map((json) => Meal.fromJson(json)).toList();
  }

  Future<List<Amount>> yearAmount() async {
    DateTime now = DateTime.now();
    String str =
        DateFormat('yyyy').format(DateTime(now.year, now.month, now.day));
    str += '%';
    final db = await instance.database;
    const orderBy = '_id DESC';
    final result = await db!.rawQuery(
        'SELECT * FROM amount WHERE date LIKE ? ORDER BY ?', [str, orderBy]);
    return result.map((json) => Amount.fromJson(json)).toList();
  }

  Future<List<Meal>> weekMeal() async {
    DateTime now = DateTime.now();
    final db = await instance.database;
    final result = await db!.rawQuery(
        'SELECT * FROM meal WHERE week = ?', [now.weekOfYear.toString()]);
    return result.map((json) => Meal.fromJson(json)).toList();
  }

  Future<int> deleteMeal(Meal m) async {
    final db = await instance.database;

    return await db!.delete(
      tableMeal,
      where: '${MealFields.id} = ?',
      whereArgs: [m.id],
    );
  }

  Future<int> deleteAmount(Amount a) async {
    final db = await instance.database;

    return await db!.delete(
      tableAmount,
      where: '${AmountFields.id} = ?',
      whereArgs: [a.id],
    );
  }

  Future<List<Amount>> monthAmountMoney() async {
    DateTime now = DateTime.now();
    String str =
        DateFormat('yyyy-MM').format(DateTime(now.year, now.month, now.day));
    str += '%';
    final db = await instance.database;
    const orderBy = '_id DESC';
    final result = await db!.rawQuery(
        'SELECT _id,date,SUM(amount) AS amount FROM amount WHERE date LIKE ? ORDER BY ?',
        [str, orderBy]);
    return result.map((json) => Amount.fromJson(json)).toList();
  }

  Future<List<Amount>> monthAmountYear() async {
    DateTime now = DateTime.now();
    String str =
        DateFormat('yyyy').format(DateTime(now.year, now.month, now.day));
    str += '%';
    final db = await instance.database;
    const orderBy = '_id DESC';
    final result = await db!.rawQuery(
        'SELECT _id,date,SUM(amount) AS amount FROM amount WHERE date LIKE ? ORDER BY ?',
        [str, orderBy]);
    return result.map((json) => Amount.fromJson(json)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db!.close();
  }
}
