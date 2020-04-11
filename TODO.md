* Include an argument `localize: false` to `Cldr.Unit.new/3` because some units are always in the system that they defined in.  A 15mm socket is always a 15mm socket as a (probbaly poor) example.

* And then `Cldr.Unit.localize/2` should include a `force: true` to ignore that flag :-)

* Need to check operator precedence on the expressions in the XML file when we are parsing and processing them

* Implement the `Cldr.Chars` protocol (and review the `String.Chars` implementation to derive the backend properly)


