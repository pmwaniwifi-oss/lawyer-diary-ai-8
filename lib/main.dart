import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
void main() => runApp(const MaterialApp(home: Diary()));
class Diary extends StatefulWidget {
  const Diary({super.key});
  @override State<Diary> createState() => _DiaryState();
}
class _DiaryState extends State<Diary> {
  final name = TextEditingController();
  final cnr = TextEditingController();
  final date = TextEditingController();
  final search = TextEditingController();
  List<Map<String, dynamic>> cases = [];
  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final value = jsonDecode(p.getString('cases') ?? '[]') as List<dynamic>;
    if (mounted) setState(() => cases = value.map((e) => Map<String,dynamic>.from(e as Map)).toList());
  }
  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('cases', jsonEncode(cases));
  }
  Future<void> add() async {
    name.clear(); cnr.clear(); date.clear();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('नया मुकदमा'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'वाद का नाम')),
        TextField(controller: cnr, decoration: const InputDecoration(labelText: 'CNR नंबर')),
        TextField(controller: date, readOnly: true, decoration: const InputDecoration(labelText: 'अगली पेशी'),
          onTap: () async {
            final d = await showDatePicker(context: ctx, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: DateTime.now());
            if (d != null) date.text = d.toIso8601String().substring(0,10);
          }),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx,false), child: const Text('रद्द')),
        FilledButton(onPressed: () => Navigator.pop(ctx,true), child: const Text('सहेजें')),
      ],
    ));
    if (ok == true && name.text.trim().isNotEmpty && date.text.isNotEmpty) {
      setState(() => cases.add({'name':name.text.trim(),'cnr':cnr.text.trim(),'date':date.text}));
      await save();
    }
  }
  @override void dispose() { name.dispose(); cnr.dispose(); date.dispose(); search.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final found = cases.where((e) => e.values.any((v) => v.toString().toLowerCase().contains(search.text.toLowerCase()))).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Lawyer Diary AI 8.0')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(controller: search,
          onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'मुकदमा खोजें', prefixIcon: Icon(Icons.search)))),
        Text('मेरी निजी डायरी • कुल मुकदमे: ${cases.length}'),
        Expanded(child: ListView.builder(itemCount: found.length, itemBuilder: (ctx,i) {
          final c = found[i];
          return ListTile(title: Text(c['name'].toString()), subtitle: Text('CNR: ${c['cnr']} | पेशी: ${c['date']}'),
            trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async {
              setState(() => cases.remove(c)); await save();
            }));
        })),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: add, label: const Text('नया केस'), icon: const Icon(Icons.add)),
    );
  }
}
