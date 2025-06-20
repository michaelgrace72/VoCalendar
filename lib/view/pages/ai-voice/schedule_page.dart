import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutterapi/view/pages/ai-voice/add_schedule_modal.dart';
import 'package:flutterapi/view/pages/ai-voice/ai_voice.dart';
import 'package:flutterapi/view/pages/ai-voice/schedule_card.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutterapi/viewmodels/schedule_viewmodel.dart';
import 'package:flutterapi/models/schedule_model.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late stt.SpeechToText _speech;
  final FlutterTts _flutterTts = FlutterTts();

  final ValueNotifier<bool> _isListeningNotifier = ValueNotifier(false);
  final ValueNotifier<String> _queryNotifier = ValueNotifier('');
  final ValueNotifier<String> _responseNotifier = ValueNotifier('');

  String? userId;

  @override
  void initState() {
    super.initState();

    // Initialize speech to text
    _speech = stt.SpeechToText();

    // Get user ID from firebase auth
    final currentUser = FirebaseAuth.instance.currentUser;
    userId = currentUser?.uid;
  }

  void _onHoldMic() async {
    _isListeningNotifier.value = true;
    bool available = await _speech.initialize();
    if (available) {
      _speech.listen(
        onResult: (result) {
          _queryNotifier.value = result.recognizedWords;
        },
        localeId: 'id-ID',
      );
    }
  }

  void _onReleaseMic() async {
    _isListeningNotifier.value = false;
    if (_queryNotifier.value != '') {
      final vm = context.read<ScheduleViewModel>();
      String? results = await vm.generateScheduleFromQuery(
        userId!,
        _queryNotifier.value,
      );

      if (results == null || results.isEmpty) {
        setState(() {
          _responseNotifier.value = 'error';
        });
      } else {
        setState(() {
          _responseNotifier.value = results;
        });
        await _flutterTts.setLanguage("id-ID");
        await _flutterTts.speak(_responseNotifier.value);
      }
    }
    _speech.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 150.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              gradient: LinearGradient(
                colors: [const Color(0xFFBDF152), const Color(0xFF3F24E6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 20.0.w,
                right: 20.0.w,
                top: 60.0.h,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      'My Schedule',
                      style: TextStyle(
                        fontSize: 28.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Icon(Icons.add, size: 30.sp, color: Colors.white),
                      tooltip: 'Add Schedule',
                      onPressed: () => showAddScheduleModal(context, userId!),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20.h),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    AiVoice(
                      messageNotifier: _responseNotifier,
                      loadingNotifier: _isListeningNotifier,
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Consumer<ScheduleViewModel>(
                        builder: (context, vm, build) {
                          return StreamBuilder<List<Schedule>>(
                            stream: vm.scheduleStream,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Center(
                                  child: Text('No Events Found'),
                                );
                              }
                              final schedules = snapshot.data!;
                              return Scrollbar(
                                child: ListView.builder(
                                  shrinkWrap:
                                      true, // If inside another scrollable (like SingleChildScrollView), set this true
                                  itemCount: schedules.length,
                                  itemBuilder: (context, index) {
                                    final schedule = schedules[index];
                                    return ScheduleCard(schedule: schedule);
                                  },
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
        ],
      ),
      floatingActionButton: GestureDetector(
        onTapDown: (_) => _onHoldMic(),
        onTapUp: (_) => _onReleaseMic(),
        onTapCancel: _onReleaseMic,
        child: SizedBox(
          width: 50,
          height: 50,
          child: FloatingActionButton(
            onPressed: null,
            shape: CircleBorder(),
            backgroundColor: Color(0xFFBDF152),
            child: Icon(Icons.mic, size: 36, color: Color(0xFF000000)),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
