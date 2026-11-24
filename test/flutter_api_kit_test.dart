import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_api_kit/flutter_api_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

class _TestRepository extends BaseRepository {}

Response<dynamic> _response(int status, [dynamic data]) => Response(
      requestOptions: RequestOptions(path: '/test'),
      statusCode: status,
      data: data,
    );

void main() {
  setUpAll(() => LoggerUtil.init(logger: Logger(level: Level.off)));

  group('BaseRepository.safeCall', () {
    final repo = _TestRepository();

    test('2xx 응답은 parser 결과를 Right 로 준다', () async {
      final r = await repo.safeCall(
        () async => _response(200, {'name': 'kim'}),
        parser: (data) => data['name'] as String,
      );
      expect(r, const Right<Failure, String>('kim'));
    });

    test('2xx 가 아니면 ResponseFailure', () async {
      final r = await repo.safeCall(() async => _response(404), parser: (d) => d);
      final failure = r.fold((l) => l, (_) => null);
      expect(failure, isA<ResponseFailure>());
      expect(failure!.message, '요청한 자원을 찾을 수 없습니다.');
    });

    test('badResponse DioException 은 상태 코드로 ResponseFailure', () async {
      final r = await repo.safeCall(
        () async => throw DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: _response(500),
        ),
        parser: (d) => d,
      );
      final failure = r.fold((l) => l, (_) => null);
      expect(failure, isA<ResponseFailure>());
      expect((failure as ResponseFailure).statusCode, 500);
    });

    test('연결 오류는 NetworkFailure', () async {
      final r = await repo.safeCall(
        () async => throw DioException.connectionError(
          requestOptions: RequestOptions(path: '/test'),
          reason: 'offline',
        ),
        parser: (d) => d,
      );
      final failure = r.fold((l) => l, (_) => null);
      expect(failure, isA<NetworkFailure>());
      expect((failure as NetworkFailure).isConnectionError, isTrue);
    });

    test('parser 예외는 UnknownFailure', () async {
      final r = await repo.safeCall(
        () async => _response(200, 'not a map'),
        parser: (d) => (d as Map)['x'],
      );
      expect(r.fold((l) => l, (_) => null), isA<UnknownFailure>());
    });

    test('isSuccess 로 성공 기준을 바꿀 수 있다', () async {
      final r = await repo.safeCall(
        () async => _response(304, 'cached'),
        parser: (d) => d as String,
        isSuccess: (code) => code == 200 || code == 304,
      );
      expect(r, const Right<Failure, String>('cached'));
    });
  });

  group('ApiClient', () {
    test('init 전에 instance 를 쓰면 StateError', () {
      expect(ApiClient.isInitialized, isFalse);
      expect(() => ApiClient.instance, throwsStateError);
    });

    test('init 하면 baseUrl 과 공통 헤더가 설정된다', () {
      final client = ApiClient.init(
        baseUrl: 'https://api.example.com',
        headers: {'X-APP': 'demo'},
        enableLog: false,
      );
      expect(ApiClient.instance, same(client));
      expect(client.dio.options.baseUrl, 'https://api.example.com');
      expect(client.dio.options.headers['X-APP'], 'demo');
    });
  });

  group('ParsingUtil', () {
    test('콤마와 + 기호를 처리하고 실패하면 기본값', () {
      expect(ParsingUtil.stringToInt('1,000'), 1000);
      expect(ParsingUtil.stringToInt('+500'), 500);
      expect(ParsingUtil.stringToInt('abc'), 0);
      expect(ParsingUtil.stringToInt(null), 0);
      expect(ParsingUtil.stringToDouble('1.5'), 1.5);
      expect(ParsingUtil.stringToBigInt('99999999999999999999'), BigInt.parse('99999999999999999999'));
    });

    test('jsonToList 는 null 이면 빈 리스트', () {
      expect(ParsingUtil.jsonToList<int>(null, (j) => j['v'] as int), isEmpty);
      expect(
        ParsingUtil.jsonToList<int>([
          {'v': 1},
          {'v': 2},
        ], (j) => j['v'] as int),
        [1, 2],
      );
    });
  });

  group('ContextExtension', () {
    testWidgets('confirmDialog 는 예 → true, 아니오 → false', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));

      final yes = ctx.confirmDialog(content: '삭제할까요?');
      await tester.pumpAndSettle();
      await tester.tap(find.text('예'));
      expect(await yes, isTrue);

      final no = ctx.confirmDialog(content: '삭제할까요?');
      await tester.pumpAndSettle();
      await tester.tap(find.text('아니오'));
      expect(await no, isFalse);
    });
  });
}
