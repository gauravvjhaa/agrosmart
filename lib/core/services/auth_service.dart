enum UserRole { owner, worker, advisor, admin }

class AuthService {
  UserRole currentRole = UserRole.owner;
  bool get isAdmin => currentRole == UserRole.admin;
  // TODO: integrate Firebase Auth
}
