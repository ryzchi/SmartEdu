import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class MaterialListPage extends StatefulWidget {
  const MaterialListPage({super.key});

  @override
  _MaterialListPageState createState() => _MaterialListPageState();
}

class _MaterialListPageState extends State<MaterialListPage> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Materials")),
      body: Column(
        children: [
          TextField(
            decoration: const InputDecoration(labelText: "Search"),
            onChanged: (val) => setState(() => search = val),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('materials').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                var docs = snapshot.data!.docs.where((doc) {
                  return doc['title'].toLowerCase().contains(search.toLowerCase());
                }).toList();

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    var data = docs[i];
                    return ListTile(
                      title: Text(data['title']),
                      subtitle: Text(data['subject']),
                      onTap: () async {
                    final uri = Uri.parse(data['url']);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                    }                   
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