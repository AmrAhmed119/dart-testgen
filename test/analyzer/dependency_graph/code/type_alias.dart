class Class1 {}
class Class2 {}

typedef alias1 = Class1 Function(Class2);
typedef alias2 = Class1 Function(int);
typedef alias3<T> = T Function(T value, Class2 val);
typedef alias4 = Map<Class1, Class2>;