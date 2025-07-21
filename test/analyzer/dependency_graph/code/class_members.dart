int globalVar1 = 30;

void globalFunc(int x) {}

mixin Logger {
  void log(String msg) {}
}

class Class1 {
  String field1 = 'test';

  void method1() {}
}

extension StringExtension on String {
  void method2() {}
}

enum Enum {
  value1(0),
  value2(1),
  value3(3);

  final int code;

  const Enum(this.code);
}

class Class2 extends Class1 with Logger {
  String field2 = 'name';
  int _field3 = 1;
  Class2? _field4;
  int conditionalVar = globalVar1 == 1 ? Enum.value1.code : 3;

  Class2.named(this.field2, Class2 c2) {
    _field4 = c2;
    print(_field3);
    method3();
  }

  void method3() {}

  Class2? get field4 => _field4;

  set field3(int i) => _field3 = i;

  void method4() {
    print(globalVar1);
    globalFunc(1);
    log('test');
    print(field1);
    method1();
    'test'.method2();
    print(Enum.value1);
    print(field2);
    print(field4);
    field3 = 3;
    method4();
  }
}
