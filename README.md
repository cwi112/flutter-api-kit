# flutter_api_kit

> 상태관리(GetX · Provider · Riverpod · Bloc)와 상관없이 쓰는 **Flutter 네트워크 · 유틸 계층**

API 호출마다 반복되는 `try/catch`, HTTP 상태 코드 확인, 오류 메시지 변환을 `BaseRepository.safeCall` 한 곳에 모았습니다. Repository는 "무엇을 요청하고 무엇으로 바꿀지"만 작성하고, 결과는 `Either<Failure, T>`로 받아 실패 종류별로 처리합니다.

GetX 화면 구조(BaseView · BaseController)가 필요하면 이 패키지를 포함한 [getx_starter_kit](https://github.com/cwi112/getx-starter-kit)을 쓰면 됩니다.

![Flutter](https://img.shields.io/badge/Flutter-3.29%2B-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.7%2B-0175C2?logo=dart)
![Dio](https://img.shields.io/badge/Dio-5.x-0F9D58)
![tests](https://img.shields.io/badge/tests-11%20passed-brightgreen)

## 패키지 관계

```
flutter_api_kit      ← 네트워크 · Failure · 유틸 (상태관리 무관)
      ▲
      │ 의존 + re-export
getx_starter_kit     ← BaseView · BaseController · BaseBinding · PageState (GetX)
```

상태관리 라이브러리를 바꿔도 네트워크 계층은 그대로 재사용할 수 있도록 GetX 의존 부분과 분리했습니다.

## 구성

| 구성 | 설명 |
| --- | --- |
| `ApiClient` | Dio 싱글턴. baseUrl, 공통 헤더, 타임아웃, 인터셉터, 요청 로그를 `init()` 한 번으로 설정 |
| `BaseRepository.safeCall` | 요청 실행 → 상태 코드 확인 → `parser`로 변환 → `Either<Failure, T>` 반환 |
| `Failure` (sealed) | `ResponseFailure`(4xx/5xx) · `NetworkFailure`(연결·타임아웃) · `UnknownFailure`(파싱 등), 사용자용 한글 메시지 포함 |
| `ParsingUtil` | JSON 배열 → 모델 목록, `"1,000"`/`"+500"` 같은 문자열 숫자 변환 (실패 시 기본값) |
| `LoggerUtil` | 앱 전역 Logger, 초기화 없이 바로 사용 |
| `ContextExtension` | `context.messageDialog` · `confirmDialog`(bool 반환) · `toast` · `deviceWidth/Height` |

```
lib/
├── flutter_api_kit.dart       # import 한 줄로 전체 사용 (Either/Left/Right 포함)
└── src/
    ├── network/               # api_client.dart, base_repository.dart, failure.dart
    ├── utils/                 # logger_util.dart, parsing_util.dart
    └── extensions/            # context_extension.dart
```

## 설치

```yaml
dependencies:
  flutter_api_kit:
    git:
      url: https://github.com/cwi112/flutter-api-kit.git
      ref: main
```

## 사용법

### 1. 앱 시작 시 한 번

```dart
void main() {
  ApiClient.init(
    baseUrl: 'https://api.example.com',
    headers: {'X-APP-VERSION': '1.0.0'},
    timeout: const Duration(seconds: 10),
  );
  runApp(const App());
}
```

### 2. Repository: 요청과 변환만

```dart
class UserRepository extends BaseRepository {
  Future<Either<Failure, User>> getUser(int id) => safeCall(
        () => client.get('/users/$id'),
        parser: (json) => User.fromJson(json),
      );

  Future<Either<Failure, List<User>>> getUsers() => safeCall(
        () => client.get('/users'),
        parser: (json) => ParsingUtil.jsonToList(json, User.fromJson),
      );
}
```

### 3. 결과 처리: 실패 종류별 분기

```dart
final result = await repository.getUser(1);

result.fold(
  (failure) => switch (failure) {
    ResponseFailure(:final statusCode) when statusCode == 401 => goLogin(),
    NetworkFailure(isConnectionError: true) => showOffline(),
    _ => context.toast(failure.message),
  },
  (user) => show(user),
);
```

`Failure`가 sealed class라서 `switch`에서 종류를 빠뜨리면 컴파일 단계에서 알려 줍니다.

## 테스트

```bash
flutter test   # 11개
```

| 대상 | 검증 내용 |
| --- | --- |
| `safeCall` | 2xx 성공, 4xx/5xx → `ResponseFailure`, badResponse 예외, 연결 오류 → `NetworkFailure`, 파싱 오류 → `UnknownFailure`, 성공 기준(`isSuccess`) 변경 |
| `ApiClient` | 초기화 전 사용 시 `StateError`, baseUrl·헤더 설정 |
| `ParsingUtil` | 콤마·부호 문자열, null, 잘못된 값, JSON 배열 변환 |
| `ContextExtension` | `confirmDialog`의 예/아니오 결과 |

## 기술 스택

- **네트워크**: Dio, pretty_dio_logger
- **결과 타입**: dartz `Either`, Dart 3 sealed class · 패턴 매칭
- **로그**: logger
- **테스트**: flutter_test
