/**
 ** pif_LongInt
 **   Version: b1.1.20170724
 **   Release Date: July 24, 2017
 **
 ***************************************************************************************************
 ***************************************************************************************************

pif_LongInt is a library that implements both signed and unsigned double, triple, and quadruple
precision (32-bit, 48-bit, and 64-bit) integers. In this beta version, only 32-bit signed and
unsigned integers are currently available in the beta.

 +------------------------+
 |                        |
 |  Contents              |
 |  1. License            |
 |  2. GitHub Repository  |
 |  3. Release Notes      |
 |  4. To Do/Plans        |
 |                        |
 +------------------------+

  1. License
  ----------------------------------------------------

  The code for pif_LongInt is released under the MIT License. Refer to "+License.dm" for the full
  text of the license.

  2. GitHub Repository
  ----------------------------------------------------

  The GibHub reposity for this library is available at the following URL. Feel free to fork the
  repository at any time!

    https://github.com/popisfizzy/pif_LongInt

  3. Release Notes
  ----------------------------------------------------

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

  4. To Do/Plans
  ----------------------------------------------------

  - Write up complete documentation for the library.
  - Implement classes for both signed and unsigned triple and quadruple-precision integers.
  - Set up a preprocessor flag that toggles allowing negative remainders or having only positive
    remainders. Currently, negative remainders are allowed to appear.

****************************************************************************************************
****************************************************************************************************/
