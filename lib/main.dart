import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
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
    p.join(await getDatabasesPath(), 'dokanmate.db'),
    version: 1,
    onCreate: createDb,
  );
  await ensureDb(db);
  runApp(DokanMate(db));
}

Future<void> createDb(Database db, int version) async {
  await ensureDb(db);
}

Future<void> ensureDb(Database db) async {
  final tables = <String>[
    'CREATE TABLE IF NOT EXISTS business(id INTEGER PRIMARY KEY, name TEXT, owner TEXT, phone TEXT, address TEXT, state TEXT, gstin TEXT, upi TEXT)',
    'CREATE TABLE IF NOT EXISTS parties(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, phone TEXT, address TEXT, state TEXT, gstin TEXT, type TEXT, balance REAL DEFAULT 0, credit_limit REAL DEFAULT 0, credit_days INTEGER DEFAULT 0)',
    'CREATE TABLE IF NOT EXISTS products(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, sku TEXT, barcode TEXT, hsn TEXT, unit TEXT, gst REAL DEFAULT 0, buy REAL DEFAULT 0, sell REAL DEFAULT 0, wholesale REAL DEFAULT 0, qty REAL DEFAULT 0, min_qty REAL DEFAULT 0)',
    'CREATE TABLE IF NOT EXISTS sales(id INTEGER PRIMARY KEY AUTOINCREMENT, invoice TEXT, date TEXT, party_id INTEGER, subtotal REAL, discount REAL, taxable REAL, cgst REAL, sgst REAL, igst REAL, total REAL, paid REAL, due REAL, mode TEXT)',
    'CREATE TABLE IF NOT EXISTS sale_items(id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER, product_id INTEGER, name TEXT, qty REAL, unit TEXT, rate REAL, discount REAL, gst REAL, amount REAL)',
    'CREATE TABLE IF NOT EXISTS purchases(id INTEGER PRIMARY KEY AUTOINCREMENT, invoice TEXT, date TEXT, party_id INTEGER, subtotal REAL, discount REAL, taxable REAL, cgst REAL, sgst REAL, igst REAL, total REAL, paid REAL, due REAL, mode TEXT)',
    'CREATE TABLE IF NOT EXISTS purchase_items(id INTEGER PRIMARY KEY AUTOINCREMENT, purchase_id INTEGER, product_id INTEGER, name TEXT, qty REAL, unit TEXT, rate REAL, discount REAL, gst REAL, amount REAL)',
    'CREATE TABLE IF NOT EXISTS payments(id INTEGER PRIMARY KEY AUTOINCREMENT, party_id INTEGER, type TEXT, amount REAL, date TEXT, mode TEXT, reference TEXT)',
    'CREATE TABLE IF NOT EXISTS expenses(id INTEGER PRIMARY KEY AUTOINCREMENT, category TEXT, amount REAL, date TEXT, mode TEXT, note TEXT)',
    'CREATE TABLE IF NOT EXISTS stock_moves(id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER, type TEXT, qty REAL, date TEXT, reference TEXT)',
    'CREATE TABLE IF NOT EXISTS audit(id INTEGER PRIMARY KEY AUTOINCREMENT, action TEXT, date TEXT, details TEXT)'
  ];
  for (final sql in tables) {
    await db.execute(sql);
  }
  final b = await db.query('business', where: 'id=1');
  if (b.isEmpty) {
    await db.insert('business', {
      'id': 1,
      'name': 'My Business',
      'owner': '',
      'phone': '',
      'address': '',
      'state': 'West Bengal',
      'gstin': '',
      'upi': ''
    });
  }
}

String money(num n) => 'Rs ' + n.toStringAsFixed(2);
String stamp() => DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
String today() => DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
String prettyDate(Object? value) {
  if (value == null) return '';
  try {
    return DateFormat('dd MMM yyyy').format(DateTime.parse(value.toString()));
  } catch (_) {
    return value.toString();
  }
}

class DokanMate extends StatefulWidget {
  final Database db;
  const DokanMate(this.db, {super.key});
  @override
  State<DokanMate> createState() => _DokanMateState();
}

class _DokanMateState extends State<DokanMate> {
  int tab = 0;
  int refreshKey = 0;

  void refresh() {
    setState(() {
      refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(widget.db, key: ValueKey('home$refreshKey')),
      SalesPage(widget.db, refresh, key: ValueKey('sales$refreshKey')),
      PurchasePage(widget.db, refresh, key: ValueKey('purchase$refreshKey')),
      PartiesPage(widget.db, refresh, key: ValueKey('party$refreshKey')),
      MorePage(widget.db, refresh, key: ValueKey('more$refreshKey')),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DokanMate',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B5CE2)),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: IndexedStack(index: tab, children: pages),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (value) {
            setState(() {
              tab = value;
            });
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.receipt_long_rounded), label: 'Sales'),
            NavigationDestination(icon: Icon(Icons.shopping_cart_rounded), label: 'Purchase'),
            NavigationDestination(icon: Icon(Icons.people_alt_rounded), label: 'Parties'),
            NavigationDestination(icon: Icon(Icons.more_horiz_rounded), label: 'More'),
          ],
        ),
      ),
    );
  }
}

Widget header(String title, String subtitle, {List<Widget> actions = const []}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF777B86))),
            ],
          ),
        ),
        ...actions,
      ],
    ),
  );
}

Widget statCard(String title, String value, IconData icon) {
  return Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(icon, color: const Color(0xFF5B5CE2)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF777B86))),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          ],
        ),
      ],
    ),
  );
}

Widget emptyState(String title, String subtitle) {
  return Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        const Icon(Icons.inbox_rounded, size: 42, color: Color(0xFFB0B3BE)),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF777B86))),
      ],
    ),
  );
}

Widget quickAction(BuildContext context, String title, IconData icon, VoidCallback onTap) {
  return SizedBox(
    width: 105,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF5B5CE2)),
            const SizedBox(height: 7),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
          ],
        ),
      ),
    ),
  );
}

class HomePage extends StatelessWidget {
  final Database db;
  const HomePage(this.db, {super.key});

  Future<Map<String, double>> totals() async {
    final sales = (await db.rawQuery(
      'SELECT COALESCE(SUM(total),0) total, COALESCE(SUM(paid),0) paid, COALESCE(SUM(due),0) due FROM sales'
    )).first;
    final purchase = (await db.rawQuery(
      'SELECT COALESCE(SUM(total),0) total, COALESCE(SUM(due),0) due FROM purchases'
    )).first;
    final expense = (await db.rawQuery(
      'SELECT COALESCE(SUM(amount),0) total FROM expenses'
    )).first;
    final stock = (await db.rawQuery(
      'SELECT COALESCE(SUM(qty*buy),0) total FROM products'
    )).first;

    return {
      'sales': (sales['total'] as num).toDouble(),
      'paid': (sales['paid'] as num).toDouble(),
      'receivable': (sales['due'] as num).toDouble(),
      'purchase': (purchase['total'] as num).toDouble(),
      'payable': (purchase['due'] as num).toDouble(),
      'expense': (expense['total'] as num).toDouble(),
      'stock': (stock['total'] as num).toDouble(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: totals(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final x = snapshot.data!;
        final result = x['sales']! - x['purchase']! - x['expense']!;

        return ListView(
          padding: const EdgeInsets.only(bottom: 25),
          children: [
            header(
              'DokanMate',
              'Modern offline business manager',
              actions: [
                IconButton(
                  onPressed: () => businessDialog(context, db),
                  icon: const Icon(Icons.storefront_rounded),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF24264D), Color(0xFF635BDB)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BUSINESS OVERVIEW',
                      style: TextStyle(color: Color(0xFFC8C9FF), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 8),
                    Text(money(x['sales']!), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                    const Text('Total sales', style: TextStyle(color: Color(0xFFD9DBEE))),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: _Hero('Collection', money(x['paid']!))),
                        const SizedBox(width: 8),
                        Expanded(child: _Hero('Net result', money(result))),
                      ],
                    )
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
              child: const Text('Quick actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  quickAction(context, 'New Sale', Icons.add_shopping_cart_rounded, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePage(db, false, () {})));
                  }),
                  quickAction(context, 'Purchase', Icons.shopping_bag_rounded, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePage(db, true, () {})));
                  }),
                  quickAction(context, 'Payment In', Icons.call_received_rounded, () => paymentDialog(context, db, true)),
                  quickAction(context, 'Payment Out', Icons.call_made_rounded, () => paymentDialog(context, db, false)),
                  quickAction(context, 'Expense', Icons.account_balance_wallet_rounded, () => expenseDialog(context, db)),
                  quickAction(context, 'Product', Icons.inventory_2_rounded, () => productDialog(context, db)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
              child: const Text('Business snapshot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: [
                  statCard('Receivable', money(x['receivable']!), Icons.account_balance_wallet_rounded),
                  statCard('Payable', money(x['payable']!), Icons.request_quote_rounded),
                  statCard('Stock value', money(x['stock']!), Icons.inventory_2_rounded),
                  statCard('Expenses', money(x['expense']!), Icons.money_off_rounded),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  final String title;
  final String value;
  const _Hero(this.title, this.value);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(color: Colors.white.withOpacity(.1), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFFD2D4E8), fontSize: 10)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }
}

class SalesPage extends StatelessWidget {
  final Database db;
  final VoidCallback refresh;
  const SalesPage(this.db, this.refresh, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePage(db, false, refresh))),
            icon: const Icon(Icons.add_circle_rounded),
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: db.rawQuery('SELECT s.*, p.name party FROM sales s LEFT JOIN parties p ON p.id=s.party_id ORDER BY s.id DESC'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snapshot.data!;
          if (rows.isEmpty) {
            return Padding(padding: const EdgeInsets.all(18), child: emptyState('No sales yet', 'Create an item-based sales invoice.'));
          }
          return ListView(
            padding: const EdgeInsets.all(18),
            children: rows.map((x) {
              return Card(
                child: ListTile(
                  onTap: () => invoicePdf(context, db, (x['id'] as num).toInt(), false),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEEF0FF),
                    child: Icon(Icons.receipt_long_rounded, color: Color(0xFF5B5CE2)),
                  ),
                  title: Text(x['invoice'].toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text((x['party'] ?? 'Walk-in').toString() + ' • ' + prettyDate(x['date'])),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(money(x['total'] as num), style: const TextStyle(fontWeight: FontWeight.w900)),
                      Text(
                        (x['due'] as num) > 0 ? 'Due ' + money(x['due'] as num) : 'Paid',
                        style: TextStyle(fontSize: 10, color: (x['due'] as num) > 0 ? Colors.red : Colors.green),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class PurchasePage extends StatelessWidget {
  final Database db;
  final VoidCallback refresh;
  const PurchasePage(this.db, this.refresh, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePage(db, true, refresh))),
            icon: const Icon(Icons.add_circle_rounded),
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: db.rawQuery('SELECT s.*, p.name party FROM purchases s LEFT JOIN parties p ON p.id=s.party_id ORDER BY s.id DESC'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snapshot.data!;
          if (rows.isEmpty) {
            return Padding(padding: const EdgeInsets.all(18), child: emptyState('No purchases yet', 'Create purchase invoices and stock will update automatically.'));
          }
          return ListView(
            padding: const EdgeInsets.all(18),
            children: rows.map((x) {
              return Card(
                child: ListTile(
                  onTap: () => invoicePdf(context, db, (x['id'] as num).toInt(), true),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEAF8F2),
                    child: Icon(Icons.shopping_bag_rounded, color: Color(0xFF15936C)),
                  ),
                  title: Text(x['invoice'].toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text((x['party'] ?? 'Supplier').toString() + ' • ' + prettyDate(x['date'])),
                  trailing: Text(money(x['total'] as num), style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class InvoiceLine {
  final int productId;
  final String name;
  final String unit;
  final double rate;
  final double gst;
  double qty;
  double discount;
  InvoiceLine(this.productId, this.name, this.unit, this.rate, this.gst, this.qty, this.discount);
  double get base => qty * rate - discount;
  double get tax => base * gst / 100;
  double get total => base + tax;
}

class InvoicePage extends StatefulWidget {
  final Database db;
  final bool purchase;
  final VoidCallback refresh;
  const InvoicePage(this.db, this.purchase, this.refresh, {super.key});
  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  List<Map<String, Object?>> parties = [];
  List<Map<String, Object?>> products = [];
  List<InvoiceLine> lines = [];
  int? partyId;
  String mode = 'Cash';
  final paid = TextEditingController();

  double get subtotal => lines.fold(0, (sum, line) => sum + line.qty * line.rate);
  double get discount => lines.fold(0, (sum, line) => sum + line.discount);
  double get taxable => lines.fold(0, (sum, line) => sum + line.base);
  double get gstTotal => lines.fold(0, (sum, line) => sum + line.tax);
  double get total => taxable + gstTotal;
  double get paidAmount => double.tryParse(paid.text) ?? 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final pRows = await widget.db.query(
      'parties',
      where: 'type=?',
      whereArgs: [widget.purchase ? 'supplier' : 'customer'],
      orderBy: 'name',
    );
    final productRows = await widget.db.query('products', orderBy: 'name');
    if (mounted) {
      setState(() {
        parties = pRows;
        products = productRows;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.purchase ? 'New Purchase Invoice' : 'New Sales Invoice', style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          _label(widget.purchase ? 'SUPPLIER / CREDITOR' : 'CUSTOMER'),
          DropdownButtonFormField<int?>(
            value: partyId,
            isExpanded: true,
            decoration: InputDecoration(labelText: widget.purchase ? 'Select supplier' : 'Select customer'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Walk-in / Cash')),
              ...parties.map((p) => DropdownMenuItem<int?>(value: p['id'] as int, child: Text(p['name'].toString()))),
            ],
            onChanged: (value) => setState(() => partyId = value),
          ),
          const SizedBox(height: 18),
          _label('ITEMS'),
          FilledButton.tonalIcon(
            onPressed: products.isEmpty ? () => productDialog(context, widget.db) : selectProduct,
            icon: const Icon(Icons.add),
            label: Text(products.isEmpty ? 'Add Product First' : 'Add Product'),
          ),
          const SizedBox(height: 10),
          if (lines.isEmpty) emptyState('No items', 'Add product, quantity, rate, discount and GST.'),
          ...lines.asMap().entries.map((entry) => lineCard(entry.key, entry.value)),
          const SizedBox(height: 12),
          _label('PAYMENT'),
          TextField(
            controller: paid,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Paid amount'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: mode,
            decoration: const InputDecoration(labelText: 'Payment mode'),
            items: ['Cash', 'UPI', 'Bank', 'Card', 'Cheque', 'Credit']
                .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                .toList(),
            onChanged: (value) => setState(() => mode = value!),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                _sum('Subtotal', money(subtotal)),
                _sum('Discount', money(discount)),
                _sum('Taxable', money(taxable)),
                _sum('GST', money(gstTotal)),
                const Divider(),
                _sum('Grand Total', money(total), bold: true),
                _sum('Due', money((total - paidAmount).clamp(0, double.infinity)), color: Colors.red),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: saveInvoice,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save Invoice'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          ),
        ],
      ),
    );
  }

  Widget lineCard(int index, InvoiceLine line) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(line.name, style: const TextStyle(fontWeight: FontWeight.w800))),
              IconButton(
                onPressed: () => setState(() => lines.removeAt(index)),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: _numberField('Qty ' + line.unit, line.qty, (v) => line.qty = v)),
              const SizedBox(width: 7),
              Expanded(child: _numberField('Rate', line.rate, null, enabled: false)),
              const SizedBox(width: 7),
              Expanded(child: _numberField('Discount', line.discount, (v) => line.discount = v)),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(money(line.total), style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _numberField(String label, double value, void Function(double)? onChanged, {bool enabled = true}) {
    return TextField(
      enabled: enabled,
      controller: TextEditingController(text: value.toString()),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      onChanged: (v) {
        if (onChanged != null) {
          onChanged(double.tryParse(v) ?? 0);
          setState(() {});
        }
      },
    );
  }

  Future<void> selectProduct() async {
    final chosen = await showModalBottomSheet<Map<String, Object?>>(
      context: context,
      builder: (sheetContext) {
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text('Select Product', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            ...products.map((p) {
              final price = widget.purchase ? p['buy'] as num : p['sell'] as num;
              return ListTile(
                title: Text(p['name'].toString()),
                subtitle: Text(p['unit'].toString() + ' • GST ' + p['gst'].toString() + '% • Stock ' + p['qty'].toString()),
                trailing: Text(money(price)),
                onTap: () => Navigator.pop(sheetContext, p),
              );
            }),
          ],
        );
      },
    );
    if (chosen != null) {
      final price = widget.purchase ? chosen['buy'] as num : chosen['sell'] as num;
      setState(() {
        lines.add(InvoiceLine(
          chosen['id'] as int,
          chosen['name'].toString(),
          chosen['unit'].toString(),
          price.toDouble(),
          (chosen['gst'] as num).toDouble(),
          1,
          0,
        ));
      });
    }
  }

  Future<void> saveInvoice() async {
    if (lines.isEmpty) {
      showMsg(context, 'Add at least one product.');
      return;
    }
    if (paidAmount < 0 || paidAmount > total) {
      showMsg(context, 'Paid amount cannot exceed invoice total.');
      return;
    }

    final business = (await widget.db.query('business', where: 'id=1')).first;
    String partyState = business['state'].toString();
    if (partyId != null) {
      final p = await widget.db.query('parties', where: 'id=?', whereArgs: [partyId]);
      if (p.isNotEmpty) partyState = p.first['state'].toString();
    }
    final sameState = business['state'].toString().trim().toLowerCase() == partyState.trim().toLowerCase();
    final cgst = sameState ? gstTotal / 2 : 0.0;
    final sgst = sameState ? gstTotal / 2 : 0.0;
    final igst = sameState ? 0.0 : gstTotal;
    final table = widget.purchase ? 'purchases' : 'sales';
    final itemTable = widget.purchase ? 'purchase_items' : 'sale_items';
    final itemKey = widget.purchase ? 'purchase_id' : 'sale_id';
    final count = Sqflite.firstIntValue(await widget.db.rawQuery('SELECT COUNT(*) FROM ' + table)) ?? 0;
    final invoice = (widget.purchase ? 'PUR-' : 'INV-') + (count + 1).toString().padLeft(5, '0');
    final due = total - paidAmount;

    await widget.db.transaction((tx) async {
      final id = await tx.insert(table, {
        'invoice': invoice,
        'date': today(),
        'party_id': partyId,
        'subtotal': subtotal,
        'discount': discount,
        'taxable': taxable,
        'cgst': cgst,
        'sgst': sgst,
        'igst': igst,
        'total': total,
        'paid': paidAmount,
        'due': due,
        'mode': mode,
      });

      for (final line in lines) {
        await tx.insert(itemTable, {
          itemKey: id,
          'product_id': line.productId,
          'name': line.name,
          'qty': line.qty,
          'unit': line.unit,
          'rate': line.rate,
          'discount': line.discount,
          'gst': line.gst,
          'amount': line.total,
        });
        final delta = widget.purchase ? line.qty : -line.qty;
        await tx.rawUpdate('UPDATE products SET qty=qty+? WHERE id=?', [delta, line.productId]);
        await tx.insert('stock_moves', {
          'product_id': line.productId,
          'type': widget.purchase ? 'PURCHASE' : 'SALE',
          'qty': delta,
          'date': today(),
          'reference': invoice,
        });
      }

      if (partyId != null && due > 0) {
        await tx.rawUpdate('UPDATE parties SET balance=balance+? WHERE id=?', [due, partyId]);
      }
      await tx.insert('audit', {'action': widget.purchase ? 'Purchase' : 'Sale', 'date': today(), 'details': invoice});
    });

    if (mounted) {
      widget.refresh();
      Navigator.pop(context);
      showMsg(context, 'Invoice ' + invoice + ' saved successfully.');
    }
  }
}

Widget _label(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 7, left: 2),
    child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF777B86), letterSpacing: 1.1)),
  );
}

Widget _sum(String a, String b, {bool bold = false, Color? color}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(a, style: TextStyle(color: color ?? const Color(0xFF70747F))),
        Text(b, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w600, color: color)),
      ],
    ),
  );
}

class PartiesPage extends StatefulWidget {
  final Database db;
  final VoidCallback refresh;
  const PartiesPage(this.db, this.refresh, {super.key});
  @override
  State<PartiesPage> createState() => _PartiesPageState();
}

class _PartiesPageState extends State<PartiesPage> {
  bool customer = true;

  @override
  Widget build(BuildContext context) {
    final type = customer ? 'customer' : 'supplier';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parties', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(onPressed: () => partyDialog(context, widget.db, type), icon: const Icon(Icons.person_add_alt_1_rounded))
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Customers')),
                ButtonSegment(value: false, label: Text('Suppliers')),
              ],
              selected: {customer},
              onSelectionChanged: (value) => setState(() => customer = value.first),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, Object?>>>(
              future: widget.db.query('parties', where: 'type=?', whereArgs: [type], orderBy: 'name'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final rows = snapshot.data!;
                if (rows.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(18),
                    child: emptyState(customer ? 'No customers' : 'No suppliers', 'Add parties to track credit and payments.'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final x = rows[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFEEF0FF),
                          child: Icon(customer ? Icons.person : Icons.factory, color: const Color(0xFF5B5CE2)),
                        ),
                        title: Text(x['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text((x['phone'] ?? '').toString() + ' • ' + (x['gstin'] ?? '').toString()),
                        trailing: Text(money((x['balance'] as num?) ?? 0), style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MorePage extends StatelessWidget {
  final Database db;
  final VoidCallback refresh;
  const MorePage(this.db, this.refresh, {super.key});

  Widget menu(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(10),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: const Color(0xFFEEF0FF), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: const Color(0xFF5B5CE2)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        header('More', 'Inventory, reports, GST and business tools'),
        menu('Inventory', 'Products, units, stock and low-stock alerts', Icons.inventory_2_rounded, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => InventoryPage(db, refresh)));
        }),
        menu('Payments', 'Payment In, Payment Out and ledger', Icons.payments_rounded, () => paymentsPage(context, db)),
        menu('Expenses', 'Rent, salary, transport and other expenses', Icons.account_balance_wallet_rounded, () => expenseDialog(context, db)),
        menu('Reports & Export', 'PDF, Excel and CSV', Icons.analytics_rounded, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsPage(db)));
        }),
        menu('Business Profile', 'GSTIN, address, UPI and invoice settings', Icons.storefront_rounded, () => businessDialog(context, db)),
        menu('Backup & Restore', 'Offline data backup', Icons.backup_rounded, () => showMsg(context, 'Backup and restore will be added next.')),
        menu('PIN / Biometric', 'Protect business data', Icons.lock_rounded, () => showMsg(context, 'PIN and biometric protection will be added next.')),
      ],
    );
  }
}

class InventoryPage extends StatelessWidget {
  final Database db;
  final VoidCallback refresh;
  const InventoryPage(this.db, this.refresh, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(onPressed: () => productDialog(context, db), icon: const Icon(Icons.add_circle_rounded))],
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: db.query('products', orderBy: 'name'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snapshot.data!;
          if (rows.isEmpty) return Padding(padding: const EdgeInsets.all(18), child: emptyState('No products', 'Add KG, PCS, GM, Litre, Box and other units.'));
          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final x = rows[index];
              final qty = (x['qty'] as num?) ?? 0;
              final low = qty <= ((x['min_qty'] as num?) ?? 0);
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: low ? const Color(0xFFFFE8E8) : const Color(0xFFEEF0FF),
                    child: Icon(Icons.inventory_2_rounded, color: low ? Colors.red : const Color(0xFF5B5CE2)),
                  ),
                  title: Text(x['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(x['unit'].toString() + ' • GST ' + x['gst'].toString() + '% • HSN ' + x['hsn'].toString()),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(qty.toStringAsFixed(2) + ' ' + x['unit'].toString(), style: const TextStyle(fontWeight: FontWeight.w900)),
                      Text(money((x['sell'] as num?) ?? 0), style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> productDialog(BuildContext context, Database db) async {
  final name = TextEditingController();
  final sku = TextEditingController();
  final hsn = TextEditingController();
  final stock = TextEditingController();
  final buy = TextEditingController();
  final sell = TextEditingController();
  final gst = TextEditingController(text: '0');
  final min = TextEditingController(text: '0');
  String unit = 'PCS';

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.w900)),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Product name *')),
                  TextField(controller: sku, decoration: const InputDecoration(labelText: 'SKU / Barcode')),
                  TextField(controller: hsn, decoration: const InputDecoration(labelText: 'HSN/SAC')),
                  TextField(controller: stock, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Opening stock')),
                  DropdownButtonFormField<String>(
                    value: unit,
                    decoration: const InputDecoration(labelText: 'Measurement unit'),
                    items: const ['PCS','KG','GM','MG','LITRE','ML','METER','CM','BOX','PACKET','BAG','BOTTLE','DOZEN','PAIR','SET']
                        .map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => unit = value);
                    },
                  ),
                  TextField(controller: buy, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Purchase price')),
                  TextField(controller: sell, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Selling price')),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: gst, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'GST %'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: min, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Low stock'))),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  if (name.text.trim().isEmpty) return;
                  await db.insert('products', {
                    'name': name.text.trim(),
                    'sku': sku.text.trim(),
                    'barcode': sku.text.trim(),
                    'hsn': hsn.text.trim(),
                    'unit': unit,
                    'gst': double.tryParse(gst.text) ?? 0,
                    'buy': double.tryParse(buy.text) ?? 0,
                    'sell': double.tryParse(sell.text) ?? 0,
                    'wholesale': 0,
                    'qty': double.tryParse(stock.text) ?? 0,
                    'min_qty': double.tryParse(min.text) ?? 0,
                  });
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> partyDialog(BuildContext context, Database db, String type) async {
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  final state = TextEditingController(text: 'West Bengal');
  final gstin = TextEditingController();
  final limit = TextEditingController();
  final days = TextEditingController();

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(type == 'customer' ? 'New Customer' : 'New Supplier'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name *')),
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
              TextField(controller: state, decoration: const InputDecoration(labelText: 'State')),
              TextField(controller: gstin, decoration: const InputDecoration(labelText: 'GSTIN')),
              TextField(controller: limit, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Credit limit')),
              TextField(controller: days, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Credit days')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              await db.insert('parties', {
                'name': name.text.trim(),
                'phone': phone.text.trim(),
                'address': address.text.trim(),
                'state': state.text.trim(),
                'gstin': gstin.text.trim(),
                'type': type,
                'balance': 0,
                'credit_limit': double.tryParse(limit.text) ?? 0,
                'credit_days': int.tryParse(days.text) ?? 0,
              });
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

Future<void> paymentDialog(BuildContext context, Database db, bool incoming) async {
  final type = incoming ? 'customer' : 'supplier';
  final rows = await db.query('parties', where: 'type=?', whereArgs: [type], orderBy: 'name');
  if (!context.mounted) return;
  int? party;
  String mode = 'Cash';
  final amount = TextEditingController();
  final reference = TextEditingController();

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(incoming ? 'Payment In' : 'Payment Out'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int?>(
                  value: party,
                  decoration: InputDecoration(labelText: incoming ? 'Customer' : 'Supplier'),
                  items: rows.map((x) => DropdownMenuItem<int?>(value: x['id'] as int, child: Text(x['name'].toString()))).toList(),
                  onChanged: (value) => setDialogState(() => party = value),
                ),
                TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount')),
                DropdownButtonFormField<String>(
                  value: mode,
                  decoration: const InputDecoration(labelText: 'Payment mode'),
                  items: ['Cash','UPI','Bank','Card','Cheque'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
                  onChanged: (value) => setDialogState(() => mode = value!),
                ),
                TextField(controller: reference, decoration: const InputDecoration(labelText: 'Reference')),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final value = double.tryParse(amount.text) ?? 0;
                  if (value <= 0) return;
                  await db.insert('payments', {'party_id': party, 'type': incoming ? 'IN' : 'OUT', 'amount': value, 'date': today(), 'mode': mode, 'reference': reference.text});
                  if (party != null) {
                    await db.rawUpdate('UPDATE parties SET balance=balance-? WHERE id=?', [value, party]);
                  }
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> expenseDialog(BuildContext context, Database db) async {
  String category = 'Other';
  String mode = 'Cash';
  final amount = TextEditingController();
  final note = TextEditingController();

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Business Expense'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount')),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ['Rent','Electricity','Salary','Transport','Packaging','Advertisement','Internet','Maintenance','Other'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
                  onChanged: (value) => setDialogState(() => category = value!),
                ),
                DropdownButtonFormField<String>(
                  value: mode,
                  decoration: const InputDecoration(labelText: 'Payment mode'),
                  items: ['Cash','UPI','Bank','Card'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
                  onChanged: (value) => setDialogState(() => mode = value!),
                ),
                TextField(controller: note, decoration: const InputDecoration(labelText: 'Note')),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final value = double.tryParse(amount.text) ?? 0;
                  if (value <= 0) return;
                  await db.insert('expenses', {'category': category, 'amount': value, 'date': today(), 'mode': mode, 'note': note.text});
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

class ReportsPage extends StatelessWidget {
  final Database db;
  const ReportsPage(this.db, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Export', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _report(context, 'Business Summary', 'Sales, purchase, due, expenses and result', Icons.analytics_rounded, () => exportPdf(context, db)),
          _report(context, 'Excel Workbook', 'Sales, purchase, parties, products, payments and expenses', Icons.table_chart_rounded, () => exportExcel(context, db)),
          _report(context, 'CSV Export', 'Portable business data', Icons.data_object_rounded, () => exportCsv(context, db)),
          _report(context, 'PDF Report', 'A4 printable report', Icons.picture_as_pdf_rounded, () => exportPdf(context, db)),
        ],
      ),
    );
  }

  Widget _report(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: const Color(0xFFEEF0FF), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: const Color(0xFF5B5CE2)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

Future<Directory> exportFolder() async {
  final base = await getApplicationDocumentsDirectory();
  final folder = Directory(p.join(base.path, 'DokanMate_Exports'));
  if (!await folder.exists()) await folder.create(recursive: true);
  return folder;
}

Future<void> shareFile(String path, String text) async {
  await Share.shareXFiles([XFile(path)], text: text);
}

CellValue excelValue(Object? value) {
  if (value == null) return TextCellValue('');
  if (value is int) return IntCellValue(value);
  if (value is num) return DoubleCellValue(value.toDouble());
  return TextCellValue(value.toString());
}

Future<void> exportExcel(BuildContext context, Database db) async {
  try {
    final book = Excel.createExcel();
    final tables = ['sales','purchases','parties','products','payments','expenses','stock_moves'];
    for (final table in tables) {
      final rows = await db.query(table);
      final sheet = book[table];
      if (rows.isEmpty) {
        sheet.appendRow([TextCellValue('No data')]);
        continue;
      }
      final keys = rows.first.keys.toList();
      sheet.appendRow(keys.map((x) => TextCellValue(x)).toList());
      for (final row in rows) {
        sheet.appendRow(keys.map((key) => excelValue(row[key])).toList());
      }
    }
    final bytes = book.save();
    if (bytes == null) throw Exception('Excel creation failed');
    final file = File(p.join((await exportFolder()).path, 'DokanMate_' + stamp() + '.xlsx'));
    await file.writeAsBytes(bytes, flush: true);
    await shareFile(file.path, 'DokanMate Excel export');
    showMsg(context, 'Excel file created successfully.');
  } catch (e) {
    showMsg(context, 'Excel export failed: ' + e.toString());
  }
}

Future<void> exportCsv(BuildContext context, Database db) async {
  try {
    final buffer = StringBuffer();
    final tables = ['sales','purchases','parties','products','payments','expenses','stock_moves'];
    for (final table in tables) {
      final rows = await db.query(table);
      buffer.writeln(table.toUpperCase());
      if (rows.isEmpty) {
        buffer.writeln('No data');
        continue;
      }
      final keys = rows.first.keys.toList();
      buffer.writeln(keys.join(','));
      for (final row in rows) {
        buffer.writeln(keys.map((key) {
          final value = (row[key] ?? '').toString().replaceAll('"', '""');
          return '"' + value + '"';
        }).join(','));
      }
      buffer.writeln();
    }
    final file = File(p.join((await exportFolder()).path, 'DokanMate_' + stamp() + '.csv'));
    await file.writeAsString(buffer.toString(), flush: true);
    await shareFile(file.path, 'DokanMate CSV export');
    showMsg(context, 'CSV file created successfully.');
  } catch (e) {
    showMsg(context, 'CSV export failed: ' + e.toString());
  }
}

Future<void> exportPdf(BuildContext context, Database db) async {
  try {
    final s = (await db.rawQuery('SELECT COALESCE(SUM(total),0) sales, COALESCE(SUM(paid),0) paid, COALESCE(SUM(due),0) due FROM sales')).first;
    final pch = (await db.rawQuery('SELECT COALESCE(SUM(total),0) total, COALESCE(SUM(due),0) due FROM purchases')).first;
    final ex = (await db.rawQuery('SELECT COALESCE(SUM(amount),0) total FROM expenses')).first;
    final result = (s['sales'] as num).toDouble() - (pch['total'] as num).toDouble() - (ex['total'] as num).toDouble();
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) {
          return [
            pw.Text('DokanMate Business Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text(DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())),
            pw.SizedBox(height: 18),
            pw.TableHelper.fromTextArray(
              headers: ['Metric', 'Amount'],
              data: [
                ['Sales', money(s['sales'] as num)],
                ['Collection', money(s['paid'] as num)],
                ['Receivable', money(s['due'] as num)],
                ['Purchase', money(pch['total'] as num)],
                ['Payable', money(pch['due'] as num)],
                ['Expenses', money(ex['total'] as num)],
                ['Net result', money(result)],
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('DokanMate offline business manager'),
          ];
        },
      ),
    );

    final file = File(p.join((await exportFolder()).path, 'DokanMate_Report_' + stamp() + '.pdf'));
    await file.writeAsBytes(await doc.save(), flush: true);
    await shareFile(file.path, 'DokanMate PDF report');
    showMsg(context, 'PDF report created successfully.');
  } catch (e) {
    showMsg(context, 'PDF export failed: ' + e.toString());
  }
}

Future<void> invoicePdf(BuildContext context, Database db, int id, bool purchase) async {
  try {
    final table = purchase ? 'purchases' : 'sales';
    final itemTable = purchase ? 'purchase_items' : 'sale_items';
    final itemKey = purchase ? 'purchase_id' : 'sale_id';
    final rows = await db.rawQuery(
      'SELECT x.*, p.name party FROM ' + table + ' x LEFT JOIN parties p ON p.id=x.party_id WHERE x.id=?',
      [id],
    );
    if (rows.isEmpty) return;
    final x = rows.first;
    final items = await db.query(itemTable, where: itemKey + '=?', whereArgs: [id]);
    final business = (await db.query('business', where: 'id=1')).first;

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) {
          final widgets = <pw.Widget>[
            pw.Text(business['name'].toString(), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text(business['address'].toString()),
            pw.Text('Phone: ' + business['phone'].toString()),
            pw.Text('GSTIN: ' + business['gstin'].toString()),
            pw.SizedBox(height: 15),
            pw.Text(purchase ? 'PURCHASE INVOICE' : 'TAX INVOICE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text('Invoice: ' + x['invoice'].toString()),
            pw.Text('Date: ' + prettyDate(x['date'])),
            pw.Text((purchase ? 'Supplier: ' : 'Bill To: ') + (x['party'] ?? 'Walk-in').toString()),
            pw.SizedBox(height: 12),
          ];
          for (final item in items) {
            widgets.add(pw.Text(
              item['name'].toString() +
              ' | ' + item['qty'].toString() + ' ' + item['unit'].toString() +
              ' | Rate ' + money(item['rate'] as num) +
              ' | GST ' + item['gst'].toString() + '%' +
              ' | ' + money(item['amount'] as num),
            ));
          }
          widgets.add(pw.Divider());
          widgets.add(pw.Text('Subtotal: ' + money(x['subtotal'] as num)));
          widgets.add(pw.Text('Discount: ' + money(x['discount'] as num)));
          widgets.add(pw.Text('GST: ' + money((x['cgst'] as num) + (x['sgst'] as num) + (x['igst'] as num))));
          widgets.add(pw.Text('Grand Total: ' + money(x['total'] as num), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)));
          widgets.add(pw.Text('Paid: ' + money(x['paid'] as num)));
          widgets.add(pw.Text('Due: ' + money(x['due'] as num)));
          return widgets;
        },
      ),
    );

    final file = File(p.join((await exportFolder()).path, x['invoice'].toString() + '.pdf'));
    await file.writeAsBytes(await doc.save(), flush: true);
    await shareFile(file.path, 'DokanMate invoice ' + x['invoice'].toString());
  } catch (e) {
    showMsg(context, 'Invoice PDF failed: ' + e.toString());
  }
}

Future<void> paymentsPage(BuildContext context, Database db) async {
  final rows = await db.rawQuery(
    'SELECT p.*, q.name party FROM payments p LEFT JOIN parties q ON q.id=p.party_id ORDER BY p.id DESC'
  );
  if (!context.mounted) return;
  Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentHistoryPage(rows)));
}

class PaymentHistoryPage extends StatelessWidget {
  final List<Map<String, Object?>> rows;
  const PaymentHistoryPage(this.rows, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payments', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (rows.isEmpty) emptyState('No payments', 'Payment In and Payment Out will appear here.'),
          ...rows.map((x) => Card(
            child: ListTile(
              title: Text((x['party'] ?? 'Account').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text((x['type'] ?? '').toString() + ' • ' + (x['mode'] ?? '').toString()),
              trailing: Text(money((x['amount'] as num?) ?? 0), style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          )),
        ],
      ),
    );
  }
}

Future<void> businessDialog(BuildContext context, Database db) async {
  final b = (await db.query('business', where: 'id=1')).first;
  final name = TextEditingController(text: b['name'].toString());
  final owner = TextEditingController(text: b['owner'].toString());
  final phone = TextEditingController(text: b['phone'].toString());
  final address = TextEditingController(text: b['address'].toString());
  final state = TextEditingController(text: b['state'].toString());
  final gstin = TextEditingController(text: b['gstin'].toString());
  final upi = TextEditingController(text: b['upi'].toString());

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Business Profile', style: TextStyle(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Business name')),
              TextField(controller: owner, decoration: const InputDecoration(labelText: 'Owner')),
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
              TextField(controller: state, decoration: const InputDecoration(labelText: 'State')),
              TextField(controller: gstin, decoration: const InputDecoration(labelText: 'GSTIN')),
              TextField(controller: upi, decoration: const InputDecoration(labelText: 'UPI ID')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await db.update('business', {
                'name': name.text,
                'owner': owner.text,
                'phone': phone.text,
                'address': address.text,
                'state': state.text,
                'gstin': gstin.text,
                'upi': upi.text,
              }, where: 'id=1');
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

Future<void> showMsg(BuildContext context, String text) async {
  await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('DokanMate'),
      content: Text(text),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('OK')),
      ],
    ),
  );
}
