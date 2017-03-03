# OID

* Author: Jonathan M. Wilbur
* Copyright: Jonathan M. Wilbur
* License: [Boost License 1.0](http://www.boost.org/LICENSE_1_0.txt)
* Date: March 2nd, 2017
* Version: 1.0.1

A OID class for strongly-typed ASN.1 Object Identifiers in D. This will
eventually be incorporated into a full-blown ASN.1 library, which I hope to
push to the D Standard Library.

## Why Can't I Just Use an Array of Integers?

You probably could, but have you considered this?

* The first node of an OID can only be either 0, 1, or 2.
* The second node of an OID cannot be greater than 40.
* Each node of an OID can have a string (descriptor) that describes what that node means
* Strongly-typing a language correlates with fewer bugs \[citation needed\]

This library provides a strongly-typed OID, which throws exceptions if the above
restrictions are violated, and maps descriptors to nodes. Plus, this library
makes sure that you can't have a gigantic OID (mitigating the possibilities for
OID-related Denial-of-Service attacks).

## Basic Usage

There are two constructors to create OID objects. One takes an array of numbers;
another takes an array of OIDNode structs.

```d
OID oid = new OID([1, 3, 6, 1]);
OID oid = new OID(1, 3, 6, 1);
OID oid = new OID(
    OIDNode(1, "iso"),
    OIDNode(3, ""),
    OIDNode(6, "dod"),
    OIDNode(1, "internet")
);
```

If you create an OID using the OID(int[]) constructor, none of the OID nodes
have labels / descriptors. You can set them with these methods:

```d
oid.descriptor(0, "iso"); // 0 is the index
oid.descriptors([ "iso", "", "dod", "internet"]);
oid.descriptors("iso", "", "dod", "internet");
```

Once you have created the OID, you can return the OID in various formats. For
all but the URN, if a node has a descriptor, the output will display the
descriptor instead of the number.

```d
oid.numericArray // [ 1L, 3L, 6L, 1L ]
oid.dotNotation // iso.3.dod.internet
oid.asn1Notation // {iso 3 dod internet}
oid.iriNotation // /iso/3/dod/internet
oid.urnNotation // urn:oid:1:3:6:1
```

And, of course, you have the length property (read-only):

```d
oid.length // 4
```

## See Also

* [X.690](http://www.itu.int/rec/T-REC-X.690/en), published by the
[International Telecommunications Union](http://www.itu.int/en/pages/default.aspx).
* [Wikipedia: Object Identifiers](https://en.wikipedia.org/wiki/Object_identifier)
* The included oid.html, generated automatically from DDoc.

## Contact Me

If you would like to suggest fixes or improvements on this library, please just
comment on this on GitHub. If you would like to contact me for other reasons,
please email me at [jwilbur@jwilbur.info](mailto:jwilbur@jwilbur.info).
