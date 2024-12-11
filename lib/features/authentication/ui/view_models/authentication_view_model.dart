import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/constants/constants.dart';
import 'package:flutter_mvvm_riverpod/extensions/string_extension.dart';
import 'package:flutter_mvvm_riverpod/features/authentication/repository/authentication_repository.dart';
import 'package:flutter_mvvm_riverpod/features/authentication/ui/state/authentication_state.dart';
import 'package:flutter_mvvm_riverpod/features/profile/ui/view_models/profile_view_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'authentication_view_model.g.dart';

@riverpod
class AuthenticationViewModel extends _$AuthenticationViewModel {
  @override
  FutureOr<AuthenticationState> build() async {
    return const AuthenticationState();
  }

  Future<void> signInWithMagicLink(String email) async {
    state = const AsyncValue.loading();
    final authRepo = ref.read(authenticationRepositoryProvider);
    final result = await AsyncValue.guard(() => authRepo.signInWithMagicLink(email));

    if (result.hasError) {
      state = AsyncError(result.error.toString(), StackTrace.current);
      return;
    }

    state = const AsyncData(AuthenticationState());
  }

  Future<void> verifyOtp({
    required String email,
    required String token,
    required bool isRegister,
  }) async {
    state = const AsyncValue.loading();
    final authRepo = ref.read(authenticationRepositoryProvider);
    final result = await AsyncValue.guard(() => authRepo.verifyOtp(
      email: email,
      token: token,
      isRegister: isRegister,
    ));
    handleResult(result);
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    final authRepo = ref.read(authenticationRepositoryProvider);
    final result = await AsyncValue.guard(authRepo.signInWithGoogle);
    handleResult(result);
  }

  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    final authRepo = ref.read(authenticationRepositoryProvider);
    final result = await AsyncValue.guard(authRepo.signInWithApple);
    handleResult(result);
  }

  void handleResult(AsyncValue result) async {
    debugPrint('${Constants.tag} [AuthenticationViewModel.handleResult] result: $result');
    if (result.hasError) {
      state = AsyncError(result.error.toString(), StackTrace.current);
      return;
    }

    final AuthResponse? authResponse = result.value;
    debugPrint('${Constants.tag} [AuthenticationViewModel.handleResult] authResponse: ${authResponse?.user?.toJson()}');
    if (authResponse == null) {
      state = AsyncError('unexpected_error_occurred'.tr(), StackTrace.current);
      return;
    }

    final isExistAccount =
        await ref.read(authenticationRepositoryProvider).isExistAccount();
    if (!isExistAccount) {
      ref.read(authenticationRepositoryProvider).setIsExistAccount(true);
    }

    ref.read(authenticationRepositoryProvider).setIsLogin(true);
    ref
        .read(profileViewModelProvider.notifier)
        .updateProfile(email: authResponse.user?.email.orEmpty());

    state = AsyncData(
      AuthenticationState(
        authResponse: authResponse,
        isRegisterSuccessfully: !isExistAccount,
        isSignInSuccessfully: true,
      ),
    );
  }
}