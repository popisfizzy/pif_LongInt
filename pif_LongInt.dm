#if	!defined(PIF_NOPREFIX_GENERAL) && !defined(PIF_NOPREFIX_LONGINT)
pif_LongInt
#else
LongInt
#endif

#if	!defined(PIF_NOPREFIX_GENERAL) && !defined(PIF_NOPREFIX_ARITHMETIC)
	parent_type = /pif_Arithmetic
#else
	parent_type = /Arithmetic
#endif

	/*
	 * Variables.
	 */

	var
		// By default, we do in-place modification to pif_LongInt objects.
		mode = OLD_OBJECT | NO_OVERFLOW_EXCEPTION | FIXED_PRECISION

	/*
	 * pif_Arithmetic defined methods.
	 */

	Power(n)
		/*
		 * This method is used in all pif_LongInt subclasses, as it is
		 * essentially the same in all of them.
		 */

		if(!isnum(n) || (round(n) != n))
			// n is either non-numeric or a non-integer, so as per the pif_Arithmetic protocol
			// specification we throw this exception.

#if	!defined(PIF_NOPREFIX_GENERAL) && !defined(PIF_NOPREFIX_ARITHMETIC)
			throw new /pif_Arithmetic/NonIntegerException(__FILE__, __LINE__)
#else
			throw new /Arithmetic/NonIntegerException(__FILE__, __LINE__)
#endif

		if(n < 0)
			// n is negative, so by the protocl we throw the following exception.
#if	!defined(PIF_NOPREFIX_GENERAL) && !defined(PIF_NOPREFIX_ARITHMETIC)
			throw new /pif_Arithmetic/NegativeIntegerException(__FILE__, __LINE__)
#else
			throw new /Arithmetic/NegativeIntegerException(__FILE__, __LINE__)
#endif

#if	!defined(PIF_NOPREFIX_GENERAL) && !defined(PIF_NOPREFIX_LONGINT)
		var/pif_LongInt
#else
		var/LongInt
#endif
			Int = new src.type(1)		// The actual result of the power operation.
			Tracker = new src.type(src)	// Computes success squares.

		// Set Int's OVERFLOW_EXCEPTION flag equal to the source object's, so that if Int overflows
		// it will have the same behavior as the source object.
		Int.SetModeFlag(OVERFLOW_EXCEPTION, src.mode & OVERFLOW_EXCEPTION)

		while(n != 0)
			// This is an implementation of exponentiation-by-squaring, which is fairly-efficient
			// algorithm when working with an exponent that is readily -accessed in binary form and
			// when you have a good way of squaring.

			if((n & 0x0001) == 1)
				Int = Int.Multiply(Tracker)

			Tracker = Tracker.Square()
			n >>= 1

		if(!(src.mode & NEW_OBJECT))
			// If we're in OLD_OBJECT mode, set src to Int and return src.
			src.Set(Int)
			return src
		else
			// Otherwise, just return Int.
			return Int

	/*
	 * Custom methods.
	 */

	proc
		// pif_LongInt also supports printing to quaternary, octal, and base-64
		// in addition to what is required by the pif_Arithmetic protocol.

		PrintQuaternary()
		PrintOctal()
		PrintBase64()

#ifdef	PIF_LONGINT_PRINTUNARY

		// And unary, for literally no other reason than as a stupid joke.
		PrintUnary()

#endif
