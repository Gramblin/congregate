import 'dart:io';

import 'package:congregate/src/constants/app_sizes.dart';
import 'package:congregate/src/features/login/presentation/controller/login_controller.dart';
import 'package:congregate/src/utils/extension_methods/context_extensions.dart';
import 'package:congregate/src/utils/extension_methods/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  void initState() {
    super.initState();
    setUpAuthListener();
  }

  void setUpAuthListener() {}

  @override
  Widget build(BuildContext context) {
    ref.listen(loginControllerProvider, (_, next) {
      if (next is AsyncError) {
        context.showInformationToast(
          next.error.toString(),
          error: SuccessTypeEnum.error,
        );
      }
    });

    final isLoading = ref.watch(loginControllerProvider).isLoading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Platform.isIOS
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Stack(
        children: [
          Scaffold(
            body: ref
                .watch(userStreamProvider)
                .when(
                  data: (data) {
                    final userAvailable = data.session != null;
                    return Column(
                      children: [
                        gapH128,
                        const Spacer(),
                        Text(
                          'Sign in with Google'.hardcoded,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Sizes.p48,
                          ),
                        ),
                        gapH32,

                        TextButton(
                          onPressed: !userAvailable && !isLoading
                              ? ref
                                    .read(
                                      loginControllerProvider.notifier,
                                    )
                                    .logInUsingGoogle
                              : null,
                          child: const Text(
                            'Sign in With X',
                            style: TextStyle(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Spacer(flex: 3),
                      ],
                    );
                  },
                  error: (error, stackTrace) => SelectableText('Error $error'),
                  loading: CircularProgressIndicator.new,
                ),
          ),
        ],
      ),
    );
  }
}
