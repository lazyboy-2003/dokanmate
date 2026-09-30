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
