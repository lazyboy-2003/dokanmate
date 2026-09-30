import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDb.open();
  runApp(DokanMateApp(db: db));
}

class AppDb {
  final Database db;
  AppDb._(this.db);

  static Future<AppDb> open() async {
    final p = join(await getDatabasesPath(), 'dokanmate.db');
    final d = await openDatabase(p, version: 1, onCreate: (db, v) async {
      await db.execute('CREATE TABLE sales(id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER, amount REAL NOT NULL, cost REAL NOT NULL, paid REAL NOT NULL, created_at TEXT NOT NULL)');
      await db.execute('CREATE TABLE customers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone TEXT, due REAL NOT NULL DEFAULT 0)');
      await db.execute('CREATE TABLE products(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, qty REAL NOT NULL DEFAULT 0, buy REAL NOT NULL DEFAULT 0, sell REAL NOT NULL DEFAULT 0)');
    });
    return AppDb._(d);
  }

  Future<List<Map<String,Object?>>> sales() => db.query('sales', orderBy: 'id DESC');
  Future<List<Map<String,Object?>>> customers() => db.query('customers', orderBy: 'name');
  Future<List<Map<String,Object?>>> products() => db.query('products', orderBy: 'name');

  Future<void> addCustomer(String name, String phone) async {
    await db.insert('customers', {'name': name, 'phone': phone, 'due': 0});
  }

  Future<void> addProduct(String name, double qty, double buy, double sell) async {
    await db.insert('products', {'name': name, 'qty': qty, 'buy': buy, 'sell': sell});
  }

  Future<void> addSale(double amount, double cost, double paid, int? customer) async {
    await db.insert('sales', {'amount': amount, 'cost': cost, 'paid': paid, 'customer_id': customer, 'created_at': DateTime.now().toIso8601String()});
    if (customer != null && amount > paid) {
      await db.rawUpdate('UPDATE customers SET due = due + ? WHERE id = ?', [amount - paid, customer]);
    }
  }

  Future<void> collect(int id, double amount) async {
    await db.rawUpdate('UPDATE customers SET due = MAX(0, due - ?) WHERE id = ?', [amount, id]);
  }
}

String rs(num n) => '₹' + n.toStringAsFixed(2);
String dt(String s) => DateFormat('dd MMM, hh:mm a').format(DateTime.parse(s));

class DokanMateApp extends StatefulWidget {
  final AppDb db;
  const DokanMateApp({super.key, required this.db});
  @override State<DokanMateApp> createState() => _DokanMateAppState();
}

class _DokanMateAppState extends State<DokanMateApp> {
  int index = 0;
  int tick = 0;
  void refresh() => setState(() => tick++);
  @override
  Widget build(BuildContext context) {
    final pages = [
      Dashboard(db: widget.db, key: ValueKey('d' + tick.toString())),
      SalesPage(db: widget.db, onChanged: refresh, key: ValueKey('s' + tick.toString())),
      CustomersPage(db: widget.db, onChanged: refresh, key: ValueKey('c' + tick.toString())),
      StockPage(db: widget.db, onChanged: refresh, key: ValueKey('p' + tick.toString())),
      MorePage(db: widget.db, key: ValueKey('m' + tick.toString())),
    ];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DokanMate',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xff1565c0), scaffoldBackgroundColor: const Color(0xfff6f8fb)),
      home: Scaffold(
        body: SafeArea(child: IndexedStack(index: index, children: pages)),
        bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: 'Sales'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Customers'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Stock'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ]),
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  final AppDb db;
  const Dashboard({super.key, required this.db});
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: Future.wait([db.sales(), db.customers(), db.products()]),
    builder: (context, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      final ss = snap.data![0], cs = snap.data![1], ps = snap.data![2];
      double sales = 0, paid = 0, profit = 0, due = 0, stock = 0;
      final now = DateTime.now();
      for (final s in ss) {
        final d = DateTime.parse(s['created_at'] as String);
        if (d.year == now.year && d.month == now.month && d.day == now.day) {
          sales += (s['amount'] as num).toDouble();
          paid += (s['paid'] as num).toDouble();
          profit += (s['amount'] as num).toDouble() - (s['cost'] as num).toDouble();
        }
      }
      for (final c in cs) due += (c['due'] as num).toDouble();
      for (final p in ps) stock += (p['qty'] as num).toDouble() * (p['buy'] as num).toDouble();
      return ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          CircleAvatar(radius: 27, child: const Icon(Icons.storefront, size: 30)),
          const SizedBox(width: 12),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DokanMate', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text('Offline shop manager')
          ])
        ]),
        const SizedBox(height: 20),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.45, children: [
          Card(child: Stat('Today Sales', rs(sales), Icons.trending_up)),
          Card(child: Stat('Collection', rs(paid), Icons.payments_outlined)),
          Card(child: Stat('Total Due', rs(due), Icons.account_balance_wallet_outlined)),
          Card(child: Stat('Today Profit', rs(profit), Icons.bar_chart)),
          Card(child: Stat('Stock Value', rs(stock), Icons.inventory_2_outlined)),
          Card(child: Stat('Customers', cs.length.toString(), Icons.people_outline)),
        ]),
        const SizedBox(height: 20),
        const Text('Recent Sales', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        ...ss.take(8).map((s) => Card(child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
          title: Text(rs((s['amount'] as num).toDouble())),
          subtitle: Text(dt(s['created_at'] as String) + ' • Paid ' + rs((s['paid'] as num).toDouble())),
          trailing: Text(rs((s['amount'] as num).toDouble() - (s['cost'] as num).toDouble())),
        ))),
        if (ss.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('No sales yet. Add your first sale.')))
      ]);
    }
  );
}

class Stat extends StatelessWidget {
  final String title, value; final IconData icon;
  const Stat(this.title, this.value, this.icon, {super.key});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon), Text(title), FittedBox(child: Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)))]));
}

class SalesPage extends StatelessWidget {
  final AppDb db; final VoidCallback onChanged;
  const SalesPage({super.key, required this.db, required this.onChanged});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sales'), actions: [IconButton(onPressed: () => add(context), icon: const Icon(Icons.add))]),
    body: FutureBuilder(future: db.sales(), builder: (context, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      final ss = snap.data!;
      return ListView.builder(padding: const EdgeInsets.all(12), itemCount: ss.length, itemBuilder: (_, i) {
        final s = ss[i];
        return Card(child: ListTile(leading: const Icon(Icons.receipt_long), title: Text(rs((s['amount'] as num).toDouble())), subtitle: Text(dt(s['created_at'] as String) + ' • Paid ' + rs((s['paid'] as num).toDouble())), trailing: Text('Profit\n' + rs((s['amount'] as num).toDouble() - (s['cost'] as num).toDouble()), textAlign: TextAlign.right)));
      });
    })
  );

  Future<void> add(BuildContext context) async {
    final a=TextEditingController(), c=TextEditingController(), p=TextEditingController();
    final cs=await db.customers();
    int? customer;
    if (!context.mounted) return;
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, set) => AlertDialog(
      title: const Text('Add Sale'),
      content: SingleChildScrollView(child: Column(children: [
        TextField(controller:a, keyboardType:TextInputType.number, decoration:const InputDecoration(labelText:'Sale amount')),
        const SizedBox(height:10), TextField(controller:c, keyboardType:TextInputType.number, decoration:const InputDecoration(labelText:'Cost price')),
        const SizedBox(height:10), TextField(controller:p, keyboardType:TextInputType.number, decoration:const InputDecoration(labelText:'Paid amount')),
        const SizedBox(height:10), DropdownButtonFormField<int?>(value:customer, decoration:const InputDecoration(labelText:'Customer'), items:[const DropdownMenuItem<int?>(value:null, child:Text('Walk-in')), ...cs.map((x)=>DropdownMenuItem<int?>(value:x['id'] as int, child:Text(x['name'] as String)))], onChanged:(v)=>set(()=>customer=v)),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:()async{
        final aa=double.tryParse(a.text)??0, cc=double.tryParse(c.text)??0, pp=double.tryParse(p.text)??0;
        if(aa<=0||pp<0||pp>aa){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter valid amounts.')));return;}
        await db.addSale(aa,cc,pp,customer); if(ctx.mounted)Navigator.pop(ctx); onChanged();
      },child:const Text('Save'))]
    )));
  }
}

class CustomersPage extends StatelessWidget {
  final AppDb db; final VoidCallback onChanged;
  const CustomersPage({super.key, required this.db, required this.onChanged});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Customers'), actions:[IconButton(onPressed:()=>add(context),icon:const Icon(Icons.person_add))]),
    body: FutureBuilder(future:db.customers(),builder:(context,snap){
      if(!snap.hasData)return const Center(child:CircularProgressIndicator());
      final cs=snap.data!;
      return ListView(padding:const EdgeInsets.all(12),children:cs.map((c)=>Card(child:ListTile(
        leading:const CircleAvatar(child:Icon(Icons.person)),
        title:Text(c['name'] as String),
        subtitle:Text((c['phone'] as String?)??''),
        trailing:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.end,children:[
          Text('Due ' + rs((c['due'] as num).toDouble()),style:const TextStyle(fontWeight:FontWeight.bold)),
          if((c['due'] as num)>0) TextButton(onPressed:()=>collect(context,c),child:const Text('Collect'))
        ])
      )).toList());
    })
  );

  Future<void> add(BuildContext context)async{
    final n=TextEditingController(),p=TextEditingController();
    await showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('New Customer'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'Name')),const SizedBox(height:10),TextField(controller:p,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Phone'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:()async{if(n.text.trim().isEmpty)return;await db.addCustomer(n.text.trim(),p.text.trim());if(ctx.mounted)Navigator.pop(ctx);onChanged();},child:const Text('Save'))]));
  }

  Future<void> collect(BuildContext context,Map<String,Object?> c)async{
    final a=TextEditingController();
    await showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text('Collect from ' + (c['name'] as String)),content:TextField(controller:a,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Amount')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:()async{final x=double.tryParse(a.text)??0;final d=(c['due'] as num).toDouble();if(x<=0||x>d)return;await db.collect(c['id'] as int,x);if(ctx.mounted)Navigator.pop(ctx);onChanged();},child:const Text('Collect'))]));
  }
}

class StockPage extends StatelessWidget {
  final AppDb db; final VoidCallback onChanged;
  const StockPage({super.key,required this.db,required this.onChanged});
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Stock'),actions:[IconButton(onPressed:()=>add(context),icon:const Icon(Icons.add_box_outlined))]),
    body:FutureBuilder(future:db.products(),builder:(context,snap){
      if(!snap.hasData)return const Center(child:CircularProgressIndicator());
      final ps=snap.data!;
      return ListView(padding:const EdgeInsets.all(12),children:ps.map((p)=>Card(child:ListTile(leading:const Icon(Icons.inventory_2),title:Text(p['name'] as String),subtitle:Text('Buy '+rs((p['buy'] as num).toDouble())+' • Sell '+rs((p['sell'] as num).toDouble())),trailing:Text('Qty '+(p['qty'] as num).toStringAsFixed(0),style:const TextStyle(fontWeight:FontWeight.bold)))).toList());
    })
  );

  Future<void> add(BuildContext context)async{
    final n=TextEditingController(),q=TextEditingController(),b=TextEditingController(),s=TextEditingController();
    await showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('Add Product'),content:SingleChildScrollView(child:Column(children:[TextField(controller:n,decoration:const InputDecoration(labelText:'Product name')),const SizedBox(height:8),TextField(controller:q,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Quantity')),const SizedBox(height:8),TextField(controller:b,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Buy price')),const SizedBox(height:8),TextField(controller:s,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Sell price'))])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:()async{if(n.text.trim().isEmpty)return;await db.addProduct(n.text.trim(),double.tryParse(q.text)??0,double.tryParse(b.text)??0,double.tryParse(s.text)??0);if(ctx.mounted)Navigator.pop(ctx);onChanged();},child:const Text('Save'))]));
  }
}

class MorePage extends StatelessWidget {
  final AppDb db;
  const MorePage({super.key,required this.db});
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('More',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),const SizedBox(height:12),
    Card(child:ListTile(leading:const Icon(Icons.lock_outline),title:const Text('PIN Lock'),subtitle:const Text('Configure a 4–6 digit app PIN'),onTap:()=>pin(context))),
    Card(child:ListTile(leading:const Icon(Icons.assessment_outlined),title:const Text('Business Report'),subtitle:const Text('Sales, collection, profit and due'),onTap:()=>report(context))),
    Card(child:ListTile(leading:const Icon(Icons.store_outlined),title:const Text('Shop Profile'),subtitle:const Text('Shop name and phone'),onTap:()=>profile(context))),
    Card(child:ListTile(leading:const Icon(Icons.workspace_premium_outlined),title:const Text('DokanMate Pro'),subtitle:const Text('Premium-ready architecture'),onTap:()=>showDialog(context:context,builder:(c)=>AlertDialog(title:const Text('DokanMate Pro'),content:const Text('Future upgrades: advanced reports, invoice PDF, backup and subscription plans.'),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('OK'))])))),
  ]);

  Future<void> pin(BuildContext context)async{
    const secure=FlutterSecureStorage();
    final t=TextEditingController();
    await showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('Set PIN'),content:TextField(controller:t,obscureText:true,keyboardType:TextInputType.number,maxLength:6,decoration:const InputDecoration(labelText:'4–6 digit PIN')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:()async{if(RegExp(r'^\\d{4,6}$').hasMatch(t.text)){await secure.write(key:'app_pin',value:t.text);if(ctx.mounted)Navigator.pop(ctx);}},child:const Text('Save'))]));
  }

  Future<void> report(BuildContext context)async{
    final ss=await db.sales(),cs=await db.customers();
    double a=0,p=0,c=0,d=0;
    for(final s in ss){a+=(s['amount'] as num).toDouble();c+=(s['paid'] as num).toDouble();p+=(s['amount'] as num).toDouble()-(s['cost'] as num).toDouble();}
    for(final x in cs)d+=(x['due'] as num).toDouble();
    if(!context.mounted)return;
    showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('Business Report'),content:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Total Sales: '+rs(a)),Text('Collection: '+rs(c)),Text('Profit: '+rs(p)),Text('Customer Due: '+rs(d)),Text('Transactions: '+ss.length.toString())]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Close'))]));
  }

  Future<void> profile(BuildContext context)async{
    const secure=FlutterSecureStorage();
    final n=TextEditingController(text:await secure.read(key:'shop_name')??''),p=TextEditingController(text:await secure.read(key:'shop_phone')??'');
    if(!context.mounted)return;
    showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('Shop Profile'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'Shop name')),const SizedBox(height:10),TextField(controller:p,decoration:const InputDecoration(labelText:'Phone'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:()async{await secure.write(key:'shop_name',value:n.text);await secure.write(key:'shop_phone',value:p.text);if(ctx.mounted)Navigator.pop(ctx);},child:const Text('Save'))]));
  }
}
