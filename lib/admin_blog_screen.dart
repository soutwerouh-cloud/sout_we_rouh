import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBlogScreen extends StatefulWidget {
  const AdminBlogScreen({super.key});

  @override
  State<AdminBlogScreen> createState() => _AdminBlogScreenState();
}

class _AdminBlogScreenState extends State<AdminBlogScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  String? _editingDocId;

  Future<void> _savePost() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء كتابة أو لصق العنوان والمحتوى أولاً ❌')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_editingDocId == null) {
        await FirebaseFirestore.instance.collection('blog_posts').add({
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'author': 'إدارة منصة صوت وروح',
          'timestamp': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نشر المقال بنجاح! 🚀'), backgroundColor: Colors.green),
        );
      } else {
        await FirebaseFirestore.instance.collection('blog_posts').doc(_editingDocId).update({
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تعديل وتحديث المقال بنجاح! ✏️'), backgroundColor: Colors.blue),
        );
        _editingDocId = null;
      }

      _titleController.clear();
      _contentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startEditing(String docId, Map<String, dynamic> postData) {
    setState(() {
      _editingDocId = docId;
      _titleController.text = postData['title'] ?? '';
      _contentController.text = postData['content'] ?? '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('أنتِ الآن في وضع تعديل المقال ✏️'), backgroundColor: Colors.purple),
    );
  }

  Future<void> _deletePost(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('blog_posts').doc(docId).delete();
      if (_editingDocId == docId) {
        _titleController.clear();
        _contentController.clear();
        _editingDocId = null;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف المقال بنجاح 🗑️'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الحذف: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_editingDocId == null ? "لوحة نشر وإدارة المقالات" : "تعديل مقال حالي ✏️", style: const TextStyle(color: Colors.white, fontSize: 16)),
          backgroundColor: Colors.purple.shade800,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Container(
          color: Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editingDocId == null ? "إضافة مقال جديد للمدونة:" : "أنتِ تقومين بتعديل المقال الحالي:",
                  style: TextStyle(fontSize: 13, color: _editingDocId == null ? Colors.black87 : Colors.purple.shade900, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'عنوان المقال',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _contentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'محتوى المقال بالكامل',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _editingDocId == null ? Colors.purple.shade700 : Colors.blue.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _isLoading ? null : _savePost,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  _editingDocId == null ? 'نشر المقال الآن 🚀' : 'تحديث المقال ✏️',
                                  style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ),
                    if (_editingDocId != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _editingDocId = null;
                            _titleController.clear();
                            _contentController.clear();
                          });
                        },
                        child: const Text('إلغاء', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ],
                ),
                
                const Divider(height: 20, thickness: 1.5),

                const Text(
                  "المقالات المنشورة (اضغطي تعديل ✏️ أو حذف 🗑️):",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.purple),
                ),
                const SizedBox(height: 6),
                
                // قائمة المقالات مع تنسيق مرن يظهر الأزرار بوضوح تام
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('blog_posts').orderBy('timestamp', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final posts = snapshot.hasData ? snapshot.data!.docs : [];
                      if (posts.isEmpty) {
                        return const Center(child: Text("لا توجد مقالات مسجلة حالياً", style: TextStyle(color: Colors.grey)));
                      }
                      return ListView.builder(
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final postDoc = posts[index];
                          final postData = postDoc.data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      postData['title'] ?? 'بدون عنوان',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade50,
                                          foregroundColor: Colors.blue.shade800,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                        onPressed: () => _startEditing(postDoc.id, postData),
                                        icon: const Icon(Icons.edit_rounded, size: 14),
                                        label: const Text('تعديل', style: TextStyle(fontSize: 11)),
                                      ),
                                      const SizedBox(width: 6),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade50,
                                          foregroundColor: Colors.red.shade800,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                        onPressed: () => _deletePost(postDoc.id),
                                        icon: const Icon(Icons.delete_rounded, size: 14),
                                        label: const Text('حذف', style: TextStyle(fontSize: 11)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}