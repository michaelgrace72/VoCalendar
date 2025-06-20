import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutterapi/dto/schedule/query_to_schedule_response.dart';
import 'package:flutterapi/dto/schedule/query_to_schedule_request.dart';
import 'package:flutterapi/api/chat_api.dart';
import 'package:flutterapi/services/database/schedule_service.dart';
import 'package:flutterapi/models/schedule_model.dart';

class ScheduleViewModel extends ChangeNotifier {
  final ChatApi _chatApi = ChatApi();
  final ScheduleService _scheduleService = ScheduleService();

  List<Schedule> _schedules = [];
  List<Schedule> get schedules => _schedules;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _hasInitialized = false;
  bool get hasInitialized => _hasInitialized;

  late final Stream<List<Schedule>>? _scheduleStream;
  Stream<List<Schedule>>? get scheduleStream => _scheduleStream;
  final userId;

  ScheduleViewModel(this.userId) {
    _scheduleStream = _scheduleService.getSchedulesForUser(userId).map((
      schedules,
    ) {
      schedules.sort((a, b) => a.startTime.compareTo(b.startTime));
      return schedules;
    });
  }

  Future<void> fetchSchedules(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _schedules = await _scheduleService.getSchedulesForUser(userId).first;
    } catch (e) {
      debugPrint("Error fetching tasks: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  String? error;

  // TODO: jadikan void return karena viewmodel, return dto hanya untuk testing
  Future<String?> generateScheduleFromQuery(String userId, String query) async {
    _isLoading = true;
    notifyListeners();

    QueryToScheduleResponseDto? responseDto;
    Map<String, dynamic> jsonResponse = {};
    String? response;
    try {
      jsonResponse = await _chatApi.postChat(
        QueryToScheduleRequestDto(user_id: userId, query: query),
      );
      responseDto = QueryToScheduleResponseDto.fromJson(jsonResponse);
      response = responseDto.toJson()['response'];
    } catch (e) {
      error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return response;
  }

  Future<void> addSchedule(Schedule schedule) async {
    await _scheduleService.addSchedule(schedule);
  }

  Future<void> updateSchedule(Schedule schedule) async {
    await _scheduleService.updateSchedule(schedule);
  }

  Future<void> deleteSchedule(String userId) async {
    await _scheduleService.deleteSchedule(userId);
  }
}
