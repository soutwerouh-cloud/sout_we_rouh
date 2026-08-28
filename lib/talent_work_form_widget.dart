import 'package:flutter/material.dart';
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
          decoration: const InputDecoration(labelText: 'عنوان العمل (مثلاً: اسم الأغنية أو القصيدة)', border: OutlineInputBorder()),
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
        TextField(
          controller: workContentController,
          readOnly: !isAuthorized || !isPoet,
          onTap: () {
            if (!isAuthorized) {
              onRequireAuth();
            }
          },
          maxLines: isPoet ? 4 : 1,
          decoration: InputDecoration(
            labelText: isPoet ? 'اكتب كلمات الشعر والقصيدة هنا...' : 'تفاصيل العمل أو الملف الصوتي',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        isUploadingAudio
            ? Column(
                children: const [
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