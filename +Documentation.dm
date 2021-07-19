/**
 ** pif_LongInt
 **   Version: b1.2.3.20210718
 **   Release Date: July 18, 2021
 **
 ***************************************************************************************************
 ***************************************************************************************************

pif_LongInt is a library that implements signed and unsigned double, triple, and quadruple precision
(32-bit, 48-bit, and 64-bit) integers. In this beta version, only 32-bit signed and unsigned
integers are available.

 +----------------------------------------+
 |                                        |
 |  Contents                              |
 |  1. License                            |
 |  2. GitHub Repository                  |
 |  3. Introduction & Overview            |
 |    3.1. Signed vs. Unsigned?           |
 |    3.2. 32-bit vs. 48-bit vs. 64-bit?  |
 |    3.3. Numerical range of data types  |
 |    3.4. Using pif_LongInt integers     |
 |        3.4.1. pif_LongInt operators    |
 |  4. Release Notes                      |
 |  5. To Do/Plans                        |
 |                                        |
 +----------------------------------------+

  1. License
  ----------------------------------------------------

  The code for pif_LongInt is released under the MIT License. Refer to "+License.dm" for the full
  text of the license.

  2. GitHub Repository
  ----------------------------------------------------

  The GibHub reposity for this library is available at the following URL. Feel free to fork the
  repository at any time!

    https://github.com/popisfizzy/pif_LongInt

  3. Introduction & Overview
  ----------------------------------------------------

  While helpful in most situations, BYOND's native single precision floating point numbers have
  downsides in certain applications. This most often occurs when one needs perfectly precise
  integers: while floating point numbers have a larger *range*, they lose precision; if you have an
  integer larger than 16,777,216 or smaller than -16,777,216, they will be rounded to a power of 2
  (though which power depends on how larger the number is). This can lead to strange things, such as
  Dream Seeker telling you that 16,777,216 + 1 = 16,777,216..

  This library provides an alternative, fixed-precision integers of a larger range than BYOND can
  handle natively. It also does this entirely in native DM code, without having to do any calls to
  external DLLs, and does this quite fast (at least for BYOND's standards). It includes 32-bit, 48-
  bit, and 64-bit integers, both signed and unsigned. In this beta, only 32-bit integers are available
  for use, with 48- and 64-bit planned.

  3.1. Signed vs. Unsigned?
  ------------------------------------------

  Integers in this library (and in most data types in other languages) distinguish between signed and
  unsigned integers. This breaks down as: unsigned integers store no information about being positive
  or negative (one can sort of think of them as always being "positive"), while signed integers do.
  Unsigned integers have an extra free bit of space, and so can store larger "positive" numbers at the
  expense of not having negative numbers.

  Because it often happens in practice that we're working with non-negative integers, this is
  frequently useful.

  3.2. 32-bit vs. 48-bit vs. 64-bit?
  ------------------------------------------

  This refers to how much space is taken up in memory, at least approximately. This gets complicated
  due to how BYOND stores variables and the information about the object itself, but the basic idea
  is that each BYOND float has (due to how floats are converted internally to integers) sixteen bits
  to store information on. Thus, 32-bit integers use two floats, 48-bit integers use three floats, and
  64-bit integers use four floats.

  A larger number of bits is not inherently better. The larger the number, the slower the operations
  are on it, and the more memory is being used up. If you don't expect your numbers to reach the
  range given by an integer of a specific size (see section 3.3. below), it's probably better to use a
  smaller integer.

  3.3. Numerical range of data types
  ------------------------------------------

  The following table specifies the upper and lower bounds of each integer, by its bits and whether it
  is signed or unsigned. It's a useful point of reference when determing what type of integer you may
  which to use.

    Bits |                    Signed Range                         |          Unsigned Range         |
    -----+---------------------------------------------------------+---------------------------------+
      32 |                         -2,147,483,648 to 2,147,483,647 |              0 to 4,294,967,295 |
    -----+---------------------------------------------------------+---------------------------------+
      48 |             -140,737,488,355,328 to 140,737,488,355,327 |        0 to 281,474,976,710,655 |
    -----+---------------------------------------------------------+---------------------------------+
      64 | -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807 | 0 to 18,446,744,073,709,551,615 |
    -----+---------------------------------------------------------+---------------------------------+

  The general pattern is that for an n-bit integer, signed integers have the range [-2**(n-1),
  2**(n-1) - 1] and unsigned integers have the range [0, 2**n - 1].

  3.4. Using pif_LongInt integers
  ------------------------------------------

  Thanks to the introduction of operator overloading in BYOND v512, you can now use pif_LongInt
  objects in a largely-"transparent" way. That is, you can use the built-in operators without much
  concern for the fact that these are objects. There are two exceptions to this:

    (1) As these are objects, they must be created and initialized.

            var/pif_LongInt
                Unsigned32/U = new(50) // U is created with a value of 50.
                Signed32/S   = new(-5) // S is created with a value of -5.

    (2) To display the value of the object, one must use the Print() method.

            world << (U*S).Print() // This will output "14000".

  3.4.1. pif_LongInt operators
  -------------------------------------

  The overloaded operators in pif_LongInt operate generally how one would expect with the floating
  point numbers native to DM, with a few caveats. For example, these numbers will work correctly with
  BYOND's built in numbers, but only if they're integers. If they're non-integers, then the operation
  will fail:

      U += 50  // Adds 50 to U.
      U += 2.5 // Throws an exception, as 2.5 is not an integer and so the result is not an integer.

  pif_LongInt objects will also accept several other types of operands in addition to integers. For a
  full list, please refer to "pif_Arithmetic Protocol.dm" for more information on the General
  Arithmetic Argument Formats (GAAF). For the average user, the two most important types of operands/
  arguments for these operators are:

    (1) Integers. These can be any integers, but to assure accuracy one should make sure they are
        between -16,777,216 and 16,777,216 inclusive.

            S *= 50
            U = S - 16000000

    (2) Strings. Though there are a number of string formats accepted, the one that is of most use to
        the general programmer is a decimal string. That is, a string consisting only of the numbers
        0 through 9, with an optional negative sign at the front.

            S *= "-123"
            U = (S - "-100") * "50"

  It is important to note that pif_LongInt distinguishes the behavior of assignment operators with
  the behavior of non-assignment operators (with two exceptions). Assignment operators will directly
  change the value of the left hand-side argument, while non-assignment operators will generate an
  entirely new object:

      var/pif_LongInt/Unsigned32/Int = new(500)

      world << Int.Print()        // "500"
      Int += 100
      world << Int.Print()        // "600"

      world << (Int + 50).Print() // "650"
      world << Int.Print()        // "600"

  Refer to the table below for complete details about the operators.

                            ARITHMETIC OPERATORS

    Name                  | Operator | Modifying | Behavior
    ----------------------+----------+-----------+---------------------------------------------------
    Addition              |    +     |    No     | Adds the operands together, producing a new object
    ----------------------+----------+-----------+---------------------------------------------------
    Addition (assignment) |    +=    |   Yes     | Adds the operand on the right to the left, storing
                          |          |           | the value on the operand on the left.
    ----------------------+----------+-----------+---------------------------------------------------
    Subtraction           |    -     |    No     | Subtracts the operand on the right from the
                          |          |           | operand on the left, producing a new object.
    ----------------------+----------+-----------+---------------------------------------------------
    Subtraction           |          |           | Subtracts the operand on the right from the
       (assignment)       |    -=    |   Yes     | operand on the left, storing the value on the
                          |          |           | operand on the left.
    ----------------------+----------+-----------+---------------------------------------------------
                          |          |           | Computes the negative of the operand. Returning a
    Negation              |    -     |    No     | new object with that value. For unsigned integers,
                          |          |           | this will be a copy of the original object.
    ----------------------+----------+-----------+---------------------------------------------------
    Multiplication        |    *     |    No     | Multiplies the operands, producing a new object.
    ----------------------+----------+-----------+---------------------------------------------------
    Multiplication        |    *=    |   Yes     | Multiplies the operands, storing the value on the
       (assignment)       |          |           | operand on the left.
    ----------------------+----------+-----------+---------------------------------------------------
                          |          |           | Divides the operand on the left by the operand on
    Integer Division      |    /     |    No     | the right, producing a new object. Note that this
                          |          |           | is integer division,  which is equivalent to
                          |          |           | rounding down the final result.
    ----------------------+----------+-----------+---------------------------------------------------
                          |          |           | Divides the operand on hte left by the operand on
    Inteder Division      |    /=    |   Yes     | the right, storing the value on the operand on the
       (assignment)       |          |           | left. Note that this is integer division, which is
                          |          |           | equivalent to rounding down the final result.
    ----------------------+----------+-----------+---------------------------------------------------
                          |          |           | Computes the remainder of division when dividing
    Modulus               |    %     |    No     | the operand on the left by the operand on the
                          |          |           | right, producing a new object.
    ----------------------+----------+-----------+---------------------------------------------------
                          |          |           | Computes the remainder of division when dividing
    Modulus               |    %=    |   Yes     | the operand on the left by the operand on the
       (assignment)       |          |           | right, then stores the result on the operand on
                          |          |           | left.
    ----------------------+----------+-----------+---------------------------------------------------
    Increment             |    ++    |   Yes     | Adds one to the operand, storing the new value in
                          |          |           | the operand.
    ----------------------+----------+-----------+---------------------------------------------------
    Decrement             |    --    |   Yes     | Subtracts one from the operand, storing the new
                          |          |           | value in the operand.
    ----------------------+----------+-----------+---------------------------------------------------
    Exponentiation        |    **    |   No      | Takes the operand on the left to the power of the
                          |          |           | operand on the right, producing a new object.
    ----------------------+----------+-----------+---------------------------------------------------

                              BITWISE OPERATORS

    Name                  | Operator | Modifying | Behavior
    ----------------------+----------+-----------+---------------------------------------------------
    Bitwise Not           |    ~     |    No     | Computes the bitwise not of the operand, producing
                          |          |           | a new object.
    ----------------------+----------+-----------+---------------------------------------------------
    Bitwise And           |    &     |    No     | Computes the bitwise and of the operands,
                          |          |           | producing a new object.
    ----------------------+----------+-----------+---------------------------------------------------
    Bitwise And           |    &=    |   Yes     | Computes the bitwise and of the operands, storing
       (assignment)       |          |           | the result on the left operand.
    ----------------------+----------+-----------+---------------------------------------------------
    Bitwise Or            |    |     |    No     | Computes the bitwise or of the operands, producing
                          |          |           | a new object.
    ----------------------+----------+-----------+---------------------------------------------------
    Bitwise Or            |    |=    |   Yes     | Computes the bitwise or of the operands, storing
       (assignment)       |          |           | the result on the left operand.
    ----------------------+----------+-----------+---------------------------------------------------
    Bitwise Xor           |    ^     |    No     | Computes the bitwise xor of the operands,
                          |          |           | producing a new object.
    ----------------------+----------+-----------+---------------------------------------------------
    Bitwise Xor           |    ^=    |   Yes     | Computes the bitwise xor of the operands, storing
       (assignment)       |          |           | the result on the left operand.
    ----------------------+----------+-----------+---------------------------------------------------
    Bitshift Left         |   <<     |    No     | Computes the bitshift left of the operands,
                          |          |           | producing a new object.
    ----------------------+----------+-----------+---------------------------------------------------
    Bitshift Left         |   <<=    |   Yes     | Computes the bitshift left of the operands,
       (assignment)       |          |           | storing the result in the left operand.
    ----------------------+----------+-----------+---------------------------------------------------
    Bitshift Right        |   >>     |    No     | Computes the bitshift right of the operands,
                          |          |           | producing a new object.
    ----------------------+----------+-----------+---------------------------------------------------
    Bitshift Right        |   >>=    |   Yes     | Computes the bitshift right of the operands,
       (assignment)       |          |           | storing the result in the left operand.
    ----------------------+----------+-----------+---------------------------------------------------

                           COMPARISON OPERATORS

    Name                  | Operator | Behavior
    ----------------------+----------+---------------------------------------------------------------
    Equivalent            |    ~=    | Returns true if the left and right hand sides have the same
                          |          | value, and false otherwise.
    ----------------------+----------+---------------------------------------------------------------
    Not Equivalent        |    ~!    | Returns false if the left and right hand sides have the same
                          |          | value, and false otherwise.
    ----------------------+----------+---------------------------------------------------------------
    Greater Than          |    >     | Returns true if the left hand side is greater than the right
                          |          | hand side, and false otherwise.
    ----------------------+----------+---------------------------------------------------------------
    Greater Than Or Equal |    >=    | Returns true if the left hand side is greater than or is equal
       To                 |          | to the right hand side, and false otherwise.
    ----------------------+----------+---------------------------------------------------------------
    Less Than             |    <     | Returns true if the left hand side is less than the right hand
                          |          | side, and false otherwise.
    ----------------------+----------+---------------------------------------------------------------
    Less Than Or Equal To |    <=    | Returns true if hte left hand side is less than or is equal to
                          |          | the right hand side, and false otherwise.
    ----------------------+----------+---------------------------------------------------------------

                           ASSIGNMENT OPERATORS

    Name                  | Operator | Behavior
    ----------------------+----------+---------------------------------------------------------------
    Assignment            |    :=    | Assigns the value on the right hand side of the operator to
                          |          | the LongInt object. This will accept any value that is in one
                          |          | of the General Arithmetic Argument Formats found in
                          |          | 'pif_Arithmetic protocol.dm'
    ----------------------+----------+---------------------------------------------------------------

  4. Release Notes
  ----------------------------------------------------

  Version b1.2.3.20210718

    - Due to a typo and a missing return value for an overloaded operator, comparison operators would
      sometimes report incorrect results. (Multiverse7)
    - Implemented the := operator, introduced in v514. This allows the library to be used more
      transparently, because now a method does not need to be (explicitly) used to assign data into
      a LongInt object.
    - Updated the documentation to address the := operator.

  Version b1.2.2.20171227

    - Fixed a bug that would result in empty arguments (except in constructors) would result in a
      runtime error.
    - Fixed a bug in the operator-() method on the Signed32 class that would fail to return the
      proper result when doing negation (that is, when the operator-() method had no arguments).
    - Changed the behavior of right bitshifting methods (BitshiftRight(), operator>>(), and
      operator>>=()) on the Signed32 class. Previously, the most significant bits were filled with
      0's, while common behavior is to fill them with 1's if the number is negative so as to keep
      right bitshifts the same as integer division by two. The BitshiftRightRotate() method is not
      affected by this change.
    - Implemented FindFirstSet(), FindLastSet(), CountLeadingZeros(), and CountTrailingZeros() on
      both Signed32 and Unsigned32.
    - A minor note about the version number: Based on my numbering scheme, the last update should
      probably have been b1.2.1.20171217, so I'm skipping over this version number and jumping to
      the correct order. To be honest, b1.1.0.20170724 should probably have been b1.2.0.20170724
      too, but oh well...

  Version b1.1.2.20171217

    - The library now supports the newly-implemented overloaded operators feature. This means that
      the integer classes can be used much more like BYOND's built in numeric types, without having
      to make explicit method calls. This change requires at least BYOND v512 to work.
    - Made the library compliant with the PIF_NOPREFIX_GENERAL preprocessor flag that's universal in
      my libraries, and added a specific PIF_NOPREFIX_LONGINT flag.
    - Added the ToFloat() method, which allows one to convert from a pif_LongInt object to BYOND's
      floating point number representation.
    - Added an "Introduction & Overview" section, which gives a brief description of how to use this
      library.

  Version b1.1.1.20170806

    - Fixed a bug where calling the constructor with the single argument of null would cause the
      value of the object to be set to 65536 instead of 0. This was caused by a typo where I wrote a
      1 in the code instead of a 0. Small errors in code...

      Thanks goes to Reformist for both finding this error and what was causing it.

  Version b1.1.0.20170724

    - Renamed UnsignedDouble and SignedDouble to Unsigned32 and Signed32. This makes it clearer, in
      my opinion, what their precision is and this convention will be followed for all future
      classes.
    - "Emancipated" the Signed32 class from Unsigned32. That is, Signed32 was rewritten so that it
      was not a child of Unsigned32, and instead inherits directly from the pif_LongInt class. The
      approach of making Signed32 a child of Unsigned32 seemed a good idea originally, but in
      retrospect it is not as useful as it once seemed due to a realization I had regarding handling
      overflow exceptions. Furthermore, a Signed32 can not replace an Unsigned32 in a method and
      keep the same functionality, due to their significantly-different range and so it is also poor
      design. Doing it as a sister class of Unsigned32 involves copying more code, but it's a better
      way of doing it in the long run.
    - Fixed the joke /Signed32.PrintUnary() method so that it works correctly for negative
      numbers.
    - Fixed an bug with the Signed32 class that would result in it throwing an overflow
      exception in the cases when UnsignedDouble would have an overflow, even though the situations
      where signed and unsigned doubles overflow are very different.

  Version b1.1.20160502.

    - Fixed several errors in computing remainders and quotients in division in the UnsignedDouble
      class.
    - Added more documentation to functions.
    - Made additions and modifications to the pif_Arithmetic protocol. Refer to "pif_Arithmetic
      Protocol.dm" to see these changes.
    - Made rewrites to /UnsignedDouble.Remainder() and /UnsignedDouble.Divide(), significantly
      increasing their speeed. These modifications will "bubble" through to all other classes
      in the library, so the rewrite is highly-significant.
    - Implemented the SignedDouble class.
    - Fixed an oversight in Quotient() and Divide() that could sometimes result in the second block
      of a SignedDouble or UnsignedDouble from being overwritten when the object was not in
      NEW_OBJECT mode.

  Version b1.0.20160409.

    - Initial beta release.
    - Implemented pif_Arithmetic protocol, which will be adapated to the pif_BigInt library and
      released publicly as a separate library when pif_BigInt goes public.
    - Implemented UnignedDouble class, which is an unsigned double-precision (32-bit) integer
      class.

  5. To Do/Plans
  ----------------------------------------------------

  - Write up complete documentation for the library.
  - Implement classes for both signed and unsigned 48-bit and 64-bit integers.
  - Set up a preprocessor flag that toggles allowing negative remainders or having only positive
    remainders. Currently, negative remainders are allowed to appear.
  - Set up a flag that disables overflow/underflow checking entirely, avoiding the processor cycles
    that are currently dedicated to at least determining if the flag is on.

****************************************************************************************************
****************************************************************************************************/
