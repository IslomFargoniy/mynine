import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart' hide ProgressCallback;

import '../../data/models/app_models.dart';
import '../../data/models/exam_models.dart';
import '../../data/models/json_helpers.dart';
import '../../data/models/part_payload.dart';
import '../time/server_clock.dart';
import 'api_exception.dart';
import 'mynine_api.dart';

const _examTokenExtra = 'mynine_exam_token';
const _noDeviceTokenExtra = 'mynine_no_device_token';
const _startedAtExtra = 'mynine_started_at';

/// Dio implementation of [MynineApi].
class HttpMynineApi implements MynineApi {
  HttpMynineApi({
    required this.baseUrl,
    required String clientHeader,
    required this.credentials,
    required this.clock,
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _dio.options
      ..connectTimeout = const Duration(seconds: 10)
      ..sendTimeout = const Duration(seconds: 20)
      ..receiveTimeout = const Duration(seconds: 30)
      ..responseType = ResponseType.json;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Accept'] = 'application/json';
          options.headers['X-Mynine-Client'] = clientHeader;
          final token = credentials.deviceToken;
          if (token != null && options.extra[_noDeviceTokenExtra] != true) {
            options.headers['X-Device-Token'] = token;
          }
          final examToken = options.extra[_examTokenExtra];
          if (examToken is String && examToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $examToken';
          }
          options.extra[_startedAtExtra] = DateTime.now().toUtc();
          handler.next(options);
        },
        onResponse: (response, handler) {
          _applyServerTime(response);
          handler.next(response);
        },
      ),
    );
  }

  final String Function() baseUrl;
  final DeviceCredentials credentials;
  final ServerClock clock;
  final Dio _dio;

  String _url(String path) {
    final base = baseUrl().replaceAll(RegExp(r'/+$'), '');
    return '$base$path';
  }

  void _applyServerTime(Response<dynamic> response) {
    final data = response.data;
    if (data is Map && data['server_time'] != null) {
      final serverTime = dateOrNull(data['server_time']);
      final started = response.requestOptions.extra[_startedAtExtra];
      if (serverTime != null) {
        clock.update(
          serverTime,
          requestStartedAt: started is DateTime ? started : null,
        );
      }
    }
  }

  Future<Map<String, Object?>> _json(
    String method,
    String path, {
    Object? body,
    Map<String, Object?>? query,
    String? examToken,
    bool noDeviceToken = false,
  }) async {
    try {
      final response = await _dio.request<Object?>(
        _url(path),
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          contentType: body == null ? null : Headers.jsonContentType,
          extra: {
            _examTokenExtra: ?examToken,
            if (noDeviceToken) _noDeviceTokenExtra: true,
          },
        ),
      );
      final data = response.data;
      if (data is Map) {
        return data.map((k, v) => MapEntry(k.toString(), v));
      }
      if (data == null || data == '') return const {};
      throw ApiException(
        code: ApiErrorCode.unknown,
        statusCode: response.statusCode,
        message: 'Unexpected response body',
        body: data,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Maps a Dio error to an [ApiException] using the `{message, code}` body.
  static ApiException mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ApiException(code: ApiErrorCode.network, message: e.message);
      case DioExceptionType.unknown:
        if (e.error is SocketException || e.error is HttpException) {
          return ApiException(code: ApiErrorCode.network, message: e.message);
        }
        return ApiException(code: ApiErrorCode.unknown, message: e.message);
      default:
        break;
    }
    final response = e.response;
    final status = response?.statusCode;
    final data = response?.data;
    String? code;
    String? message;
    String? minVersion;
    DateTime? startsAt;
    if (data is Map) {
      code = data['code']?.toString();
      message = data['message']?.toString();
      minVersion = data['min_version']?.toString();
      startsAt = dateOrNull(data['starts_at']);
    }
    return ApiException(
      code: ApiErrorCode.fromWire(code, status),
      statusCode: status,
      message: message,
      minVersion: minVersion,
      startsAt: startsAt,
      body: data,
    );
  }

  // ---- App -----------------------------------------------------------------

  @override
  Future<AppVersionInfo> appVersion({String? current}) async =>
      AppVersionInfo.fromJson(await _json(
        'GET',
        '/app/version',
        query: {'current': ?current},
        noDeviceToken: true,
      ));

  // ---- Device --------------------------------------------------------------

  @override
  Future<DeviceRegistration> registerDevice({
    required String machineId,
    required String name,
    required String osVersion,
    required String appVersion,
  }) async =>
      DeviceRegistration.fromJson(await _json(
        'POST',
        '/device/register',
        body: {
          'machine_id': machineId,
          'name': name,
          'os_version': osVersion,
          'app_version': appVersion,
        },
        noDeviceToken: true,
      ));

  @override
  Future<DeviceHeartbeat> deviceHeartbeat({
    required String appVersion,
    required DeviceState state,
  }) async =>
      DeviceHeartbeat.fromJson(await _json('POST', '/device/heartbeat', body: {
        'app_version': appVersion,
        'state': state.name,
      }));

  @override
  Future<bool> deviceUnlock(String password) async {
    try {
      final data =
          await _json('POST', '/device/unlock', body: {'password': password});
      return data['ok'] == true;
    } on ApiException catch (e) {
      if (e.statusCode == 422) return false;
      rethrow;
    }
  }

  @override
  Future<DeviceConfig> deviceConfig() async =>
      DeviceConfig.fromJson(await _json('GET', '/device/config'));

  // ---- Exam auth -----------------------------------------------------------

  @override
  Future<LoginResponse> login(String code) async => LoginResponse.fromJson(
        await _json('POST', '/exam/login', body: {'code': code.trim().toUpperCase()}),
      );

  @override
  Future<void> logout(String examToken) async {
    await _json('POST', '/exam/logout', examToken: examToken);
  }

  // ---- Exam ----------------------------------------------------------------

  @override
  Future<ExamState> examState(String examToken) async =>
      ExamState.fromJson(await _json('GET', '/exam', examToken: examToken));

  @override
  Future<PrefetchPayload> prefetch(String examToken) async =>
      PrefetchPayload.fromJson(
        await _json('GET', '/exam/prefetch', examToken: examToken),
      );

  @override
  Future<PartPayload> part(String examToken, int partId) async =>
      PartPayload.fromJson(
        await _json('GET', '/exam/parts/$partId', examToken: examToken),
      );

  @override
  Future<ModuleStartResponse> startModule(String examToken, int typeId) async =>
      ModuleStartResponse.fromJson(await _json(
        'POST',
        '/exam/modules/$typeId/start',
        examToken: examToken,
      ));

  @override
  Future<AnswersResponse> sendAnswers(
    String examToken,
    List<AnswerItem> answers,
  ) async =>
      AnswersResponse.fromJson(await _json(
        'POST',
        '/exam/answers',
        examToken: examToken,
        body: {'answers': answers.map((a) => a.toJson()).toList()},
      ));

  @override
  Future<ModuleSubmitResponse> submitModule(String examToken, int typeId) async =>
      ModuleSubmitResponse.fromJson(await _json(
        'POST',
        '/exam/modules/$typeId/submit',
        examToken: examToken,
      ));

  @override
  Future<ExamSubmitResponse> submitExam(String examToken) async =>
      ExamSubmitResponse.fromJson(
        await _json('POST', '/exam/submit', examToken: examToken),
      );

  @override
  Future<ExamHeartbeatResponse> examHeartbeat(
    String examToken, {
    int? typeId,
    int? partId,
    required int queuedAnswers,
    required int queuedViolations,
    DateTime? onlineSince,
  }) async =>
      ExamHeartbeatResponse.fromJson(await _json(
        'POST',
        '/exam/heartbeat',
        examToken: examToken,
        body: {
          'type_id': typeId,
          'part_id': partId,
          'queued_answers': queuedAnswers,
          'queued_violations': queuedViolations,
          'online_since': dateToJson(onlineSince),
        },
      ));

  @override
  Future<ViolationsResponse> sendViolations(
    String examToken,
    List<ViolationItem> violations,
  ) async =>
      ViolationsResponse.fromJson(await _json(
        'POST',
        '/exam/violations',
        examToken: examToken,
        body: {'violations': violations.map((v) => v.toJson()).toList()},
      ));

  // ---- Download with resume --------------------------------------------------

  @override
  Future<File> download(
    String url,
    File target, {
    String? examToken,
    ProgressCallback? onProgress,
  }) async {
    await target.parent.create(recursive: true);
    final partial = File('${target.path}.part');
    var existing = await partial.exists() ? await partial.length() : 0;

    Response<ResponseBody> response;
    try {
      response = await _dio.get<ResponseBody>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(minutes: 2),
          headers: {
            if (existing > 0) 'Range': 'bytes=$existing-',
            'Accept': '*/*',
          },
          extra: {_examTokenExtra: ?examToken},
          validateStatus: (s) => s != null && (s < 400 || s == 416),
        ),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }

    final status = response.statusCode ?? 0;
    if (status == 416) {
      // Requested range not satisfiable: the .part file is already complete
      // (or corrupt — the SHA-256 check by the caller decides).
      if (await target.exists()) await target.delete();
      return partial.rename(target.path);
    }

    final append = status == 206 && existing > 0;
    if (!append) existing = 0;
    final lengthHeader =
        int.tryParse(response.headers.value(Headers.contentLengthHeader) ?? '');
    final total = lengthHeader == null ? -1 : lengthHeader + existing;

    final sink = partial.openWrite(mode: append ? FileMode.append : FileMode.write);
    var received = existing;
    try {
      await for (final chunk in response.data!.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.flush();
    } catch (e) {
      await sink.close();
      if (e is DioException) throw mapDioError(e);
      throw ApiException(code: ApiErrorCode.network, message: e.toString());
    }
    await sink.close();
    if (await target.exists()) await target.delete();
    return partial.rename(target.path);
  }
}
