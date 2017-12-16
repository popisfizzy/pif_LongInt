/**
 ** pif_LongInt
 **   Version: b1.1.2.201712??
 **   Release Date: December ??, 2017
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
  (though which power depends on how larger the number is. This can lead to strange things, such as
  Dream Seeker telling you that 16,777,216.

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
  are on it, and the more memory is being used up. If you don't expect your numberse to reach the
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
  2**(n-1) - 1] and signed [0, 2**n - 1].

  3.4. Using pif_LongInt integers
  ------------------------------------------

  Thanks to the introduction of operator overloading in BYOND v512, you can now use pif_LongInt
  objects in a largely-"transparent" way. That is, you can use the built-in operators without much
  concern for the fact that these are objects. There are three exceptions to this:

    (1) As these are objects, they must be created and initialized.

            var/pif_LongInt
                Unsigned32/U = new(50) // U is created with a value of 50.
                Signed32/S   = new(-5) // S is created with a value of -5.

    (2) Assigning a new value to an existing pif_LongInt object must be done using the Set() method,
        rather than the assignment operation.

            U.Set(500) // 500 is now stored in U.
            S.Set(28)  // 28 is now stored in S.

        Using the assignment operator will result in that value being stored in the variable, rather
        than in the object.

    (3) To display the value of the object, one must use the Print() method.

            world << (U*S).Print() // This will output "14000".

  3.4.1. pif_LongInt operators
  -------------------------------------


/****************************************************************************************************/

  4. Release Notes
  ----------------------------------------------------

  Version b1.1.2.201712?? [unreleased]

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
  - Implement classes for both signed and unsigned 48-bit and 64-bit integers..
  - Set up a preprocessor flag that toggles allowing negative remainders or having only positive
    remainders. Currently, negative remainders are allowed to appear.
  - Set up a flag that disables overflow/underflow checking entirely, avoiding the processor cycles
    that are currently dedicated to at least determining if the flag is on.

****************************************************************************************************
****************************************************************************************************/
