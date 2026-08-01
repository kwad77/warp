import 'package:freezed_annotation/freezed_annotation.dart';

import '../../models/user.dart';

part 'auth_state.freezed.dart';

/// SPEC §12 auth flow states.
@freezed
class AuthState with _$AuthState {
  const factory AuthState.loggedOut() = _LoggedOut;
  const factory AuthState.codeSent(String email) = _CodeSent;
  const factory AuthState.loggedIn(User user) = _LoggedIn;
  const factory AuthState.error(String message) = _Error;
}
