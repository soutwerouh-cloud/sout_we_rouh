import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

class TalentWorkFormWidget extends StatelessWidget {
  final bool isPoet;
  final bool isAuthorized;
  final bool isUploadingAudio;
  final TextEditingController workTitleController;
  final TextEditingController audioLinkController;
  final TextEditingController workContentController;
  final PlatformFile? selectedPlatformFile;
  final VoidCallback onPickAudioFile;
  final VoidCallback onAddNewWork;
  final VoidCallback onRequireAuth;

  const TalentWorkFormWidget({
    super.key,
    required this.isPoet,
    required this.isAuthorized,
    required this.isUploadingAudio,
    required this.workTitleController,
    required this.audioLinkController,
    required this.workContentController,
    required this.selectedPlatformFile,
    required this.onPickAudioFile,
    required this.onAddNewWork,
    required this.onRequireAuth,
  });

  // نافذة ذكية مخصصة للception ولصق النصوص الطويلة والقصائد لتجاوز قيود متصفحات الويب
  void _showPasteDialog(BuildContext context) {
    final TextEditingController tempController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('📋 لصق القصيدة أو العمل الأدبي', style: TextStyle(color: Color(0xFF7B1FA2), fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: TextField(
              controller: tempController,
              maxLines: 10,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'اضغط هنا ثم اضغط Ctrl+V للصق النص...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B1FA2)),
              onPressed: () {
                workContentController.text = tempController.text;
                Navigator.pop(context);
              },
              child: const Text('إدراج النص بالحقل 🚀', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        isPoet ? '📜 إضافة قصيدة أو عمل كتابي جديد' : '🎵 رفع الأغنية أو إدخال رابطها المباشر',
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7B1FA2)),
      ),
      children: [
        const SizedBox(height: 8),
        TextField(
          controller: workTitleController,
          readOnly: !isAuthorized,
          onTap: () {
            if (!isAuthorized) {
              onRequireAuth();
            }
          },
          decoration: const InputDecoration(
            labelText: 'عنوان العمل (مثلاً: اسم الأغنية أو القصيدة)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        if (!isPoet) ...[
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.audio_file, color: Colors.white),
            label: Text(
              selectedPlatformFile == null ? 'اختر ملف الأغنية MP3 من الجهاز 📂' : 'تم اختيار: ${selectedPlatformFile!.name} ✅',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: onPickAudioFile,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: audioLinkController,
            readOnly: !isAuthorized,
            onTap: () {
              if (!isAuthorized) {
                onRequireAuth();
              }
            },
            decoration: const InputDecoration(
              labelText: 'أو أدخل رابط يوتيوب / فيس بوك / أو رابط مباشر 🔗',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // زر لصق ذكي ومضمون 100% لتجاوز حظر الويب
        if (isPoet) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B1FA2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () {
                  if (!isAuthorized) {
                    onRequireAuth();
                    return;
                  }
                  _showPasteDialog(context);
                },
                icon: const Icon(Icons.paste, size: 16, color: Colors.white),
                label: const Text('اضغط هنا للّصق السريع للقصيدة 📋', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],

        TextField(
          controller: workContentController,
          readOnly: !isAuthorized,
          onTap: () {
            if (!isAuthorized) {
              onRequireAuth();
            }
          },
          maxLines: isPoet ? 4 : 1,
          enableInteractiveSelection: true,
          decoration: InputDecoration(
            labelText: isPoet ? 'اكتب كلمات الشعر والقصيدة هنا...' : 'تفاصيل العمل أو الملف الصوتي',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        isUploadingAudio
            ? const Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF7B1FA2)),
                  SizedBox(height: 8),
                  Text('جاري رفع الأغنية للسحابة، يرجى الانتظار قليلاً...', style: TextStyle(color: Colors.purple, fontSize: 13)),
                ],
              )
            : ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B1FA2)),
                onPressed: onAddNewWork,
                child: const Text('حفظ ونشر العمل 🚀', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
        const SizedBox(height: 12),
      ],
    );
  }
}