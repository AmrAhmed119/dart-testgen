/// mutli variable declaration
int a = 5, b = 10;

extension StringExtension on String {
  String reversed() => split('').reversed.join();
}

mixin Logger {
  void log(String message) => print('Log: new Log');
}

enum Status {
  pending(0),
  approved(1),
  rejected(2);

  final int code;

  const Status(this.code);

  void describe() {
    print('Status: $name with code $code');
  }
}

/// A typedef for a callback that takes an int and returns an int.
/// This is a multi-line comment.
typedef IntCallback = int Function(int);

/// generic typedef
typedef Mapper<T> = T Function(T value);

/// Test comment
extension type UserID(int id) {
  bool get isValid => id > 0;

  /// get user id in a formatted string
  String getUser() => 'UserID($id)';
}

/// Class Definition for [Person]
/// Multi line comment
class Person
extends Another
with Logger {
  /// The name of the person
  String name;

  /// Constructor for Person
  Person.named(this.name);

  /// Greet the person
  void greet() {
    print('Hello $name');
  }
}

class Another {}

/// comment above annotation
@Deprecated('Use sum instead')
int sum(int x, int y) => x + y;
