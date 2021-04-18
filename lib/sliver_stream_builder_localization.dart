import 'package:flutter/material.dart';

abstract class StreamSliverBuilderLocalization {
  String get languageCode;
  String get errorRetryButtonText;
  String get errorMessageDefaultText;

  static StreamSliverBuilderLocalization of(BuildContext context) {
    final lcode = Localizations.localeOf(context).languageCode;
    // TODO this code need api check and testing
    switch (lcode) {
      case 'ru':
        return StreamSliverBuilderLocalizationRu();
      case 'en':
        return StreamSliverBuilderLocalizationEn();
      default:
        return StreamSliverBuilderLocalizationEn();
    }
  }
}

class StreamSliverBuilderLocalizationRu
    extends StreamSliverBuilderLocalization {
  @override
  String get errorMessageDefaultText => 'Произошла ошибка при загрузке данных.';

  @override
  String get errorRetryButtonText => 'Попробовать снова';

  @override
  String get languageCode => 'ru';
}

class StreamSliverBuilderLocalizationEn
    extends StreamSliverBuilderLocalization {
  @override
  String get errorMessageDefaultText => 'The error has been acquired.';

  @override
  String get errorRetryButtonText => 'Retry';

  @override
  String get languageCode => 'en';
}
