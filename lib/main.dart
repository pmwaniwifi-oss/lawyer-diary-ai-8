import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LawyerDiary());
}
class LawyerDiary extends StatelessWidget {
  const LawyerDiary({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Lawyer Diary AI 8.0',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
    home: StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) => snapshot.data == null
          ? const LoginScreen() : const CasesScreen(),
    ),
  );
}
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool registering = false;
  bool busy = false;
  @override void dispose() {
    email.dispose(); password.dispose(); super.dispose();
  }
  Future<void> submit() async {
    setState(() => busy = true);
    try {
      if (registering) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.trim(), password: password.text);
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(), password: password.text);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'लॉगिन असफल')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lawyer Diary AI 8.0')),
    body: Center(child: SingleChildScrollView(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.gavel, size: 70),
        Text(registering ? 'अधिवक्ता पंजीकरण' : 'अधिवक्ता लॉगिन',
          style: Theme.of(context).textTheme.headlineSmall),
        TextField(controller: email, decoration: const InputDecoration(labelText: 'ईमेल')),
        TextField(controller: password, obscureText: true,
          decoration: const InputDecoration(labelText: 'पासवर्ड')),
        const SizedBox(height: 16),
        FilledButton(onPressed: busy ? null : submit,
          child: Text(registering ? 'पंजीकरण करें' : 'लॉगिन करें')),
        TextButton(onPressed: () => setState(() => registering = !registering),
          child: Text(registering ? 'लॉगिन' : 'नया अकाउंट बनाएँ')),
      ]),
    ))),
  );
}
class CasesScreen extends StatelessWidget {
  const CasesScreen({super.key});
  CollectionReference<Map<String, dynamic>> get cases => FirebaseFirestore.instance
    .collection('lawyers').doc(FirebaseAuth.instance.currentUser!.uid)
    .collection('cases');
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('मेरी केस डायरी'), actions: [
      IconButton(onPressed: () => FirebaseAuth.instance.signOut(),
        icon: const Icon(Icons.logout), tooltip: 'लॉगआउट'),
    ]),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: cases.orderBy('nextDate').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('डेटा त्रुटि: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('कोई केस नहीं। + दबाकर जोड़ें।'));
        return ListView.builder(itemCount: docs.length, itemBuilder: (context, i) {
          final d = docs[i];
          return ListTile(
            title: Text(d.data()['title']?.toString() ?? ''),
            subtitle: Text('CNR: ${d.data()['cnr'] ?? ''}  |  अगली तारीख: ${d.data()['nextDate'] ?? ''}'),
            trailing: IconButton(icon: const Icon(Icons.delete_outline),
              onPressed: () => d.reference.delete()),
          );
        });
      },
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => showDialog<void>(context: context,
        builder: (_) => AddCaseDialog(cases: cases)),
      label: const Text('नया केस'), icon: const Icon(Icons.add)),
  );
}
class AddCaseDialog extends StatefulWidget {
  const AddCaseDialog({super.key, required this.cases});
  final CollectionReference<Map<String, dynamic>> cases;
  @override State<AddCaseDialog> createState() => _AddCaseDialogState();
}
class _AddCaseDialogState extends State<AddCaseDialog> {
  final title = TextEditingController();
  final cnr = TextEditingController();
  final date = TextEditingController();
  @override void dispose() {
    title.dispose(); cnr.dispose(); date.dispose(); super.dispose();
  }
  @override Widget build(BuildContext context) => AlertDialog(
    title: const Text('नया मुकदमा'),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: title, decoration: const InputDecoration(labelText: 'वाद का नाम')),
      TextField(controller: cnr, decoration: const InputDecoration(labelText: 'CNR नंबर')),
      TextField(controller: date, readOnly: true,
        decoration: const InputDecoration(labelText: 'अगली पेशी'),
        onTap: () async {
          final d = await showDatePicker(context: context, firstDate: DateTime(2020),
            lastDate: DateTime(2100), initialDate: DateTime.now());
          if (d != null) date.text = '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
        }),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('रद्द')),
      FilledButton(onPressed: () async {
        if (title.text.trim().isEmpty || date.text.isEmpty) return;
        await widget.cases.add({
          'title': title.text.trim(), 'cnr': cnr.text.trim(),
          'nextDate': date.text, 'createdAt': FieldValue.serverTimestamp()
        });
        if (context.mounted) Navigator.pop(context);
      }, child: const Text('सहेजें')),
    ],
  );
}
