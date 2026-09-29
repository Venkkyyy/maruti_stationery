import 'dart:convert';
import 'package:http/http.dart' as http;

const String projectId = 'maruti-stationery-d7862';
const String baseUrl =
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

// ─────────────────────────────────────────────────────────────────────────────
// Tag rules
//
// A product is tagged "back_to_school" if its name / description / category
// contains any of the school keywords below.
//
// A product is tagged "office_essentials" if it matches the office keywords.
//
// Keywords are matched case-insensitively against the product name,
// description, and brand fields.
// ─────────────────────────────────────────────────────────────────────────────

const List<String> schoolKeywords = [
  'notebook', 'note book', 'school', 'pencil', 'eraser', 'sharpener',
  'geometry', 'compass', 'scale', 'ruler', 'crayon', 'colour pencil',
  'color pencil', 'sketch', 'drawing', 'water color', 'watercolor',
  'glue stick', 'gum', 'textbook', 'text book', 'exam pad', 'chart paper',
  'graph paper', 'index card', 'flash card', 'backpack', 'school bag',
  'lunch box', 'tiffin', 'colouring', 'coloring', 'art', 'craft',
  'highlighter', 'marker',
];

const List<String> officeKeywords = [
  'register', 'file', 'folder', 'binder', 'pen', 'ballpoint', 'ball pen',
  'gel pen', 'ink', 'stamp', 'stapler', 'staple', 'punch', 'clip',
  'paper clip', 'rubber band', 'tape', 'scissor', 'cutter', 'envelope',
  'letterhead', 'visiting card', 'business card', 'calculator', 'desk',
  'organiser', 'organizer', 'tray', 'calendar', 'planner', 'diary',
  'sticky note', 'post-it', 'whiteboard', 'board marker', 'printer',
  'photocopy', 'a4', 'legal pad', 'memo', 'invoice', 'receipt book',
  'account book', 'ledger', 'voucher', 'carbon', 'peon book', 'attendance',
];

// ─────────────────────────────────────────────────────────────────────────────

String _str(dynamic field) {
  if (field == null) return '';
  final m = field as Map<String, dynamic>;
  return m.containsKey('stringValue') ? (m['stringValue'] as String? ?? '') : '';
}

List<String> _strList(dynamic field) {
  if (field == null) return [];
  final m = field as Map<String, dynamic>;
  if (!m.containsKey('arrayValue')) return [];
  final av = m['arrayValue'] as Map<String, dynamic>?;
  if (av == null || !av.containsKey('values')) return [];
  final values = av['values'] as List<dynamic>;
  return values.map((v) => _str(v)).toList();
}

bool _matchesAny(String haystack, List<String> needles) {
  final lower = haystack.toLowerCase();
  return needles.any((n) => lower.contains(n));
}

Future<void> main() async {
  print('═══════════════════════════════════════════════');
  print('  Auto-Tagger: back_to_school & office_essentials');
  print('═══════════════════════════════════════════════\n');

  // 1. Fetch ALL products (Firestore REST caps at 300; handle pageToken)
  final List<Map<String, dynamic>> allDocs = [];
  String? pageToken;

  do {
    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: {
      'pageSize': '300',
      'pageToken': ?pageToken,
    });

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      print('ERROR fetching products: ${res.statusCode}\n${res.body}');
      return;
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final docs = (body['documents'] as List?) ?? [];
    allDocs.addAll(docs.cast<Map<String, dynamic>>());
    pageToken = body['nextPageToken'] as String?;
    print('Fetched ${docs.length} products (total so far: ${allDocs.length})');
  } while (pageToken != null);

  print('\nTotal products fetched: ${allDocs.length}\n');

  int schoolUpdated = 0;
  int officeUpdated = 0;
  int skipped = 0;

  for (final doc in allDocs) {
    final docName = doc['name'] as String; // full resource path
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};

    final name = _str(fields['name']);
    final description = _str(fields['description']);
    final brand = _str(fields['brand']);
    final existingTags = _strList(fields['tags']);

    final searchText = '$name $description $brand';

    final isSchool = _matchesAny(searchText, schoolKeywords);
    final isOffice = _matchesAny(searchText, officeKeywords);

    if (!isSchool && !isOffice) {
      skipped++;
      continue;
    }

    // Build the updated tags list
    final newTags = List<String>.from(existingTags);
    if (isSchool && !newTags.contains('back_to_school')) {
      newTags.add('back_to_school');
    }
    if (isOffice && !newTags.contains('office_essentials')) {
      newTags.add('office_essentials');
    }

    // Only update if something changed
    final changed = !_listsEqual(existingTags, newTags);
    if (!changed) {
      skipped++;
      continue;
    }

    // PATCH only the tags field
    final patchUri = Uri.parse(
        'https://firestore.googleapis.com/v1/$docName?updateMask.fieldPaths=tags');

    final payload = {
      'fields': {
        'tags': {
          'arrayValue': {
            'values': newTags.map((t) => {'stringValue': t}).toList(),
          },
        },
      },
    };

    final patchRes = await http.patch(
      patchUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (patchRes.statusCode == 200) {
      final tagsAdded = newTags.where((t) => !existingTags.contains(t)).toList();
      print('✅ [$name]  +${tagsAdded.join(', ')}');
      if (isSchool) schoolUpdated++;
      if (isOffice) officeUpdated++;
    } else {
      print('❌ Failed to update [$name]: ${patchRes.statusCode} ${patchRes.body}');
    }
  }

  print('\n═══════════════════════════════════════════════');
  print('  Done!');
  print('  Tagged as back_to_school    : $schoolUpdated products');
  print('  Tagged as office_essentials : $officeUpdated products');
  print('  Skipped (no match / no change): $skipped products');
  print('═══════════════════════════════════════════════');
}

bool _listsEqual(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  final sa = {...a};
  final sb = {...b};
  return sa.containsAll(sb) && sb.containsAll(sa);
}
