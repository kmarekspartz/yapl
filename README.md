# YAPL

Inspired by [YAML](http://yaml.org), Scheme, and [TCL](https://www.tcl.tk/).

Based on [ulithp](http://fogus.github.io/ulithp/).

Converts YAML to s-expressions then evaluates using ulithp.


```yaml
# example.yaml
- define:
    max:
      - [a, b]
      - if: [gt: [a, b], a, b]
    a: 42
    b: 46
- max: [a, b]
```

## Run it

    ruby interpreter.rb example.yaml

## Test it

    ruby test.rb
