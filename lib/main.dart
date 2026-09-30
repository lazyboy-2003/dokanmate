import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await openDatabase(join(await getDatabasesPath(), 'dokanmate.db'), version: 1, onCreate: (db, v) async {
    await db.execute('CREATE TABLE sales(id INTEGER PRIMARY KEY AUTOINCREMENT, amount REAL, cost REAL, paid REAL)');
    await db.execute('CREATE TABLE customers(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, phone TEXT, due REAL)');
    await db.execute('CREATE TABLE products(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, qty REAL, buy REAL, sell REAL)');
  });
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
  @override Widget build(BuildContext context) {
    final pages = <Widget>[Home(widget.db), Sales(widget.db, refresh), Customers(widget.db, refresh), Stock(widget.db, refresh), More(widget.db)];
    return MaterialApp(debugShowCheckedModeBanner:false, title:'DokanMate',
      theme:ThemeData(useMaterial3:true,colorSchemeSeed:const Color(0xff1565c0)),
      home:Scaffold(body:SafeArea(child:IndexedStack(index:tab,children:pages)),
        bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),
          destinations:const[
            NavigationDestination(icon:Icon(Icons.dashboard),label:'Dashboard'),
            NavigationDestination(icon:Icon(Icons.point_of_sale),label:'Sales'),
            NavigationDestination(icon:Icon(Icons.people),label:'Customers'),
            NavigationDestination(icon:Icon(Icons.inventory_2),label:'Stock'),
            NavigationDestination(icon:Icon(Icons.more_horiz),label:'More'),
          ])));
  }
  void refresh(){setState((){});}
}

class Home extends StatelessWidget {
  final Database db;
  const Home(this.db,{super.key});
  @override Widget build(BuildContext context)=>FutureBuilder(
    future:Future.wait([db.query('sales'),db.query('customers'),db.query('products')]),
    builder:(context,s){
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      final sales=s.data![0], customers=s.data![1], products=s.data![2];
      double sale=0,paid=0,profit=0,due=0,stock=0;
      for(final x in sales){sale+=(x['amount'] as num);paid+=(x['paid'] as num);profit+=(x['amount'] as num)-(x['cost'] as num);}
      for(final x in customers){due+=(x['due'] as num);}
      for(final x in products){stock+=(x['qty'] as num)*(x['buy'] as num);}
      return ListView(padding:const EdgeInsets.all(16),children:[
        const Text('DokanMate',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),
        const Text('Offline shop manager'),const SizedBox(height:20),
        Wrap(spacing:10,runSpacing:10,children:[
          Box('Sales',money(sale),Icons.trending_up),Box('Collection',money(paid),Icons.payments),Box('Due',money(due),Icons.wallet),Box('Profit',money(profit),Icons.bar_chart),Box('Stock',money(stock),Icons.inventory),Box('Customers',customers.length.toString(),Icons.people)]),
        const SizedBox(height:20),const Text('Recent Sales',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
        ...sales.reversed.take(8).map((x) => Card(child: ListTile(title: Text(money(x['amount'] as num)), subtitle: Text('Paid ' + money(x['paid'] as num)), trailing: Text(money((x['amount'] as num) - (x['cost'] as num)))))).toList(),
      ]);
    });
}
class Box extends StatelessWidget{
  final String a,b;final IconData i;
  const Box(this.a,this.b,this.i,{super.key});
  @override Widget build(BuildContext c)=>SizedBox(width:165,child:Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(i),Text(a),Text(b,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold))]))));
}

class Sales extends StatelessWidget{
  final Database db;final VoidCallback refresh;
  const Sales(this.db,this.refresh,{super.key});
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Sales'),actions:[IconButton(onPressed:()=>add(c),icon:const Icon(Icons.add))]),body:FutureBuilder(future:db.query('sales',orderBy:'id DESC'),builder:(c,s){
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    return ListView(children:s.data!.map((x)=>Card(child:ListTile(title:Text(money(x['amount'] as num)),subtitle:Text('Paid '+money(x['paid'] as num)),trailing:Text('Profit '+money((x['amount'] as num)-(x['cost'] as num)))))).toList());
  }));
  Future<void> add(BuildContext c)async{
    final a=TextEditingController(),cost=TextEditingController(),paid=TextEditingController();
    await showDialog(context:c,builder:(d)=>AlertDialog(title:const Text('Add Sale'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:a,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Sale amount')),
      TextField(controller:cost,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Cost price')),
      TextField(controller:paid,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Paid amount'))]),
      actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Cancel')),FilledButton(onPressed:()async{
        final x=double.tryParse(a.text)??0,y=double.tryParse(cost.text)??0,z=double.tryParse(paid.text)??0;
        if(x<=0||z<0||z>x)return;
        await db.insert('sales',{'amount':x,'cost':y,'paid':z});
        if(d.mounted)Navigator.pop(d);refresh();
      },child:const Text('Save'))]));
  }
}

class Customers extends StatelessWidget{
  final Database db;final VoidCallback refresh;
  const Customers(this.db,this.refresh,{super.key});
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Customers'),actions:[IconButton(onPressed:()=>add(c),icon:const Icon(Icons.person_add))]),body:FutureBuilder(future:db.query('customers'),builder:(c,s){
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    return ListView(children:s.data!.map((x)=>Card(child:ListTile(title:Text(x['name'] as String),subtitle:Text((x['phone'] as String?)??''),trailing:Text('Due '+money(x['due'] as num)))).toList());
  }));
  Future<void> add(BuildContext c)async{
    final n=TextEditingController(),p=TextEditingController();
    await showDialog(context:c,builder:(d)=>AlertDialog(title:const Text('New Customer'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'Name')),TextField(controller:p,decoration:const InputDecoration(labelText:'Phone'))]),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Cancel')),FilledButton(onPressed:()async{if(n.text.isEmpty)return;await db.insert('customers',{'name':n.text,'phone':p.text,'due':0});if(d.mounted)Navigator.pop(d);refresh();},child:const Text('Save'))]));
  }
}

class Stock extends StatelessWidget{
  final Database db;final VoidCallback refresh;
  const Stock(this.db,this.refresh,{super.key});
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Stock'),actions:[IconButton(onPressed:()=>add(c),icon:const Icon(Icons.add_box))]),body:FutureBuilder(future:db.query('products'),builder:(c,s){
    if(!s.hasData)return const Center(child:CircularProgressIndicator());
    return ListView(children:s.data!.map((x)=>Card(child:ListTile(title:Text(x['name'] as String),subtitle:Text('Buy '+money(x['buy'] as num)+'  Sell '+money(x['sell'] as num)),trailing:Text('Qty '+(x['qty'] as num).toString())))).toList());
  }));
  Future<void> add(BuildContext c)async{
    final n=TextEditingController(),q=TextEditingController(),b=TextEditingController(),s=TextEditingController();
    await showDialog(context:c,builder:(d)=>AlertDialog(title:const Text('Add Product'),content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:n,decoration:const InputDecoration(labelText:'Product name')),TextField(controller:q,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Quantity')),TextField(controller:b,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Buy price')),TextField(controller:s,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Sell price'))]),
      actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('Cancel')),FilledButton(onPressed:()async{if(n.text.isEmpty)return;await db.insert('products',{'name':n.text,'qty':double.tryParse(q.text)??0,'buy':double.tryParse(b.text)??0,'sell':double.tryParse(s.text)??0});if(d.mounted)Navigator.pop(d);refresh();},child:const Text('Save'))]));
  }
}

class More extends StatelessWidget{
  final Database db;
  const More(this.db,{super.key});
  @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('More',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),
    Card(child:ListTile(leading:const Icon(Icons.assessment),title:const Text('Business Report'),onTap:()=>report(c))),
    const Card(child:ListTile(leading:Icon(Icons.lock),title:Text('PIN Lock'),subtitle:Text('Coming next'))),
    const Card(child:ListTile(leading:Icon(Icons.workspace_premium),title:Text('DokanMate Pro'),subtitle:Text('Premium features coming next'))),
  ]);
  Future<void> report(BuildContext c)async{
    final s=await db.query('sales'),u=await db.query('customers');double a=0,p=0,d=0;
    for(final x in s){a+=(x['amount'] as num);p+=(x['amount'] as num)-(x['cost'] as num);}
    for(final x in u){d+=(x['due'] as num);}
    if(!c.mounted)return;
    showDialog(context:c,builder:(dctx)=>AlertDialog(title:const Text('Business Report'),content:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Sales: '+money(a)),Text('Profit: '+money(p)),Text('Customer Due: '+money(d))]),actions:[TextButton(onPressed:()=>Navigator.pop(dctx),child:const Text('Close'))]));
  }
}
