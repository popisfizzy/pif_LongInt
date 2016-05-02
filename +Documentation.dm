/**
 ** pif_LongInt
 **   Version: b1.1.20160502
 **   Release Date: May 2, 2016
 **
 ***************************************************************************************************
 ***************************************************************************************************

pif_LongInt is a library that implements both signed and unsigned double, triple, and quadruple
precision (32-bit, 48-bit, and 64-bit) integers. In this beta version, only 32-bit signed and
unsigned double precision integers are available.

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
  - Fully-implemented the SignedDouble class.
  - Implement classes for both signed and unsigned triple and quadruple-precision integers.
  - Set up a preprocessor flag that toggles allowing negative remainders or having only positive
    remainders. Currently, negative remainders are allowed to appear.

****************************************************************************************************
****************************************************************************************************/
