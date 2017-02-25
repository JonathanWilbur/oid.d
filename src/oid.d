/**
    Provides a strong type for Object Identifiers as specified in
    $(LINK2 http://www.itu.int/rec/T-REC-X.690/en, X.690), published by the
    $(LINK2 http://www.itu.int/en/pages/default.aspx, International Telecommunications Union),
    as well as related exceptions.

    Note that all OIDs are limited by this implementation to 64 nodes, and each
    node's number may range from zero to ulong.max. Each node descriptor may
    only be up to 65536 characters long. This is to prevent denial of service
    attacks involving extraordinarily long OIDs, numbers, or descriptors.

    Author: Jonathan M. Wilbur
    Copyright: Jonathan M. Wilbur
    Date: February 25th, 2017
    License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Standards: $(LINK2 http://www.itu.int/rec/T-REC-X.690/en, X.690)
    Version: 1.0.0
    See_Also:
        $(LINK2 http://www.itu.int/rec/T-REC-X.690/en, X.690)
        $(LINK2 https://en.wikipedia.org/wiki/Object_identifier, Wikipedia: Object Identifier)
*/
module oid;

version (unittest)
{
    import std.exception : assertThrown, assertNotThrown;
}

/// A generic OID-related exception
class OIDException : Exception
{
    import std.exception : basicExceptionCtors;
    mixin basicExceptionCtors;
}

/**
    Thrown if the OID is more than 64 nodes long. This is thrown to prevent
    OID-related denial-of-service attacks.
*/
class OIDLengthException : OIDException
{
    import std.exception : basicExceptionCtors;
    mixin basicExceptionCtors;
}

/**
    Thrown if an OID node number is negative or larger than ulong.max.
*/
class OIDNumberException : OIDException
{
    import std.exception : basicExceptionCtors;
    mixin basicExceptionCtors;
}

/**
    Thrown if the object descriptor is not entirely graphical characters or if
    the descriptor is longer than 65536 characters. See
    $(LINK2 https://en.wikipedia.org/wiki/Graphic_character, Wikipedia: Graphic Characters)
    for more information on what constitutes Graphic Characters. Also, see
    $(LINK2 https://dlang.org/phobos/std_ascii.html#.isGraphical, std.ascii.isGraphical).
*/
class OIDDescriptorException : OIDException
{
    import std.exception : basicExceptionCtors;
    mixin basicExceptionCtors;
}

/**
    A class for Object Identifiers, that supports object descriptors and various
    output formatting.
*/
public class OID
{
    private import std.traits : isIntegral;
    private import std.conv : text;
    private import std.exception : enforce;

    private OIDNode[] oidNodes = [];

    /**
        A struct representing a single node in an OID, which has a mandatory
        number and an optional descriptor.
    */
    public struct OIDNode
    {
        /**
            The constructor for OIDNode
            Returns: An OIDNode
            Throws:
                OIDNumberException if the number is negative or greater than ulong.max
                OIDDescriptorException if the descriptor is greater than 65536
                    characters long or contains non graphic characters
            See_Also:
                $(LINK2 https://en.wikipedia.org/wiki/Graphic_character, Wikipedia: Graphic Characters)
        */
        this(T)(T number, string descriptor = "")
            if (isIntegral!T)
        {
            this.number = number;
            this.descriptor = descriptor;
        }

        ///
        unittest
        {
            OIDNode node = OIDNode(1234, "boop");
            assert(node.number == 1234L);
            assert(node.descriptor == "boop");
        }

        private ulong _number;
        private string _descriptor;

        /// Returns: the number associated with this OIDNode
        @property public ulong number()
        {
            return this._number;
        }

        ///
        unittest
        {
            OIDNode node = OIDNode(0x03);
            assert(node.number == 3L);
        }

        /// Returns: the descriptor associated with this OIDNode
        @property public string descriptor()
        {
            return this._descriptor;
        }

        ///
        unittest
        {
            OIDNode node = OIDNode(0x03, "blap");
            assert(node.descriptor == "blap");
        }

        /**
            Sets the number associated with this OIDNode, casting it as a ulong
            in the process

            Throws:
                OIDNumberException if the number is negative or greater than ulong.max
        */
        @property public void number(T)(T number)
            if (isIntegral!T)
        {
            enforce!OIDNumberException(number > 0, "OID node numbers cannot be negative.");
            enforce!OIDNumberException(number <= ulong.max, "OID node number too large.");
            this._number = cast(ulong) number;
        }

        ///
        unittest
        {
            OIDNode node = OIDNode(5, "blip");
            node.number = 0x06;
            assert(node.number == 6L);
        }

        /**
            Sets the descriptor associated with this OIDNode

            Throws:
                OIDDescriptorException if the descriptor is greater than 65536
                characters long, or contains non-graphic characters.
            See_Also:
                $(LINK2 https://en.wikipedia.org/wiki/Graphic_character, Wikipedia: Graphic Characters)
        */
        @property public void descriptor(string descriptor)
        {
            import std.ascii : isGraphical;
            enforce!OIDDescriptorException(descriptor.length <= 65536, "OID node descriptor too large.");
            foreach(c; descriptor)
            {
                enforce!OIDDescriptorException(c.isGraphical, "Object descriptors must be a GraphicalString.");
            }
            this._descriptor = descriptor;
        }

        ///
        unittest
        {
            OIDNode node = OIDNode(0x08, "dangitbobby");
            node.descriptor = "butdad";
            assert(node.descriptor == "butdad");
        }

    }

    /**
        Constructor for OID.
        Params:
            oidNumberArray = An array of any integers of any integral type representing
                the sequence of node numbers that constitute the OID.
        Returns: An OID object with no descriptors.
        Throws:
            OIDLengthException if the array is empty
            OIDNumberException if any number is negative or greater than ulong.max
    */
    this(T)(T[] oidNumberArray ...)
        if (isIntegral!T)
    {
        enforce!OIDLengthException(oidNumberArray.length > 0, "No OID numbers provided to constructor.");
        enforce!OIDLengthException(oidNumberArray.length <= 64, "OID is too long.");
        foreach (number; oidNumberArray)
        {
            oidNodes ~= OIDNode(number, "");
        }
    }

    ///
    unittest
    {
        assertNotThrown!OIDException
            (enforce!OIDException(new OID([1, 22, 333]), "Exception thrown!"));
        assertThrown!OIDNumberException
            (enforce!OIDNumberException(new OID([1, 22, -333]), "Negative numbers in OID."));
        assertThrown!OIDLengthException
            (enforce!OIDLengthException(new OID([]), "No OID numbers provided to constructor."));
    }

    /**
        Constructor for OID
        Params:
            oidnodes = An array of OIDNodes
        Returns: An OID object
        Throws:
            OIDLengthException if number of oidnodes (length of OID) is negative
            or greater than 64
    */
    this(OIDNode[] nodes ...)
    {
        enforce!OIDLengthException(nodes.length > 0, "No OID numbers provided to constructor.");
        enforce!OIDLengthException(nodes.length <= 64, "OID is longer than 64 nodes.");
        this.oidNodes = nodes;
    }

    ///
    unittest
    {
        OIDNode node1 = OIDNode(1, "iso");
        OIDNode node2 = OIDNode(3, "");
        OIDNode node3 = OIDNode(6, "dod");
        OID oid = new OID(node1, node2, node3);
        assert(oid.dotNotation == "iso.3.dod");

        // Try to create an OID greater than 64 nodes long.
        OIDNode[] nodes = [];
        for (int i = 0; i < 70; i++)
        {
            nodes ~= OIDNode(7, "fail");
        }
        assertThrown!OIDLengthException
            (enforce!OIDLengthException(new OID(nodes)));
    }

    /**
        Returns: The descriptor at the specified index.
    */
    public string descriptor(T)(T index)
        if (isIntegral!T)
    {
        return this.oidNodes[index].descriptor;
    }

    ///
    unittest
    {
        OID oid = new OID([1, 3, 6]);
        oid.descriptor(0, "iso");
        oid.descriptor(1, "");
        oid.descriptor(2, "dod");
        assert(oid.descriptor(0) == "iso");
        assert(oid.descriptor(1) == "");
        assert(oid.descriptor(2) == "dod");
    }

    /**
        Supplies a node descriptor for a node at a specified index in the OID
        Params:
            index = an integer specifying an index of the node you wish to change
            descriptor = the actual text that you want associated with a node.
                This must be composed of only
                $(LINK2 https://en.wikipedia.org/wiki/Graphic_character, Graphic Characters).
        Throws:
            RangeError if the node addressed is non-existent or negative.
            OIDDescriptorException if the descriptor is too long or non graphical.
    */
    public void descriptor(T)(T index, string descriptor)
        if (isIntegral!T)
    {
        //REVIEW: Is there any advantage to catching / throwing RangeErrors here?
        //REVIEW: Should index be a ubyte?
        this.oidNodes[index].descriptor = descriptor;
    }

    ///
    unittest
    {
        OID oid = new OID([1, 3, 6]);
        oid.descriptor(0, "iso");
        oid.descriptor(1, "");
        oid.descriptor(2, "dod");
        assert(oid.dotNotation() == "iso.3.dod");
    }

    /**
        Returns: an array of all descriptors in order
    */
    public string[] descriptors()
    {
        string[] ret;
        foreach(node; this.oidNodes)
        {
            ret ~= node.descriptor;
        }
        return ret;
    }

    ///
    unittest
    {
        OID oid = new OID([1, 3, 6]);
        oid.descriptor(0, "iso");
        oid.descriptor(1, "");
        oid.descriptor(2, "dod");
        assert(oid.descriptors() == [ "iso", "", "dod"]);
    }

    /**
        Supplies multiple descriptors for nodes in the OID
        Params:
            descriptors = descriptors for each node in order
        Throws:
            RangeError if the node addressed is non-existent or negative.
            OIDLengthException if the number of descriptors is more than 64.
            OIDDescriptorException if the descriptor is too long or non-graphical.
    */
    public void descriptors(string[] descriptors ...)
    {
        enforce!OIDLengthException(descriptors.length <= 64, "Too many descriptors.");
        enforce!OIDLengthException(descriptors.length <= oidNodes.length, "Too many descriptors.");
        for (int i = 0; i < descriptors.length; i++)
        {
            this.oidNodes[i].descriptor = descriptors[i];
        }
    }

    ///
    unittest
    {
        OID oid = new OID([1, 3, 6, 1]);
        oid.descriptors("iso", "", "dod", "internet");
        assert(oid.descriptors() == [ "iso", "", "dod", "internet" ]);
    }

    /**
        Returns:
            an array of ulongs representing the dot-delimited sequence of
            integers that constitute the numeric OID
    */
    @property public ulong[] numericArray()
    {
        ulong[] ret;
        foreach(node; this.oidNodes)
        {
            ret ~= node.number;
        }
        return ret;
    }

    ///
    unittest
    {
        OID oid = new OID([1, 3, 6, 1]);
        assert(oid.numericArray == [ 1L, 3L, 6L, 1L]);
    }

    /**
        Returns: the OID in ASN.1 Notation
    */
    @property public string asn1Notation()
    {
        string ret = "{";
        foreach(node; this.oidNodes)
        {
            if (node.descriptor != "")
            {
                ret ~= (node.descriptor ~ '(' ~ text(node.number) ~ ") ");
            }
            else
            {
                ret ~= (text(node.number) ~ ' ');
            }
        }
        return (ret[0 .. $-1] ~ '}');
    }

    ///
    unittest
    {
        OID oid = new OID([1, 22, 333, 4444, 55555]);
        oid.descriptor(2, "boop");
        assert(oid.asn1Notation == "{1 22 boop(333) 4444 55555}");
    }

    /**
        Returns:
            the OID as a dot-delimited string, where all nodes with descriptors
            are represented as descriptors instead of numbers
    */
    @property public string dotNotation()
    {
        string ret;
        foreach (node; this.oidNodes)
        {
            if (node.descriptor != "")
            {
                ret ~= node.descriptor;
            }
            else
            {
                ret ~= text(node.number);
            }
            ret ~= '.';
        }
        return ret[0 .. $-1];
    }

    ///
    unittest
    {
        OID oid = new OID([1, 22, 333, 4444, 55555]);
        oid.descriptor(2, "boop");
        assert(oid.dotNotation == "1.22.boop.4444.55555");
    }

    /**
        Returns:
            the OID as a forward-slash-delimited string (as one might expect in
            a URI / IRI path), where all nodes with descriptors are represented
            as descriptors instead of numbers
    */
    @property public string iriNotation()
    {
        import std.uri;
        string ret = "/";
        foreach (node; this.oidNodes)
        {
            if (node.descriptor != "")
            {
                ret ~= (encodeComponent(node.descriptor) ~ '/');
            }
            else
            {
                ret ~= (text(node.number) ~ '/');
            }
        }
        return ret[0 .. $-1];
    }

    ///
    unittest
    {
        OID oid = new OID([1, 22, 333, 4444, 55555]);
        oid.descriptor(2, "boop");
        assert(oid.iriNotation == "/1/22/boop/4444/55555");
    }

    /**
        Returns:
            the OID as a URN, where all nodes of the OID are translated to a
            segment in the URN path, and where all nodes are represented as
            numbers regardless of whether or not they have a descriptor
        See_Also:
            $(LINK2 https://www.ietf.org/rfc/rfc3061.txt, RFC 3061)
    */
    @property public string urnNotation()
    {
        string ret = "urn:oid:";
        foreach (node; this.oidNodes)
        {
            ret ~= (text(node.number) ~ ':');
        }
        return ret[0 .. $-1];
    }

    ///
    unittest
    {
        OID oid = new OID([1, 22, 333, 4444, 55555]);
        oid.descriptor(2, "boop"); // This does not affect the URN.
        assert(oid.urnNotation == "urn:oid:1:22:333:4444:55555");
    }

    /**
        Returns: the number of nodes in the OID.
    */
    @property public int length()
    {
        //REVIEW: I don't quite know why this is returning a ulong...
        return cast(int) oidNodes.length;
    }

    invariant
    {
        assert(this.oidNodes.length > 0, "OID length is zero!");
    }

}

//This test is meant to exceed the 65536-character limit on OID descriptors.
unittest
{
    string reallyLongString;
    for (int i = 0; i < 7000; i++)
    {
        reallyLongString ~= "abcdefghij";
    }
    OID oid = new OID([1, 22, 333, 4444, 55555]);
    assertThrown!OIDDescriptorException(oid.descriptor(2, reallyLongString));
}
