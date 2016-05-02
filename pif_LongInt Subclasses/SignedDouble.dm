/*
 * Implementation of an signed double precision (32-bit) integer that uses the
 * pif_Arithmetic protocol. Numbers are stored in two's complement form, and
 * thus have a precision between -2,147,483,648 (-2**31) and 2,147,483,647 (2**31-1).
 * That is, between 0x80000000 and 0x7FFFFFFF in hexadecimal.
 */

pif_LongInt/SignedDouble
	parent_type = /pif_LongInt/UnsignedDouble

	mode = OLD_OBJECT | NO_OVERFLOW_EXCEPTION | FIXED_PRECISION | SIGNED_MODE

	_Process(list/arguments)
		// Does the processing for GAAF_format arguments. I'd really prefer this
		// be broken up into a number of subroutines, but I think the impact on
		// performance will be too significant. If static methods become available
		// in DM, I'll probably break this up and then implement methods like
		// /pif_LongInt/FromString() or /pif_LongInt/FromIntegers() so that I can
		// avoid a performance hit.

		var/list/Data = new
		Data.len = Length // Note that Data[0] is less-significant and Data[1] is
						  // more-significant.

		/*

		  1.  proc/Method() or proc/Method(null)

		    This is a special case that should be interpreted as passing 0.

		*/

		if(arguments.len == 0)
			Data[1] = 0
			Data[2] = 0

		if(arguments.len == 1)


			if(isnull(arguments[1]))
				Data[1] = 0
				Data[2] = 1

		/*

		  2.  proc/Method(datum/pAr_Object)

		      i.   pAr_Object is an object that implements the pif_Arithmetic protocol, and data is pulled
		           directly from this object. Ways of handling if pAr_object is too large for the source
		           object to process are implementation-specific.

		           If pAr_Object does not appear to implement the pif_Arithmetic protocol (e.g., by not
		           having a necessary method) throw a /pif_Arithmetic/ProtocolNonConformingObjectException
		           exception.
		*/

			else if(istype(arguments[1], /pif_LongInt))
				// If it's a pif_LongInt object, we can be a little more sure that we're dealing with an object
				// that implements the pif_Arithmetic protocol.

				var/pif_LongInt/IntegerObject = arguments[1]

				if((IntegerObject.Length() > Length) && (mode & OVERFLOW_EXCEPTION))
					var/L = IntegerObject.Length()
					for(var/i = 3, i <= L, i ++)
						// We'll look at the other data in the object. If we find any non-zero data, then the
						// object is too large to read in and we must throw an exception.
						if(IntegerObject._GetBlock(i) != 0)
							throw new /pif_Arithmetic/OverflowException(__FILE__, __LINE__)

				else
					// Otherwise, just assign the relevant data to the list.
					Data[1] = IntegerObject._GetBlock(1)
					Data[2] = IntegerObject._GetBlock(2)

			else if(istype(arguments[1], /datum))
				// If it's some other type of object, we'll assume it's something that implements the pif_Arithmetic
				// protocol.

				var/pif_Arithmetic/pif_ArithmeticObject = arguments[1]

				if(!hascall(pif_ArithmeticObject, "Length") || !hascall(pif_ArithmeticObject, "_GetBlock"))
					// If it doesn't conform to the pif_Arithmetic protocol, we throw the required exception.
					throw new /pif_Arithmetic/ProtocolNonConformingObjectException(__FILE__, __LINE__)

				// Otherwise, we do the same as above.

				if((pif_ArithmeticObject.Length() > Length) && (mode & OVERFLOW_EXCEPTION))
					// Same as above with the /pif_LongInt object: if we find any non-zero data beyond block two,
					// then the object is too large to read in.
					var/L = pif_ArithmeticObject.Length()
					for(var/i = 3, i <= L, i ++)
						if(pif_ArithmeticObject._GetBlock(i) != 0)
							throw new /pif_Arithmetic/OverflowException(__FILE__, __LINE__)

				else
					Data[1] = pif_ArithmeticObject._GetBlock(1)
					Data[2] = pif_ArithmeticObject._GetBlock(2)

		/*

		3.  proc/Method(list/List)

		  i.   List is a /list object that is interpreted as left-significant. That is, the left-most
		       entry ("block") of the list (the entry with the lowest index) is interpreted as the
		       most-significant element of that list, while the right-most block (the entry with the
		       highest index) is interpreted as the most-significant element of that list. This is so
		       that something of the form

		         Method(0x6789, 0xABCD)

		       is interpreted as the number 0x6789ABCD, which is intuitive. If the list were interpreted
		       as right-significant, this would instead be the number 0xABCD6789.

		       All elements of the list should be integers. If a non-integer is found in the list, then
		       a /pif_Arithmetic/NonIntegerException exception should be thrown. If a non-numeric value is
		       found then a /pif_Arithmetic/NonNumericInvalidPositionException exception should be thrown.

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
		       raw binary data by performing bitwise AND with the data and the value 0xFFFF. There should
		       be no regard for sign data or floating point values.

		*/

			else if(istype(arguments[1], /list))
				var/list/Args = arguments[1]

				if(Args.len == 1)
					// When passing a single integer argument, we allow a larger block than usual.

					var
						Integer = Args[1]

						block_1
						block_2

						negate_flag = 0

					if(!isnum(Integer))
						throw new /pif_Arithmetic/NonNumericInvalidPositionException(__FILE__, __LINE__)
					else if(round(Integer) != Integer)
						// Must be an integer.
						throw new /pif_Arithmetic/NonIntegerException(__FILE__, __LINE__)

					if(Integer < 0)
						// If it's less than zero, we negate Integer and mark the data as needing negated
						// back at the end.

						Integer = -Integer
						negate_flag = 1

					// Any other value we'll interpret as an integer. Only values in the range [0,
					// 16777215] are guaranteed to be accurate; above that range, it may not be
					// accurate and either strings or lists of two elements should be used.

					block_1 = Integer % 65536
					block_2 = (Integer - block_1) / 65536

					if(negate_flag)
						block_1 = ~block_1
						block_2 = ~block_2

						var
							byte1 = pliBYTE_ONE(block_1) // Least significant.
							byte2 = pliBYTE_TWO(block_1)
							byte3 = pliBYTE_ONE(block_2)
							byte4 = pliBYTE_TWO(block_2) // Most significant.

						byte1 ++
						pliADDBUFFER(byte1, byte2)
						pliADDBUFFER(byte2, byte3)
						pliADDBUFFER(byte3, byte4)

						block_1 = byte1 | pliBYTE_ONE_SHIFTED(byte2)
						block_2 = byte3 | pliBYTE_ONE_SHIFTED(byte4)

					Data[1] = block_1
					Data[2] = block_2

				else
					// Lists of two elements are simply interpreted as bitstrings provided they
					// are integer values.

					var
						block_1 = arguments[arguments.len  ]
						block_2 = arguments[arguments.len-1]

					if(!isnum(block_1) || !isnum(block_2))
						throw new /pif_Arithmetic/NonNumericInvalidPositionException(__FILE__, __LINE__)
					else if( (round(block_1) != block_1) || (round(block_2) != block_2) )
						throw new /pif_Arithmetic/NonIntegerException(__FILE__, __LINE__)

					// Because this class is unsigned, we will interpret negative values as bitstrings.
					if(block_1 < 0)
						block_1 &= 0xFFFF
					if(block_2 < 0)
						block_2 &= 0xFFFF

					Data[1] = block_1
					Data[2] = block_2

					for(var/i = 1, i <= Args.len-2, i ++)
						// Now we look through the rest of the arguments to make sure they don't violate
						// any requirements of the GAAF format.

						var/block = Args[i]

						if(!isnum(block))
							throw new /pif_Arithmetic/NonNumericInvalidPositionException(__FILE__, __LINE__)
						else if(round(block) != block)
							throw new /pif_Arithmetic/NonIntegerException(__FILE__, __LINE__)
						else if((mode & OVERFLOW_EXCEPTION) && (block != 0))
							// If there is non-zero data and OVERFLOW_EXCEPTION mode is enabled, then the
							// incoming data is too large to read in and we must throw the exception.
							throw new /pif_Arithmetic/OverflowException(__FILE__, __LINE__)

		/*

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

		*/

			else if(istext(arguments[1]))
				var/String = arguments[1]

				if(length(String) == 0)
					// Zero-length strings are not allowed.
					throw new /pif_Arithmetic/InvalidStringArgumentException(__FILE__, __LINE__)

				else if(findtextEx(String, "0b", 1, 3) || findtextEx(String, "-0b", 1, 4))
					/*
					 * We have a string with a binary-encoded number.
					 */

					var
						pif_LongInt/SignedDouble/Tracker = new src.type

						delta = 2 // Basically the amount of prefix characters there are.
						length

						const/ASCII_ZERO = 48

						negate_flag = findtext(String, "-", 1, 2)
					delta = negate_flag ? (delta+1) : delta
					length = length(String) - delta

					Tracker.SetModeFlag(NEW_OBJECT, 0)

					for(var/i = length, i > 0, i --)
						// This loop starts from the *end* of the string and moves forward, so we
						// can get the least-significant characters first. This is largely because
						// it makes the math a bit easier.

						var/c = text2ascii(String, i+delta) - ASCII_ZERO

						if( (c != 0) && (c != 1) )
							// If we've encountered an invalid character, throw an exception.
							throw new /pif_Arithmetic/InvalidStringEncodingException(__FILE__, __LINE__)

						if((length - i) < 16)
							Tracker.Add(0x0000, c << (length - i))
						else if((length - i) < 32)
							Tracker.Add(c << ((length - i) - 16), 0x0000)
						else
							if(!(mode & OVERFLOW_EXCEPTION))
								// If we're at a point larger than can
								// be stored in a double precision integer,
								// and if we're aren't tracking for overflow,
								// then just stop the loop.
								break

							else if(c != 0)
								// Otherwise, wait until we find a non-zero
								// term and throw the exception.
								throw new /pif_Arithmetic/OverflowException(__FILE__, __LINE__)

					if(negate_flag)
						Tracker.Negate()

					Data[1] = Tracker._GetBlock(1)
					Data[2] = Tracker._GetBlock(2)

				else if(findtextEx(String, "0x", 1, 3) || findtextEx(String, "-0x", 1, 4))
					/*
					 * A string with a hexadecimal-encoded integer.
					 */

					var
						pif_LongInt/SignedDouble/Tracker = new src.type

						delta = 2 // Basically the amount of prefix characters there are.
						length

						const
							HEX_ZERO      = 0x0000
							HEX_NINE      = 0x0009
							HEX_FIFTEEN   = 0x000F

							ASCII_ZERO	  = 48
							ASCII_NINE    = 57
							ASCII_DIFF	  = 39

							LOWERCASE_BIT = 32 // Turning this bit on will convert an uppercase
											   // character to lowercase.

						negate_flag = findtext(String, "-", 1, 2)
					delta = negate_flag ? (delta+1) : delta
					length = length(String) - delta

					Tracker.SetModeFlag(NEW_OBJECT, 0)

					for(var/i = length, i > 0, i --)
						// This loop starts from the *end* of the string and moves forward, so we
						// can get the least-significant characters first. This is largely because
						// it makes the math a bit easier.
						var/c = text2ascii(String, i+delta)

						if(c > ASCII_NINE)
							// If it's non-numeric, then make it lowercase so we can have consistent
							// behavior.
							c |= LOWERCASE_BIT

						// We subtract the value of ASCII_ZERO so that "0" maps to 0, "1" maps to
						// 1, ..., and "9" maps to 9...
						c -= ASCII_ZERO

						if(c > HEX_NINE)
							// ... but, "a", ..., "f" will map to 49, ..., 54, so we have to subtract
							// the correct difference (ASCII_DIFF) to have them map to 10, ..., 15.
							c -= ASCII_DIFF

						if( (c < HEX_ZERO) || (c > HEX_FIFTEEN) )
							// If we've encountered an invalid character, throw an exception.
							throw new /pif_Arithmetic/InvalidStringEncodingException(__FILE__, __LINE__)

						if((length - i) < 4)
							// If i is in the range [0, 4) then we can still write to the first block.
							Tracker.Add(0x0000, c << 4*(length - i))
						else if((length - i) < 8)
							// If i is in the range [4, 8) then we can still write to the second block.
							Tracker.Add(c << 4*((length - i) - 4), 0x0000)
						else
							// If i is 8 or more, then there are no more blocks to write to.

							if(!(mode & OVERFLOW_EXCEPTION))
								// If we're at a point larger than can be stored in a double precision
								// integer, and if we're aren't tracking for overflow, then just stop
								// the loop.
								break

							else if(c != HEX_ZERO)
								// Otherwise, wait until we find a non-zero term and throw the
								// exception.
								throw new /pif_Arithmetic/OverflowException(__FILE__, __LINE__)

					if(negate_flag)
						Tracker.Negate()

					Data[1] = Tracker._GetBlock(1)
					Data[2] = Tracker._GetBlock(2)

				else if(findtext(String, regex("0\[^0-9]"), 1, 3))
					// We found another prefix but one that is unsupported.
					throw new /pif_Arithmetic/InvalidStringPrefixException(__FILE__, __LINE__)

				else
					// If only the character 0-9 show up in the string, then it's a valid decimal
					// string and we may proceed.

					// Anything else and we assume a decimal-encoded string was passed. This method
					// seems a bit slow, so I'd love to figure out a faster version.

					var
						pif_LongInt/SignedDouble
							// This tracks the current position. That is, at each step we multiply it by
							// ten to keep it in the right position.
							PositionTracker = new src.type(1)
							Buffer = new src.type // Temporarily holds a product before adding it to
												  // the Tracker object.

							Tracker = new src.type // Tracks the final value.

						length = length(String)

						const/ASCII_ZERO = 48

					PositionTracker.SetModeFlag(OVERFLOW_EXCEPTION, mode & OVERFLOW_EXCEPTION)
					PositionTracker.SetModeFlag(NEW_OBJECT, 0)

					Tracker.SetModeFlag(NEW_OBJECT, 0)
					Buffer.SetModeFlag(NEW_OBJECT, 0)

					for(var/i = length, i > 0, i --)
						// This loop starts from the *end* of the string and moves forward, so we
						// can get the least-significant characters first. This is largely because
						// it makes the math a bit easier.

						var/c = text2ascii(String, i) - ASCII_ZERO

						if((c < 0) || (c > 9))
							// If we've encountered an invalid character, throw an exception.
							throw new /pif_Arithmetic/InvalidStringEncodingException(__FILE__, __LINE__)

						else if(c != 0)
							// If c is non-zero, then compute the corresponding value, store it in the
							// buffer, and add it to the tracker.

							// If c is non-zero, then we store the value in the buffer, multiply the
							// buffer by the current position as stored in PositionTracker, and then add
							// the result to the Tracker object.

							Buffer.Set(c)
							Tracker.Add(Buffer.Multiply(PositionTracker))

						PositionTracker.Multiply(10)

					Data[1] = Tracker._GetBlock(1)
					Data[2] = Tracker._GetBlock(2)


		/*

		7.  proc/Method(...)

		       A left-significant list of integer arguments. See 3. for details on this format.

		*/

			else if(isnum(arguments[1]))
				// This situation is when a single integer has been passed as an argument.

				var
					Integer = arguments[1]

					block_1
					block_2

					negate_flag = 0

				if(!isnum(Integer))
					throw new /pif_Arithmetic/NonNumericInvalidPositionException(__FILE__, __LINE__)
				else if(round(Integer) != Integer)
					// Must be an integer.
					throw new /pif_Arithmetic/NonIntegerException(__FILE__, __LINE__)

				if(Integer < 0)
					// If it's less than zero, we negate Integer and mark the data as needing negated
					// back at the end.

					Integer = -Integer
					negate_flag = 1

				// Any other value we'll interpret as an integer. Only values in the range [0,
				// 16777215] are guaranteed to be accurate; above that range, it may not be
				// accurate and either strings or lists of two elements should be used.

				block_1 = Integer % 65536
				block_2 = (Integer - block_1) / 65536

				if(negate_flag)
					block_1 = ~block_1
					block_2 = ~block_2

					var
						byte1 = pliBYTE_ONE(block_1) // Least significant.
						byte2 = pliBYTE_TWO(block_1)
						byte3 = pliBYTE_ONE(block_2)
						byte4 = pliBYTE_TWO(block_2) // Most significant.

					byte1 ++
					pliADDBUFFER(byte1, byte2)
					pliADDBUFFER(byte2, byte3)
					pliADDBUFFER(byte3, byte4)

					block_1 = byte1 | pliBYTE_ONE_SHIFTED(byte2)
					block_2 = byte3 | pliBYTE_ONE_SHIFTED(byte4)

				Data[1] = block_1
				Data[2] = block_2

		/*

		If the format provided for a GAAF-specified method does not match one of the above formats, then a
		/pif_Arithmetic/InvalidArgumentFormatException exception is thrown.

		*/

			else
				throw new /pif_Arithmetic/InvalidArgumentFormatException(__FILE__, __LINE__)

		/*

		TODO:

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
		       string (i.e., "") then a /pif_Arithmetic/InvalidStringArgumentException exception is thrown.

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

		*/

		// ...

		/*

		7.  proc/Method(...)

		       A left-significant list of integer arguments. See 3. for details on this format.

		*/

		else
			var
				block_1 = arguments[arguments.len  ]
				block_2 = arguments[arguments.len-1]

			if(!isnum(block_1) || !isnum(block_2))
				throw new /pif_Arithmetic/NonNumericInvalidPositionException(__FILE__, __LINE__)
			else if( (round(block_1) != block_1) || (round(block_2) != block_2) )
				throw new /pif_Arithmetic/NonIntegerException(__FILE__, __LINE__)

			// Because this class is unsigned, we will interpret negative values as bitstrings.
			if(block_1 < 0)
				block_1 &= 0xFFFF
			if(block_2 < 0)
				block_2 &= 0xFFFF

			Data[1] = block_1
			Data[2] = block_2

			for(var/i = 1, i <= arguments.len-2, i ++)
				// Now we look through the rest of the arguments to make sure they don't violate
				// any requirements of the GAAF format.

				var/block = arguments[i]

				if(!isnum(block))
					throw new /pif_Arithmetic/NonNumericInvalidPositionException(__FILE__, __LINE__)
				else if(round(block) != block)
					throw new /pif_Arithmetic/NonIntegerException(__FILE__, __LINE__)
				else if((mode & OVERFLOW_EXCEPTION) && (block != 0))
					// If there is non-zero data and OVERFLOW_EXCEPTION mode is enabled, then the
					// incoming data is too large to read in and we must throw the exception.
					throw new /pif_Arithmetic/OverflowException(__FILE__, __LINE__)

		return Data

	Negate()
		// Note that if A = 0x80000000, then A.Negate() == A. This is allowed by
		// the pif_Arithmetic protocol, and is basically a drawback of using two's
		// complement.

		if(mode & NEW_OBJECT)
			var/pif_LongInt/SignedDouble/Int = new src.type(src)
			Int.SetModeFlag(NEW_OBJECT, 0)

			Int.block_1 = ~block_1
			Int.block_2 = ~block_2
			Int.Increment()

			Int.SetModeFlag(NEW_OBJECT, 1)

			return Int

		else
			block_1 = ~block_1
			block_2 = ~block_2
			return src.Increment()

	IsPositive()
		return !IsNegative() && !IsZero()
	IsZero()
		return (block_1 == 0) && (block_2 == 0)
	IsNegative()
		// In two's complement notation, a number is negative if and only if
		// its largest bit is on.
		return (block_2 & 0x8000) != 0

	IsNonPositive()
		return !IsPositive()
	IsNonZero()
		return !IsZero()
	IsNonNegative()
		return !IsNegative()

	PrintDecimal()
		var
			pif_LongInt/SignedDouble
				Printer = new src.type(src)
				R
			list/QR

			negative = 0

		Printer.SetModeFlag(NEW_OBJECT, 0)
		. = ""

		if(IsNegative())
			if((block_1 == 0x0000) && (block_2 == 0x8000))
				// This special case has to be taken into account because 0x80000000 is
				// the minimum for a signed double, and is outside the positive range.
				// What happens is that when trying to negate it, you have ~0x80000000 + 1
				// = 0x7FFFFFFF + 1 = 0x80000000 and thus get nowhere, breaking this
				// method. This is the only value that could cause something like, though,
				// so we only need to take special considerations for it and not any
				// others.

				return "-2147483648"

			Printer.Negate()
			negative = 1

		while(Printer.IsNonZero())
			QR = Printer.Divide(10)
			Printer = QR[1]

			R = QR[2]

			. = "[R.block_1][.]"

		if(. == "")
			return "0"

		if(negative)
			. = "-[.]"

	Compare(pif_LongInt/Int)
		// While the pif_Arithmetic protocol only requires a guarantee that comparisons against
		// incoming data will work correctly for data of the same (or less) length and the same
		// sign behavior, pif_LongInt will additionally guarantee that comparisons against other
		// pif_LongInt objects will produce the correct result.

		var
			B1 // Least-significant.
			B2 // Most-significant.

		if(istype(Int))
			// pif_LongInt objects are handled specially due to the aforementioned guarantee.

			if(Int.Length() > Length)
				// If the incoming object is larger than the source object, it will handle the
				// comparison instead. The negative sign is because we're doing the opposite comparison
				// by passing it off, so we have to reverse the sign to get back to the right one
				// again. For example, if A = 10 and B = 9, A.Compare(B) will output 1 because A >B,
				// but B.Compare(A) will output -1 because B < A. When they're equal, the result is 0
				// and 0 = -0 so we don't need to worry.
				return -Int.Compare(src)

			B1 = Int._GetBlock(1) // It's always guaranteed to have at least one block.
			B2 = (Int.Length() == 2) ? Int._GetBlock(2) : 0

			if(!(Int.Mode() & SIGNED_MODE))
				// If the incoming data is not in signed mode, then we need to first double-check
				// whether the source data is negative or not. If it is negative, then automatically
				// the source data is less than the input data, *but* if we proceed as usually it could
				// on its face appear to be larger due to how two's complement works. E.g., if the input
				// data is equal to 4,294,967,295 and the source data is equal to -1, then without checking
				// the comparison would report htem equal because both have the same representation of
				// 0xFFFFFFFF.

				if(IsNegative())
					return -1
		else
			var
				list/Processed = _Process(args)

			B1 = Processed[1]
			B2 = Processed[2]

		var
			src_sign
			input_sign

		// These are true if negative and false if non-negative.
		src_sign   = block_2 & 0x8000
		input_sign = B2      & 0x8000

		/*
		 * Comparisons between data of different signs won't work as nicely as when
		 * they have the same sign. Luckily, once we know the sign we can immediately
		 * determine which is greater than and less than.
		 */

		if(!src_sign && input_sign)
			// (src >= 0) and (input < 0)
			return 1
		else if(src_sign && !input_sign)
			// (src < 0) and (input >= 0)
			return -1

		/*
		 * If they do have the same sign, though, we can proceed like we did with the
		 * parent method.
		 */

		. = block_2 - B2
		if(. != 0)
			return (. > 0) ? 1 : -1

		. = block_1 - B1
		return (. == 0) ? 0 : ( (. > 0) ? 1 : -1 )

	SetMode(_m)
		// Make sure that FIXED_PRECISION and SIGNED_MODE are both always on.
		mode = _m | (SIGNED_MODE | FIXED_PRECISION)

		return mode

	SetModeFlag(flag, state)
		if(state)
			mode |= flag
		else
			mode &= ~flag

		// Make sure that FIXED_PRECISION is always on and SIGNED_MODE are both always on.
		mode = mode | (SIGNED_MODE | FIXED_PRECISION)

		return mode

	Maximum()
		//  2,147,483,647 =  2**31 - 1.
		return new /pif_LongInt/SignedDouble(0x7FFF, 0xFFFF)
	Minimum()
		// -2,147,483,648 = -2**31
		return new /pif_LongInt/SignedDouble(0x8000, 0x0000)

	Zero()
		return new /pif_LongInt/SignedDouble(0x0000, 0x0000)

/*

Let D(x,y) = (q,r) iff y*q + r = x. Then we have the following where "+" denotes some positive number
and "-" denotes some negative number:

  * D(+,+) -> (+,+)
  * D(+,-) -> (-,+)
  * D(-,+) -> (-,-)
  * D(-,-) -> (+,-)

That is, if Q(x,y) is the quotient of x and y, and if R(x,y) is the remainder of x and y, and
if the relationship y*Q(x,y) + R(x,y) = x holds for all integers x, y, then we have the
following:

  If x, y > 0, then
      Q(x,y), R(x,y) > 0.

  If (x > 0) and (y < 0), then
      Q(x,y) < 0 and
      R(x,y) > 0.

  If (x < 0) and (y > 0), then
      Q(x,y), R(x,y) < 0.

  If x, y < 0, then
      Q(x,y) > 0 and
      R(x,y) < 0.

This pattern holds in the following code because it is set up so that the following four are always
equal:

   Q( x, y)
  -Q(-x, y)
  -Q( x,-y)
   Q(-x,-y)

As an illustrating example,

  * D( 40, 3) -> ( 13, 1) because  3*( 13) + 1 =  40.
  * D( 40,-3) -> (-13, 1) because -3*(-13) + 1 =  40.
  * D(-40, 3) -> (-13,-1) because  3*(-13) - 1 = -40.
  * D(-40,-3) -> ( 13,-1) because -3*( 13) - 1 = -40.

This has the bonus that the following four are also equal,

   R( x, y)
  -R(-x, y)
   R( x,-y)
  -R(-x,-y)

though the downside that remainders may be negative.

*/

	Quotient(...)
		var
			list
				// Processed contains the processed data from the passed arguments. Keep in mind
				// that Processed[1] is least-significant and Processed[2] is most-significant.
				Processed = _Process(args)
				D // Data from the _AlgorithmD method.

			// Where the result is stored.
			pif_LongInt/SignedDouble/Quot

			// The sign of the quotient at the end.
			quotient_sign = 1

			// If on, we have to make a few changes to the source object at the end of the method,
			// before returning Quot.
			swap_sign = 0

		/*
		 * Data processing to account for negatives.
		 */

		if(Processed[2] & 0x8000)
			// If the largest bit is turned on, then Processed is negative and we need to make
			// it positive. This is because Knuth's Algorithm D (and consequently the _Algorithmd()
			// method) only work on two unsigned integers.

			quotient_sign *= -1

			Processed[1] = ~Processed[1]
			Processed[2] = ~Processed[2]

			var
				byte1 = pliBYTE_ONE(Processed[1]) // Least-significant block.
				byte2 = pliBYTE_TWO(Processed[1])
				byte3 = pliBYTE_ONE(Processed[2])
				byte4 = pliBYTE_TWO(Processed[2]) // Most-significant block.

			byte1 ++
			pliADDBUFFER(byte1, byte2)
			pliADDBUFFER(byte2, byte3)
			pliADDBUFFER(byte3, byte4)

			Processed[1] = pliBYTE_ONE(byte1) | pliBYTE_ONE_SHIFTED(byte2)
			Processed[2] = pliBYTE_ONE(byte3) | pliBYTE_ONE_SHIFTED(byte4)

		if(IsNegative())
			quotient_sign *= -1

			// Doing it this way could be a problem if DM ever got asynchronous programming, but
			// that will not be an issue for quite a while I imagine.

			if(mode & NEW_OBJECT)
				// If we're in NEW_OBJECT mode, then at the end we need to swap signs from positive
				// to negative and set NEW_OBJECT mode back on, as right here we're turning it off.
				// Note that if swap_sign is set to 0 we don't have to switch the sign at the end
				// even though we're still switching the sign now. This is because we're not in
				// NEW_OBJECT mode, and the data will be overwritten.
				swap_sign = 1

				SetModeFlag(NEW_OBJECT, 0)
				Negate()
				SetModeFlag(NEW_OBJECT, 1)

			else
				Negate()

		/*
		 * Construct the quotient.
		 */

		D = _AlgorithmD(Processed[1], Processed[2])

		if(mode & NEW_OBJECT)
			Quot = new src.type
		else
			Quot = src

		switch(D[1]) // switch(quot_size)
			// We have the following
			//  * D[2] = q1
			//  * D[3] = q2
			//  * D[4] = q3
			//  * D[5] = q4

			if(1)
				Quot._SetBlock(1, D[2]                             )
				Quot._SetBlock(2, 0                                )

			if(2)
				Quot._SetBlock(1, D[3] | pliBYTE_ONE_SHIFTED(D[2]) )
				Quot._SetBlock(2, 0                                )

			if(3)
				Quot._SetBlock(2, D[2])
				Quot._SetBlock(1, D[4] | pliBYTE_ONE_SHIFTED(D[3]) )

			if(4)
				Quot._SetBlock(2, D[3] | pliBYTE_ONE_SHIFTED(D[2]) )
				Quot._SetBlock(1, D[5] | pliBYTE_ONE_SHIFTED(D[4]) )

		/*
		 * And do final adjustments for sign before returning the quotient.
		 */

		if(swap_sign)
			// We converted the source object from negative to positive and it was in
			// NEW_OBJECT mode, so now we have to set it back.

			SetModeFlag(NEW_OBJECT, 0)
			Negate()
			SetModeFlag(NEW_OBJECT, 1)

		if(quotient_sign < 0)
			// If quotient_sign is negative, then we have to adjust the sign of
			// Quot correctly.
			var/m = Quot.mode & NEW_OBJECT

			Quot.SetModeFlag(NEW_OBJECT, 0)
			Quot.Negate()
			Quot.SetModeFlag(NEW_OBJECT, m)

		return Quot

	Remainder(...)
		var
			list
				Processed = _Process(args)
				D // Data from _AlgorithmD()

			// Where the remainder of division will be stored.
			pif_LongInt/SignedDouble/Rem

			// Sign of the remainder. With our assumptions, it happens that the sign of the
			// remainder coincides with the sign of the dividend (the source object).
			rem_sign = 1

			// True if the sign of the source object needs to be swapped at the end. This happens
			// if NEW_OBJECT mode is off and the source object was negative at the start.
			swap_sign = 0

		/*
		 * Correct for signs, due to _AlgorithmD() needing positive inputs.
		 */

		if(Processed[2] & 0x8000)
			// If the largest bit is turned on, then Processed is negative and we need to make
			// it positive.

			Processed[1] = ~Processed[1]
			Processed[2] = ~Processed[2]

			var
				byte1 = pliBYTE_ONE(Processed[1]) // Least-significant block.
				byte2 = pliBYTE_TWO(Processed[1])
				byte3 = pliBYTE_ONE(Processed[2])
				byte4 = pliBYTE_TWO(Processed[2]) // Most-significant block.

			byte1 ++
			pliADDBUFFER(byte1, byte2)
			pliADDBUFFER(byte2, byte3)
			pliADDBUFFER(byte3, byte4)

			Processed[1] = pliBYTE_ONE(byte1) | pliBYTE_ONE_SHIFTED(byte2)
			Processed[2] = pliBYTE_ONE(byte3) | pliBYTE_ONE_SHIFTED(byte4)

		if(IsNegative())
			rem_sign = -1

			// Doing it this way could be a problem if DM ever got asynchronous programming, but
			// that will not be an issue for quite a while I imagine.

			if(mode & NEW_OBJECT)
				// If we're in NEW_OBJECT mode, then at the end we need to swap signs from positive
				// to negative and set NEW_OBJECT mode back on, as right here we're turning it off.
				// Note that if swap_sign is set to 0 we don't have to switch the sign at the end
				// even though we're still switching the sign now. This is because we're not in
				// NEW_OBJECT mode, and the data will be overwritten.
				swap_sign = 1

				SetModeFlag(NEW_OBJECT, 0)
				Negate()
				SetModeFlag(NEW_OBJECT, 1)

			else
				Negate()

		/*
		 * Construct the remainder.
		 */

		D = _AlgorithmD(Processed[1], Processed[2])

		if(mode & NEW_OBJECT)
			Rem = new src.type
		else
			Rem = src

		var
			byte_1 = 0
			byte_2 = 0
			byte_3 = 0
			byte_4 = 0

			adj = D[13]

		switch(D[11]) // switch(M)
			// We have the following to keep in mind:
			//  * D[ 6] = src0
			//  * D[ 7] = src1
			//  * D[ 8] = src2
			//  * D[ 9] = src3
			//  * D[10] = src4
			//
			// Additionally, M+N < 4.

			if(0)
				switch(D[12]) // switch(N)

					if(1)
						byte_4 = D[7]
					if(2)
						byte_3 = D[7]
						byte_4 = D[8]
					if(3)
						byte_2 = D[7]
						byte_3 = D[8]
						byte_4 = D[9]
					if(4)
						byte_1 = D[7]
						byte_2 = D[8]
						byte_3 = D[9]
						byte_4 = D[10]

			if(1)

				switch(D[12]) // switch(N)

					if(1)
						byte_4 = D[8]
					if(2)
						byte_3 = D[8]
						byte_4 = D[9]
					if(3)
						byte_2 = D[8]
						byte_3 = D[9]
						byte_4 = D[10]

			if(2)

				switch(D[12]) // switch(N)

					if(1)
						byte_4 = D[9]
					if(2)
						byte_3 = D[9]
						byte_4 = D[10]

			if(3)
				byte_4 = D[10]

		// This a highly-abbreviated variation of _AlgorithmD(). It's shorter because
		// we can assume that M = 3, N = 1, and we don't have to worry about finding the
		// remainder (because it's equal to 0).

		var
			q0
			q1
			q2
			q3

			const/BASE = 0x0100

		q0 = pliFLOOR(byte_1 / adj)
		byte_1 -= adj*q0

		q1 = pliFLOOR( (byte_1*BASE + byte_2) / adj)
		byte_1 = (pliBYTE_ONE_SHIFTED(byte_1) | byte_2) - (adj*q1)
		byte_2 = pliDATA(byte_1)

		q2 = pliFLOOR( (byte_2*BASE + byte_3) / adj)
		byte_2 = (pliBYTE_ONE_SHIFTED(byte_2) | byte_3) - (adj*q2)
		byte_3 = pliDATA(byte_2)

		q3 = pliFLOOR( (byte_3*BASE + byte_4) / adj)

		Rem._SetBlock(2, pliBYTE_ONE_SHIFTED(q0) | q1)
		Rem._SetBlock(1, pliBYTE_ONE_SHIFTED(q2) | q3)

		/*
		 * And do final adjustments for sign before returning the remainder.
		 */

		if(swap_sign)
			// We converted the source object from negative to positive and it was in
			// NEW_OBJECT mode, so now we have to set it back.

			SetModeFlag(NEW_OBJECT, 0)
			Negate()
			SetModeFlag(NEW_OBJECT, 1)

		if(rem_sign < 0)

			if(Rem.mode & NEW_OBJECT)
				Rem.SetModeFlag(NEW_OBJECT, 0)
				Rem.Negate()
				Rem.SetModeFlag(NEW_OBJECT, 1)

			else
				Rem.Negate()

		return Rem

	Divide(...)
		var
			list
				Processed = _Process(args)
				D // Data from _AlgorithmD()

			pif_LongInt/SignedDouble
				Quot 			   // Might be a new object depending on the NEW_OBJECT setting.
				Rem = new src.type // Will always be a new object.

			// The sign of the quotient at the end.
			quotient_sign = 1

			// Sign of the remainder. With our assumptions, it happens that the sign of the
			// remainder coincides with the sign of the dividend (the source object).
			rem_sign = 1

			// True if the sign of the source object needs to be swapped at the end. This happens
			// if NEW_OBJECT mode is off and the source object was negative at the start.
			swap_sign = 0

		/*
		 * Correct for signs, due to _AlgorithmD() needing positive inputs.
		 */

		if(Processed[2] & 0x8000)
			// If the largest bit is turned on, then Processed is negative and we need to make
			// it positive.

			quotient_sign *= -1

			Processed[1] = ~Processed[1]
			Processed[2] = ~Processed[2]

			var
				byte1 = pliBYTE_ONE(Processed[1]) // Least-significant block.
				byte2 = pliBYTE_TWO(Processed[1])
				byte3 = pliBYTE_ONE(Processed[2])
				byte4 = pliBYTE_TWO(Processed[2]) // Most-significant block.

			byte1 ++
			pliADDBUFFER(byte1, byte2)
			pliADDBUFFER(byte2, byte3)
			pliADDBUFFER(byte3, byte4)

			Processed[1] = pliBYTE_ONE(byte1) | pliBYTE_ONE_SHIFTED(byte2)
			Processed[2] = pliBYTE_ONE(byte3) | pliBYTE_ONE_SHIFTED(byte4)

		if(IsNegative())
			quotient_sign *= -1
			rem_sign = -1

			// Doing it this way could be a problem if DM ever got asynchronous programming, but
			// that will not be an issue for quite a while I imagine.

			if(mode & NEW_OBJECT)
				// If we're in NEW_OBJECT mode, then at the end we need to swap signs from positive
				// to negative and set NEW_OBJECT mode back on, as right here we're turning it off.
				// Note that if swap_sign is set to 0 we don't have to switch the sign at the end
				// even though we're still switching the sign now. This is because we're not in
				// NEW_OBJECT mode, and the data will be overwritten.
				swap_sign = 1

				SetModeFlag(NEW_OBJECT, 0)
				Negate()
				SetModeFlag(NEW_OBJECT, 1)

			else
				Negate()

		/*
		 * Construct the quotient and remainder.
		 */

		D = _AlgorithmD(Processed[1], Processed[2])

		if(mode & NEW_OBJECT)
			Quot = new src.type
		else
			Quot = src

		/* Constructing the quotient */

		switch(D[1]) // switch(quot_size)
			// We have the following
			//  * D[2] = q1
			//  * D[3] = q2
			//  * D[4] = q3
			//  * D[5] = q4

			if(1)
				Quot._SetBlock(2, 0                                )
				Quot._SetBlock(1, D[2]                             )

			if(2)
				Quot._SetBlock(2, 0                                )
				Quot._SetBlock(1, D[3] | pliBYTE_ONE_SHIFTED(D[2]) )

			if(3)
				Quot._SetBlock(2, D[2])
				Quot._SetBlock(1, D[4] | pliBYTE_ONE_SHIFTED(D[3]) )

			if(4)
				Quot._SetBlock(2, D[3] | pliBYTE_ONE_SHIFTED(D[2]) )
				Quot._SetBlock(1, D[5] | pliBYTE_ONE_SHIFTED(D[4]) )

		/* Constructing the remainder. */

		var
			byte_1 = 0
			byte_2 = 0
			byte_3 = 0
			byte_4 = 0

			adj = D[13]

		switch(D[11]) // switch(M)
			// We have the following to keep in mind:
			//  * D[ 6] = src0
			//  * D[ 7] = src1
			//  * D[ 8] = src2
			//  * D[ 9] = src3
			//  * D[10] = src4
			//
			// Additionally, M+N < 4.

			if(0)
				switch(D[12]) // switch(N)

					if(1)
						byte_4 = D[7]
					if(2)
						byte_3 = D[7]
						byte_4 = D[8]
					if(3)
						byte_2 = D[7]
						byte_3 = D[8]
						byte_4 = D[9]
					if(4)
						byte_1 = D[7]
						byte_2 = D[8]
						byte_3 = D[9]
						byte_4 = D[10]

			if(1)

				switch(D[12]) // switch(N)

					if(1)
						byte_4 = D[8]
					if(2)
						byte_3 = D[8]
						byte_4 = D[9]
					if(3)
						byte_2 = D[8]
						byte_3 = D[9]
						byte_4 = D[10]

			if(2)

				switch(D[12]) // switch(N)

					if(1)
						byte_4 = D[9]
					if(2)
						byte_3 = D[9]
						byte_4 = D[10]

			if(3)
				byte_4 = D[10]

		// This a highly-abbreviated variation of _AlgorithmD(). It's shorter because
		// we can assume that M = 3, N = 1, and we don't have to worry about finding the
		// remainder (because it's equal to 0).

		var
			q0
			q1
			q2
			q3

			const/BASE = 0x0100

		q0 = pliFLOOR(byte_1 / adj)
		byte_1 -= adj*q0

		q1 = pliFLOOR( (byte_1*BASE + byte_2) / adj)
		byte_1 = (pliBYTE_ONE_SHIFTED(byte_1) | byte_2) - (adj*q1)
		byte_2 = pliDATA(byte_1)

		q2 = pliFLOOR( (byte_2*BASE + byte_3) / adj)
		byte_2 = (pliBYTE_ONE_SHIFTED(byte_2) | byte_3) - (adj*q2)
		byte_3 = pliDATA(byte_2)

		q3 = pliFLOOR( (byte_3*BASE + byte_4) / adj)

		Rem._SetBlock(2, pliBYTE_ONE_SHIFTED(q0) | q1)
		Rem._SetBlock(1, pliBYTE_ONE_SHIFTED(q2) | q3)

		/*
		 * Now do adjustement for signs.
		 */

		if(swap_sign)
			// We converted the source object from negative to positive and it was in
			// NEW_OBJECT mode, so now we have to set it back.

			SetModeFlag(NEW_OBJECT, 0)
			Negate()
			SetModeFlag(NEW_OBJECT, 1)

		if(quotient_sign < 0)
			// If quotient_sign is negative, then we have to adjust the sign of
			// Quot correctly.
			var/m = Quot.mode & NEW_OBJECT

			Quot.SetModeFlag(NEW_OBJECT, 0)
			Quot.Negate()
			Quot.SetModeFlag(NEW_OBJECT, m)

		if(rem_sign < 0)

			if(Rem.mode & NEW_OBJECT)
				Rem.SetModeFlag(NEW_OBJECT, 0)
				Rem.Negate()
				Rem.SetModeFlag(NEW_OBJECT, 1)

			else
				Rem.Negate()

		return list(
			Quot,
			Rem
		)
