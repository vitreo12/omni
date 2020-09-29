## 0.2.0

1) Support for command-like calls. Just like `nim`, it works for one arguments only:

    ```nim
    a = Data 10
    a = Data(10) #equivalent
    ```

2) Support for `new` statement, both as `dotExpr` and command:

    ```nim
    a = new Data
    a = new Data 10
    a = new Data(10)
    a = Data.new()
    a = Data.new(10)
    ```

3) Introducing `modules` via the `use` / `require` statements (they are equivalent, still deciding which name I like better):

    `One.omni:`

    ```nim
    struct Something:
        a

    def someFunc():
        return 0.7
    ```

    `Two.omni`

    ```nim
    struct Something:
        a

    def someFunc():
        return 0.3
    ```

    `Three.omni:`

    ```nim
    use One:
        Something as Something1
        someFunc as someFunc1

    use Two:
        Something as Something2
        someFunc as someFunc2

    init:
        one = Something1()
        two = Something2()

    sample:
        out1 = someFunc1() + someFunc2()
    ```

    For more complex examples, check the `NewModules` folder in `omni_lang`'s tests.

4) Better handling of variables' scope. `if / elif / else / for / while` have their own scope, but won't overwrite variables of encapsulating scopes.

    ```nim
    init:
        a = 0
        if in1 > 0:
            a = 2 #Gonna change declared a
            b = 0 #b belongs to this if statement
        else:
            a = 3 #Gonna change declared a
            b = 1 #b belongs to this else statement
    ```
