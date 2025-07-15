class Class1 {
  int field = 1;

  int method1() => 1;
}

enum Enum { value1 }

extension Extension on int {
  int method2() => 3;
}

int func1() => 1;

final var1 = Class1();
int var2 = 1;
int var3 =
    var2 +
    func1() +
    var1.field +
    var1.method1() +
    Enum.value1.index +
    3.method2();

typedef IntCallback = int Function(int);
IntCallback var4 = (int x) => x * x;
int var5 = var4(var2);

typedef ClassList = List<Class1>;
final ClassList var6 = [Class1(), Class1()];

void func2(Class1 c1, Enum e) {
  print(Enum.value1.index);
  print(Class1().field);
  print(Class1().method1());
  print(1.method2());
  print(func1());
  print(var1);
  print(var2);
  print(var4(3));
  print(var5);
  print(var6);
}
