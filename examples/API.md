API documentation for the VPack library
=======================================

This document provides a step-by-step instruction for using the most 
important VPack classes. Use cases covered are 

* building new VPack objects dynamically
* inspecting the contents of VPack objects
* converting JSON data into VPack values
* serializing VPack values to JSON 

Please also have a look at the file [Embedding.md](Embedding.md) as it
contains information about how to include the VPack classes in other
applications and link against the VPack library.


Building VPack objects programmatically
---------------------------------------

VPack objects can be assembled easily with a `Builder` object.
This `Builder` class organizes the buildup of one or many VPack objects.
It manages the memory allocation and provides convenience methods to build
compound objects recursively.

The following example program will build a top-level object of VPack 
type `Object`, with the following 4 keys:

- `b`: is an integer with value `12`
- `a`: is the Boolean value `true`
- `l`: is an Array with the 3 numeric sub-values `1`, `2` and `3`
- `name`: is the String value `"Gustav"`

This resembles the following JSON object:
```json
{
  "b" : 12,
  "a" : true,
  "l" : [
    1,
    2,
    3
  ],
  "name" : "Gustav"
}
```

After the VPack value is created, the example program will print a 
hex dump of its underlying memory:

```cpp
#include <velocypack/vpack.h>
#include <iostream>

using namespace arangodb::velocypack;

int main () {
  // create an object with attributes "b", "a", "l" and "name"
  // note that the attribute names will be sorted in the target VPack object!
  Builder b;

  b.add(Value(ValueType::Object));
  b.add("b", Value(12));
  b.add("a", Value(true));
  b.add("l", Value(ValueType::Array));
  b.add(Value(1));
  b.add(Value(2));
  b.add(Value(3));
  b.close();
  b.add("name", Value("Gustav"));
  b.close();

  // now dump the resulting VPack value
  std::cout << "Resulting VPack:" << std::endl;
  std::cout << HexDump(b.slice()) << std::endl;
}
```

Values will automatically be added to the last created compound value, 
i.e. the last created `Array` or `Object` value. To finish a compound
object, the Builder's `close` method must be called.

If you like fancy syntactic sugar, the same object can alternatively be
built using operator syntax:

```cpp
#include <velocypack/vpack.h>
#include <iostream>

using namespace arangodb::velocypack;

int main () {
  // create an object with attributes "b", "a", "l" and "name"
  // note that the attribute names will be sorted in the target VPack object!
  Builder b;

  b(Value(ValueType::Object))
    ("b", Value(12))
    ("a", Value(true))
    ("l", Value(ValueType::Array))
      (Value(1)) (Value(2)) (Value(3)) ()
    ("name", Value("Gustav")) ();

  // now dump the resulting VPack value
  std::cout << "Resulting VPack:" << std::endl;
  std::cout << HexDump(b.slice()) << std::endl;
}
```

Note that the behavior of `Builder` objects can be adjusted by setting the
following attributes in the Builder's `options` attribute:

- `sortAttributeNames`: when creating a VPack Object value, the Builder
  object will sort the Object's attribute names alphabetically in the
  assembled VPack object.
  Sorting the names allows accessing individual attributes by name quickly
  later. However, sorting takes CPU time so client applications may
  want to turn it off, especially when constructing *temporary*
  objects. Additionally, sorting may lead to the VPack Object having
  a different order of attributes than the source JSON value.
  By default, attribute names are sorted.
- `checkAttributeUniqueness`: when building a VPack Object value,
  the same attribute name may be used multiple times due to a programming
  error in the client application.
  Client applications can set this flag to make the `Builder` validate
  that attribute names are actually unique on each nesting level of Object
  values. This option is turned off by default to save CPU time.

For example, to turn on attribute name uniqueness checks and turn off
the attribute name sorting, a `Builder` could be configured as follows:

```cpp
Builder b;
b.options.checkAttributeUniqueness = true;
b.options.sortAttributeNames = false;

// now do something with Builder b
```


Inspecting the contents of a VPack object
-----------------------------------------

The `Slice` class can be used for accessing existing VPack objects and
inspecting them. A `Slice` can be considered a *view over a memory
region that contains a VPack value*, but it provides high-level access
methods so users don't need to mess with the raw memory. 
`Slice` objects themselves are very lightweight and the cost of their
construction is relatively low.

```cpp
#include <velocypack/vpack.h>
#include <iostream>

using namespace arangodb::velocypack;

int main () {
  // create an object with attributes "b", "a", "l" and "name"
  // note that the attribute names will be sorted in the target VPack object!
  Builder b;

  b(Value(ValueType::Object))
    ("b", Value(12))
    ("a", Value(true))
    ("l", Value(ValueType::Array))
      (Value(1)) (Value(2)) (Value(3)) ()
    ("name", Value("Gustav")) ();

  // a Slice is a lightweight accessor for a VPack value
  Slice s(b.start());

  // inspect the outermost value (should be an Object...)
  std::cout << "Slice: " << s << std::endl;
  std::cout << "Type: " << s.type() << std::endl;
  std::cout << "Bytesize: " << s.byteSize() << std::endl;
  std::cout << "Members: " << s.length() << std::endl;

  if (s.isObject()) {
    Slice ss = s.get("l");   // Now ss points to the subvalue under "l"
    std::cout << "Length of .l: " << ss.length() << std::endl;
    std::cout << "Second entry of .l:" << ss.at(1).getInt() << std::endl;
  }

  Slice sss = s.get("name");
  if (sss.isString()) {
    ValueLength len;
    char const* st = sss.getString(len);
    std::cout << "Name in .name: " << std::string(st, len) << std::endl;
  }
}
```

It should be noted that `Slice` objects do not own the VPack value
they are pointing to. The client must make sure that the memory a `Slice`
refers to is actually valid. In the above case, the VPack value is
owned by the Builder object b, which is still available and valid when
Slice object s is created and used. 

`Slice` objects are immutable and cannot be used to modify the underlying 
VPack value. In order to modify an existing `VPack` value, a new value
needs to be assembled using a `Builder` or a `Parser` object.

The recommended way to get the contents of a String VPack value is to
use the method `Slice::copyString`, which returns the String value in
an `std::string`.
If access to the VPack value's underlying `char const*` is needed, then
`Slice::getString` will also work, but this is potentially unsafe because
VPack String values are not terminated with a NUL-byte. Using the `char const*`
in functions that work on NUL-byte-terminated C strings will therefore
likely cause problems (crashes, undefined behavior etc.). In order to
avoid some of these problems, `Slice::getString` also returns the length
of the String value in bytes in its first call argument:

```cpp
Slice slice = object.get("name"); 

if (slice.isString()) {
  // the following is unsafe, because the char* returned by
  // getString is not terminated with a NUL-byte
  ValueLength length;
  std::cout << "name* " << slice.getString(length) << std::endl;
  
  // better do this:
  char const* p = slice.getString(length);
  std::cout << "name* " << std::string(p, length) << std::endl;

  // or even better: 
  std::cout << "name: " << slice.copyString() << std::endl;
}
```


Iterating over VPack Arrays and Objects
---------------------------------------

With the VPack compound value types *Array* and *Object* there comes the
need to iterate over their individual members. This can be achieved easily
with the helper classes `ArrayIterator` and `ObjectIterator`.

An `ArrayIterator` object can be constructed from a `Slice` with an 
underlying VPack Array value. Iterating over the Array members can then
be achieved easily using a range-based for loop:

```cpp
Builder b;

// create an Array value with 10 numeric members...
b(Value(ValueType::Array));
for (size_t i = 0; i < 10; ++i) {
  b.add(Value(i));
}
b.close();

Slice s(b.start());

// ...and iterate over the array's members
for (auto const& it : ArrayIterator(s)) {
  std::cout << it << ", number value: " << it.getUInt() << std::endl;
}
```

For VPack values of type *Object*, there is `ObjectIterator`. It provides
the attributes `key` and `value` for the currently pointed-to member: 

```cpp
Builder b;

// create an Object value...
b(Value(ValueType::Object));
b.add("foo", Value(42)); 
b.add("bar", Value("some string value")); 
b.add("qux", Value(true));
b.close();

Slice s(b.start());

// ...and iterate over its members
for (auto const& it : ObjectIterator(s)) {
  std::cout << it.key.copyString() << ", value: " << it.value << std::endl;
}
```


Parsing JSON into a VPack value
-------------------------------

Often there is already existing data in JSON format. To convert that
data into VPack, use the `Parser` class. `Parser` provides an efficient 
JSON parser.

A `Parser` object contains its own `Builder` object. After parsing this
`Builder` object will contain the VPack value constructed from the JSON
input. Use the Parser's `steal` method to get your hands on that 
`Builder` object:

```cpp
#include <velocypack/vpack.h>
#include <iostream>

using namespace arangodb::velocypack;

int main () {
  // this is the JSON string we are going to parse
  std::string const json = "{\"a\":12,\"b\":\"foobar\"}";

  Parser parser;
  try {
    size_t nr = parser.parse(json);
    std::cout << "Number of values: " << nr << std::endl;
  }
  catch (std::bad_alloc const& e) {
    std::cout << "Out of memory!" << std::endl;
    throw;
  }
  catch (Exception const& e) {
    std::cout << "Parse error: " << e.what() << std::endl;
    std::cout << "Position of error: " << parser.errorPos() << std::endl;
    throw;
  }

  // the parser is done. now get its Builder object
  Builder b = parser.steal();

  // now dump the resulting VPack value
  std::cout << "Resulting VPack:" << std::endl;
  std::cout << HexDump(b.slice()) << std::endl;
}
```

When a parse error occurs while parsing the JSON input, the `Parser`
object will throw an exception. The exception message can be retrieved
by querying the Exception's `what` method. The error position in the
input JSON can be retrieved by using the Parser's `errorPos` method.

The parser behavior can be adjusted by setting the following attributes
in the Parser's `options` attribute:

- `validateUt8Strings`: when set to `true`, string values will be
  validated for UTF-8 compliance. UTF-8 checking can slow down the parser
  performance so client applications are given the choice about this.
  By default, UTF-8 checking is turned off.
- `sortAttributeNames`: when creating a VPack Object value
  programmatically or via a (JSON) Parser, the Builder object will
  sort the Object's attribute names alphabetically in the assembled
  VPack object.
  Sorting the names allows accessing individual attributes by name quickly
  later. However, sorting takes CPU time so client applications may
  want to turn it off, especially when constructing *temporary*
  objects. Additionally, sorting may lead to the VPack Object having
  a different order of attributes than the source JSON value.
  By default, attribute names are sorted.
- `checkAttributeUniqueness`: when building a VPack Object value,
  the same attribute name may be used multiple times due to a programming
  error in the client application or when parsing JSON input data with
  duplicate attribute names.
  For untrusted inputs, client applications can set this flag to make the
  `Builder` validate that attribute names are actually unique on each
  nesting level of Object values. This option is turned off by default to
  save CPU time.

Here's an example that configures the Parser to validate UTF-8 strings
in its JSON input. Additionally, the options for the Parser's `Builder`
object are adjusted so attribute name uniqueness is checked and attribute
name sorting is turned off:

```cpp
Parser parser;
parser.options.validateUtf8Strings = true;
parser.options.checkAttributeUniqueness = true;
parser.options.sortAttributeNames = false;

// now do something with the parser
```


Serializing a VPack value into JSON
-----------------------------------

When the task is to create a JSON representation of a VPack value, the
`Dumper` class can be used. A `Dumper` needs a `Sink` for writing the
data. There are ready-to-use `Sink`s for writing into a `char[]` buffer 
or into an `std::string`.

```cpp
#include <iostream>
#include "velocypack/vpack.h"

using namespace arangodb::velocypack;

int main () {
  // don't sort the attribute names in the VPack object we construct
  // attribute name sorting is turned on by default, so attributes can
  // be quickly accessed by name. however, sorting adds overhead when
  // constructing VPack objects so it's optional. there may also be
  // cases when the original attribute order needs to be preserved. in
  // this case, turning off sorting will help, too
  Options options;
  options.sortAttributeNames = false;

  Builder b(&options);
  
  // build an object with attribute names "b", "a", "l", "name"
  b(Value(ValueType::Object))
    ("b", Value(12))
    ("a", Value(true))
    ("l", Value(ValueType::Array))
      (Value(1)) (Value(2)) (Value(3)) ()
    ("name", Value("Gustav")) ();

  Slice s(b.start());

  // turn on pretty printing
  Options dumperOptions;
  dumperOptions.prettyPrint = true;

  // now dump the Slice into an std::string
  StringSink sink;
  Dumper dumper(&sink, &dumperOptions);
  dumper.dump(s);

  // and print it
  std::cout << "Resulting JSON:" << std::endl << sink.buffer << std::endl;
}
```

Note that VPack values may contain data types that cannot be represented in
JSON. If a value is dumped that has no equivalent in JSON, a `Dumper` object
will by default throw an exception. To change the default behavior, set the
Dumper's `unsupportedTypeBehavior` attribute to `NullifyUnsupportedType`:

```cpp
// convert non-JSON types into JSON null values if possible
Options options;
options.unsupportedTypeBehavior = NullifyUnsupportedType;

// now dump the Slice into an std::string
Dumper dumper(&sink, &options);
dumper.dump(s);
```

The `Dumper` also has an `options` attribute that can be used to control
whether forward slashes inside strings should be escaped with a backslash
when producing JSON. The default is to not escape them. This can be changed
by setting the `escapeForwardSlashes` attribute of the Dumper's `option`s:

```cpp
Parser parser;
parser.parse("{\"foo\":\"this/is/a/test\"}");

Options options;
options.escapeForwardSlashes = true;

StringSink sink;
Dumper dumper(&sink, &options);
dumper.dump(parser.steal().slice());
std::cout << sink.buffer << std::endl;
```

Note that several JSON parsers in the wild provide extensions to the
original JSON format. For example, some implementations allow comments 
inside the JSON or support usage of the literals `inf` and `nan`/`NaN`
for out-of-range and invalid numbers. The VPack JSON parser does not 
support any of these extensions but sticks to the JSON specification.
