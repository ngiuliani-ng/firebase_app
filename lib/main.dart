import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

bool firestoreEmulator = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  if (firestoreEmulator) {
    FirebaseFirestore.instance.settings = Settings(
      host: 'localhost:8080',
      sslEnabled: false,
      persistenceEnabled: false,
    );
  }
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.white,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Firebase"),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    /**
     * Il widget "StreamBuilder" ascolta gli aggiornamenti del database
     * ed aggiorna l'elenco ogni volta che i dati cambiano.
     * Quando non ci sono dati, mostra un indicatore di avanzamento.
     */
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('months')
          .orderBy('order')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();
        return _buildList(context, snapshot.data.docs);
      },
    );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: snapshot.map((data) => _buildListItem(context, data)).toList(),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
    final record = Record.fromSnapshot(data);

    _getCurrentDate() {
      var date = new DateTime.now().toString();
      var dateParse = DateTime.parse(date);
      return dateParse;
    }

    return Padding(
      key: ValueKey(record.month),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: (_getCurrentDate().month == record.order)
              ? Colors.transparent
              : Colors.grey.shade300,
          border: Border.all(
            color: Colors.grey.shade600,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: ListTile(
          title: Text(
            record.month,
          ),
          subtitle: Text(
            record.hours.toString(),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  if (_getCurrentDate().month == record.order)
                    return record.reference
                        .update({'hours': record.hours + 0.5});
                  return null;
                },
              ),
              IconButton(
                icon: Icon(Icons.remove),
                onPressed: () {
                  if (_getCurrentDate().month == record.order)
                    return record.reference
                        .update({'hours': record.hours - 0.5});
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Record {
  final String month;
  final dynamic hours;
  final dynamic order;
  final DocumentReference reference;

  Record.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['month'] != null),
        assert(map['hours'] != null),
        assert(map['order'] != null),
        month = map['month'],
        hours = map['hours'],
        order = map['order'];

  Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data(), reference: snapshot.reference);

  @override
  String toString() => "Record<$order:$month:$hours>";
}
