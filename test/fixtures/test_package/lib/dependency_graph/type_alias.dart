class Class1 {}

class Class2 {}

typedef Alias1 = Class1 Function(Class2);
typedef Alias2 = Class1 Function(int);
typedef Alias3<T> = T Function(T value, Class2 val);
typedef Alias4 = Map<Class1, Class2>;
