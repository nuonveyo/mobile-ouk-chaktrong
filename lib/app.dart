import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/localization/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Main app widget
class OukChaktrongApp extends StatelessWidget {
  const OukChaktrongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OutChaktrongAppBloc(),
      child: BlocBuilder<OutChaktrongAppBloc, OutChaktrongAppState>(
        buildWhen: (previous, current) => previous.local != current.local,
        builder: (context, state) {
          return MaterialApp.router(
            title: 'Ouk Chaktrong',
            locale: Locale(state.local),
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            routerConfig: AppRouter.router,
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
