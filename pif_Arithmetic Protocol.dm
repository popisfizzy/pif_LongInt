// This file defines the pif_Arithmetic protocol, which will be implemented by all of my libraries
// that do extended integer arithmetic (e.g., pif_BigInt, and pif_LongInt). Floating point numbers
// will be a sub-protocol that extends  this one (planned only right now, for pif_LongFloat).

// Classes implementing the pif_Arithmetic protocol for integer operations are expected to implement
// it such that each "block" is encoded in base 65536--that is, each block of the object represents
// two bytes. Typically, protocols do not prescribe internal structure, but this is essentially
// required for objects implementing the pif_Arithmetic protocol in order to make them "play nice".
// This does have the bonus of being a memory-efficient method of operation, though.

/**
 ** pif_Arithmetic
 **   Version: b1.1.20160502
 **   Release Date: May 5, 2016
 **
 ***************************************************************************************************
 ***************************************************************************************************

 +--------------------+
 |                    |
 |  Contents          |
 |  1. License        |
 |  2. Release Notes  |
 |  3. To Do/Plans    |
 |                    |
 +--------------------+

  1. License
  ----------------------------------------------------

  The code for pif_Arithmetic is released under the MIT License. Refer to "+License.dm" for the full
  text of the license.

  2. Release Notes
  ----------------------------------------------------

  Version b1.1.20160502.

    - Added Release Notes and To Do sections to pif_Arithmetic.
    - Added FirstFirstSet() and FindLastSet() methods.
    - Changed Highest() and Lowest() to Maximum() and Minumum(), respectively.
    - Clarified the behavior of the PrintBinary(), PrintDecimal(), and PrintHexadecimal() methods.
    - Added notes about the relationship between Quotient() and Remainder().
    - Added note about the legal output values of Remainder().
    - Added a note about restrictions on the output of Divide().
    - Added notes on how the comparison methods should handle incoming data when it is "distinct"
      from the source object. Refer to those methods for details.
    - Added a note on the behavior of Negate() for signed integer objects, and more specifically for
      the largest negative number representable for a fixed-width signed integer.
    - Added the Zero() "static" method.
    - Added a /pif_Arithmetic/ProtocolNonConformingObjectException exception as well as a note on
      where to use it in the GAAF format.
    - Added a /pif_Arithmetic/NonNumericInvalidPositionException exception as well as a note on
      where to use it in the GAAF format.
    - Updated the GAAF format to provide more details on how a list of integers should be
      interpreted, and especially a list of one integer.

  Version b1.0.20160409.

    - Initial beta release.

  3. To Do/Plans
  ----------------------------------------------------

    - Add /pif_Arithmetic/DivisionByZeroException exception and documentation.
    - Add /pif_Arithmetic/ZeroToZerothPowerException exception and documentation.
    - Give this a separate hub entry upon a full release on pif_LongInt or a full release of
      pif_BigInt, whichever seems most appropriate.

****************************************************************************************************
****************************************************************************************************/

#ifndef PIF_ARITHMETIC_INCLUDED
#define	PIF_ARITHMETIC_INCLUDED

#if	!defined(PIF_NOPREFIX_GENERAL) && !defined(PIF_NOPREFIX_ARITHMETIC)
pif_Arithmetic
#else
Arithmetic
#endif

	var
		const

			// These define the variable operation modes. They can change at runtime,
			// but can be fixed by the implementation.

			NEW_OBJECT			=	1 // In NEW_OBJECT mode, a new object is
									  // output for each arithmetic operation.
			OLD_OBJECT			=	0 // In OLD_OBJECT mode, the old object is
									  // changed in place. This is the default
									  // mode.

			OVERFLOW_EXCEPTION	=	2 // In OVERFLOW_EXCEPTION mode, an exception will
									  // be thrown when a fixed-width integer becomes
									  // too large to store, resulting in overflow. This
									  // is the /pif_Arithmetic/OverflowException exception.
			NO_OVERFLOW_EXCEPTION = 0

			// These define the fixed operation modes. These modes are presumed to be
			// fixed for a class and will not change in any way at run time.

			FIXED_PRECISION		=	4 // In FIXED_PRECISION mode, the object can not
									  // expand to fill more space. FIXED_PRECISION
									  // mode objects may overflow.
			ARBITRARY_PRECISION	=	0

			SIGNED_MODE			=	8 // In signed mode, the object will be able to
									  // store positive and negative numbers.
			UNSIGNED_MODE		=	0

/*

The General Arithmetic Argument Formats (GAAF) for the pif_Arithmetic protocol are the allowed
(standard) types of argument formats for many methods specified in the protocol.

They are as follows.

  1.  proc/Method() or proc/Method(null)

           This is a special case that should be interpreted as passing 0.

  2.  proc/Method(datum/pAr_Object)

      i.   pAr_Object is an object that implements the pif_Arithmetic protocol, and data is pulled
           directly from this object. Ways of handling if pAr_object is too large for the source
           object to process are implementation-specific.

           If pAr_Object does not appear to implement the pif_Arithmetic protocol (e.g., by not
           having a necessary method) throw a /pif_Arithmetic/ProtocolNonConformingObjectException
           exception.

  3.  proc/Method(list/List)

      i.   List is a /list object that is interpreted as left-significant. That is, the left-most
           entry ("block") of the list (the entry with the lowest index) is interpreted as the
           most-significant element of that list, while the right-most block (the entry with the
           highest index) is interpreted as the least-significant element of that list. This is so
           that something of the form

             Method(0x6789, 0xABCD)

           is interpreted as the number 0x6789ABCD, which is intuitive. If the list were interpreted
           as right-significant, this would instead be the number 0xABCD6789.

           All elements of the list should be integers. If a non-integer is found in the list, then
           a /pif_Arithmetic/NonIntegerException exception should be thrown. If a non-numeric value
		   is found then a /pif_Arithmetic/NonNumericInvalidPositionException exception should be
		   thrown.

           If a list contains only one element, then,

             a. If SIGNED_MODE is enabled, integers in the range [-16777215, 16777215] must be
                supported.
             b. If SIGNED_MODE is not enabled, then integers in the range [0, 16777215] must be
                supported. If a negative value is found, then either it should be treated as a raw
                bitstring or a /pif_Arithmetic/NegativeInvalidPositionException exception should be
                thrown.

           Interpretation of integers with an absolute value larger than 16777215 is undefined and
           left to the implementation.

           If the list contains more than one element, then the resulting data should be treated as
           raw binary data by performing bitwise AND with the data and the value 0xFFFF. There
		   should be no regard for sign data or floating point values.

  4.  proc/Method(String)

      i.   String is a string with the following requirement.

           a. If unprefixed (e.g., "12345") the string is interpreted as a base ten (decimal) number
              using the characters in the set {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}
              with their standard decimal interpretation. If a character other than these is found,
              then a /pif_Arithmetic/InvalidStringEncodingException exception is thrown.

           b. If previxed with "0x" (e.g., "0x1234") the string is interpreted as a base sixteen
              (hexadecimal) number using the characters in the set {"0", "1", "2", "3", "4", "5",
              "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "a", "b", "c", "d", "e", "f"}, using
              their standard hexadecimal interpretation; furthermore, mixed case (i.e., both upper
              and lower case) is allowed. If a character other than these is found beyond the
              prefix, then a /pif_Arithmetic/InvalidStringEncodingException exception is thrown.

           c. If prefixed with "0b" (e.g., "0b1010") the string is interpreted as a base two
              (binary) number using the characters in teh set {"0", "1"} using their standard binary
              interpretation. If a character other than these is found beyond the prefix, then a
              /pif_Arithmetic/InvalidStringEncodingException exception is thrown.

           To indicate a negative number, a negative sign appears before the prefix for binary and
           hexadecmal number (e.g., "-0b1010" or "-0x1234") and as usual for decimal numbers (e.g.,
           "-150"). If a negative sign is found in a number with SIGNED_MODE disabled, then a
           /pif_Arithmetic/NegativeInvalidPositionException exception is thrown.

           If an invalid prefix specifically is found, then a /pif_Arithmetic/InvalidStringPrefixException
           exception is thrown. If String is a zero-length string (i.e., "") then a
           /pif_Arithmetic/InvalidStringArgumentException exception is thrown.

  5.  proc/Method(String, Base, EncodingRef)

      i.   String is an arbitrary string. If this is argument is not a string or is a zero-length
           string (i.e., "") then a /pif_Arithmetic/InvalidStringArgumentException exception is
           thrown.

      ii.  Base is a positive integer indicating the base the string. If Base does not satisfy these
           requirements (e.g. Base is a non-integer, or is zero or negative) then a /pif_Arithmetic/InvalidStringBaseException
           exception is thrown.

      iii. EncodingRef is a proc typepath (e.g., /proc/MyEncodingProc) that accepts a single
           character from the string and outputs a positive integer that indicates the value of that
           character. If the returned value is not a positive integer, a /pif_Arithmetic/InvalidStringEncodingValueException
           exception is thrown. If EncodingRef accepts an invalid character, a /pif_Arithmetic/InvalidStringEncodingException
           exception is thrown by the EncodingRef proc.

  6.  proc/Method(String, Base, datum/EncodingObj, EncodingRef)

      i.   String is an arbitrary string. If this is argument is not a string or is a zero-length
           string (i.e., "") then a /pif_Arithmetic/InvalidStringArgumentException exception is
		   thrown.

      ii.  Base is a positive integer indicating the base the string. If Base does not satisfy these
           requirements (e.g. Base is a non-integer, or is zero or negative) then a /pif_Arithmetic/InvalidStringBaseException
           exception is thrown.

      iii. EncodingObj is an object that EncodingRef is attached to. If this argument is not an
           object, then a /pif_Arithmetic/InvalidStringEncodingObjException exception is thrown.

      iv.  EncodingRef is a string (e.g., "MyEncodingMethod") that is the name of a method on the
           EncodingObj object. This omethod accepts a single character from the string and outputs a
           positive integer that indicates the value of that character. If the returned value is not
           a positive integer, a /pif_Arithmetic/InvalidStringEncodingValueException exception is
           thrown. If EncodingRef accepts an invalid character, a /pif_Arithmetic/InvalidStringEncodingException
           exception is thrown by the EncodingRef method.

  7.  proc/Method(...)

           A left-significant list of integer arguments. See 3. for details on this format.

If the format provided as the arguments to a GAAF_specified method do not match one of the above
formats (and this can be determined) then a /pif_Arithmetic/InvalidArgumentFormatException exception
should be thrown. In practice, this may be difficult to determine because Format 7. provides a
"catch all" for when others are not matched, and typically the exceptions provided in Format 3.
would be of more use than the /pif_Arithmetic/InvalidArgumentFormatException exception.

*/

	New(...)
		/*

		Initializes an object of the class implementing the pif_Arithmetic protocol.

		  Arguments.

		    Uses the GAAF format.

		  Behavior.

		    Sets the source object equal to the argument data.

		  Returns.

		    The new object.

		*/

	proc
		/*
		 * Arithmetic methods.
		 */

		// Core arithmetic methods.

		Add(...)
			/*

			Computes the result of addition.

			  Arguments.

			    Uses the GAAF argument format.

			  Behavior.

			    Computes the result of adding the source object and the data provided by the
			    argument.

			    If NEW_OBJECT mode is set, then the source object will not be modified and instead a
			    new object of the same type is returned. If OLD_OBJECT mode is set, then the source
			    object will be modified and returned.

			  Returns.

			    An object of the same type as the source object.

			*/

		Subtract(...)
			/*

			Computes the result of subtraction.

			  Arguments.

			    Uses the GAAF argument format.

			  Behavior.

			    Computes the result of subtracting the argument data from the source object.

			    If NEW_OBJECT mode is set, then the source object will not be modified and instead a
			    new object of the same type is returned. If OLD_OBJECT mode is set, then the source
			    object will be modified and returned.

			  Returns.

			    An object of the same type as the source object.

			*/

		Multiply(...)
			/*

			Computes the result of multiplication.

			  Arguments.

			    Uses the GAAF argument format.

			  Behavior.

			    Computes the result of multiplying the source argument by the argument data.

			    If NEW_OBJECT mode is set, then the source object will not be modified and instead a
			    new object of the same type is returned. If OLD_OBJECT mode is set, then the source
			    object will be modified and returned.

			  Returns.

			    An object of the same type as the source object.

			*/

		Quotient(...)
			/*

			Computes the quotient of division.

			  Arguments.

			    Uses the GAAF argument format.

			  Behavior.

			    Computes the quotient that results from dividing the source object by the argument
			    data.

			    If NEW_OBJECT mode is set, then the source object will not be modified and instead a
			    new object of the same type is returned. If OLD_OBJECT mode is set, then the source
			    object will be modified and returned.

			  Returns.

			    An object of the same type as the source object.

			  Note.

			    If A is the dividend (source object) and B is the divisor (argument) then the
				following relationship should always hold between Quotient() and Remainder():

			      B * (A.Quotient(B)) + (A.Remainder(B)) == A.

			*/

		Remainder(...)
			/*

			Computes the remainder of division.

			  Arguments.

			    Uses the GAAF argument format.

			  Behavior.

			    Computes the remainder that results from dividing the source object by the argument
			    data.

			    If NEW_OBJECT mode is set, then the source object will not be modified and instead a
			    new object of the same type is returned. If OLD_OBJECT mode is set, then the source
			    object will be modified and returned.

			  Returns.

			    An object of the same type as the source object.

			  Note.

			    If A is the dividend (source object) and B is the divisor (argument) then the
				following relationship should always hold between Quotient() and Remainder():

			      B * (A.Quotient(B)) + (A.Remainder(B)) == A.

			    Furthermore, Remainder() should have the property that

			      0 <= |A.Remainder(B)| < |B|.

			*/

		Power(N)
			/*

			Computes the source object to the Nth power.

			  Arguments

			    An non-negative integer N. If n is negative, then a /pif_Arithmetic/NegativeIntegerException
			    exception is thrown. If N is a non-integer, then a /pif_Arithmetic/NonIntegerException
			    exception is thrown.

			  Behavior.

			    Computes the result of taking the source object to the Nth power.

		        If NEW_OBJECT mode is set, then the source object will not be modified and instead a
		        new object of the same type is returned. If OLD_OBJECT mode is set, then the source
		        object will be modified and returned.

		      Returns.

		        An object of the same type as the source object.

		      Note.

		        This should have the same behavior as the following code for an object Integer of
				some IntegerClass class that implements the pif_Arithmetic protocol.

		          var/IntegerClass/OriginalInt = new(Integer)
		          for(var/i = 1, i <= N, i ++)
		            Integer = Integer.Multiply(OriginalInt).

		        That is, the same behavior as multiply the source object times itself N times.

			*/

		// Alias methods.

		Mod(...)	// Alias for Remainder()

		// Miscellaneous arithmetic methods.

		Divide(...)
			/*

			Computes the quotient and remainder of division.

			  Arguments.

			    Uses the GAAF argument format.

			  Behavior.

			  	Computes both the quotient and remainder that result from dividing the source object
			  	by the argument data.

			  	If NEW_OBJECT mode is set, then the source object will not be modified and instead a
			  	new objects of the same type as the source object will store both the quotient and
			  	remainder. If OLD_OBJECT mode is set, then the source object will be modified to
			  	store the quotient, and a new object of the same type as the source object will
			  	store the remainder.

			  Returns.

			    A /list object, where the first element stores the quotient and the second stores
			    the remainder. The first element of this list should have the same value as the
			    Quotient() method would output, while the second element of this list should have
			    the same value as the Remainder() method would output.
			*/

		Increment()
			/*

			Increments the source object.

			  Arguments.

			    None.

			  Behavior.

			  	Computes the increment of the source object; that is, the result of adding one to
			  	the source object.

		        If NEW_OBJECT mode is set, then the source object will not be modified and instead a
		        new object of the same type is returned. If OLD_OBJECT mode is set, then the source
		        object will be modified and returned.

		      Returns.

		        An object of the same type as the source object.

		      Note.

		        This should have the same behavior as calling src.Add(1)

			*/

		Decrement()
			/*

			Decrements the source object.

			  Arguments.

			    None.

			  Behavior.

			  	Computes the decrement of the source object; that is, the result of subtracing one
			  	from the source object.

		        If NEW_OBJECT mode is set, then the source object will not be modified and instead a
		        new object of the same type is returned. If OLD_OBJECT mode is set, then the source
		        object will be modified and returned.

		      Returns.

		        An object of the same type as the source object.

		      Note.

		        This should have the same behavior as calling src.Subtract(1).

			*/

		Negate()
			/*

			Negates the source object.

			  Arguments.

			    None.

			  Behavior.

			  	Computes the negative of the source object.

		        If NEW_OBJECT mode is set, then the source object will not be modified and instead a
		        new object of the same type is returned. If OLD_OBJECT mode is set, then the source
		        object will be modified and returned.

		      Returns.

		        An object of the same type as the source object.

		      Note.

		        If SIGNED_MODE is set, then this should have the same behavior as calling
		        src.Multiply(-1). If SIGNED_MODE is not set, its behavior is undefined and
		        implementation-specific.

		        If SIGNED_MODE is set, then the behavior of this method is undefined for the object
		        returned by Minimum(). This is because, in two's complement notation, the largest
		        negative number can not be converted to positive without a loss of precision. Two
		        reasonable behaviors are to return 0 (an object equivalent to that output by the
		        Zero() method) or return an object equal to the original object (an object
				equivalent to that output by the Minimum() method).

			*/

		Square()
			/*

			The square the source object.

			  Arguments.

			    None.

			  Behavior.

			  	Computes the square of the source object.

		        If NEW_OBJECT mode is set, then the source object will not be modified and instead a
		        new object of the same type is returned. If OLD_OBJECT mode is set, then the source
		        object will be modified and returned.

		      Returns.

		        An object of the same type as the source object.

		      Note.

		        This method should have the same behavior as src.Power(2). Consequently, it should
		        also have the same behavior as src.Multiply(src).

			*/

		/*
		 * Bitwise methods.
		 */

		// Bitwise arithmetic methods.

		BitwiseNot()
			/*

			The bitwise not of the source object.

			  Arguments.

			    None.

			  Behavior.

			  	Computes the square of the source object.

		        If NEW_OBJECT mode is set, then the source object will not be modified and instead a
		        new object of the same type is returned. If OLD_OBJECT mode is set, then the source
		        object will be modified and returned.

		      Returns.

		        An object of the same type as the source object.

			*/

		BitwiseAnd(...)
			/*

			The bitwise and of the source object and the argument data.

			  Arguments.

			    Uses the GAAF argument format.

			  Behavior.

			  	Computes the bitwise not of the source object and the data from the argument.

		        If NEW_OBJECT mode is set, then the source object will not be modified and instead a
		        new object of the same type is returned. If OLD_OBJECT mode is set, then the source
		        object will be modified and returned.

		      Returns.

		        An object of the same type as the source object.

			*/

		BitwiseOr(...)
			/*

			The bitwise or of the source object and the argument data.

			  Arguments.

			    Uses the GAAF argument format.

			  Behavior.

			  	Computes the bitwise or of the source object and the data from the argument.

		        If NEW_OBJECT mode is set, then the source object will not be modified and instead a
		        new object of the same type is returned. If OLD_OBJECT mode is set, then the source
		        object will be modified and returned.

		      Returns.

		        An object of the same type as the source object.

			*/

		BitwiseXor(...)
			/*

			The bitwise xor of the source object and the argument data.

			  Arguments.

			    Uses the GAAF argument format.

			  Behavior.

			  	Computes the bitwise xor of the source object and the data from the argument.

		        If NEW_OBJECT mode is set, then the source object will not be modified and instead a
		        new object of the same type is returned. If OLD_OBJECT mode is set, then the source
		        object will be modified and returned.

		      Returns.

		        An object of the same type as the source object.

			*/

		// Bitshifting methods.

		BitshiftLeft(N)
			/*

			The bitshift-no-rotate-left of the source object and the argument data.

			  Arguments.

			    An integer. Negative integers may be allowed depending on the implementation, to
			    indicate a bitshift to the right. If not allowed, then a /pif_Arithmetic/NegativeIntegerException
			    exception is thrown.

			  Behavior.

			  	Computes the bitshift-no-rotate-left of the source data and the provided argument.
			  	Bitshift-no-rotate-left means that bits shifted beyond the most-significant bit are
			  	discarded, and zeros fill in the least-significant bits.

		        If NEW_OBJECT mode is set, then the source object will not be modified and instead a
		        new object of the same type is returned. If OLD_OBJECT mode is set, then the source
		        object will be modified and returned.

		      Returns.

		        An object of the same type as the source object.

			*/

		BitshiftLeftRotate(N)
			/*

			The bitshift-with-rotate-left of the source object and the argument data.

			  Arguments.

			    An integer. Negative integers may be allowed depending on the implementation, to
                indicate a bitshift to the right. If not allowed, then a /pif_Arithmetic/NegativeIntegerException
			    exception is thrown.

			  Behavior.

			  	Computes the bitshift-with-rotate-left of the source data and the provided argument.
                Bitshift-with-rotate-left means that bits that go beyond the most-significant bit
                are "rotated" into the least-signficant bit position and fill in bits there.

		        If NEW_OBJECT mode is set, then the source object will not be modified and instead a
                new object of the same type is returned. If OLD_OBJECT mode is set, then the source
                object will be modified and returned.

		      Returns.

		        An object of the same type as the source object.

			*/

		BitshiftRight(N)
			/*

			The bitshift-no-rotate-right of the source object and the argument data.

			  Arguments.

			    An integer. Negative integers may be allowed depending on the implementation, to
                indicate a bitshift to the right. If not allowed, then a /pif_Arithmetic/NegativeIntegerException
			    exception is thrown.

			  Behavior.

			  	Computes the bitshift-no-rotate-right of the source data and the provided argument.
                Bitshift-no-rotate-right means that bits that go beyond the least-significant bit
                are discarded, and zeros fill in the positions in the most-signifiant bit.

		        If NEW_OBJECT mode is set, then the source object will not be modified and instead a
                new object of the same type is returned. If OLD_OBJECT mode is set, then the source
                object will be modified and returned.

		      Returns.

		        An object of the same type as the source object.

			*/

		BitshiftRightRotate(N)
			/*

			The bitshift-with-rotate-right of the source object and the argument data.

			  Arguments.

			    An integer. Negative integers may be allowed depending on the implementation, to
                indicate a bitshift to the right. If not allowed, then a /pif_Arithmetic/NegativeIntegerException
			    exception is thrown.

			  Behavior.

			  	Computes the bitshift-with-rotate-right of the source data and the provided
                argument. Bitshift-with-rotate-right means that bits that go beyond the least-
                significant bit are "rotated" onto the most-significant bits and fill in teh spaces
                there.

		        If NEW_OBJECT mode is set, then the source object will not be modified and instead a
                new object of the same type is returned. If OLD_OBJECT mode is set, then the source
                object will be modified and returned.

		      Returns.

		        An object of the same type as the source object.

			*/

		// Bitstring methods.

		Bit(P)
			/*

			The value of the bit in the P position.

			  Arguments.

			    An non-negative integer, where 0 refers to the bit in the least-significant
                position. If P is negative, then a /pif_Arithmetic/NegativeIntegerException
                exception is thrown.

			  Behavior.

			  	Outputs the value of the bit in the Pth position.

		      Returns.

		        A DM integer with all zeros except (at most) the least-significant bit.

			*/


		BitString(P, L)
			/*

			A string of length L in the Pth position.

			  Arguments.

			    * P is a non-negative integer, where 0 refers to the the least-significant position.
                  If P is negative, then a /pif_Arithmetic/NegativeIntegerException is thrown.

			    * L is a positive integer which indicates the length of a bitstring to extract,
                  starting at position P. L is at most 16 (because integers are sixteen bit in DM).
                  If L is greater than sixteen, the implementation may either throw a
                  /pif_Arithmetic/InvalidBitstringLengthException exception, or they may set it to
                  sixteen.

			  Behavior.

			  	Outputs a bitstring of length L, starting from position P.

		      Returns.

		        A DM integer.

			*/

		BitObject(P, L)
			/*

			A string of length L in the Pth position.

			  Arguments.

			    * P is a non-negative integer, where 0 refers to the the least-significant position.
                  If P is negative, then a /pif_Arithmetic/NegativeIntegerException is thrown.

			    * L is a positive integer which indicates the length of a bitstring to extract,
                  starting at position P. L is at most src.BitLength() (see below for this method).
                  If L is greater than this, the implementation may either throw a
                  /pif_Arithmetic/InvalidBitstringLengthException exception, or they may set it to
                  src.BitLength().

			  Behavior.

			  	Outputs an object as the same type as the source object, which is a bitstring
                extracted from the source object starting at position P and of length L.

		      Returns.

		        An object as the same type as the source object..

			*/

		// Miscellaneous methods.

		FindFirstSet()
			/*

			Outputs the position of the least-significant non-zero bit.

			  Arguments.

			    None.

			  Behavior.

			    Outputs the position of least-significant non-zero bit. That is, the position of the
                first bit from the right which is not equal to zero. The least-significant bit is
                considered in position zero.

			  Returns.

			    A non-negative integer.

			*/

		FindLastSet()
			/*

			Outputs the position of the most-significant non-zero bit.

			  Arguments.

			    None.

			  Behavior.

			    Outputs the position of the most-significant non-zero bit. Taht is, the position of
			    the first bit from the left which is not equal to zero. The least-significant bit is
			    considered to be in position zero.

			  Returns.

			    A non-negative integer.

			*/

		/*
		 * Comparison methods.
		 */

		// Core comparison methods.

		Compare(...)
			/*

			Compares the source object and the argument data

			  Arguments.

			    Uses the GAAF argument format.

			  Behavior.

			  	Compares the source object and the argument data.

		      Returns.

		        The sign of the difference of the source object and the argument data (though this
                does not have to be how this method is implemented). That is,

		        *  1 is returned if the source object is larger than the argument data.
		        *  0 is returned if the source object is equal to the argument data.
		        * -1 is returned if the source object is less than the argument data.

		      Note.

		        This method is only guaranteed if (1) the input data is at most as long as the class
		        it's being passed to and (2) the input data is of the same "sign behavior" as the
		        class it's being passed to. For example, if the source object is of double-precision
		        unsigned and the input data is single- or double-precision unsigned, then comparison
		        is guaranteed to be accurate. But, comparing to triple-precision unsigned or single-
		        precision signed is not guaranteed to be accurate. Specifically, these cases are
		        considered undefined and left up to the implementation.

			*/

		EqualTo(...)
			/*

			Compares the equality of source object and the argument data

			  Arguments.

			    Uses the GAAF argument format.

			  Behavior.

			  	Determines if the source object is equal to the argument data..

		      Returns.

		        True if the two values are equal, and false otherwise.

		      Note.

		        For some arbitrary argument or set of arguments Foo, the following should all be
                equivalent.

		           src.Compare(Foo) == 0

		           src.EqualTo(Foo)
		          !src.NotEqualTo(Foo)

		          !src.GreaterThan(Foo) && !src.LessThan(Foo)
		           src.GreaterThanOrEqual(Foo) && src.LessThanOrEqual(Foo).

		        This method is only guaranteed if (1) the input data is at most as long as the class
		        it's being passed to and (2) the input data is of the same "sign behavior" as the
		        class it's being passed to. For example, if the source object is of double-precision
		        unsigned and the input data is single- or double-precision unsigned, then comparison
		        is guaranteed to be accurate. But, comparing to triple-precision unsigned or single-
		        precision signed is not guaranteed to be accurate. Specifically, these cases are
		        considered undefined and left up to the implementation.

			*/

		NotEqualTo(...)
			/*

			Compares the inequality of source object and the argument data

			  Arguments.

			    Uses the GAAF argument format.

			  Behavior.

			  	Determines if the source object is not equal to the argument data..

		      Returns.

		        True if the two values are not equal, and false otherwise.

		      Note.

		        For some arbitrary argument or set of arguments Foo, the following should all be
                equivalent.

		           src.Compare(Foo) != 0

		           src.NotEqualTo(Foo)
		          !src.EqualTo(Foo)

		           src.GreaterThan(Foo) || src.LessThan(Foo)

		        This method is only guaranteed if (1) the input data is at most as long as the class
		        it's being passed to and (2) the input data is of the same "sign behavior" as the
		        class it's being passed to. For example, if the source object is of double-precision
		        unsigned and the input data is single- or double-precision unsigned, then comparison
		        is guaranteed to be accurate. But, comparing to triple-precision unsigned or single-
		        precision signed is not guaranteed to be accurate. Specifically, these cases are
		        considered undefined and left up to the implementation.

			*/

		GreaterThan(...)
			/*

			Determines if the source object is greater than the argument data

			  Arguments.

			    Uses the GAAF argument format.

			  Behavior.

			    Determines if the source object is greater than the argument data

		      Returns.

		        True if the source object is strictly greater than the argument data.

		      Note.

		        For some arbitrary argument or set of arguments Foo, the following should all be
                equivalent.

		           src.Compare(Foo) == 1

		          !src.EqualTo(Foo) && !src.LessThan(Foo)
		           src.NotEqualTo(Foo) && !src.LessThan(Foo)

		           src.GreaterThan(Foo)
		          !src.LessThanOrEqualTo(Foo)

		        This method is only guaranteed if (1) the input data is at most as long as the class
		        it's being passed to and (2) the input data is of the same "sign behavior" as the
		        class it's being passed to. For example, if the source object is of double-precision
		        unsigned and the input data is single- or double-precision unsigned, then comparison
		        is guaranteed to be accurate. But, comparing to triple-precision unsigned or single-
		        precision signed is not guaranteed to be accurate. Specifically, these cases are
		        considered undefined and left up to the implementation.
			*/

		GreaterThanOrEqualTo(...)
			/*

			Determines if the source object is greater than or equal to the argument data.

			  Arguments.

			    Uses the GAAF argument format.

			  Behavior.

			    Determines if the source object is greater than or equal to the argument data.

		      Returns.

		        True if the source object is greater than or equal to the argument data.

		      Note.

		        For some arbitrary argument or set of arguments Foo, the following should all be
                equivalent.

		           src.Compare(Foo) != -1

		           src.EqualTo(Foo) && !src.LessThan(Foo)
		          !src.NotEqualTo(Foo) && !src.LessThan(Foo)

		           src.GreaterThanOrEqualTo(Foo)

		        This method is only guaranteed if (1) the input data is at most as long as the class
		        it's being passed to and (2) the input data is of the same "sign behavior" as the
		        class it's being passed to. For example, if the source object is of double-precision
		        unsigned and the input data is single- or double-precision unsigned, then comparison
		        is guaranteed to be accurate. But, comparing to triple-precision unsigned or single-
		        precision signed is not guaranteed to be accurate. Specifically, these cases are
		        considered undefined and left up to the implementation.
			*/

		LessThan(...)
			/*

			Determines if the source object is less than the argument data

			  Arguments.

			    Uses the GAAF argument format.

			  Behavior.

			    Determines if the source object is less than the argument data

		      Returns.

		        True if the source object is strictly less than the argument data.

		      Note.

		        For some arbitrary argument or set of arguments Foo, the following should all be
                equivalent.

		           src.Compare(Foo) == -1

		          !src.EqualTo(Foo) && !src.GreaterThan(Foo)
		           src.NotEqualTo(Foo) && !src.GreaterThan(Foo)

		          !src.GreaterThanOrEqualTo(Foo)
		           src.LessThan(Foo)

		        This method is only guaranteed if (1) the input data is at most as long as the class
		        it's being passed to and (2) the input data is of the same "sign behavior" as the
		        class it's being passed to. For example, if the source object is of double-precision
		        unsigned and the input data is single- or double-precision unsigned, then comparison
		        is guaranteed to be accurate. But, comparing to triple-precision unsigned or single-
		        precision signed is not guaranteed to be accurate. Specifically, these cases are
		        considered undefined and left up to the implementation.
			*/

		LessThanOrEqualTo(...)
			/*

			Determines if the source object is less than or equal to the argument data.

			  Arguments.

			    Uses the GAAF argument format.

			  Behavior.

			    Determines if the source object is less than or equal to the argument data.

		      Returns.

		        True if the source object is less than or equal to the argument data.

		      Note.

		        For some arbitrary argument or set of arguments Foo, the following should all be
                equivalent.

		           src.Compare(Foo) != 1

		           src.EqualTo(Foo) && !src.GreaterThan(Foo)
		          !src.NotEqualTo(Foo) && !src.GreaterThan(Foo)

		           src.LessThanOrEqualTo(Foo)

		        This method is only guaranteed if (1) the input data is at most as long as the class
		        it's being passed to and (2) the input data is of the same "sign behavior" as the
		        class it's being passed to. For example, if the source object is of double-precision
		        unsigned and the input data is single- or double-precision unsigned, then comparison
		        is guaranteed to be accurate. But, comparing to triple-precision unsigned or single-
		        precision signed is not guaranteed to be accurate. Specifically, these cases are
		        considered undefined and left up to the implementation.
			*/

		// Alias methods.

		// Alias for...
		EQ(...)		// ... EqualTo(...)
		NEQ(...)	// ... NotEqualTo(...)
		GT(...)		// ... GreaterThan(...)
		GEQ(...)	// ... GreaterThanOrEqualTo(...)
		LT(...)		// ... LessThan(...)
		LEQ(...)	// ... LessThanOrEqualTo(...)

		// Miscellaneous comparison methods.

		IsPositive()
			/*

			Determines if the source object is positive.

			  Arguments.

			    None

			  Behavior.

			    Determines if the source object is positive (greater than zero).

		      Returns.

		        True if the source object is greater than zero.

		      Note.

		        The following should all be equivalent.

		           src.IsPositive()
		          !src.IsNonPositive()

		           src.Compare(0) == 1

		           src.GreaterThan(0)
		          !src.LessThanOrEqualTo(0)

		          !src.EqualTo(0) && !src.LessThan(0)
		           src.NotEqualTo(0) && !src.LessThan(0)

			*/

		IsZero()
			/*

			Determines if the source object is equal to zero.

			  Arguments.

			    None

			  Behavior.

			    Determines if the source object is zero.

		      Returns.

		        True if the source object is equal to zero.

		      Note.

		        The following should all be equivalent.

		           src.IsZero()
		          !src.IsNonZero()

		           src.Compare(0) == 0

		           src.Equal(0)
		          !src.NotEqualTo(0)

		          !src.GreaterThan(0) && !src.LessThan(0)
		           src.GreaterThanOrEqual(0) && src.LessThanOrEqual(0)

			*/

		IsNegative()
			/*

			Determines if the source object is negative.

			  Arguments.

			    None

			  Behavior.

			    Determines if the source object is negative (less than zero).

		      Returns.

		        True if the source object is less than zero.

		      Note.

		        The following should all be equivalent.

		           src.IsNegative()
		          !src.IsNonNegative()

		           src.Compare(0) == -1

		           src.LessThan(0)
		          !src.GreaterThanOrEqualTo(0)

		          !src.EqualTo(0) && !src.GreaterThan(0)
		           src.NotEqualTo(0) && !src.GreaterThan(0)

			*/

		IsNonPositive()
			/*

			Determines if the source object is non-positive.

			  Arguments.

			    None

			  Behavior.

			    Determines if the source object is non-positive (less than or equal to zero).

		      Returns.

		        True if the source object is less than or equal to zero.

		      Note.

		        The following should all be equivalent.

		          !src.IsPositive()
		           src.IsNonPositive()

		           src.Compare(0) != 1

		          !src.GreaterThan(0)
		           src.LessThanOrEqualTo(0)

		           src.EqualTo(0) || src.LessThan(0)
		          !src.NotEqualTo(0) || src.LessThan(0)

			*/

		IsNonZero()
			/*

			Determines if the source object is non-zero.

			  Arguments.

			    None

			  Behavior.

			    Determines if the source object is non-zero (not equal to zero).

		      Returns.

		        True if the source object is not equal to zero.

		      Note.

		        The following should all be equivalent.

		          !src.IsZero()
		           src.IsNonZero()

		           src.Compare(0) != 0

		          !src.Equal(0)
		           src.NotEqualTo(0)

		           src.GreaterThan(0) || src.LessThan(0)

			*/

		IsNonNegative()
			/*

			Determines if the source object is non-negative.

			  Arguments.

			    None

			  Behavior.

			    Determines if the source object is non-negative (greater than or equal to zero).

		      Returns.

		        True if the source object is greater than or equal to zero.

		      Note.

		        The following should all be equivalent.

		          !src.IsNegative()
		           src.IsNonNegative()

		           src.Compare(0) != -1

		          !src.LessThan(0)
		           src.GreaterThanOrEqualTo(0)

		           src.EqualTo(0) || src.GreaterThan(0)
		          !src.NotEqualTo(0) || src.GreaterThan(0)

			*/

		/*
		 * Print methods.
		 */

		PrintBinary()
			/*

			Outputs a binary-encoded string equal to the value of the source object. It should be
			essentially a plain read-out of the stored binary data, and include nothing about signs.

			  Arguments.

			    None

		      Returns.

		        A binary-encoded string equal in value to the source object.

			*/

		PrintDecimal()
			/*

			Outputs a decimal-encoded string equal to the value of the source object. This should be
			in standard decimal notation, and include signs if necessary (e.g., for negative
			numbers).

			  Arguments.

			    None

		      Returns.

		        A decimal-encoded string equal in value to the source object.

			*/

		PrintHexadecimal()
			/*

			Outputs a hexadecimal-encoded string equal to the value of the source object. It should
			be essentially a plain read-out of the stored hexadecimal data, and include nothing
			about signs.

			  Arguments.

			    None

		      Returns.

		        A hexadecimal-encoded string equal in value to the source object.

			*/

		// Alias methods.

		// Alias for...
		Print()		// ... PrintDecimal()
		PrintBin()	// ... PrintBinary()
		PrintHex()	// ... PrintHexadecimal()

		/*
		 * Inspection methods.
		 */

		Length()
			/*

			Outputs the number of blocks the source object contains.

			  Arguments.

			    None

		      Returns.

		        A positive DM integer.

			*/

		BitLength()
			/*

			Outputs the number of bits the source object has.

			  Arguments.

			    None

			  Behavior.

			    The number of bits in the source object. For integers, this is most-likely
			    equal to src.Length()*16.

		      Returns.

		        A positive DM integer.

			*/

		Mode()
			/*

			Outputs the current mode flags for the object.

			  Arguments.

			    None.

			  Returns.

			    A DM integer.

			*/

		/*
		 * Mutator methods.
		 */

		Set(...)
			/*

			Sets the source object equal to the argument data.

			  Arguments.

			    Uses the GAAF argument format.

			  Behavior.

			    Sets the source object equal to the argument data.

			  Returns.

			    The source object.

			*/

		SetMode(M)
			/*

			Sets the mode equal to M.

			  Arguments.

			    M is a bitstring (16-bit integer). If it is a non-integer, a /pif_Arithmetic/NonIntegerException
			    exception is thrown. Because it is a bitstring, we can ignore sign information.

			  Behavior.

			    Sets the mode of the source object equal to the argument data.

			  Returns.

			    A bitstring corresponding to the new mode.

			*/

		SetModeFlag(F, S)
			/*

			Sets the mode F equal to the state S

			  Arguments.

			    * F is a flag corresponding to one or both of the constants,

			      - NEW_OBJECT	 		(1)
			      - OVERFLOW_EXCEPTION	(2)

			    * S is boolean.

			  Behavior.

			    One or both of the flags is set to the state S. If S is false, the specified flag(s)
			    is/are turned off, while if S is true they are turned on.

			  Returns.

			    A bitstring corresponding to the new mode.

			*/


		/*
		 * "Static" methods.
		 *
		 *    Note.
		 *
		 *      DM does not currently have static methods, so these are kind of a pie-in-the-sky
         *      sort of thing, but hopefully at some point.
		 */

		Maximum(/* N (see below) */)
			/*

			Outputs an object with the maximum integer value allowed.

			  Arguments.

			    If the FIXED_WIDTH flag is set, then there are no arguments. If the FIXED_WIDTH
                argument is not set (i.e., the object is arbitrary-precision) then N is a positive
                integer referring to the "highest" integer that can be stored in N blocks. If N is a
                non-integer, then a /pif_Arithmetic/NonIntegerException exception is thrown. If a
                non-positive integer is passed, then a /pif_Arithmetic/NonPositiveIntegerException
                exception is thrown.

			  Behavior.

			    This outputs an object of the same type as the local method class which is the
                "maximum" integer that can be stored on N blocks. By "maximum", this is an object
                such that if it were incremented it would overflow; equivalently, one can imagine it
                as the largest positive integer represented given the width of the object.

			    If the FIXED_WIDTH flag is not set, then this should instead output the largest
                positive number that can be stored on N blocks.

			  Returns.

			    An object of the same type as the local method class.

			*/

		Minimum(/* N (see below) */)
			/*

			Outputs an object with the minimum integer value allowed.

			  Arguments.

			    If the FIXED_WIDTH flag is set, then there are no arguments. If the FIXED_WIDTH
                argument is not set (i.e., the object is arbitrary-precision) then N is a positive
                integer referring to the "highest" integer that can be stored in N blocks. If N is a
                non-integer, then a /pif_Arithmetic/NonIntegerException exception is thrown. If a
                non-positive integer is passed, then a /pif_Arithmetic/NonPositiveIntegerException
                exception is thrown.

			  Behavior.

			    This outputs an object of the same type as the local method class which is the
                "minimum" integer that can be stored on N blocks. By "minimum", this is an object
				such that if it were decrement it would overflow; equivalently, one can imagine it
				as the largest (in absolute value) non-positive integer represented given the width
				of the object.

			    If the FIXED_WIDTH flag is not set, then this should instead output the largest (in
                absolute value) non-positive integer representable in N blocks.

			  Returns.

			    An object of the same type as the local method class.

			  Note.

			    If the SIGNED_MODE flag is not set, this method will always output an object equal
                to 0. That is, an object O such that O.IsZero() is true.

			*/

		Zero()
			/*

			Outputs an object equal to zero.

			Arguments.

			  None.

			Behavior.

			  Returns an object equal to zero. That is, for the output object, IsZero() is true.

			Returns.

			  An object of the same type as the local method class.

			*/

		/*
		 * "Private" method.
		 *
		 *    Note.
		 *
		 *      Typically, protocols will not prescribe private methods, but due to the nature
		 *      of this protocol (specifying how numerical data that is larger than DM can typically
		 *      handle, and how these objects interact with one another) it is essentially a
		 *      requirement.
		 */

		_GetBlock(P)
			/*

			Outputs the Pth block.

			  Arguments.

			    A positive integer. If a non-integer is passed, then a /pif_Arithmetic/NonIntegerException
			    exception is thrown. If a non-positive integer is passed, then a /pif_Arithmetic/NonPositiveIntegerException
			    exception is thrown. If P is larger than the total number of blocks, then we throw a
			    /pif_Arithmetic/OutOfBoundsException.

			  Behavior.

			    Returns a 16-bit DM integer that should contain the portions of the source object's
                data with bits between the ((P-1)*16)th and (P*16-1)th positions (where 0 is the
                position of the least-significant bit), or equivalently the Pth block of data, where
                the 1st block is the least-significant block.

			  Returns.

			    An integer.

			*/

		_SetBlock(P, D)
			/*

			Sets the Pth block to D.

			  Arguments.

			    * P is a positive integer. If a non-integer is passed, then a /pif_Arithmetic/NonIntegerException
			      exception is thrown. If a non-positive integer is passed, then a /pif_Arithmetic/NonPositiveIntegerException
			      exception is thrown.

			    * D is an integer. If a non-integer is thrown, then a /pif_Arithmetic/NonIntegerException
                  exception is thrown.

			  Behavior.

			    Sets the Pth block equal to D. This should be the block which has bits between
                ((P-1)*16)th and (P*16-1)th positions (where 0 is the position of the least-
                significant bit), or equivalently the Pth block of data, where the 1st block is the
                least-significant block. If P is larger than the total number of blocks, then we
                throw a /pif_Arithmetic/OutOfBoundsException.

			  Returns.

			    The new value of the block.

			*/

	/*
	 * Exceptions
	 */

	GenericArithmeticException
		parent_type = /exception

		New(_file, _line)
			file = _file
			line = _line

	NonIntegerException
#if	!defined(PIF_NOPREFIX_GENERAL) && !defined(PIF_NOPREFIX_ARITHMETIC)
		parent_type = /pif_Arithmetic/GenericArithmeticException
#else
		parent_type = /Arithmetic/GenericArithmeticException
#endif

		name = "Non-Integer Exception"
		desc = "Non-integer data found where integer data expected."

	NonPositiveIntegerException
#if	!defined(PIF_NOPREFIX_GENERAL) && !defined(PIF_NOPREFIX_ARITHMETIC)
		parent_type = /pif_Arithmetic/GenericArithmeticException
#else
		parent_type = /Arithmetic/GenericArithmeticException
#endif

		name = "Non-Positive Integer Exception"
		desc = "Non-positive integer data found where positive integer data expected."

	NegativeIntegerException
#if	!defined(PIF_NOPREFIX_GENERAL) && !defined(PIF_NOPREFIX_ARITHMETIC)
		parent_type = /pif_Arithmetic/GenericArithmeticException
#else
		parent_type = /Arithmetic/GenericArithmeticException
#endif

		name = "Negative Integer Exception"
		desc = "Negative integer data found where non-negative integer data expected."

	NegativeInvalidPositionException
#if	!defined(PIF_NOPREFIX_GENERAL) && !defined(PIF_NOPREFIX_ARITHMETIC)
		parent_type = /pif_Arithmetic/GenericArithmeticException
#else
		parent_type = /Arithmetic/GenericArithmeticException
#endif

		name = "Negative In Invalid Position Exception"
		desc = "Negative integer data found in position where non-negative integer data expected."

	NegativeInUnsignedIntegerException
#if	!defined(PIF_NOPREFIX_GENERAL) && !defined(PIF_NOPREFIX_ARITHMETIC)
		parent_type = /pif_Arithmetic/GenericArithmeticException
#else
		parent_type = /Arithmetic/GenericArithmeticException
#endif

		name = "Negative In Unsigned Integer Exception"
		desc = "Negative integer data passed to unsigned integer object."

	InvalidStringEncodingException
#if	!defined(PIF_NOPREFIX_GENERAL) && !defined(PIF_NOPREFIX_ARITHMETIC)
		parent_type = /pif_Arithmetic/GenericArithmeticException
#else
		parent_type = /Arithmetic/GenericArithmeticException
#endif

		name = "Invalid String Encoding Exception"
		desc = "Invalid character found for specified string encoding."

	InvalidStringPrefixException
#if	!defined(PIF_NOPREFIX_GENERAL) && !defined(PIF_NOPREFIX_ARITHMETIC)
		parent_type = /pif_Arithmetic/GenericArithmeticException
#else
		parent_type = /Arithmetic/GenericArithmeticException
#endif

		name = "Invalid String Prefix Exception"
		desc = "Invalid prefix for string encoding integer data."

	InvalidStringArgumentException
#if	!defined(PIF_NOPREFIX_GENERAL) && !defined(PIF_NOPREFIX_ARITHMETIC)
		parent_type = /pif_Arithmetic/GenericArithmeticException
#else
		parent_type = /Arithmetic/GenericArithmeticException
#endif

		name = "Invalid String Argument Exception"
		desc = "Found zero-length string where a positive-length string expected."

	InvalidStringEncodingObjException
#if	!defined(PIF_NOPREFIX_GENERAL) && !defined(PIF_NOPREFIX_ARITHMETIC)
		parent_type = /pif_Arithmetic/GenericArithmeticException
#else
		parent_type = /Arithmetic/GenericArithmeticException
#endif

		name = "Invalid String-Encoding Object Exception"
		desc = "Non-object found where object was expected for string-encoding processing."

	InvalidArgumentFormatException
#if	!defined(PIF_NOPREFIX_GENERAL) && !defined(PIF_NOPREFIX_ARITHMETIC)
		parent_type = /pif_Arithmetic/GenericArithmeticException
#else
		parent_type = /Arithmetic/GenericArithmeticException
#endif

		name = "Invalid Argument Format Exception"
		desc = "Invalid argument format encountered."

	InvalidBitstringLengthException
#if	!defined(PIF_NOPREFIX_GENERAL) && !defined(PIF_NOPREFIX_ARITHMETIC)
		parent_type = /pif_Arithmetic/GenericArithmeticException
#else
		parent_type = /Arithmetic/GenericArithmeticException
#endif

		name = "Invalid Bitstring Length Exception"
		desc = "Invalid length for bitstring extraction."

	OverflowException
#if	!defined(PIF_NOPREFIX_GENERAL) && !defined(PIF_NOPREFIX_ARITHMETIC)
		parent_type = /pif_Arithmetic/GenericArithmeticException
#else
		parent_type = /Arithmetic/GenericArithmeticException
#endif

		name = "Overflow Exception"
		desc = "Integer overflow has occurred."

	OutOfBoundsException
#if	!defined(PIF_NOPREFIX_GENERAL) && !defined(PIF_NOPREFIX_ARITHMETIC)
		parent_type = /pif_Arithmetic/GenericArithmeticException
#else
		parent_type = /Arithmetic/GenericArithmeticException
#endif

		name = "Out of Bounds Exception"
		desc = "Block request is out of bounds."

	ProtocolNonConformingObjectException
#if	!defined(PIF_NOPREFIX_GENERAL) && !defined(PIF_NOPREFIX_ARITHMETIC)
		parent_type = /pif_Arithmetic/GenericArithmeticException
#else
		parent_type = /Arithmetic/GenericArithmeticException
#endif

		name = "Protocol Non-Conforming Object Exception"
		desc = "Passed object does not conform to the pif_Arithmetic protocol."

	NonNumericInvalidPositionException
#if	!defined(PIF_NOPREFIX_GENERAL) && !defined(PIF_NOPREFIX_ARITHMETIC)
		parent_type = /pif_Arithmetic/GenericArithmeticException
#else
		parent_type = /Arithmetic/GenericArithmeticException
#endif

		name = "Non-Numeric Data In Invalid Position Exception"
		desc = "Non-numeric data was passed in an invalid position."

#endif
