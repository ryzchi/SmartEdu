import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_client.dart';

class MaterialListPage extends StatefulWidget {
  const MaterialListPage({super.key});

  @override
  State<MaterialListPage> createState() => _MaterialListPageState();
}

class _MaterialListPageState extends State<MaterialListPage> {
  String search = '';

  Future<List<Map<String, dynamic>>> fetchMaterials() async {
    final response = await ApiClient().get('materials.php');
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from((response['materials'] ?? []) as List);
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Materials')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(labelText: 'Search'),
              onChanged: (val) => setState(() => search = val),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchMaterials(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final docs = snapshot.data?.where((doc) {
                  return doc['title']
                      .toString()
                      .toLowerCase()
                      .contains(search.toLowerCase());
                }).toList() ?? [];

                if (docs.isEmpty) {
                  return const Center(child: Text('No materials found.'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i];
                    return ListTile(
                      title: Text(data['title'] ?? ''),
                      subtitle: Text(data['subject'] ?? ''),
                      onTap: () async {
                        final uri = Uri.parse(data['file_url'] ?? '');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
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
