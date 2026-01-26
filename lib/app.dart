import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/localization/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

import 'core/config/env_config.dart';

/// Main app widget
class OukChaktrongApp extends StatelessWidget {
  final EnvConfig config;
  const OukChaktrongApp({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OutChaktrongAppBloc(),
      child: BlocBuilder<OutChaktrongAppBloc, OutChaktrongAppState>(
        buildWhen: (previous, current) => previous.local != current.local,
        builder: (context, state) {
          return MaterialApp.router(
            title: config.appName,
            locale: Locale(state.local),
            debugShowCheckedModeBanner: config.isUat,
            theme: AppTheme.darkTheme,
            routerConfig: AppRouter.router,
            builder: (context, child) {
              if (config.isUat) {
                return Banner(
                  message: "UAT",
                  location: BannerLocation.topEnd,
                  color: Colors.red,
                  child: child!,
                );
              }
              return child!;
            },
          );
        },
      ),
    );
  }
}

class OutChaktrongAppState extends Equatable {
  final String local;

  const OutChaktrongAppState({required this.local});

  OutChaktrongAppState copyWith({String? local}) {
    return OutChaktrongAppState(local: local ?? this.local);
  }

  @override
  List<Object?> get props => [local];
}

class OutChaktrongAppBloc extends Cubit<OutChaktrongAppState> {
  OutChaktrongAppBloc() : super(OutChaktrongAppState(local: "en")) {
    _init();
  }

  void _init() async {
    String local = await appStrings.getLanguage();
    emit(state.copyWith(local: local));
  }

  void updateLanguage(String local) async {
    await appStrings.setLanguage(local);
    emit(state.copyWith(local: local));
  }
}
