class Foo {
  private int x;
  private final int y;
  Foo(int x) {
    this.x = x;
  }
  Foo(int y) {
    this.y = y;
  }
  Foo(int y) {
    this(1);
  }
  void bar() {
  }
  static void bar2() {
  }
}
