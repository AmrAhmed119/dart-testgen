mixin Mixin1 {}
mixin Mixin2 {}

abstract class Abstract1 {}

abstract class Abstract2 {}

class Class1 {}

class Class2 extends Class1
    with Mixin1, Mixin2
    implements Abstract1, Abstract2 {}

abstract class Abstract3 extends Abstract1
    with Mixin1, Mixin2
    implements Abstract2 {}

mixin Mixin3 on Mixin1, Mixin2 implements Class1, Class2 {}

enum Enum implements Abstract1, Abstract2 { value1 }

extension Extension on Class1 {}

extension type ExtensionType(Class2 c)
    implements Class1, Abstract1, Abstract2 {}
