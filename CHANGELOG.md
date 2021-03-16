## 0.4.0

1) `def` now supports generics instantiation:
    
    ```nim
    def something[T](a T):
        return a * 2

    init:
        a = something(1)          #like structs: no generics == float
        a int = something[int](1) #explicit int
    ```

2) `struct` now supports default initialization for fields.

    ```nim
    struct Something[T]:
        a T
    
    def newData[T](size):
        return Data[T](size)
    
    struct SomethingElse[T]:
        a = 0.5
        b int = 3
        something Something[T]
        something2 = Something[T](samplerate) #using a constructor: type is inferred
        data Data[T] = newData[T](100)        #not calling a constructor: must be explicit on the type!
    ```

3) `Data[T]` will compile even with uninitialized fields: they will be initialized with the default constructor of `T`, and a warning will be printed.

4) Accessing a `Data[T]` field in the `init` block will initialize it to the default `T` constructor.

## 0.3.0

1) Deprecate `nim < 1.4`.

2) New `ins` and `outs` mechanism: dynamic counting of IO:

    ```nim
    ins 2

    ins 2:
        freq
        amp

    ins:
        freq
        amp
    
    outs 2

    outs 2:
        out1
        out2

    outs:
        out1
        out2
    ```

3) New `ins` and `outs` mechanism: dynamic counting of IO inside `perform` and `sample`. This allows to not having to declare `ins` and `outs` explicitly, but they will be extracted by parsing the `perform` or `sample` blocks. Dynamic access still works as expected:

    ```nim
    sample:
        out1 = in15
        out26 = in2
        outs[27] = 2       #Will be ignored, outs are 26
        outs[20] = ins[16] #outs[20] will be set to 0, as ins[16] is out of bounds
    ```

4) Introducing `params`. These are `floats` like inputs, but they imply a separation between what's audio rate and what's control rate: `ins` will always be audio rate, while `params` will always be control rate.
    
    ```nim
    params:
        freq {440, 1, 22000}
        amp  {1, 0, 1}

    init:
        phase = 0

    sample:
        freq_incr = freq / samplerate
        out1 = sin(phase * twopi) * amp
        phase = (phase + freq_incr) % 1
    ```

    When names are not declared, `params` will be named `param1, param2, etc...`:
    
    ```nim
    params 3

    sample:
        out1 = param1 + param2 + param3
    ```

5) Introducing `buffers`. This is the new way of declaring a `Buffer`. An Omni wrapper, then, would use this interface to provide its own implementation of a `Buffer`. Refer to `Writing an Omni wrapper` on the manual.

    ```nim
    buffers:
        myBuf1 "defaultValue"
        myBuf2 
        myBuf3 "anotherDefaultValue"

    sample:
        out1 = myBuf1[0] + myBuf2[0] + myBuf3[0]
    ```

    When names are not declared, `buffers` will be named `buf1, buf2, etc...`:
    
    ```nim
    buffers 3

    sample:
        out1 = buf1[0] + buf2[0] + buf3[0]
    ```

6) Dynamic access to `ins`, `outs`, `params` and `buffers`:

    ```nim
    params 2
    buffers 3
    ins 4
    outs 5

    sample:
        loop(i, params):
            outs[i] = ins[i] * buffers[i][params[i]]
    ```

7) Define `default` / `min` / `max` with keywords:

    ```nim
    ins:
        freq {min: 0, max: 1000}
    
    params:
        freq {default: 440, min: 0, max: 20000}
        amp  {min: 0}
    ```
8) Introducing `:=` for aliases:
    
    ```nim
    struct Something:
        data Data

    init:
        something = Something(Data())
        bubu := something.data

    sample:
        out1 = bubu[0]
        bubu[0] = in1
    ```

9) `def` can now be used without arguments, if needed:

    ```nim
    def something:
        return 0.5

    def something2 float:
        return 0.5

    def something3 float:
        return 0.5
    ```

10) `loop`: reversed the arguments and support for range.

    ```nim
    loop(i, 4)

    loop(i, 0..3)
    
    loop(i, 0..<4)

    loop i 4

    loop i 0..3
    
    loop i 0..<4

    loop i, 4

    loop i, 0..3

    loop i, 0..<4
    ```

    Anonymous index through the `_` identifier:

    ```nim
    loop 4:
        print _
    ```

    Support for `Data` access and initialization:

    ```nim
    struct Something:
        a float

    init:
        data = Data[Something](10)
        loop(something, data):
            something = Something()

        data2 = Data[Something](10)
        loop data2:
            _ = Something()
    ```

    Infinite loops:

    ```nim
    loop:
        print "hanging forever"
    ```

11) New CLI flag: `--exportIO`. This will export an `omni_io.txt` file with infos about `ins` / `params` / `buffers` / `outs`.

12) CLI's `--importModule` flag is now shortened with `-m`.

13) New `--define` options:
    
    1) *omni_locks_disable*: disable all locks relative to `params` and `buffers` access, turning them into no-ops. This option also defines both *omni_locks_disable_param_lock* and *omni_locks_disable_buffer_lock*.
    2) *omni_locks_disable_param_lock*: disable all locks (even individual ones when `omni_locks_multi_param_lock` is defined) relative to `params`.
    3) *omni_locks_disable_buffer_lock*: disable the global `buffer` lock.
    4) *omni_locks_multi_param_lock*: use an individual lock for each `param`. If not defined, a global lock, like the one for `buffers`, will be used
    5) *omni_buffers_disable_multithreading*: don't run the `unlock()` call on `buffers` (no multithread access to them).

    **NOTE:** These locks are internal `Omni` locks, and they do not refer to the ones that an `Omni` wrapper might implement for safe access to `buffers`. The `Omni` locks only make sure that any `Omni_UGenSetParam` / `Omni_UGenSetBuffer` operation is thread safe.
        
## 0.2.3

1) Fix for `-d:lto` on MacOS
2) Added `-v` flag and copyright
3) Added Error printing on Warning[GcMem]

## 0.2.2

1) Support for Nim 1.4.0
2) Added `-d:lto` flag
3) Added `--panics:on` flag
4) `Delay` length defaults to 1

## 0.2.1

1) Introducing the `loop` construct:

    ```nim
    loop 4 i:
        print i
    ```

2) Better error printing for invalid `def` and `struct` builds.

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

3) Explicit casting at variables declaration will keep the type:

    ```nim
    a = int(1) #Will be int, not float!
    ```

4) Variables and `Buffers` can now be declared from the `ins` statement:

    ```nim
    ins 2:
        buffer Buffer
        speed  {1, 0, 10}

    outs 1

    init:
        phase = 0.0

    sample:
        scaled_rate = buffer.samplerate / samplerate
        out1 = buffer[phase]
        phase += (speed * scaled_rate)
        phase = phase % buffer.len
    ```

5) Added `tuples` support:

    ```nim
    def giveMeATuple():
        a (int, int) = (1, 2) #OR a = (int(1), int(2))
        b = (1, 2, a) #(float, float, (int, int))
        return b     

    init:
        a = giveMeATuple()
        print a[0]; print a[1]
        print a[2][0]; print a[2][1]
    ```

6) Introducing `modules` via the `use` / `require` statements (they are equivalent, still deciding which name I like better):

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

7) Better handling of variables' scope. `if / elif / else / for / while` have their own scope, but won't overwrite variables of encapsulating scopes.

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
