class MyClass {
  const MyClass.forEnum();
}

enum MyEnum {
  value1(MyClass.forEnum()),
  value2(MyClass.forEnum());

  final MyClass myClass;

  const MyEnum(this.myClass);
}
