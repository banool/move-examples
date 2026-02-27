To compile try something like this:
```
aptos move compile --named-addresses thisaddr=0x5,otheraddrone=0x6,otheraddrtwo=0x7
```

Notice that we're using the renamed named addresses that we defined in the Move.toml in this directory (`otheraddrone` and `otheraddrtwo`), not the named addresses defined in the dependencies (`otheraddr`).

TODO: This resolves the conflicting named address problem, but what now I get a conflicting module names problem:
```
error: duplicate declaration, item, or annotation
  ┌─ /Users/dport/github/move-examples/multiple_dependencies_with_same_named_address/main_package/../other_package_two/sources/code.move:1:19
  │
1 │ module otheraddr::basic {
  │                   ^^^^^
  │                   │
  │                   Duplicate definition for module '(otheraddr=0x6)::basic'
  │                   Module previously defined here, with '(otheraddr=0x6)::basic'
```

TODO: It seems there is no way to handle the case where the two packages have the same name, you have to rename the packages. Confirm this.
