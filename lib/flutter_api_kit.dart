/// 상태관리(GetX, Provider, Riverpod 등)와 무관하게 쓰는 네트워크·유틸 계층.
///
/// `import 'package:flutter_api_kit/flutter_api_kit.dart';` 한 줄로
/// ApiClient / BaseRepository / Failure / 유틸을 모두 쓸 수 있다.
library;

export 'package:dartz/dartz.dart' show Either, Left, Right;

export 'src/extensions/context_extension.dart';
export 'src/network/api_client.dart';
export 'src/network/base_repository.dart';
export 'src/network/failure.dart';
export 'src/utils/logger_util.dart';
export 'src/utils/parsing_util.dart';
