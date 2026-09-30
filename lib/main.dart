import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:excel/excel.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await openDatabase(
    join(await getDatabasesPath(), 'dokanmate.db'),
    version: 1,
    onCreate: (db, v) async {
      await db.execute('CREATE TABLE sales(id INTEGER PRIMARY KEY AUTOINCREMENT, amount REAL, cost REAL, paid REAL)');
      await db.execute('CREATE TABLE customers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, phone TEXT, due REAL)');
      await db.execute('CREATE TABLE products(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, qty REAL, buy REAL, sell REAL)');
    },
  );
  await coreSchema(db);
  runApp(App(db));
}

String money(num n) => 'Rs ' + n.toStringAsFixed(2);

class App extends StatefulWidget {
  final Database db;
  const App(this.db, {super.key});
  @override State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int tab = 0;
  void refresh() => setState(() {});
  @override
  Widget build(BuildContext context) {
    final pages = [
      Home(widget.db),
      Sales(widget.db, refresh),
      Customers(widget.db, refresh),
      Stock(widget.db, refresh),
      More(widget.db),
    ];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DokanMate',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xff1565c0)),
      home: Scaffold(
        body: SafeArea(child: IndexedStack(index: tab, children: pages)),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'Sales'),
            NavigationDestination(icon: Icon(Icons.people), label: 'Customers'),
            NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Stock'),
            NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
          ],
        ),
      ),
    );
  }
}

class Home extends StatelessWidget {
  final Database db;
  const Home(this.db, {super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([db.query('sales', orderBy: 'id DESC'), db.query('customers'), db.query('products')]),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final sales = snap.data![0], customers = snap.data![1], products = snap.data![2];
        double total = 0, collected = 0, profit = 0, due = 0, stock = 0;
        for (final x in sales) {
          total += (x['amount'] as num).toDouble();
          collected += (x['paid'] as num).toDouble();
          profit += (x['amount'] as num).toDouble() - (x['cost'] as num).toDouble();
        }
        for (final x in customers) due += (x['due'] as num).toDouble();
        for (final x in products) stock += (x['qty'] as num).toDouble() * (x['buy'] as num).toDouble();
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          children: [
            Row(children: [
              Container(width: 46, height: 46, decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF5B5CE2), Color(0xFF7B61FF)]),
                borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.storefront_rounded, color: Colors.white)),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('DokanMate', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
                Text('Your shop, beautifully organized', style: TextStyle(color: Color(0xFF7A7F8A), fontSize: 12)),
              ])),
              IconButton(onPressed: () {}, style: IconButton.styleFrom(backgroundColor: Colors.white), icon: const Icon(Icons.notifications_none_rounded)),
            ]),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF24264D), Color(0xFF5B5CE2)]),
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [BoxShadow(color: Color(0x2524254D), blurRadius: 22, offset: Offset(0, 10))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('BUSINESS OVERVIEW', style: TextStyle(color: Color(0xFFBFC4FF), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
                const SizedBox(height: 12),
                Text(money(total), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
                const Text('Total sales recorded', style: TextStyle(color: Color(0xFFD9DBEE), fontSize: 12)),
                const SizedBox(height: 18),
                Row(children: [
                  _HeroMetric('Collected', money(collected), Icons.payments_rounded),
                  const SizedBox(width: 10),
                  _HeroMetric('Profit', money(profit), Icons.trending_up_rounded),
                ]),
              ]),
            ),
            const SizedBox(height: 20),
            const Text('Quick overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 11),
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 11, crossAxisSpacing: 11, childAspectRatio: 1.5,
              children: [
                _StatCard('Customer due', money(due), Icons.account_balance_wallet_rounded, const Color(0xFFFFF3E7)),
                _StatCard('Stock value', money(stock), Icons.inventory_2_rounded, const Color(0xFFEAF7F2)),
                _StatCard('Customers', customers.length.toString(), Icons.people_alt_rounded, const Color(0xFFEEF0FF)),
                _StatCard('Products', products.length.toString(), Icons.category_rounded, const Color(0xFFFFEEF5)),
              ],
            ),
            const SizedBox(height: 21),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Recent sales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text(sales.length.toString() + ' entries', style: const TextStyle(color: Color(0xFF858995), fontSize: 12)),
            ]),
            const SizedBox(height: 10),
            if (sales.isEmpty) const _EmptyCard(icon: Icons.receipt_long_rounded, title: 'No sales yet', subtitle: 'Add your first sale from the Sales tab.'),
            ...sales.take(6).map((x) => _SaleTile(
              amount: (x['amount'] as num).toDouble(),
              paid: (x['paid'] as num).toDouble(),
              profit: (x['amount'] as num).toDouble() - (x['cost'] as num).toDouble(),
            )),
          ],
        );
      },
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String title, value; final IconData icon;
  const _HeroMetric(this.title, this.value, this.icon);
  @override
  Widget build(BuildContext c) => Expanded(child: Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(color: Colors.white.withOpacity(.10), borderRadius: BorderRadius.circular(15)),
    child: Row(children: [
      Icon(icon, color: Colors.white, size: 19), const SizedBox(width: 7),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Color(0xFFCFD2E8), fontSize: 10)),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      ])),
    ]),
  ));
}

class _StatCard extends StatelessWidget {
  final String title, value; final IconData icon; final Color bg;
  const _StatCard(this.title, this.value, this.icon, this.bg);
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x0C101828), blurRadius: 15, offset: Offset(0, 5))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Container(width: 34, height: 34, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)), child: Icon(icon, size: 18, color: const Color(0xFF5B5CE2))),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF777B86), fontSize: 11)),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ]),
    ]),
  );
}

class _SaleTile extends StatelessWidget {
  final double amount, paid, profit;
  const _SaleTile({required this.amount, required this.paid, required this.profit});
  @override
  Widget build(BuildContext c) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
    child: Row(children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFEEF0FF), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.receipt_rounded, color: Color(0xFF5B5CE2))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(money(amount), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        Text('Paid ' + money(paid), style: const TextStyle(color: Color(0xFF80848F), fontSize: 11)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        const Text('Profit', style: TextStyle(color: Color(0xFF80848F), fontSize: 10)),
        Text(money(profit), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF148A63), fontSize: 12)),
      ]),
    ]),
  );
}

class _EmptyCard extends StatelessWidget {
  final IconData icon; final String title, subtitle;
  const _EmptyCard({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFFEEF0FF), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: const Color(0xFF5B5CE2))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(subtitle, style: const TextStyle(color: Color(0xFF7B7F89), fontSize: 12)),
      ])),
    ]),
  );
}

class Sales extends StatelessWidget {
  final Database db;
  final VoidCallback refresh;
  const Sales(this.db, this.refresh, {super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Sales'), actions: [IconButton(onPressed: () => add(c), icon: const Icon(Icons.add))]),
    body: FutureBuilder(
      future: db.query('sales', orderBy: 'id DESC'),
      builder: (c, s) {
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        return ListView(children: s.data!.map((x) => Card(
          child: ListTile(
            title: Text(money(x['amount'] as num)),
            subtitle: Text('Paid ' + money(x['paid'] as num)),
            trailing: Text('Profit ' + money((x['amount'] as num) - (x['cost'] as num))),
          ),
        )).toList());
      },
    ),
  );

  Future<void> add(BuildContext c) async {
    final a = TextEditingController(), cost = TextEditingController(), paid = TextEditingController();
    await showDialog(
      context: c,
      builder: (d) => AlertDialog(
        title: const Text('Add Sale'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: a, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sale amount')),
          TextField(controller: cost, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost price')),
          TextField(controller: paid, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Paid amount')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            final x = double.tryParse(a.text) ?? 0, y = double.tryParse(cost.text) ?? 0, z = double.tryParse(paid.text) ?? 0;
            if (x <= 0 || z < 0 || z > x) return;
            await db.insert('sales', {'amount': x, 'cost': y, 'paid': z});
            if (d.mounted) Navigator.pop(d);
            refresh();
          }, child: const Text('Save')),
        ],
      ),
    );
  }
}

class Customers extends StatelessWidget {
  final Database db;
  final VoidCallback refresh;
  const Customers(this.db, this.refresh, {super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Customers'), actions: [IconButton(onPressed: () => add(c), icon: const Icon(Icons.person_add))]),
    body: FutureBuilder(
      future: db.query('customers'),
      builder: (c, s) {
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        return ListView(children: s.data!.map((x) => Card(
          child: ListTile(
            title: Text(x['name'] as String),
            subtitle: Text((x['phone'] as String?) ?? ''),
            trailing: Text('Due ' + money(x['due'] as num)),
          ),
        )).toList());
      },
    ),
  );

  Future<void> add(BuildContext c) async {
    final n = TextEditingController(), p = TextEditingController();
    await showDialog(
      context: c,
      builder: (d) => AlertDialog(
        title: const Text('New Customer'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: n, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: p, decoration: const InputDecoration(labelText: 'Phone')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            if (n.text.isEmpty) return;
            await db.insert('customers', {'name': n.text, 'phone': p.text, 'due': 0});
            if (d.mounted) Navigator.pop(d);
            refresh();
          }, child: const Text('Save')),
        ],
      ),
    );
  }
}

class Stock extends StatelessWidget {
  final Database db;
  final VoidCallback refresh;
  const Stock(this.db, this.refresh, {super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Stock'), actions: [IconButton(onPressed: () => add(c), icon: const Icon(Icons.add_box))]),
    body: FutureBuilder(
      future: db.query('products'),
      builder: (c, s) {
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        return ListView(children: s.data!.map((x) => Card(
          child: ListTile(
            title: Text(x['name'] as String),
            subtitle: Text('Buy ' + money(x['buy'] as num) + '  Sell ' + money(x['sell'] as num)),
            trailing: Text('Qty ' + (x['qty'] as num).toString()),
          ),
        )).toList());
      },
    ),
  );

  Future<void> add(BuildContext c) async {
    final n = TextEditingController(), q = TextEditingController(), b = TextEditingController(), s = TextEditingController();
    await showDialog(
      context: c,
      builder: (d) => AlertDialog(
        title: const Text('Add Product'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: n, decoration: const InputDecoration(labelText: 'Product name')),
          TextField(controller: q, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
          TextField(controller: b, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Buy price')),
          TextField(controller: s, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sell price')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            if (n.text.isEmpty) return;
            await db.insert('products', {'name': n.text, 'qty': double.tryParse(q.text) ?? 0, 'buy': double.tryParse(b.text) ?? 0, 'sell': double.tryParse(s.text) ?? 0});
            if (d.mounted) Navigator.pop(d);
            refresh();
          }, child: const Text('Save')),
        ],
      ),
    );
  }
}

class More extends StatelessWidget {
  final Database db;
  const More(this.db, {super.key});

  @override
  Widget build(BuildContext c) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
    children: [
      const Text('More', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
      const Text('Tools and business settings', style: TextStyle(color: Color(0xFF7C808B))),
      const SizedBox(height: 18),
      _MoreCard(Icons.file_download_rounded, 'Export Center', 'Excel, PDF and CSV', () => Navigator.push(c, MaterialPageRoute(builder: (_) => ExportPage(db)))),
      _MoreCard(Icons.assessment_rounded, 'Business Report', 'View sales, profit and due summary', () => report(c)),
      _MoreCard(Icons.lock_rounded, 'PIN Lock', 'Secure your business data', () {}, badge: 'Coming next'),
      _MoreCard(Icons.workspace_premium_rounded, 'DokanMate Pro', 'Premium business features', () {}, badge: 'Soon'),
    ],
  );

  Future<void> report(BuildContext c) async {
    final s = await db.query('sales'), u = await db.query('customers');
    double a = 0, p = 0, d = 0;
    for (final x in s) {
      a += (x['amount'] as num).toDouble();
      p += (x['amount'] as num).toDouble() - (x['cost'] as num).toDouble();
    }
    for (final x in u) d += (x['due'] as num).toDouble();
    if (!c.mounted) return;
    showModalBottomSheet(context: c, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), builder: (_) => Padding(
      padding: const EdgeInsets.all(22),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Business report', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        _ReportRow('Total sales', money(a)),
        _ReportRow('Total profit', money(p)),
        _ReportRow('Customer due', money(d)),
      ]),
    ));
  }
}

class _MoreCard extends StatelessWidget {
  final IconData icon; final String title, subtitle; final String? badge; final VoidCallback onTap;
  const _MoreCard(this.icon, this.title, this.subtitle, this.onTap, {this.badge});
  @override
  Widget build(BuildContext c) => Container(
    margin: const EdgeInsets.only(bottom: 11),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      leading: Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFFEEF0FF), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: const Color(0xFF5B5CE2))),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF7C808B))),
      trailing: badge == null ? const Icon(Icons.chevron_right_rounded) : Text(badge!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF7B61FF))),
    ),
  );
}

class _ReportRow extends StatelessWidget {
  final String a, b;
  const _ReportRow(this.a, this.b);
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(a, style: const TextStyle(color: Color(0xFF6F7480))),
      Text(b, style: const TextStyle(fontWeight: FontWeight.w800)),
    ]),
  );
}

class ExportPage extends StatefulWidget {
  final Database db;
  const ExportPage(this.db, {super.key});
  @override State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  bool busy = false;
  String status = 'Choose a format to export your offline data.';

  Future<Directory> folder() async {
    final base = await getApplicationDocumentsDirectory();
    final f = Directory(join(base.path, 'DokanMate_Exports'));
    if (!await f.exists()) await f.create(recursive: true);
    return f;
  }

  String stamp() => DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  Future<void> shareFile(String path, String text) => Share.shareXFiles([XFile(path)], text: text);
  void done(String text) => setState(() { busy = false; status = text; });

  Future<void> excelExport() async {
    setState(() { busy = true; status = 'Creating Excel workbook...'; });
    try {
      final sales = await widget.db.query('sales', orderBy: 'id DESC');
      final customers = await widget.db.query('customers');
      final products = await widget.db.query('products');
      final book = Excel.createExcel();

      final sh = book['Sales'];
      sh.appendRow([TextCellValue('ID'), TextCellValue('Amount'), TextCellValue('Cost'), TextCellValue('Paid'), TextCellValue('Profit')]);
      for (final x in sales) {
        sh.appendRow([IntCellValue((x['id'] as int?) ?? 0), DoubleCellValue((x['amount'] as num).toDouble()), DoubleCellValue((x['cost'] as num).toDouble()), DoubleCellValue((x['paid'] as num).toDouble()), DoubleCellValue((x['amount'] as num).toDouble() - (x['cost'] as num).toDouble())]);
      }

      final cu = book['Customers'];
      cu.appendRow([TextCellValue('ID'), TextCellValue('Name'), TextCellValue('Phone'), TextCellValue('Due')]);
      for (final x in customers) {
        cu.appendRow([IntCellValue((x['id'] as int?) ?? 0), TextCellValue((x['name'] as String?) ?? ''), TextCellValue((x['phone'] as String?) ?? ''), DoubleCellValue((x['due'] as num).toDouble())]);
      }

      final st = book['Stock'];
      st.appendRow([TextCellValue('ID'), TextCellValue('Product'), TextCellValue('Quantity'), TextCellValue('Buy Price'), TextCellValue('Sell Price'), TextCellValue('Stock Value')]);
      for (final x in products) {
        st.appendRow([IntCellValue((x['id'] as int?) ?? 0), TextCellValue((x['name'] as String?) ?? ''), DoubleCellValue((x['qty'] as num).toDouble()), DoubleCellValue((x['buy'] as num).toDouble()), DoubleCellValue((x['sell'] as num).toDouble()), DoubleCellValue((x['qty'] as num).toDouble() * (x['buy'] as num).toDouble())]);
      }

      final bytes = book.save();
      if (bytes == null) throw Exception('Workbook creation failed');
      final file = File(join((await folder()).path, 'DokanMate_' + stamp() + '.xlsx'));
      await file.writeAsBytes(bytes, flush: true);
      await shareFile(file.path, 'DokanMate Excel export');
      done('Excel file created and ready to share.');
    } catch (e) {
      done('Excel export failed: ' + e.toString());
    }
  }

  Future<void> csvExport() async {
    setState(() { busy = true; status = 'Creating CSV file...'; });
    try {
      final sales = await widget.db.query('sales', orderBy: 'id DESC');
      final customers = await widget.db.query('customers');
      final products = await widget.db.query('products');
      final b = StringBuffer();

      b.writeln('DOKANMATE SALES');
      b.writeln('ID,Amount,Cost,Paid,Profit');
      for (final x in sales) b.writeln(x['id'].toString() + ',' + x['amount'].toString() + ',' + x['cost'].toString() + ',' + x['paid'].toString() + ',' + ((x['amount'] as num) - (x['cost'] as num)).toString());
      b.writeln();
      b.writeln('DOKANMATE CUSTOMERS');
      b.writeln('ID,Name,Phone,Due');
      for (final x in customers) b.writeln(x['id'].toString() + ',"' + csv(x['name']) + '","' + csv(x['phone']) + '",' + x['due'].toString());
      b.writeln();
      b.writeln('DOKANMATE STOCK');
      b.writeln('ID,Product,Quantity,Buy Price,Sell Price,Stock Value');
      for (final x in products) b.writeln(x['id'].toString() + ',"' + csv(x['name']) + '",' + x['qty'].toString() + ',' + x['buy'].toString() + ',' + x['sell'].toString() + ',' + ((x['qty'] as num) * (x['buy'] as num)).toString());

      final file = File(join((await folder()).path, 'DokanMate_' + stamp() + '.csv'));
      await file.writeAsString(b.toString(), flush: true);
      await shareFile(file.path, 'DokanMate CSV export');
      done('CSV file created and ready to share.');
    } catch (e) {
      done('CSV export failed: ' + e.toString());
    }
  }

  String csv(Object? value) => (value ?? '').toString().replaceAll('"', '""');

  Future<void> pdfExport() async {
    setState(() { busy = true; status = 'Creating PDF report...'; });
    try {
      final sales = await widget.db.query('sales', orderBy: 'id DESC');
      final customers = await widget.db.query('customers');
      final products = await widget.db.query('products');
      double total = 0, paid = 0, profit = 0, due = 0, stock = 0;

      for (final x in sales) {
        total += (x['amount'] as num).toDouble();
        paid += (x['paid'] as num).toDouble();
        profit += (x['amount'] as num).toDouble() - (x['cost'] as num).toDouble();
      }
      for (final x in customers) due += (x['due'] as num).toDouble();
      for (final x in products) stock += (x['qty'] as num).toDouble() * (x['buy'] as num).toDouble();

      final doc = pw.Document();
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          pw.Text('DokanMate', style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold)),
          pw.Text('Business Report - ' + DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: ['Metric', 'Value'],
            data: [
              ['Total Sales', money(total)], ['Collection', money(paid)], ['Profit', money(profit)],
              ['Customer Due', money(due)], ['Stock Value', money(stock)],
              ['Customers', customers.length.toString()], ['Products', products.length.toString()],
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('Recent Sales', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 7),
          pw.TableHelper.fromTextArray(
            headers: ['ID', 'Amount', 'Paid', 'Profit'],
            data: sales.take(20).map((x) => [x['id'].toString(), money(x['amount'] as num), money(x['paid'] as num), money((x['amount'] as num) - (x['cost'] as num))]).toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Text('Stock Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 7),
          pw.TableHelper.fromTextArray(
            headers: ['Product', 'Qty', 'Buy', 'Sell'],
            data: products.take(30).map((x) => [x['name'].toString(), x['qty'].toString(), money(x['buy'] as num), money(x['sell'] as num)]).toList(),
          ),
        ],
      ));

      final file = File(join((await folder()).path, 'DokanMate_Report_' + stamp() + '.pdf'));
      await file.writeAsBytes(await doc.save(), flush: true);
      await shareFile(file.path, 'DokanMate PDF report');
      done('PDF report created and ready to share.');
    } catch (e) {
      done('PDF export failed: ' + e.toString());
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(backgroundColor: const Color(0xFFF6F7FB), title: const Text('Export Center', style: TextStyle(fontWeight: FontWeight.w800))),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF24264D), Color(0xFF5B5CE2)]), borderRadius: BorderRadius.circular(25)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.cloud_download_rounded, color: Colors.white, size: 30),
            SizedBox(height: 12),
            Text('Take your data anywhere', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
            SizedBox(height: 5),
            Text('Your offline shop data stays on your phone. Export a copy whenever you need it.', style: TextStyle(color: Color(0xFFDDE0F4), height: 1.35, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 18),
        _ExportCard(Icons.table_chart_rounded, 'Excel Workbook', 'Sales + Customers + Stock in separate sheets', 'XLSX', busy ? null : excelExport),
        _ExportCard(Icons.picture_as_pdf_rounded, 'PDF Report', 'Printable business summary and tables', 'PDF', busy ? null : pdfExport),
        _ExportCard(Icons.data_object_rounded, 'CSV Data', 'Portable spreadsheet-friendly data export', 'CSV', busy ? null : csvExport),
        const SizedBox(height: 8),
        if (busy) const LinearProgressIndicator(),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFF5B5CE2)),
            const SizedBox(width: 10),
            Expanded(child: Text(status, style: const TextStyle(fontSize: 12, color: Color(0xFF6E7380)))),
          ]),
        ),
      ],
    ),
  );
}

class _ExportCard extends StatelessWidget {
  final IconData icon; final String title, subtitle, type; final VoidCallback? onTap;
  const _ExportCard(this.icon, this.title, this.subtitle, this.type, this.onTap);
  @override
  Widget build(BuildContext c) => Container(
    margin: const EdgeInsets.only(bottom: 11),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFEEF0FF), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: const Color(0xFF5B5CE2))),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF7C808B))),
      trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFF1F1FF), borderRadius: BorderRadius.circular(9)), child: Text(type, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF5B5CE2)))),
    ),
  );
}


Future<void> coreSchema(Database db) async {
  final q = [
    'CREATE TABLE IF NOT EXISTS dm_business(id INTEGER PRIMARY KEY, name TEXT, owner TEXT, phone TEXT, address TEXT, state TEXT, gstin TEXT, upi TEXT, invoice_prefix TEXT)',
    'CREATE TABLE IF NOT EXISTS dm_parties(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, phone TEXT, address TEXT, state TEXT, gstin TEXT, type TEXT, balance REAL DEFAULT 0, credit_limit REAL DEFAULT 0, credit_days INTEGER DEFAULT 0)',
    'CREATE TABLE IF NOT EXISTS dm_products(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, sku TEXT, barcode TEXT, category TEXT, hsn TEXT, unit TEXT, gst REAL DEFAULT 0, buy REAL DEFAULT 0, sell REAL DEFAULT 0, wholesale REAL DEFAULT 0, qty REAL DEFAULT 0, min_qty REAL DEFAULT 0)',
    'CREATE TABLE IF NOT EXISTS dm_sales(id INTEGER PRIMARY KEY AUTOINCREMENT, invoice TEXT, date TEXT, party_id INTEGER, subtotal REAL, discount REAL, taxable REAL, cgst REAL, sgst REAL, igst REAL, total REAL, paid REAL, due REAL, mode TEXT)',
    'CREATE TABLE IF NOT EXISTS dm_sale_items(id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER, product_id INTEGER, name TEXT, qty REAL, unit TEXT, rate REAL, discount REAL, gst REAL, amount REAL)',
    'CREATE TABLE IF NOT EXISTS dm_purchases(id INTEGER PRIMARY KEY AUTOINCREMENT, invoice TEXT, date TEXT, party_id INTEGER, subtotal REAL, discount REAL, taxable REAL, cgst REAL, sgst REAL, igst REAL, total REAL, paid REAL, due REAL, mode TEXT)',
    'CREATE TABLE IF NOT EXISTS dm_purchase_items(id INTEGER PRIMARY KEY AUTOINCREMENT, purchase_id INTEGER, product_id INTEGER, name TEXT, qty REAL, unit TEXT, rate REAL, discount REAL, gst REAL, amount REAL)',
    'CREATE TABLE IF NOT EXISTS dm_payments(id INTEGER PRIMARY KEY AUTOINCREMENT, party_id INTEGER, type TEXT, amount REAL, date TEXT, mode TEXT, reference TEXT)',
    'CREATE TABLE IF NOT EXISTS dm_expenses(id INTEGER PRIMARY KEY AUTOINCREMENT, category TEXT, amount REAL, date TEXT, mode TEXT, note TEXT)',
    'CREATE TABLE IF NOT EXISTS dm_stock(id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER, type TEXT, qty REAL, date TEXT, reference TEXT)'
  ];
  for (final x in q) { try { await db.execute(x); } catch (_) {} }
  if ((await db.query('dm_business')).isEmpty) {
    await db.insert('dm_business', {'id':1,'name':'My Business','owner':'','phone':'','address':'','state':'West Bengal','gstin':'','upi':'','invoice_prefix':'INV'});
  }
}

class CoreDashboard extends StatelessWidget {
  final Database db;
  const CoreDashboard(this.db,{super.key});
  Future<List<double>> get data async {
    final s=(await db.rawQuery('SELECT COALESCE(SUM(total),0) a,COALESCE(SUM(paid),0) b,COALESCE(SUM(due),0) c FROM dm_sales')).first;
    final p=(await db.rawQuery('SELECT COALESCE(SUM(total),0) a,COALESCE(SUM(due),0) b FROM dm_purchases')).first;
    final e=(await db.rawQuery('SELECT COALESCE(SUM(amount),0) a FROM dm_expenses')).first;
    final st=(await db.rawQuery('SELECT COALESCE(SUM(qty*buy),0) a FROM dm_products')).first;
    return [(s['a'] as num).toDouble(),(s['b'] as num).toDouble(),(s['c'] as num).toDouble(),(p['a'] as num).toDouble(),(p['b'] as num).toDouble(),(e['a'] as num).toDouble(),(st['a'] as num).toDouble()];
  }
  @override Widget build(BuildContext c)=>FutureBuilder(future:data,builder:(c,s){
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    final x=s.data!,profit=x[0]-x[3]-x[5];
    return ListView(padding:const EdgeInsets.only(bottom:25),children:[
      titleBar('DokanMate','Complete business management',actions:[IconButton(onPressed:()=>coreBusiness(c,db),icon:const Icon(Icons.storefront_rounded))]),
      Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF25274E),Color(0xFF635BDB)]),borderRadius:BorderRadius.circular(26)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('BUSINESS OVERVIEW',style:TextStyle(color:Color(0xFFC8C9FF),fontSize:10,fontWeight:FontWeight.w800,letterSpacing:1.2)),
        const SizedBox(height:8),Text(money(x[0]),style:const TextStyle(color:Colors.white,fontSize:32,fontWeight:FontWeight.w900)),const Text('Total sales',style:TextStyle(color:Color(0xFFD9DBEE))),
        const SizedBox(height:16),Row(children:[coreHero('Collection',money(x[1])),const SizedBox(width:8),coreHero('Net result',money(profit))])
      ]))),
      Padding(padding:const EdgeInsets.fromLTRB(18,20,18,10),child:const Text('Quick actions',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900))),
      Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:Wrap(spacing:9,runSpacing:9,children:[
        quick(c,'New Sale',Icons.add_shopping_cart_rounded,()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>CoreInvoice(db,false,()=>setState((){}))))),
        quick(c,'Purchase',Icons.shopping_bag_rounded,()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>CoreInvoice(db,true,()=>setState((){}))))),
        quick(c,'Payment In',Icons.call_received_rounded,()=>corePayment(c,db,'IN')),
        quick(c,'Payment Out',Icons.call_made_rounded,()=>corePayment(c,db,'OUT')),
        quick(c,'Expense',Icons.account_balance_wallet_rounded,()=>coreExpense(c,db)),
        quick(c,'Product',Icons.inventory_2_rounded,()=>coreProduct(c,db))
      ])),
      Padding(padding:const EdgeInsets.fromLTRB(18,20,18,10),child:const Text('Business snapshot',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900))),
      Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:GridView.count(crossAxisCount:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:1.5,children:[
        stat('Receivable',money(x[2]),Icons.account_balance_wallet_rounded),stat('Payable',money(x[4]),Icons.request_quote_rounded),stat('Stock value',money(x[6]),Icons.inventory_2_rounded),stat('Expenses',money(x[5]),Icons.money_off_rounded)
      ]))
    ]);
  });
}
Widget coreHero(String a,String b)=>Expanded(child:Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:Colors.white.withOpacity(.1),borderRadius:BorderRadius.circular(14)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a,style:const TextStyle(color:Color(0xFFD2D4E8),fontSize:10)),Text(b,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:12))])));

class CoreSales extends StatelessWidget {
  final Database db;final VoidCallback refresh;
  const CoreSales(this.db,this.refresh,{super.key});
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Sales',style:TextStyle(fontWeight:FontWeight.w900)),actions:[IconButton(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>CoreInvoice(db,false,refresh))),icon:const Icon(Icons.add_circle_rounded))]),body:FutureBuilder(future:db.rawQuery('SELECT s.*,p.name party FROM dm_sales s LEFT JOIN dm_parties p ON p.id=s.party_id ORDER BY s.id DESC'),builder:(c,s){
    if(!s.hasData)return const Center(child:CircularProgressIndicator());final r=s.data!;
    return ListView(padding:const EdgeInsets.all(18),children:[if(r.isEmpty)emptyBox('No sales yet','Create a proper item-based sales invoice.'),...r.map((x)=>Card(child:ListTile(onTap:()=>coreInvoicePdf(c,db,(x['id'] as num).toInt(),false),leading:const CircleAvatar(backgroundColor:Color(0xFFEEF0FF),child:Icon(Icons.receipt_long_rounded,color:Color(0xFF5B5CE2))),title:Text(x['invoice'].toString(),style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text((x['party']??'Walk-in').toString()+' • '+ddate(x['date'])),trailing:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.end,children:[Text(money(x['total'] as num),style:const TextStyle(fontWeight:FontWeight.w900)),Text((x['due'] as num)>0?'Due '+money(x['due'] as num):'Paid',style:TextStyle(fontSize:10,color:(x['due'] as num)>0?Colors.red:Colors.green))]))))]);
  });
}

class CorePurchase extends StatelessWidget {
  final Database db;final VoidCallback refresh;
  const CorePurchase(this.db,this.refresh,{super.key});
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Purchase',style:TextStyle(fontWeight:FontWeight.w900)),actions:[IconButton(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>CoreInvoice(db,true,refresh))),icon:const Icon(Icons.add_circle_rounded))]),body:FutureBuilder(future:db.rawQuery('SELECT s.*,p.name party FROM dm_purchases s LEFT JOIN dm_parties p ON p.id=s.party_id ORDER BY s.id DESC'),builder:(c,s){
    if(!s.hasData)return const Center(child:CircularProgressIndicator());final r=s.data!;
    return ListView(padding:const EdgeInsets.all(18),children:[if(r.isEmpty)emptyBox('No purchases yet','Create purchase invoices; stock updates automatically.'),...r.map((x)=>Card(child:ListTile(onTap:()=>coreInvoicePdf(c,db,(x['id'] as num).toInt(),true),leading:const CircleAvatar(backgroundColor:Color(0xFFEAF8F2),child:Icon(Icons.shopping_bag_rounded,color:Color(0xFF15936C))),title:Text(x['invoice'].toString(),style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text((x['party']??'Supplier').toString()+' • '+ddate(x['date'])),trailing:Text(money(x['total'] as num),style:const TextStyle(fontWeight:FontWeight.w900))))]);
  });
}

class CoreInvoice extends StatefulWidget {
  final Database db;final bool purchase;final VoidCallback refresh;
  const CoreInvoice(this.db,this.purchase,this.refresh,{super.key});
  @override State<CoreInvoice> createState()=>_CoreInvoiceState();
}
class CoreLine {
  int id;String name,unit;double qty,rate,gst,discount;
  CoreLine(this.id,this.name,this.unit,this.qty,this.rate,this.gst,this.discount);
  double get base=>qty*rate-discount;double get tax=>base*gst/100;double get total=>base+tax;
}
class _CoreInvoiceState extends State<CoreInvoice>{
  List<Map<String,dynamic>> parties=[],products=[];List<CoreLine> lines=[];int? party;String mode='Cash';final paid=TextEditingController();
  double get subtotal=>lines.fold(0,(a,x)=>a+x.qty*x.rate);double get discount=>lines.fold(0,(a,x)=>a+x.discount);double get taxable=>lines.fold(0,(a,x)=>a+x.base);double get gst=>lines.fold(0,(a,x)=>a+x.tax);double get total=>taxable+gst;double get paidValue=>double.tryParse(paid.text)??0;
  @override void initState(){super.initState();load();}
  Future<void> load()async{final a=await widget.db.query('dm_parties',where:'type=?',whereArgs:[widget.purchase?'supplier':'customer'],orderBy:'name');final b=await widget.db.query('dm_products',orderBy:'name');if(mounted)setState((){parties=a;products=b;});}
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(widget.purchase?'New Purchase Invoice':'New Sales Invoice',style:const TextStyle(fontWeight:FontWeight.w900))),body:ListView(padding:const EdgeInsets.fromLTRB(18,5,18,30),children:[
    label(widget.purchase?'SUPPLIER / CREDITOR':'CUSTOMER'),
    DropdownButtonFormField<int?>(value:party,isExpanded:true,decoration:InputDecoration(labelText:widget.purchase?'Select supplier':'Select customer'),items:[const DropdownMenuItem<int?>(value:null,child:Text('Walk-in / Cash')), ...parties.map((p)=>DropdownMenuItem(value:p['id'] as int,child:Text(p['name'].toString())))],onChanged:(v)=>setState(()=>party=v)),
    const SizedBox(height:18),label('ITEMS'),
    FilledButton.tonalIcon(onPressed:products.isEmpty?()=>coreProduct(c,widget.db):pick,icon:const Icon(Icons.add),label:Text(products.isEmpty?'Add Product First':'Add Product')),
    const SizedBox(height:8),if(lines.isEmpty)emptyBox('No items','Add product, quantity, rate, discount and GST.'),...lines.asMap().entries.map((e)=>line(e.key,e.value)),
    const SizedBox(height:12),label('PAYMENT'),
    TextField(controller:paid,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Paid amount'),onChanged:(_)=>setState((){})),
    const SizedBox(height:8),DropdownButtonFormField<String>(value:mode,decoration:const InputDecoration(labelText:'Payment mode'),items:['Cash','UPI','Bank','Card','Cheque','Credit'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>setState(()=>mode=v!)),
    const SizedBox(height:12),Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:Column(children:[sumrow('Subtotal',money(subtotal)),sumrow('Discount',money(discount)),sumrow('Taxable',money(taxable)),sumrow('GST',money(gst)),const Divider(),sumrow('Grand Total',money(total),true),sumrow('Due',money((total-paidValue).clamp(0,double.infinity)),false,Colors.red)])),
    const SizedBox(height:14),FilledButton.icon(onPressed:save,icon:const Icon(Icons.save_rounded),label:const Text('Save Invoice'),style:FilledButton.styleFrom(minimumSize:const Size.fromHeight(54)))
  ]);
  Widget line(int i,CoreLine x)=>Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18)),child:Column(children:[
    Row(children:[Expanded(child:Text(x.name,style:const TextStyle(fontWeight:FontWeight.w800))),IconButton(onPressed:()=>setState(()=>lines.removeAt(i)),icon:const Icon(Icons.delete_outline,color:Colors.red))]),
    Row(children:[Expanded(child:TextField(controller:TextEditingController(text:x.qty.toString()),keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:'Qty '+x.unit),onChanged:(v){x.qty=double.tryParse(v)??0;setState((){});})),const SizedBox(width:7),Expanded(child:TextField(controller:TextEditingController(text:x.rate.toString()),keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Rate'),onChanged:(v){x.rate=double.tryParse(v)??0;setState((){});})),const SizedBox(width:7),Expanded(child:TextField(controller:TextEditingController(text:x.discount.toString()),keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Discount'),onChanged:(v){x.discount=double.tryParse(v)??0;setState((){});}))]
    ),Align(alignment:Alignment.centerRight,child:Text(money(x.total),style:const TextStyle(fontWeight:FontWeight.w900)))
  ]));
  Future<void> pick()async{final p=await showModalBottomSheet<Map<String,dynamic>>(context:context,builder:(_)=>ListView(padding:const EdgeInsets.all(18),children:[const Text('Select Product',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),...products.map((p)=>ListTile(title:Text(p['name'].toString()),subtitle:Text(p['unit'].toString()+' • GST '+p['gst'].toString()+'% • Stock '+p['qty'].toString()),trailing:Text(money((widget.purchase?p['buy']:p['sell']) as num)),onTap:()=>Navigator.pop(context,p)))]));if(p!=null)setState(()=>lines.add(CoreLine(p['id'] as int,p['name'].toString(),p['unit'].toString(),1,(widget.purchase?p['buy']:p['sell'] as num).toDouble(),(p['gst'] as num).toDouble(),0)));}
  Future<void> save()async{
    if(lines.isEmpty){msg(context,'Add at least one product.');return;}if(paidValue<0||paidValue>total){msg(context,'Paid amount cannot exceed total.');return;}
    final table=widget.purchase?'dm_purchases':'dm_sales';final itemTable=widget.purchase?'dm_purchase_items':'dm_sale_items';final itemKey=widget.purchase?'purchase_id':'sale_id';final n=(Sqflite.firstIntValue(await widget.db.rawQuery('SELECT COUNT(*) FROM '+table))??0)+1;final inv=(widget.purchase?'PUR-':'INV-')+n.toString().padLeft(5,'0');final due=total-paidValue;
    await widget.db.transaction((tx)async{
      final id=await tx.insert(table,{'invoice':inv,'date':now(),'party_id':party,'subtotal':subtotal,'discount':discount,'taxable':taxable,'cgst':gst/2,'sgst':gst/2,'igst':0,'total':total,'paid':paidValue,'due':due,'mode':mode});
      for(final x in lines){
        await tx.insert(itemTable,{itemKey:id,'product_id':x.id,'name':x.name,'qty':x.qty,'unit':x.unit,'rate':x.rate,'discount':x.discount,'gst':x.gst,'amount':x.total});
        await tx.rawUpdate('UPDATE dm_products SET qty=qty+? WHERE id=?',[widget.purchase?x.qty:-x.qty,x.id]);
        await tx.insert('dm_stock',{'product_id':x.id,'type':widget.purchase?'PURCHASE':'SALE','qty':widget.purchase?x.qty:-x.qty,'date':now(),'reference':inv});
      }
      if(party!=null&&due>0)await tx.rawUpdate('UPDATE dm_parties SET balance=balance+? WHERE id=?',[due,party]);
    });
    if(mounted){widget.refresh();Navigator.pop(context);msg(context,'Invoice '+inv+' saved.');}
  }
}

class CoreParties extends StatefulWidget{final Database db;final VoidCallback refresh;const CoreParties(this.db,this.refresh,{super.key});@override State<CoreParties> createState()=>_CorePartiesState();}
class _CorePartiesState extends State<CoreParties>{bool customer=true;@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Parties',style:TextStyle(fontWeight:FontWeight.w900)),actions:[IconButton(onPressed:()=>coreParty(c,widget.db,customer?'customer':'supplier'),icon:const Icon(Icons.person_add_alt_1_rounded))]),body:Column(children:[
 Padding(padding:const EdgeInsets.all(14),child:SegmentedButton<bool>(segments:const[ButtonSegment(value:true,label:Text('Customers')),ButtonSegment(value:false,label:Text('Suppliers'))],selected:{customer},onSelectionChanged:(x)=>setState(()=>customer=x.first))),
 Expanded(child:FutureBuilder(future:widget.db.query('dm_parties',where:'type=?',whereArgs:[customer?'customer':'supplier'],orderBy:'name'),builder:(c,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());final r=s.data!;return ListView(padding:const EdgeInsets.symmetric(horizontal:18),children:[if(r.isEmpty)emptyBox(customer?'No customers':'No suppliers',customer?'Add customers to manage receivables.':'Add suppliers to manage payables.'),...r.map((x)=>Card(child:ListTile(leading:CircleAvatar(backgroundColor:const Color(0xFFEEF0FF),child:Icon(customer?Icons.person:Icons.factory,color:const Color(0xFF5B5CE2))),title:Text(x['name'].toString(),style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text((x['phone']??'').toString()+' • '+(x['gstin']??'').toString()),trailing:Text(money(x['balance'] as num),style:const TextStyle(fontWeight:FontWeight.w900)))))];}))
]) );}

class CoreMore extends StatelessWidget{final Database db;final VoidCallback refresh;const CoreMore(this.db,this.refresh,{super.key});@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.fromLTRB(18,18,18,30),children:[
 titleBar('More','Inventory, payments, GST, reports and settings'),
 menu(c,'Inventory','Products, units, GST, stock and low-stock alerts',Icons.inventory_2_rounded,()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>CoreInventory(db,refresh)))),
 menu(c,'Payments','Customer collections and supplier payments',Icons.payments_rounded,()=>corePayments(c,db)),
 menu(c,'Expenses','Rent, salary, transport and other expenses',Icons.account_balance_wallet_rounded,()=>coreExpense(c,db)),
 menu(c,'Reports & Export','PDF, Excel and CSV',Icons.analytics_rounded,()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>CoreReports(db)))),
 menu(c,'Business Profile','GSTIN, address, UPI and invoice settings',Icons.storefront_rounded,()=>coreBusiness(c,db)),
 menu(c,'Backup & Restore','Offline data protection',Icons.backup_rounded,()=>msg(c,'Backup and restore will be added in the next release.')),
 menu(c,'PIN / Biometric','Protect business data',Icons.lock_rounded,()=>msg(c,'PIN and biometric protection will be added in the security release.'))
]);}

class CoreInventory extends StatelessWidget{final Database db;final VoidCallback refresh;const CoreInventory(this.db,this.refresh,{super.key});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Inventory',style:TextStyle(fontWeight:FontWeight.w900)),actions:[IconButton(onPressed:()=>coreProduct(c,db),icon:const Icon(Icons.add_circle_rounded))]),body:FutureBuilder(future:db.query('dm_products',orderBy:'name'),builder:(c,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());final r=s.data!;return ListView(padding:const EdgeInsets.all(18),children:[if(r.isEmpty)emptyBox('No products','Add products with KG, PCS, Litre or another unit.'),...r.map((x){final low=(x['qty'] as num)<=((x['min_qty'] as num));return Card(child:ListTile(leading:CircleAvatar(backgroundColor:low?const Color(0xFFFFE8E8):const Color(0xFFEEF0FF),child:Icon(Icons.inventory_2_rounded,color:low?Colors.red:const Color(0xFF5B5CE2))),title:Text(x['name'].toString(),style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(x['unit'].toString()+' • GST '+x['gst'].toString()+'% • HSN '+x['hsn'].toString()),trailing:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.end,children:[Text((x['qty'] as num).toStringAsFixed(2)+' '+x['unit'].toString(),style:const TextStyle(fontWeight:FontWeight.w900)),Text(money(x['sell'] as num),style:const TextStyle(fontSize:10))]))})]);});}

Future<void> coreProduct(BuildContext c,Database db)async{final n=TextEditingController(),sku=TextEditingController(),q=TextEditingController(),buy=TextEditingController(),sell=TextEditingController(),gst=TextEditingController(text:'0'),min=TextEditingController(text:'0'),hsn=TextEditingController();String unit='PCS';await showDialog(context:c,builder:(d)=>StatefulBuilder(builder:(d,set)=>AlertDialog(title:const Text('Add Product',style:TextStyle(fontWeight:FontWeight.w900)),content:SingleChildScrollView(child:Column(children:[
TextField(controller:n,decoration:const InputDecoration(labelText:'Product name *')),TextField(controller:sku,decoration:const InputDecoration(labelText:'SKU / Barcode')),TextField(controller:hsn,decoration:const InputDecoration(labelText:'HSN/SAC')),
Row(children:[Expanded(child:TextField(controller:q,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Opening stock'))),const SizedBox(width:7),Expanded(child:DropdownButtonFormField<String>(value:unit,decoration:const InputDecoration(labelText:'Unit'),items:['PCS','KG','GM','MG','LITRE','ML','METER','CM','BOX','PACKET','BAG','BOTTLE','DOZEN','PAIR','SET'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>set(()=>unit=v!)))]),
Row(children:[Expanded(child:TextField(controller:buy,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Purchase price'))),const SizedBox(width:7),Expanded(child:TextField(controller:sell,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Selling price')))]),
Row(children:[Expanded(child:TextField(controller:gst,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'GST %'))),const SizedBox(width:7),Expanded(child:TextField(controller:min,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Low-stock level')))])
])),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Cancel')),FilledButton(onPressed:()async{if(n.text.trim().isEmpty)return;await db.insert('dm_products',{'name':n.text.trim(),'sku':sku.text.trim(),'barcode':sku.text.trim(),'category':'','hsn':hsn.text.trim(),'unit':unit,'gst':double.tryParse(gst.text)??0,'buy':double.tryParse(buy.text)??0,'sell':double.tryParse(sell.text)??0,'wholesale':0,'qty':double.tryParse(q.text)??0,'min_qty':double.tryParse(min.text)??0});if(d.mounted)Navigator.pop(d);},child:const Text('Save'))]));}

Future<void> coreParty(BuildContext c,Database db,String type)async{final n=TextEditingController(),p=TextEditingController(),a=TextEditingController(),s=TextEditingController(text:'West Bengal'),g=TextEditingController(),l=TextEditingController(),days=TextEditingController();await showDialog(context:c,builder:(d)=>AlertDialog(title:Text(type=='customer'?'New Customer':'New Supplier',style:const TextStyle(fontWeight:FontWeight.w900)),content:SingleChildScrollView(child:Column(children:[TextField(controller:n,decoration:const InputDecoration(labelText:'Name *')),TextField(controller:p,decoration:const InputDecoration(labelText:'Phone')),TextField(controller:a,decoration:const InputDecoration(labelText:'Address')),TextField(controller:s,decoration:const InputDecoration(labelText:'State')),TextField(controller:g,decoration:const InputDecoration(labelText:'GSTIN')),Row(children:[Expanded(child:TextField(controller:l,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Credit limit'))),const SizedBox(width:7),Expanded(child:TextField(controller:days,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Credit days')))]))),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Cancel')),FilledButton(onPressed:()async{if(n.text.trim().isEmpty)return;await db.insert('dm_parties',{'name':n.text.trim(),'phone':p.text.trim(),'address':a.text.trim(),'state':s.text.trim(),'gstin':g.text.trim(),'type':type,'balance':0,'credit_limit':double.tryParse(l.text)??0,'credit_days':int.tryParse(days.text)??0});if(d.mounted)Navigator.pop(d);},child:const Text('Save'))]));}

Future<void> corePayment(BuildContext c,Database db,String type)async{final list=await db.query('dm_parties',where:'type=?',whereArgs:[type=='IN'?'customer':'supplier'],orderBy:'name');if(!c.mounted)return;int? party;String mode='Cash';final a=TextEditingController(),ref=TextEditingController();await showDialog(context:c,builder:(d)=>StatefulBuilder(builder:(d,set)=>AlertDialog(title:Text(type=='IN'?'Payment In':'Payment Out'),content:Column(mainAxisSize:MainAxisSize.min,children:[DropdownButtonFormField<int?>(value:party,decoration:InputDecoration(labelText:type=='IN'?'Customer':'Supplier'),items:list.map((x)=>DropdownMenuItem<int?>(value:x['id'] as int,child:Text(x['name'].toString()))).toList(),onChanged:(v)=>set(()=>party=v)),TextField(controller:a,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Amount')),DropdownButtonFormField<String>(value:mode,decoration:const InputDecoration(labelText:'Mode'),items:['Cash','UPI','Bank','Card','Cheque'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>set(()=>mode=v!)),TextField(controller:ref,decoration:const InputDecoration(labelText:'Reference'))]),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Cancel')),FilledButton(onPressed:()async{final v=double.tryParse(a.text)??0;if(v<=0)return;await db.insert('dm_payments',{'party_id':party,'type':type,'amount':v,'date':now(),'mode':mode,'reference':ref.text});if(party!=null)await db.rawUpdate('UPDATE dm_parties SET balance=balance-? WHERE id=?',[v,party]);if(d.mounted)Navigator.pop(d);},child:const Text('Save'))])));}

Future<void> coreExpense(BuildContext c,Database db)async{String cat='Other',mode='Cash';final a=TextEditingController(),n=TextEditingController();await showDialog(context:c,builder:(d)=>StatefulBuilder(builder:(d,set)=>AlertDialog(title:const Text('Business Expense'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:a,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Amount')),DropdownButtonFormField<String>(value:cat,decoration:const InputDecoration(labelText:'Category'),items:['Rent','Electricity','Salary','Transport','Packaging','Advertisement','Internet','Maintenance','Other'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>set(()=>cat=v!)),DropdownButtonFormField<String>(value:mode,decoration:const InputDecoration(labelText:'Payment mode'),items:['Cash','UPI','Bank','Card'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>set(()=>mode=v!)),TextField(controller:n,decoration:const InputDecoration(labelText:'Note'))]),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Cancel')),FilledButton(onPressed:()async{final v=double.tryParse(a.text)??0;if(v<=0)return;await db.insert('dm_expenses',{'category':cat,'amount':v,'date':now(),'mode':mode,'note':n.text});if(d.mounted)Navigator.pop(d);},child:const Text('Save'))])));}

Future<void> corePayments(BuildContext c,Database db)async{final r=await db.rawQuery('SELECT p.*,q.name party FROM dm_payments p LEFT JOIN dm_parties q ON q.id=p.party_id ORDER BY p.id DESC');if(!c.mounted)return;Navigator.push(c,MaterialPageRoute(builder:(_)=>SimplePage('Payments','Payment history',r)));}

class CoreReports extends StatelessWidget{final Database db;const CoreReports(this.db,{super.key});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Reports & Export',style:TextStyle(fontWeight:FontWeight.w900))),body:ListView(padding:const EdgeInsets.all(18),children:[
reportCard('Business Summary','Sales, purchase, profit, receivable, payable and expenses',Icons.analytics_rounded,()=>corePdf(c,db)),
reportCard('Excel Workbook','Separate sheets for sales, purchase, parties, products, payments and expenses',Icons.table_chart_rounded,()=>coreExcel(c,db)),
reportCard('CSV Export','Portable business data',Icons.data_object_rounded,()=>coreCsv(c,db)),
reportCard('PDF Report','A4 report ready to share or print',Icons.picture_as_pdf_rounded,()=>corePdf(c,db))
]));}
Future<Directory> coreFolder()async{final d=await getApplicationDocumentsDirectory();final f=Directory(join(d.path,'DokanMate_Exports'));if(!await f.exists())await f.create(recursive:true);return f;}
Future<void> coreShare(String p,String t)async=>Share.shareXFiles([XFile(p)],text:t);
Future<void> coreExcel(BuildContext c,Database db)async{try{final book=Excel.createExcel();for(final t in ['dm_sales','dm_purchases','dm_parties','dm_products','dm_payments','dm_expenses','dm_stock']){final r=await db.query(t);final sh=book[t];if(r.isEmpty){sh.appendRow([TextCellValue('No data')]);continue;}final k=r.first.keys.toList();sh.appendRow(k.map((x)=>TextCellValue(x)).toList());for(final row in r)sh.appendRow(k.map((x)=>excelCell(row[x])).toList());}final bytes=book.save();if(bytes==null)throw Exception('Workbook failed');final f=File(join((await coreFolder()).path,'DokanMate_'+DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())+'.xlsx'));await f.writeAsBytes(bytes,flush:true);await coreShare(f.path,'DokanMate Excel export');msg(c,'Excel exported successfully.');}catch(e){msg(c,'Excel failed: '+e.toString());}}
CellValue excelCell(Object? v){if(v==null)return TextCellValue('');if(v is int)return IntCellValue(v);if(v is num)return DoubleCellValue(v.toDouble());return TextCellValue(v.toString());}
Future<void> coreCsv(BuildContext c,Database db)async{try{final b=StringBuffer();for(final t in ['dm_sales','dm_purchases','dm_parties','dm_products','dm_payments','dm_expenses','dm_stock']){final r=await db.query(t);b.writeln(t.toUpperCase());if(r.isEmpty){b.writeln('No data');continue;}final k=r.first.keys.toList();b.writeln(k.join(','));for(final row in r)b.writeln(k.map((x)=>'"'+(row[x]??'').toString().replaceAll('"','""')+'"').join(','));b.writeln();}final f=File(join((await coreFolder()).path,'DokanMate_'+DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())+'.csv'));await f.writeAsString(b.toString(),flush:true);await coreShare(f.path,'DokanMate CSV export');msg(c,'CSV exported successfully.');}catch(e){msg(c,'CSV failed: '+e.toString());}}
Future<void> corePdf(BuildContext c,Database db)async{try{final s=(await db.rawQuery('SELECT COALESCE(SUM(total),0) sales,COALESCE(SUM(paid),0) paid,COALESCE(SUM(due),0) due FROM dm_sales')).first;final p=(await db.rawQuery('SELECT COALESCE(SUM(total),0) purchase,COALESCE(SUM(due),0) payable FROM dm_purchases')).first;final e=(await db.rawQuery('SELECT COALESCE(SUM(amount),0) expense FROM dm_expenses')).first;final result=(s['sales'] as num).toDouble()-(p['purchase'] as num).toDouble()-(e['expense'] as num).toDouble();final doc=pw.Document();doc.addPage(pw.MultiPage(pageFormat:PdfPageFormat.a4,build:(_)=>[pw.Text('DokanMate Business Report',style:pw.TextStyle(fontSize:24,fontWeight:pw.FontWeight.bold)),pw.Text(DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())),pw.SizedBox(height:18),pw.TableHelper.fromTextArray(headers:['Metric','Amount'],data:[['Sales',money(s['sales'] as num)],['Collection',money(s['paid'] as num)],['Receivable',money(s['due'] as num)],['Purchase',money(p['purchase'] as num)],['Payable',money(p['payable'] as num)],['Expenses',money(e['expense'] as num)],['Net result',money(result)]])),pw.SizedBox(height:20),pw.Text('DokanMate offline business manager') ]));final f=File(join((await coreFolder()).path,'DokanMate_Report_'+DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())+'.pdf'));await f.writeAsBytes(await doc.save(),flush:true);await coreShare(f.path,'DokanMate PDF report');msg(c,'PDF created successfully.');}catch(e){msg(c,'PDF failed: '+e.toString());}}


Future<void> coreBusiness(BuildContext c,Database db)async{
 final b=(await db.query('dm_business',where:'id=1')).first;final n=TextEditingController(text:b['name'].toString()),o=TextEditingController(text:b['owner'].toString()),p=TextEditingController(text:b['phone'].toString()),a=TextEditingController(text:b['address'].toString()),s=TextEditingController(text:b['state'].toString()),g=TextEditingController(text:b['gstin'].toString()),u=TextEditingController(text:b['upi'].toString());
 await showDialog(context:c,builder:(d)=>AlertDialog(title:const Text('Business Profile',style:TextStyle(fontWeight:FontWeight.w900)),content:SingleChildScrollView(child:Column(children:[TextField(controller:n,decoration:const InputDecoration(labelText:'Business name')),TextField(controller:o,decoration:const InputDecoration(labelText:'Owner')),TextField(controller:p,decoration:const InputDecoration(labelText:'Phone')),TextField(controller:a,decoration:const InputDecoration(labelText:'Address')),TextField(controller:s,decoration:const InputDecoration(labelText:'State')),TextField(controller:g,decoration:const InputDecoration(labelText:'GSTIN')),TextField(controller:u,decoration:const InputDecoration(labelText:'UPI ID')])),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Cancel')),FilledButton(onPressed:()async{await db.update('dm_business',{'name':n.text,'owner':o.text,'phone':p.text,'address':a.text,'state':s.text,'gstin':g.text,'upi':u.text},where:'id=1');if(d.mounted)Navigator.pop(d);},child:const Text('Save'))]));
}

Future<void> coreInvoicePdf(BuildContext c,Database db,int id,bool purchase)async{
 try{
  final t=purchase?'dm_purchases':'dm_sales';final it=purchase?'dm_purchase_items':'dm_sale_items';final key=purchase?'purchase_id':'sale_id';
  final r=await db.rawQuery('SELECT x.*,p.name party FROM '+t+' x LEFT JOIN dm_parties p ON p.id=x.party_id WHERE x.id=?',[id]);if(r.isEmpty)return;final x=r.first,items=await db.query(it,where:key+'=?',whereArgs:[id]);final b=(await db.query('dm_business',where:'id=1')).first;
  final doc=pw.Document();doc.addPage(pw.Page(pageFormat:PdfPageFormat.a4,build:(_)=>pw.Padding(padding:const pw.EdgeInsets.all(28),child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
   pw.Text(b['name'].toString(),style:pw.TextStyle(fontSize:24,fontWeight:pw.FontWeight.bold)),pw.Text(b['address'].toString()),pw.Text('Phone: '+b['phone'].toString()),pw.Text('GSTIN: '+b['gstin'].toString()),
   pw.SizedBox(height:18),pw.Text(purchase?'PURCHASE INVOICE':'TAX INVOICE',style:pw.TextStyle(fontSize:18,fontWeight:pw.FontWeight.bold)),pw.Text('Invoice: '+x['invoice'].toString()+'   Date: '+ddate(x['date'])),pw.Text((purchase?'Supplier: ':'Bill To: ')+(x['party']??'Walk-in').toString()),
   pw.SizedBox(height:14),pw.TableHelper.fromTextArray(headers:['Item','Qty','Unit','Rate','GST','Amount'],data:items.map((i)=>[i['name'],i['qty'].toString(),i['unit'],money(i['rate'] as num),i['gst'].toString()+'%',money(i['amount'] as num)]).toList()),
   pw.SizedBox(height:14),pw.Align(alignment:pw.Alignment.centerRight,child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.end,children:[pw.Text('Subtotal: '+money(x['subtotal'] as num)),pw.Text('Discount: '+money(x['discount'] as num)),pw.Text('GST: '+money(((x['cgst'] as num)+(x['sgst'] as num)+(x['igst'] as num)))),pw.Text('Grand Total: '+money(x['total'] as num),style:pw.TextStyle(fontSize:16,fontWeight:pw.FontWeight.bold)),pw.Text('Paid: '+money(x['paid'] as num)),pw.Text('Due: '+money(x['due'] as num))])),pw.SizedBox(height:28),pw.Text('Thank you.')
  ])));
  final f=File(join((await coreFolder()).path,x['invoice'].toString()+'.pdf'));await f.writeAsBytes(await doc.save(),flush:true);await coreShare(f.path,'DokanMate invoice');
 }catch(e){msg(c,'Invoice PDF failed: '+e.toString());}
}


Widget titleBar(String title,String sub,{List<Widget> actions=const[]})=>Padding(padding:const EdgeInsets.fromLTRB(18,18,18,10),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:28,fontWeight:FontWeight.w900)),Text(sub,style:const TextStyle(fontSize:12,color:Color(0xFF777B86)))])),...actions]));
Widget emptyBox(String a,String b)=>Container(padding:const EdgeInsets.all(22),margin:const EdgeInsets.only(bottom:12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:Column(children:[const Icon(Icons.inbox_rounded,size:40,color:Color(0xFFB0B3BE)),const SizedBox(height:8),Text(a,style:const TextStyle(fontWeight:FontWeight.w800)),Text(b,textAlign:TextAlign.center,style:const TextStyle(fontSize:12,color:Color(0xFF777B86)))]));
Widget menu(BuildContext c,String a,String b,IconData i,VoidCallback f)=>Card(child:ListTile(onTap:f,contentPadding:const EdgeInsets.all(10),leading:Container(width:48,height:48,decoration:BoxDecoration(color:const Color(0xFFEEF0FF),borderRadius:BorderRadius.circular(14)),child:Icon(i,color:const Color(0xFF5B5CE2))),title:Text(a,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(b,style:const TextStyle(fontSize:11)),trailing:const Icon(Icons.chevron_right_rounded)));
Widget label(String x)=>Padding(padding:const EdgeInsets.only(bottom:7,left:2),child:Text(x,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w900,color:Color(0xFF777B86),letterSpacing:1.1)));
Widget sumrow(String a,String b,[bool bold=false,Color? color])=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(a,style:TextStyle(color:color??const Color(0xFF70747F))),Text(b,style:TextStyle(fontWeight:bold?FontWeight.w900:FontWeight.w600,color:color))]));
Widget reportCard(String a,String b,IconData i,VoidCallback f)=>Card(child:ListTile(onTap:f,contentPadding:const EdgeInsets.all(12),leading:Container(width:48,height:48,decoration:BoxDecoration(color:const Color(0xFFEEF0FF),borderRadius:BorderRadius.circular(14)),child:Icon(i,color:const Color(0xFF5B5CE2))),title:Text(a,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(b,style:const TextStyle(fontSize:11)),trailing:const Icon(Icons.chevron_right_rounded)));
String now()=>DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
String ddate(Object? v){if(v==null)return '';try{return DateFormat('dd MMM yyyy').format(DateTime.parse(v.toString()));}catch(_){return v.toString();}}
Future<void> msg(BuildContext c,String x)=>showDialog(context:c,builder:(_)=>AlertDialog(title:const Text('DokanMate'),content:Text(x),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('OK'))]));
