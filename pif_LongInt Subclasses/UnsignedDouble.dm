/*
 * Implementation of an unsigned double precision (32-bit) integer that uses the
 * pif_Arithmetic protocol (inherited from the /pif_LongInt superclass). It can
 * accurately store numbers between 0 and 4294967295 (between 0x0000 and 0xFFFF).
 */

pif_LongInt/UnsignedDouble
	/*
	 * Variables.
	 */

	var
		block_1 = 0 // Least-significant block.
		block_2 = 0 // Most-significant block.

		const/Length = 2

	/*
	 * Constructor.
	 */

	New(...)

		if(args.len != 0)
			var/list/Processed = _Process(args)

			block_1 = Processed[1]
			block_2 = Processed[2]

		return src

	/*
	 * Miscellaneous methods.
	 */

	proc
		_Process(list/arguments)
			// Does the processing for GAAF format arguments.

			if(arguments.len == 0)
				// No arguments passed is treated as if 0 passed.
				return list(0, 0)

			. = list(null, null)
			var/datum/Int = arguments[1]

			if(istype(Int, /pif_LongInt))
				// It's a /pif_LongInt object, so we can readily read directly from
				// it.

				if((Int:Length() > Length) && !(mode & OVERFLOW_EXCEPTION))
					// If it's too long for the source object and the OVERFLOW_EXCEPTION mode
					// is ennabled, then throw the relevant exception.
					throw new /pif_Arithmetic/OverflowException(__FILE__, __LINE__)

				else
					// Otherwise, just read from it.

					.[1] = Int:_GetBlock(1)
					.[2] = Int:_GetBlock(2)

			else if(istype(Int))
				// If it's another /datum type, we assume it's implementing the /pif_Arithmetic
				// protocol.

				var/pif_Arithmetic/Obj = Int

				if((Obj.Length() > Length) && !(mode & OVERFLOW_EXCEPTION))
					// As above, throw the OverflowException if necessary.
					throw new /pif_Arithmetic/OverflowException(__FILE__, __LINE__)

				else
					.[1] = Obj._GetBlock(1)
					.[2] = Obj._GetBlock(2)

			else if(istext(Int))
				// Currently only implemented for binary, hexadecimal, and decimal
				// strings in the beta version.

				if(findtext(Int, "0b", 1, 3))
					// A binary-encoded string was passed.

					var
						pif_LongInt/UnsignedDouble/Tracker = new src.type

						length = length(Int) - 2

					Tracker.SetModeFlag(NEW_OBJECT, 0)

					for(var/i = length, i > 0, i --)
						var/c = text2ascii(Int, i+2) - 48

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

					.[1] = Tracker._GetBlock(1)
					.[2] = Tracker._GetBlock(2)

				else if(findtext(Int, "0x", 1, 3))
					// A hexadecimal-encoded string was passed.

					Int = uppertext(Int)

					var
						pif_LongInt/UnsignedDouble/Tracker = new src.type

						length = length(Int) - 2

					Tracker.SetModeFlag(NEW_OBJECT, 0)

					for(var/i = length, i > 0, i --)
						var/c = text2ascii(Int, i+2) - 48
						if(c > 9)
							c -= 7

						if( (c < 0) || (c > 15) )
							// If we've encountered an invalid character, throw an exception.
							throw new /pif_Arithmetic/InvalidStringEncodingException(__FILE__, __LINE__)

						if((length - i) < 4)
							Tracker.Add(0x0000, c << 4*(length - i))
						else if((length - i) < 8)
							Tracker.Add(c << 4*((length - i) - 4), 0x0000)
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

					.[1] = Tracker._GetBlock(1)
					.[2] = Tracker._GetBlock(2)

				else
					// Anything else and we assume a decimal-encoded string was passed. This method
					// seems a bit slow, so I'd love to figure out a faster version.

					var
						pif_LongInt/UnsignedDouble
							RadixTracker = new src.type(1) // Tracks the radix.
							Buffer = new src.type // Temporarily holds a product.

							Tracker = new src.type // Tracks the final value.

							length = length(Int)

					RadixTracker.SetModeFlag(OVERFLOW_EXCEPTION, mode & OVERFLOW_EXCEPTION)
					RadixTracker.SetModeFlag(NEW_OBJECT, 0)

					Tracker.SetModeFlag(NEW_OBJECT, 0)
					Buffer.SetModeFlag(NEW_OBJECT, 0)

					for(var/i = 0, i < length, i ++)
						var/c = text2ascii(Int, length-i) - 48

						if((c < 0) || (c > 9))
							// If we've encountered an invalid character, throw an exception.
							throw new /pif_Arithmetic/InvalidStringEncodingException(__FILE__, __LINE__)

						if(c != 0)
							// If c is non-zero, then computer the corresponding value,
							// store it in the buffer, and add it to the tracker.

							Buffer.Set(c)
							Tracker.Add(Buffer.Multiply(RadixTracker))

						RadixTracker.Multiply(10)

					.[1] = Tracker._GetBlock(1)
					.[2] = Tracker._GetBlock(2)

			else if(istype(Int, /list))
				// It's a left-significant list.

				if((Int:len > Length) && !(mode & OVERFLOW_EXCEPTION))
					// Too long and we need to throw the OverflowException.
					throw new /pif_Arithmetic/OverflowException(__FILE__, __LINE__)

				else

					// How we allocate the blocks depends on the size of the
					// list, due to it being left-significant while the notation
					// of our blocks is right-significant.

					switch(Int:len)

						if(1)
							.[1] = Int[1]
							.[2] = 0

						if(2)
							.[1] = Int[2]
							.[2] = Int[1]

						else
							// Assign the blocks to the last two blocks of the list.
							.[1] = Int[Int:len]
							.[2] = Int[Int:len-1]

					if(!isnum(block_1) || !isnum(block_2) || (round(block_1) != block_1) || (round(block_2) != block_2))
						// Non-integer data was found. We need to throw the NonIntegerException.
						throw new /pif_Arithmetic/NonIntegerException(__FILE__, __LINE__)

					// Even though this is an unsigned integer, we'll accept negative values and
					// simply treat them as a bitstream.

			else if(isnull(Int))
				// Treat null as 0.

				.[1] = 0
				.[2] = 0

			else
				// Otherwise, we treat it as an argument list of integers.

				if((arguments.len > Length) && !(mode & OVERFLOW_EXCEPTION))
					// Too long and need to throw OverflowException.
					throw new /pif_Arithmetic/OverflowException(__FILE__, __LINE__)

				else
					// Once again, it's a list so we allocate differently depending on
					// its size.

					switch(arguments.len)

						if(1)
							.[1] = arguments[1]
							.[2] = 0

						if(2)
							.[1] = arguments[2]
							.[2] = arguments[1]

						else
							.[1] = arguments[arguments.len]
							.[2] = arguments[arguments.len-1]

			return .

	/*
	 * "Private" methods.
	 */

	_GetBlock(i)
		if(!isnum(i))
			throw new /pif_Arithmetic/NonIntegerException(__FILE__, __LINE__)
		if(i <= 0)
			throw new /pif_Arithmetic/NonPositiveIntegerException(__FILE__, __LINE__)
		if(i > Length)
			throw new /pif_Arithmetic/OutOfBoundsException(__FILE__, __LINE__)

		return (i == 1) ? block_1 : block_2

	_SetBlock(i, j)
		if(!isnum(i) || !isnum(j))
			throw new /pif_Arithmetic/NonIntegerException(__FILE__, __LINE__)
		if(i <= 0)
			throw new /pif_Arithmetic/NonPositiveIntegerException(__FILE__, __LINE__)
		if(i > Length)
			throw new /pif_Arithmetic/OutOfBoundsException(__FILE__, __LINE__)

		if(i == 1)
			block_1 = j
			return block_1
		else
			block_2 = j
			return block_2

	/*
	 * Arithmetic methods.
	 */

	Add(...)

		/*
		 * Argument processing and assignment of variables.
		 */

		var
			list/Processed = _Process(args)

			Int_block_1 = Processed[1] // Least significant.
			Int_block_2 = Processed[2] // Most significant.

			pif_LongInt/UnsignedDouble/Sum

		if(mode & NEW_OBJECT)
			Sum = new src.type(src)
		else
			Sum = src

		/*
		 * Now we do the actual computation.
		 */

		var
			// Used to store the result of addition before being sent to
			// the Sum object. These are the first and second bytes of
			// a given block, respectively.
			B1 = 0
			B2 = 0

		// Compute the first block.

		B1 = pliBYTE_ONE(block_1) + pliBYTE_ONE(Int_block_1)
		B2 = pliBYTE_TWO(block_1) + pliBYTE_TWO(Int_block_1) + pliBUFFER(B1)

		Sum._SetBlock(1, pliBYTE_ONE(B1) | pliBYTE_ONE_SHIFTED(B2))

		// And the second block.

		B1 = pliBYTE_ONE(block_2) + pliBYTE_ONE(Int_block_2) + pliBUFFER(B2)
		B2 = pliBYTE_TWO(block_2) + pliBYTE_TWO(Int_block_2) + pliBUFFER(B1)

		Sum._SetBlock(2, pliBYTE_ONE(B1) | pliBYTE_ONE_SHIFTED(B2))

		if( (pliBUFFER(B2) != 0) && (mode & OVERFLOW_EXCEPTION) )
			// If B2's buffer is not equal to zero, then we overflowed and need
			// to throw the OverflowException if it's flag set.

			throw new /pif_Arithmetic/OverflowException(__FILE__, __LINE__)

		return Sum

	Subtract(...)

		/*
		 * Argument processing and assignment of variables.
		 */

		var
			list/Processed = _Process(args)

			Int_block_1 = Processed[1] // Least significant.
			Int_block_2 = Processed[2] // Most significant.

			pif_LongInt/UnsignedDouble/Diff

		if(mode & NEW_OBJECT)
			Diff = new src.type(src)
		else
			Diff = src

		/*
		 * Now we do the actual computation.
		 */

		var
			// Used to store the result of addition before being sent to
			// the Sum object. These are the first and second bytes of
			// a given block, respectively.
			B1 = 0
			B2 = 0

		// Compute the first block. The computation is largely the same as
		// in addition, except that for each step we take the bitwise not
		// of the relevant Int block, as well as adding 1 to the first part
		// of Int_block_1. In two's complement notation, this is equivalent
		// to negating it.

		B1 = pliBYTE_ONE(block_1) + pliBYTE_ONE_N(Int_block_1) + 1 // Adding one for negation.
		B2 = pliBYTE_TWO(block_1) + pliBYTE_TWO_N(Int_block_1) + pliBUFFER(B1)

		Diff._SetBlock(1, pliBYTE_ONE(B1) | pliBYTE_ONE_SHIFTED(B2))

		// And now the second block.

		B1 = pliBYTE_ONE(block_2) + pliBYTE_ONE_N(Int_block_2) + pliBUFFER(B2)
		B2 = pliBYTE_TWO(block_2) + pliBYTE_TWO_N(Int_block_2) + pliBUFFER(B1)

		Diff._SetBlock(2, pliBYTE_ONE(B1) | pliBYTE_ONE_SHIFTED(B2))

		if( (pliBUFFER(B2) == 0) && (mode & OVERFLOW_EXCEPTION) )
			// If B2's buffer is equal to zero, then there was a negative
			// overflow. Thus, we need to possibly throw the OverflowException.

			throw new /pif_Arithmetic/OverflowException(__FILE__, __LINE__)

		return Diff

	Multiply(...)
		var
			list/Processed = _Process(args)

			Int_block_1 = Processed[1] // Least significant.
			Int_block_2 = Processed[2] // Most significant.

			pif_LongInt/UnsignedDouble/Prod

		if(mode & NEW_OBJECT)
			Prod = new src.type(null)
		else
			Prod = src

		/*
		 * Computation of multiplication.
		 *

		The idea beihind the following method is this: Let A and B be two integers between 0 and
		2**32 - 1. Then if R = 256, we may write them each as

		  A = R**3 a_3 + R**2 a_2 + R a_1 + a_0
		  B = R**3 b_3 + R**2 b_2 + R b_1 + b_0

		where a_n and b_n are between 0 and 255 (for n = 0, 1, 2, 3). If we take the product A*B of
		A and B, then rearrange the terms so that terms with the same power of R as coefficients are
		grouped together, we then get

		  A*B = R**6 (a_3*b_3) + R**5 (a_3*b_2 + a_2*b_3) + R**4 (a_3*b_1 + a_2*b_2 + a_1*b_3) +
		        R**3 (a_3*b_0 + a_2*b_1 + a_1*b_2 + a_0*b_3) + R**2 (a_2*b_0 + a_1*b_1 + a_0*b_1) +
		        R (a_1*c_0 + a_0*c_1) + a_0*b_0.

		Then note that R**4 = 256**4 = (2**8)**4 = 2**32. But, 2**32 > 2**32 - 1, so each term with
		a coefficienet larger than R**3 will be larger than 2**32 - 1 and too large to store in this
		object. Therefore, they are simply discarded.

		Instead, we will only compute the terms whose coefficients are R**3, R**2, R**1 == R, or
		R**0 == 1. We'll do a quick check for the others if we must check for overflow.

		*/

		var
			// These are the bytes of both src and Int.

			src0 = pliBYTE_ONE(block_1)		// Least significant.
			src1 = pliBYTE_TWO(block_1)
			src2 = pliBYTE_ONE(block_2)
			src3 = pliBYTE_TWO(block_2)		// Most significant.

			Int0 = pliBYTE_ONE(Int_block_1)	// Least significant.
			Int1 = pliBYTE_TWO(Int_block_1)
			Int2 = pliBYTE_ONE(Int_block_2)
			Int3 = pliBYTE_TWO(Int_block_2)	// Most significant.

			// Bytes of the final result. We will only use the first byte of each, while
			// the second byte will be used as a buffer to temporarily store bits until we
			// shift them to the next byte. E.g., byte_1 = XXXX FFFF, where XXXX is data that
			// will be moved to the first byte of byte_2.

			prod_1 = 0
			prod_2 = 0
			prod_3 = 0
			prod_4 = 0

			// A buffer used to temporarily store results of multiplication.
			buffer

			// Set if overflow is detected.
			overflow_flag = 0

		/*

		Compute the terms with a coefficient of R**0 == 1. If we assume that src0 == Int0 == 0x00FF--which is the
		largest value that can be stored in one byte--then src0*Int0 = 0xFE01. In other words, for arbitrary src0
		and Int0, their product is at most 0xFE01, which can be stored inone byte. Thus, we'll just store it in
		prod_1 and take its buffer into prod_2.

		Because we have a coefficient of R**0 == 1, we start adding to prod_1.

		*/

		prod_1 = src0*Int0

		pliADDBUFFER(prod_1, prod_2)
		pliFLUSH(prod_1)

		/*

		Now compute terms with a coefficient of R**1. Assuming all terms are 0xFF, then the largest integer that
		can result from src1*Int0 + src0*Int1 is given by 0x2*(0xFF*0xFF) = 0x2*0xFE01 = 0x1FC02. Thus, we must
		take the buffer and move it into the next byte.

		Because we have a coefficient of R**1 == R, we start adding to prod_2.

		*/

		buffer  = src1*Int0

		pliADDDATA(buffer, prod_2)
		prod_3 = pliBUFFER(buffer) + pliBUFFER(prod_2)
		pliFLUSH(prod_2)

		buffer  = src0*Int1

		pliADDDATA(buffer, prod_2)
		prod_3 += pliBUFFER(buffer) + pliBUFFER(prod_2)
		pliADDBUFFER(prod_3, prod_4) // Still zero up to this point, and pliBUFFER is at most 255, so we don't need
								  // to worry about flushing it.

		pliFLUSH(prod_2)
		pliFLUSH(prod_3)

		/*

		Compute the terms with a coefficient of R**2. Once again, assuming all terms are 0xFF then the largest
		integer than can result is src2*Int0 + src1*Int1 + src0*Int2 = 0x3*(0xFF*0xFF) = 0x3*0xFE01 = 0x2FA03.
		The integer may overflow at this step, so we'll check if it's required.

		Because we have a coefficient of R**2, we start adding to prod_3.

		*/

		if(overflow_flag || !(mode & OVERFLOW_EXCEPTION))
			// Don't bother checking for overflow.

			buffer  = src2*Int0

			pliADDDATA(buffer, prod_3)
			prod_4 += pliBUFFER(buffer) + pliBUFFER(prod_3)
			pliFLUSH(prod_3)
			pliFLUSH(prod_4)

			buffer  = src1*Int1

			pliADDDATA(buffer, prod_3)
			prod_4 += pliBUFFER(buffer) + pliBUFFER(prod_3)
			pliFLUSH(prod_3)
			pliFLUSH(prod_4)

			buffer  = src0*Int2

			pliADDDATA(buffer, prod_3)
			prod_4 += pliBUFFER(buffer) + pliBUFFER(prod_3)
			pliFLUSH(prod_3)
			pliFLUSH(prod_4)

		else
			// Check for it.

			buffer  = src2*Int0

			pliADDDATA(buffer, prod_3)
			prod_4 += pliBUFFER(buffer) + pliBUFFER(prod_3)
			if(!overflow_flag && (pliBUFFER(prod_4) != 0))
				overflow_flag = 1
			pliFLUSH(prod_3)
			pliFLUSH(prod_4)

			buffer  = src1*Int1

			pliADDDATA(buffer, prod_3)
			prod_4 += pliBUFFER(buffer) + pliBUFFER(prod_3)
			if(!overflow_flag && (pliBUFFER(prod_4) != 0))
				overflow_flag = 1
			pliFLUSH(prod_3)
			pliFLUSH(prod_4)

			buffer  = src0*Int2

			pliADDDATA(buffer, prod_3)
			prod_4 += pliBUFFER(buffer) + pliBUFFER(prod_3)
			if(!overflow_flag && (pliBUFFER(prod_4) != 0))
				overflow_flag = 1
			pliFLUSH(prod_3)
			pliFLUSH(prod_4)

		/*

		And lastly, the terms with a coefficient of R**3. One again, assuming largest terms the
		largest integer that can result is src3*Int0 + src2*Int1 + src1*Int2 + src0*Int3 = 0x4*0xFE01
		= 0x3F804. The integer may overflow at this step, so we'll check for this if we need to.

		Because we have a coefficient of R**3, we start adding at prod_4.

		*/

		if(overflow_flag || !(mode & OVERFLOW_EXCEPTION))
			// If we arent' checking for overflow, then we can directly add the data to prod_4
			// and flush at the end.

			prod_4 += pliDATA(src3*Int0)
			prod_4 += pliDATA(src2*Int1)
			prod_4 += pliDATA(src1*Int2)
			prod_4 += pliDATA(src0*Int3)

			pliFLUSH(prod_4)

		else

			prod_4 += src3*Int0
			if(!overflow_flag && (pliBUFFER(prod_4) != 0))
				overflow_flag = 1

			prod_4 += src2*Int1
			if(!overflow_flag && (pliBUFFER(prod_4) != 0))
				overflow_flag = 1

			prod_4 += src1*Int2
			if(!overflow_flag && (pliBUFFER(prod_4) != 0))
				overflow_flag = 1

			prod_4 += src0*Int3
			if(!overflow_flag && (pliBUFFER(prod_4) != 0))
				overflow_flag = 1

		// Now we check the last few situations that could have caused an overflow.
		// These particular products were large enough that we did not compute them
		// because they can not be stored. Therefore, if any of them are non-zero then
		// there is an overflow.

		if(!overflow_flag && (mode & OVERFLOW_EXCEPTION))
			// R**6 (a_3*b_3) + R**5 (a_3*b_2 + a_2*b_3) + R**4 (a_3*b_1 + a_2*b_2 + a_1*b_3)

			overflow_flag = ( (src3 != 0) && ( (Int3 != 0) || (Int2 != 0) || (Int1 != 0) )) || \
							( (src2 != 0) && ( (Int3 != 0) && (Int2 != 0) ) ) || \
							( (src1 != 0) && (Int3 != 0) )

		/*
		 * We have computed the result, so glue the bytes back together in the proper way and return the
		 * result.
		 */

		Prod._SetBlock(1, prod_1 | pliBYTE_ONE_SHIFTED(prod_2) )
		Prod._SetBlock(2, prod_3 | pliBYTE_ONE_SHIFTED(prod_4) )

		if(overflow_flag && (mode & OVERFLOW_EXCEPTION))
			// If overflow occured and we need to report it, then throw the OverflowException.
			throw new /pif_Arithmetic/OverflowException(__FILE__, __LINE__)

		return Prod

	proc/_AlgorithmD(Int_block_1, Int_block_2)
		// This is an implementation of Knuth's Algorithm D. The algorithm is described
		// in The Art of Computer Programming, Volume 2: Seminumerical Methods on pages
		// 237 and 238.

		// Unfortunately, due to unrolling the loops this method is both long and repetitious,
		// but given trying to make these operations fast this is essentially an inevitability.

		// This method is used in the Quotient(), Remainder(), and Divide() methods.

		var
			// These are (per Knuth's notation) in decreasing significance, as opposed to
			// the other methods where lower numbers indicate lower significance.

			// Bytes of the src object.
			src0 = 0 // Used once we "normalize" the data.
			src1 = pliBYTE_TWO(block_2)
			src2 = pliBYTE_ONE(block_2)
			src3 = pliBYTE_TWO(block_1)
			src4 = pliBYTE_ONE(block_1)

			// Bytes of the Int data.
			Int1 = pliBYTE_TWO(Int_block_2)
			Int2 = pliBYTE_ONE(Int_block_2)
			Int3 = pliBYTE_TWO(Int_block_1)
			Int4 = pliBYTE_ONE(Int_block_1)

			// Bytes of the result.
			q0 = 0
			q1 = 0
			q2 = 0
			q3 = 0

			// Number of bytes in the quotient.
			quot_size

			// Because we're working on single bytes, we're essentially working in base
			// 256.
			const/base = 0x0100

			M // Number of non-zero bytes in src, in excess of N below.
			N // Number of non-zero bytes in Int.

			adj // "Normalization" factor.

		/*
		 * Compute M and N.
		 */

		N = (Int1 != 0) ? 4 : (
				(Int2 != 0) ? 3 : (
					(Int3 != 0) ? 2 : (
						(Int4 != 0) ? 1 : 0
					)
				)
			)
		M = (src1 != 0) ? 4 : (
				(src2 != 0) ? 3 : (
					(src3 != 0) ? 2 : (
						(src4 != 0) ? 1 : 0
					)
				)
			)

		if(N == 0)
			// In this case, Int == 0, and we're dividing by zero.
			throw EXCEPTION("Divide-by-zero error.")
		else if(M < N)
			// If M < N, then src < Int => src / Int = 0.

			return list(
				// Used for finding the quotient.
				1,								// Size of the quotient, in bytes.
				0, 0, 0, 0, 					// Pieces of the quotient.

				// Used for finding the remainder.
				src0, src1, src2, src3, src4,	// Pieces of src.
				0, 4,							// We divide (src(M+1), ..., src(M+N)) by adj in order
												// to get the remainder.
				1								// Factor to divide the src values by in order
												// to get the remainder.
			)

		// Otherwise, we set M to the amount in excess of N.
		M -= N

		switch(M+N)
			// We want src1 to be the largest non-zero byte of src, so we do a little
			// shifting around to get there.

			if(1)
				src1 = src4

				src2 = 0
				src3 = 0
				src4 = 0

			if(2)
				src1 = src3
				src2 = src4

				src3 = 0
				src4 = 0

			if(3)
				src1 = src2
				src2 = src3
				src3 = src4

				src4 = 0

			// The case of (M+N) == 4 is how the integers are already arranged, so we
			// don't change anything.

		switch(N)
			// Likewise, we want Int1 to be the largest non-zero byte of Int.

			if(1)
				Int1 = Int4

				Int2 = 0
				Int3 = 0
				Int4 = 0

			if(2)
				Int1 = Int3
				Int2 = Int4

				Int3 = 0
				Int4 = 0

			if(3)
				Int1 = Int2
				Int2 = Int3
				Int3 = Int4

				Int4 = 0

		// Step D1 [Normalize].

		// Now we compute the normalization factor. This term is used to make sure that
		// Int1 >= pliFLOOR(base / 2).
		adj = pliFLOOR(base / (Int1 + 1))

		// We multiply both Int and src by adj. Int will always remain the same number
		// of bytes, but src may gain one extra. This is why src0 is defined.

		Int4 *=  adj
		Int3  = (adj*Int3) + pliBUFFER(Int4)
		Int2  = (adj*Int2) + pliBUFFER(Int3)
		Int1  = (adj*Int1) + pliBUFFER(Int2)

		pliFLUSH(Int1)
		pliFLUSH(Int2)
		pliFLUSH(Int3)
		pliFLUSH(Int4)

		src4 *=  adj
		src3  = (adj*src3) + pliBUFFER(src4)
		src2  = (adj*src2) + pliBUFFER(src3)
		src1  = (adj*src1) + pliBUFFER(src2)
		src0  = pliBUFFER(src1) // Since src0 = 0 from the get go, (adj*src0) = 0.

		pliFLUSH(src0)
		pliFLUSH(src1)
		pliFLUSH(src2)
		pliFLUSH(src3)
		pliFLUSH(src4)

		/*
		 * Computation.
		 */

		var
			// qhat is an estimation of q_j which is adjusted to get an accurate answer.
			qhat

			// Buffers for multiplying Int*qhat.
			i0
			i1
			i2
			i3
			i4

			// A flag for if we rolled over in step D4, because we have to adjust for it in
			// step D6.
			rollover_flag = 0

		/*

		First "iteration", with j := 0.

		*/

		// Step D3 [Calculate q-hat.]

		if(src0 == Int1)	qhat = base - 1
		else				qhat = pliFLOOR( (src0*base + src1) / Int1 )

		while( (Int2*qhat) > ((src0*base + src1 - Int1*qhat)*base + src2) )
			qhat --

		// Step D4 [Multiply and subtract.]

		if(qhat != 0)
			// When qhat == 0, nothing would change so we'll just skip this step. Otherwise,
			// we proceed..

			i4 = qhat*Int4
			i3 = qhat*Int3 + pliBUFFER(i4)
			i2 = qhat*Int2 + pliBUFFER(i3)
			i1 = qhat*Int1 + pliBUFFER(i2)
			i0 = pliBUFFER(i1)

			pliFLUSH(i0)
			pliFLUSH(i1)
			pliFLUSH(i2)
			pliFLUSH(i3)
			pliFLUSH(i4)

			switch(N)
				// We have to change how subtraction is done depending on the value of
				// N (i.e., the position that Int1 and the rest actually correspond
				// to).

				if(1)
					src1 = pliBYTE_ONE(src1) + pliBYTE_ONE_N(i1) + 1
					src0 = pliBYTE_ONE(src0) + pliBYTE_ONE_N(i0) + pliBUFFER(src1)

				if(2)
					src2 = pliBYTE_ONE(src2) + pliBYTE_ONE_N(i2) + 1
					src1 = pliBYTE_ONE(src1) + pliBYTE_ONE_N(i1) + pliBUFFER(src2)
					src0 = pliBYTE_ONE(src0) + pliBYTE_ONE_N(i0) + pliBUFFER(src1)

				if(3)
					src3 = pliBYTE_ONE(src3) + pliBYTE_ONE_N(i3) + 1
					src2 = pliBYTE_ONE(src2) + pliBYTE_ONE_N(i2) + pliBUFFER(src3)
					src1 = pliBYTE_ONE(src1) + pliBYTE_ONE_N(i1) + pliBUFFER(src2)
					src0 = pliBYTE_ONE(src0) + pliBYTE_ONE_N(i0) + pliBUFFER(src1)

				if(4)
					src4 = pliBYTE_ONE(src4) + pliBYTE_ONE_N(i4) + 1
					src3 = pliBYTE_ONE(src3) + pliBYTE_ONE_N(i3) + pliBUFFER(src4)
					src2 = pliBYTE_ONE(src2) + pliBYTE_ONE_N(i2) + pliBUFFER(src3)
					src1 = pliBYTE_ONE(src1) + pliBYTE_ONE_N(i1) + pliBUFFER(src2)
					src0 = pliBYTE_ONE(src0) + pliBYTE_ONE_N(i0) + pliBUFFER(src1)

			if(pliBUFFER(src0) == 0)
				// If pliBUFFER(src0) == 0, then we rolled over and need to set
				// the relevant flag.
				rollover_flag = 1
			else
				rollover_flag = 0

			pliFLUSH(src0)
			pliFLUSH(src1)
			pliFLUSH(src2)
			pliFLUSH(src3)
			pliFLUSH(src4)

			// Step D5 [Test remainder.]

			q0 = qhat

			// Step D6 [Add back.]

			if(rollover_flag)
				// Subtract one to account for the rollover.

				q0 --

				// And add Int to (src0, ..., srcN). As above with subtraction, we need to know the
				// value of N in order to figure out how to add correctly.

				switch(N)

					if(1)
						src1 = pliBYTE_ONE(src1) + pliBYTE_ONE(Int1)
						src0 = pliBYTE_ONE(src0)                  + pliBUFFER(src1)

					if(2)
						src2 = pliBYTE_ONE(src2) + pliBYTE_ONE(Int2)
						src1 = pliBYTE_ONE(src1) + pliBYTE_ONE(Int1) + pliBUFFER(src2)
						src0 = pliBYTE_ONE(src0)                  + pliBUFFER(src1)

					if(3)
						src3 = pliBYTE_ONE(src3) + pliBYTE_ONE(Int3)
						src2 = pliBYTE_ONE(src2) + pliBYTE_ONE(Int2) + pliBUFFER(src3)
						src1 = pliBYTE_ONE(src1) + pliBYTE_ONE(Int1) + pliBUFFER(src2)
						src0 = pliBYTE_ONE(src0)                  + pliBUFFER(src1)

					if(4)
						src4 = pliBYTE_ONE(src4) + pliBYTE_ONE(Int4)
						src3 = pliBYTE_ONE(src3) + pliBYTE_ONE(Int3) + pliBUFFER(src4)
						src2 = pliBYTE_ONE(src2) + pliBYTE_ONE(Int2) + pliBUFFER(src3)
						src1 = pliBYTE_ONE(src1) + pliBYTE_ONE(Int1) + pliBUFFER(src2)
						src0 = pliBYTE_ONE(src0)                  + pliBUFFER(src1)

				pliFLUSH(src0)
				pliFLUSH(src1)
				pliFLUSH(src2)
				pliFLUSH(src3)
				pliFLUSH(src4)

		quot_size = 1

		/*

		Second "iteration", with j := 1.

		*/

		if(1 <= M)
			// Equivalently, if(j <= M). We only proceed so long as j is at least
			// as large as M.

			// Step D3 [Calculate q-hat.]

			if(src1 == Int1)	qhat = base - 1
			else				qhat = pliFLOOR( (src1*base + src2) / Int1 )

			while( (Int2*qhat) > ((src1*base + src2 - Int1*qhat)*base + src3) )
				qhat --

			// Step D4 [Multiply and subtract.]

			if(qhat != 0)
			// When qhat == 0, nothing would change so we'll just skip this step. Otherwise,
			// we proceed.

				i4 = qhat*Int4
				i3 = qhat*Int3 + pliBUFFER(i4)
				i2 = qhat*Int2 + pliBUFFER(i3)
				i1 = qhat*Int1 + pliBUFFER(i2)
				i0 = pliBUFFER(i1)

				pliFLUSH(i0)
				pliFLUSH(i1)
				pliFLUSH(i2)
				pliFLUSH(i3)
				pliFLUSH(i4)

				switch(N)
					// We have to change how subtraction is done depending on the value of
					// N (i.e., the position that Int1 and the rest actually correspond
					// to).

					if(1)
						src2 = pliBYTE_ONE(src2) + pliBYTE_ONE_N(i1) + 1
						src1 = pliBYTE_ONE(src1) + pliBYTE_ONE_N(i0) + pliBUFFER(src2)

					if(2)
						src3 = pliBYTE_ONE(src3) + pliBYTE_ONE_N(i2) + 1
						src2 = pliBYTE_ONE(src2) + pliBYTE_ONE_N(i1) + pliBUFFER(src3)
						src1 = pliBYTE_ONE(src1) + pliBYTE_ONE_N(i0) + pliBUFFER(src2)

					if(3)
						src4 = pliBYTE_ONE(src4) + pliBYTE_ONE_N(i3) + 1
						src3 = pliBYTE_ONE(src3) + pliBYTE_ONE_N(i2) + pliBUFFER(src4)
						src2 = pliBYTE_ONE(src2) + pliBYTE_ONE_N(i1) + pliBUFFER(src3)
						src1 = pliBYTE_ONE(src1) + pliBYTE_ONE_N(i0) + pliBUFFER(src2)

					// If N == 4, then this entire iteration will not be performed.

				if(pliBUFFER(src1) == 0)
					// If pliBUFFER(src0) == 0, then we rolled over and need to set
					// the relevant flag.
					rollover_flag = 1
				else
					rollover_flag = 0

				pliFLUSH(src1)
				pliFLUSH(src2)
				pliFLUSH(src3)
				pliFLUSH(src4)

				// Step D5 [Test remainder.]

				q1 = qhat

				// Step D6 [Add back.]

				if(rollover_flag)
					// Subtract one to account for the rollover.

					q1 --

					// And add Int to (src1, ..., srcN). As above with subtraction, we need to know the
					// value of N in order to figure out to figure out how to add correctly.

					switch(N)

						if(1)
							src2 = pliBYTE_ONE(src2) + pliBYTE_ONE(Int1)
							src1 = pliBYTE_ONE(src1)                  + pliBUFFER(src2)

						if(2)
							src3 = pliBYTE_ONE(src3) + pliBYTE_ONE(Int2)
							src2 = pliBYTE_ONE(src2) + pliBYTE_ONE(Int1) + pliBUFFER(src3)
							src1 = pliBYTE_ONE(src1)                  + pliBUFFER(src2)

						if(3)
							src4 = pliBYTE_ONE(src4) + pliBYTE_ONE(Int3)
							src3 = pliBYTE_ONE(src3) + pliBYTE_ONE(Int2) + pliBUFFER(src4)
							src2 = pliBYTE_ONE(src2) + pliBYTE_ONE(Int1) + pliBUFFER(src3)
							src1 = pliBYTE_ONE(src1)                  + pliBUFFER(src2)

					pliFLUSH(src1)
					pliFLUSH(src2)
					pliFLUSH(src3)
					pliFLUSH(src4)

			quot_size = 2

		/*

		Third "iteration", with j := 2.

		*/

		if(2 <= M)
			// Equivalently, if(j <= M). We only proceed so long as j is at least
			// as large as M.

			// Step D3 [Calculate q-hat.]

			if(src2 == Int1)	qhat = base - 1
			else				qhat = pliFLOOR( (src2*base + src3) / Int1 )

			while( (Int2*qhat) > ((src2*base + src3 - Int1*qhat)*base + src4) )
				qhat --

			// Step D4 [Multiply and subtract.]

			if(qhat != 0)
			// When qhat == 0, nothing would change so we'll just skip this step. Otherwise,
			// we proceed..

				i4 = qhat*Int4
				i3 = qhat*Int3 + pliBUFFER(i4)
				i2 = qhat*Int2 + pliBUFFER(i3)
				i1 = qhat*Int1 + pliBUFFER(i2)
				i0 = pliBUFFER(i1)

				pliFLUSH(i0)
				pliFLUSH(i1)
				pliFLUSH(i2)
				pliFLUSH(i3)
				pliFLUSH(i4)

				switch(N)
					// We have to change how subtraction is done depending on the value of
					// N (i.e., the position that Int1 and the rest actually correspond
					// to).

					if(1)
						src3 = pliBYTE_ONE(src3) + pliBYTE_ONE_N(i1) + 1
						src2 = pliBYTE_ONE(src2) + pliBYTE_ONE_N(i0) + pliBUFFER(src3)

					if(2)
						src4 = pliBYTE_ONE(src4) + pliBYTE_ONE_N(i2) + 1
						src3 = pliBYTE_ONE(src3) + pliBYTE_ONE_N(i1) + pliBUFFER(src4)
						src2 = pliBYTE_ONE(src2) + pliBYTE_ONE_N(i0) + pliBUFFER(src3)

					// If N == 3 or N == 4, then this entire iteration will not be performed.

				if(pliBUFFER(src2) == 0)
					// If pliBUFFER(src0) == 0, then we rolled over and need to set
					// the relevant flag.
					rollover_flag = 1
				else
					rollover_flag = 0

				pliFLUSH(src2)
				pliFLUSH(src3)
				pliFLUSH(src4)

				// Step D5 [Test remainder.]

				q2 = qhat

				// Step D6 [Add back.]

				if(rollover_flag)
					// Subtract one to account for the rollover.

					q2 --

					// And add Int to (src2, ..., srcN). As above with subtraction, we need to know the
					// value of N in order to figure out to figure out how to add correctly.

					switch(N)

						if(1)
							src3 = pliBYTE_ONE(src3) + pliBYTE_ONE(Int1)
							src2 = pliBYTE_ONE(src2)                  + pliBUFFER(src3)

						if(2)
							src4 = pliBYTE_ONE(src4) + pliBYTE_ONE(Int2)
							src3 = pliBYTE_ONE(src3) + pliBYTE_ONE(Int1) + pliBUFFER(src4)
							src2 = pliBYTE_ONE(src2)                  + pliBUFFER(src3)

					pliFLUSH(src2)
					pliFLUSH(src3)
					pliFLUSH(src4)

			quot_size = 3

		/*

		Third "iteration", with j := 3.

		*/

		if(3 <= M)
			// Equivalently, if(j <= M). We only proceed so long as j is at least
			// as large as M.

			// Step D3 [Calculate q-hat.]

			if(src3 == Int1)	qhat = base - 1
			else				qhat = pliFLOOR( (src3*base + src4) / Int1 )

			while( (Int2*qhat) > (src3*base + src4 - Int1*qhat)*base )
				qhat --

			// Step D4 [Multiply and subtract.]

			if(qhat != 0)
				// When qhat == 0, nothing would change so we'll just skip this step. Otherwise,
				// we proceed..

				i4 = qhat*Int4
				i3 = qhat*Int3 + pliBUFFER(i4)
				i2 = qhat*Int2 + pliBUFFER(i3)
				i1 = qhat*Int1 + pliBUFFER(i2)
				i0 = pliBUFFER(i1)

				pliFLUSH(i0)
				pliFLUSH(i1)
				pliFLUSH(i2)
				pliFLUSH(i3)
				pliFLUSH(i4)

				src4 = pliBYTE_ONE(src4) + pliBYTE_ONE_N(i1) + 1
				src3 = pliBYTE_ONE(src3) + pliBYTE_ONE_N(i0) + pliBUFFER(src4)

				if(pliBUFFER(src3) == 0)
					// If pliBUFFER(src0) == 0, then we rolled over and need to set
					// the relevant flag.
					rollover_flag = 1
				else
					rollover_flag = 0

				pliFLUSH(src3)
				pliFLUSH(src4)

				// Step D5 [Test remainder.]

				q3 = qhat

				// Step D6 [Add back.]

				if(rollover_flag)
					// Subtract one to account for the rollover.

					q3 --

					// And add Int to (src3, src4).

					src4 = pliBYTE_ONE(src4) + pliBYTE_ONE(Int1)
					src3 = pliBYTE_ONE(src3)                  + pliBUFFER(src4)

					pliFLUSH(src3)
					pliFLUSH(src4)

			quot_size = 4

		/*
		 * In the standard Algorithm D implementation, this is where we would put all the
		 * data together and output the remainder and quotient. Instead, we will output the
		 * individual pieces so that other methods can put them together.
		 */

		return list(
			// Used for finding the quotient.
			quot_size,						// Size of the quotient, in bytes.
			q0, q1, q2, q3, 				// Pieces of the quotient.

			// Used for finding the remainder.
			src0, src1, src2, src3, src4,	// Pieces of src.
			M, N,							// We divide (src(M+1), ..., src(M_N)) by adj in order
											// to get the remainder.
			adj								// Factor to divide the src values by in order
											// to get the remainder.
		)

	Quotient(...)
		var
			// Get the data from _AlgorithmD
			list
				Processed = _Process(args)
				D = _AlgorithmD(Processed[1], Processed[2])

		/*
		 * Set Quot as needed.
		 */

			pif_LongInt/UnsignedDouble/Quot
		if(mode & NEW_OBJECT)
			Quot = new src.type
		else
			Quot = src

		/*
		 * Compute the result.
		 */

		switch(D[1]) // switch(quot_size)
			// We have the following
			//  * D[2] = q1
			//  * D[3] = q2
			//  * D[4] = q3
			//  * D[5] = q4

			if(1)
				Quot._SetBlock(1, D[2]                          )

			if(2)
				Quot._SetBlock(1, D[3] | pliBYTE_ONE_SHIFTED(D[2]) )

			if(3)
				Quot._SetBlock(2, D[2])
				Quot._SetBlock(1, D[4] | pliBYTE_ONE_SHIFTED(D[3]) )

			if(4)
				Quot._SetBlock(2, D[3] | pliBYTE_ONE_SHIFTED(D[2]) )
				Quot._SetBlock(1, D[5] | pliBYTE_ONE_SHIFTED(D[4]) )

		return Quot

	Remainder(...)
		var
			// Get the data from _AlgorithmD
			list
				Processed = _Process(args)
				D = _AlgorithmD(Processed[1], Processed[2])

		/*
		 * Set the remainder correctly.
		 */

			pif_LongInt/UnsignedDouble/Rem
		if(mode & NEW_OBJECT)
			Rem = new src.type
		else
			Rem = src

		/*
		 * Compute the remainder.
		 */

		var
			byte_1 = 0
			byte_2 = 0
			byte_3 = 0
			byte_4 = 0

			adj = D[13]

		switch(D[11]) // switch(M)
			// We have the following to keep in mind:
			//	* D[ 6] = src0
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

		// This a highly-abbreviated variation of _AlgorithmD() above. It's shorter because
		// we can assume that M = 3, N = 1, and we don't have to worry about finding the
		// remainder (because it's equal to 0).

		var
			q0
			q1
			q2
			q3

		q0 = pliFLOOR(byte_1 / adj)
		byte_1 -= adj*q0

		q1 = pliFLOOR( (byte_1*256 + byte_2) / adj)
		byte_1 = (pliBYTE_ONE_SHIFTED(byte_1) | byte_2) - (adj*q1)
		byte_2 = pliDATA(byte_1)

		q2 = pliFLOOR( (byte_2*256 + byte_3) / adj)
		byte_2 = (pliBYTE_ONE_SHIFTED(byte_2) | byte_3) - (adj*q2)
		byte_3 = pliDATA(byte_2)

		q3 = pliFLOOR( (byte_3*256 + byte_4) / adj)

		Rem._SetBlock(2, pliBYTE_ONE_SHIFTED(q0) | q1)
		Rem._SetBlock(1, pliBYTE_ONE_SHIFTED(q2) | q3)

		return Rem

	// Alias methods

	Mod(...)
		return Remainder(arglist(args))

	// Miscellaneous arithmetic methods.

	Divide(...)
		var
			// Get the data from _AlgorithmD
			list
				Processed
				D

			pif_LongInt/UnsignedDouble
				Rem = new src.type

		/*
		 * Set Quot as needed.
		 */

				Quot
		if(mode & NEW_OBJECT)
			Quot = new src.type
		else
			Quot = src

		/*
		 * Compute the results.
		 */

		Processed = _Process(args)
		D = _AlgorithmD(Processed[1], Processed[2])

		// Rem will change itself rather than outputting an new object.
		Rem.SetModeFlag(NEW_OBJECT, 0)

		// Quotient.

		switch(D[1]) // switch(quot_size)
			// We have the following
			//  * D[2] = q1
			//  * D[3] = q2
			//  * D[4] = q3
			//  * D[5] = q4

			if(1)
				Quot._SetBlock(1, D[2]                          )

			if(2)
				Quot._SetBlock(1, D[3] | pliBYTE_ONE_SHIFTED(D[2]) )

			if(3)
				Quot._SetBlock(2, D[2])
				Quot._SetBlock(1, D[4] | pliBYTE_ONE_SHIFTED(D[3]) )

			if(4)
				Quot._SetBlock(2, D[3] | pliBYTE_ONE_SHIFTED(D[2]) )
				Quot._SetBlock(1, D[5] | pliBYTE_ONE_SHIFTED(D[4]) )

		// Remainder.

		var
			byte_1 = 0
			byte_2 = 0
			byte_3 = 0
			byte_4 = 0

			adj = D[13]

		switch(D[11]) // switch(M)
			// We have the following to keep in mind:
			//	* D[ 6] = src0
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

		// This a highly-abbreviated variation of _AlgorithmD() above. It's shorter because
		// we can assume that M = 3, N = 1, and we don't have to worry about finding the
		// remainder (because it's equal to 0).

		var
			q0
			q1
			q2
			q3

		q0 = pliFLOOR(byte_1 / adj)
		byte_1 -= adj*q0

		q1 = pliFLOOR( (byte_1*256 + byte_2) / adj)
		byte_1 = (pliBYTE_ONE_SHIFTED(byte_1) | byte_2) - (adj*q1)
		byte_2 = pliDATA(byte_1)

		q2 = pliFLOOR( (byte_2*256 + byte_3) / adj)
		byte_2 = (pliBYTE_ONE_SHIFTED(byte_2) | byte_3) - (adj*q2)
		byte_3 = pliDATA(byte_2)

		q3 = pliFLOOR( (byte_3*256 + byte_4) / adj)

		Rem._SetBlock(2, pliBYTE_ONE_SHIFTED(q0) | q1)
		Rem._SetBlock(1, pliBYTE_ONE_SHIFTED(q2) | q3)

		/*
		 * Send it back whence it came.
		 */

		return list(
			Quot,
			Rem
		)

	Increment()
		// Adding 1 to the object.

		var/pif_LongInt/UnsignedDouble/Sum

		if(mode & NEW_OBJECT)
			Sum = new src.type
		else
			Sum = src

		/*
		 * Computation.
		 */

		var
			B1 = 0
			B2 = 0

		B1 = pliBYTE_ONE(block_1) + 1
		B2 = pliBYTE_TWO(block_1) + pliBUFFER(B1)

		Sum._SetBlock(1, pliBYTE_ONE(B1) | pliBYTE_ONE_SHIFTED(B2))

		B1 = pliBYTE_ONE(block_2) + pliBUFFER(B2)
		B2 = pliBYTE_TWO(block_2) + pliBUFFER(B1)

		Sum._SetBlock(2, pliBYTE_ONE(B1) | pliBYTE_ONE_SHIFTED(B2))

		if( (pliBUFFER(B2) != 0) && (mode & OVERFLOW_EXCEPTION) )
			// If B2's buffer is not equal to zero, then we overflowed and need
			// to throw the OverflowException if it's flag set.

			throw new /pif_Arithmetic/OverflowException(__FILE__, __LINE__)

		return Sum

	Decrement()
		// Subtracting 1 from the object.

		var/pif_LongInt/UnsignedDouble/Diff

		if(mode & NEW_OBJECT)
			Diff = new src.type
		else
			Diff = src

		/*
		 * Computation.
		 */

		// We add 0xFFFF to each block, as this is equivalent to adding -1
		// to the integer. This is because 0xFF...FF = -1 in two's complement
		// notation.

		var
			B1 = 0
			B2 = 0

		B1 = pliBYTE_ONE(block_1) + 0x00FF
		B2 = pliBYTE_TWO(block_1) + pliBUFFER(B1) + 0x00FF

		Diff._SetBlock(1, pliBYTE_ONE(B1) | pliBYTE_ONE_SHIFTED(B2))

		B1 = pliBYTE_ONE(block_2) + pliBUFFER(B2) + 0x00FF
		B2 = pliBYTE_TWO(block_2) + pliBUFFER(B1) + 0x00FF

		Diff._SetBlock(2, pliBYTE_ONE(B1) | pliBYTE_ONE_SHIFTED(B2))

		if( (pliBUFFER(B2) == 0) && (mode & OVERFLOW_EXCEPTION) )
			// If B2's buffer is equal to zero, then there was a negative
			// overflow. Thus, we need to possibly throw the OverflowException.

			throw new /pif_Arithmetic/OverflowException(__FILE__, __LINE__)

		return Diff

	Negate()
		// Unsigned, so we'll simply return the object itself.

		if(mode & NEW_OBJECT)
			return new /pif_LongInt/UnsignedDouble(src)
		else
			return src

	Square()
		// Returns the square of the src object, that is src**2. There are a few slight simplifications
		// that can be made in this method that are not possible in the multiply method, due to different
		// assumptions. In most situations, the computational difference between these two should be quite
		// slim and largely irrelevant, but if you're doing a lot of computations (especially exponentiations)
		// at once, they should be helpful.

		var
			// The final result.
			pif_LongInt/UnsignedDouble/Square

			// Bytes of src.

			src0 = pliBYTE_ONE(block_1)
			src1 = pliBYTE_TWO(block_1)
			src2 = pliBYTE_ONE(block_2)
			src3 = pliBYTE_TWO(block_2)

			// Bytes of the final result's blocks. As in the multiply method, the first byte of each
			// of these is the actual value, while the second byte is a buffer until that data is
			// pushed (i.e., added) to the next block.

			byte_1 = 0
			byte_2 = 0
			byte_3 = 0
			byte_4 = 0

			// Buffer to temporarily store multiplications.
			buffer

			// A flag to set if an overflow occured.
			overflow_flag = 0

		if(mode & NEW_OBJECT)
			Square = new src.type
		else
			Square = src

		/*
		 *
		 * Performing the computation.
		 *

		The idea behind the computation here is basically the same as above. That is, we let

		  A = R**3 a_3 + R**2 a_2 + R a_1 + a_0

		where R = 256 and 0 <= a_n <= 255 (for n = 0, 1, 2, 3). Then we expand the square of
		A as

		  A**2 = A*A = R**6 (a_3*a_3) + R**5 (2*a_2*_a3) + R**4 (2*a_1*a_3 + a_2*a_2) +
		               R**3 (2*a_0*a_3 + 2*a_1*a_2) + R**2 (2*a_0*a_2 + a_1*_a1) + R (a_0*a_1)
		               + a_0*a_0.

		And then take note of the terms we can discard.

		*/

		// Terms with coefficient R**0 == 1.

		byte_1 = src0*src0

		pliADDBUFFER(byte_1, byte_2)
		pliFLUSH(byte_1)

		// Terms with coefficient R**1 == R.

		buffer = src0*src1

		pliADDDATA_T2(buffer, byte_2)
		byte_3 = pliBUFFER(byte_2) + pliBUFFER_T2(buffer)
		pliADDBUFFER(byte_3, byte_4) // byte_4 = 0 before this operation. Because only the buffer is
								  // being added, after the operation byte_4 <= 255.

		pliFLUSH(byte_2)
		pliFLUSH(byte_3)

		// Terms with coefficient R**2.

		if(overflow_flag || !(mode & OVERFLOW_EXCEPTION))
			buffer = src1*src1
			pliADDDATA(buffer, byte_3)
			byte_4 += pliBUFFER(byte_3) + pliBUFFER(buffer)
			pliFLUSH(byte_3)
			pliFLUSH(byte_4)

			buffer = src0*src2
			pliADDDATA_T2(buffer, byte_3)
			byte_4 += pliBUFFER(byte_3) + pliBUFFER_T2(buffer)
			pliFLUSH(byte_3)
			pliFLUSH(byte_4)

		else
			buffer = src1*src1
			pliADDDATA(buffer, byte_3)
			byte_4 += pliBUFFER(byte_3) + pliBUFFER(buffer)
			if(!overflow_flag && (pliBUFFER(byte_4) != 0))
				overflow_flag = 1

			pliFLUSH(byte_3)
			pliFLUSH(byte_4)

			buffer = src0*src2
			pliADDDATA_T2(buffer, byte_3)
			byte_4 += pliBUFFER(byte_3) + pliBUFFER_T2(buffer)
			if(!overflow_flag && (pliBUFFER(byte_4) != 0))
				overflow_flag = 1

			pliFLUSH(byte_3)
			pliFLUSH(byte_4)

		// Terms with coefficient R**3.

		if(overflow_flag || !(mode & OVERFLOW_EXCEPTION))
			byte_4 += pliDATA_T2(src0*src3)
			if(!overflow_flag && (pliBUFFER(byte_4) != 0))
				overflow_flag = 1

			byte_4 += pliDATA_T2(src1*src2)
			if(!overflow_flag && (pliBUFFER(byte_4) != 0))
				overflow_flag = 1

		// Now we check, as with multipliation, the last few that indicate an overflow
		// occurred but were not computes.

		if(!overflow_flag && (mode & OVERFLOW_EXCEPTION))
			//R**6 (a_3*a_3) + R**5 (2*a_2*_a3) + R**4 (2*a_1*a_3 + a_2*a_2)

			overflow_flag = (src3 != 0) || (src2 != 0)

		/*
		 * Glue the pieces back together, and deliver the result.
		 */

		Square._SetBlock(1, byte_1 | pliBYTE_ONE_SHIFTED(byte_2) )
		Square._SetBlock(2, byte_3 | pliBYTE_ONE_SHIFTED(byte_4) )

		if(overflow_flag && (mode & OVERFLOW_EXCEPTION))
			// If overflow occured and we need to report it, then throw the OverflowException.
			throw new /pif_Arithmetic/OverflowException(__FILE__, __LINE__)

		return Square

	/*
	 * Bitwise methods.
	 */

	// Bitwise arithmetic methods.

	BitwiseNot()
		if(mode & NEW_OBJECT)
			var/pif_LongInt/UnsignedDouble/Int = new src.type(src)

			Int.block_1 = ~Int.block_1
			Int.block_2 = ~Int.block_2

			return Int

		else
			block_1 = ~block_1
			block_2 = ~block_2

			return src

	BitwiseAnd(...)
		var
			list/Processed = _Process(args)

			b1 = Processed[1]
			b2 = Processed[2]

		/*
		 * Computation
		 */

		if(mode & NEW_OBJECT)
			var/pif_LongInt/UnsignedDouble/Int = new src.type(src)

			Int.block_1 &= b1
			Int.block_2 &= b2

			return Int

		else
			block_1 &= b1
			block_2 &= b2

			return src

	BitwiseOr(...)
		var
			list/Processed = _Process(args)

			b1 = Processed[1]
			b2 = Processed[2]

		/*
		 * Computation
		 */

		if(mode & NEW_OBJECT)
			var/pif_LongInt/UnsignedDouble/Int = new src.type(src)

			Int.block_1 |= b1
			Int.block_2 |= b2

			return Int

		else
			block_1 |= b1
			block_2 |= b2

			return src

	BitwiseXor(...)
		var
			list/Processed = _Process(args)

			b1 = Processed[1]
			b2 = Processed[2]

		/*
		 * Computation
		 */

		if(mode & NEW_OBJECT)
			var/pif_LongInt/UnsignedDouble/Int = new src.type(src)

			Int.block_1 ^= b1
			Int.block_2 ^= b2

			return Int

		else
			block_1 ^= b1
			block_2 ^= b2

			return src

	// Bitshifting methods.

	BitshiftLeft(n)
		if(!isnum(n) || (round(n) != n))
			throw new /pif_Arithmetic/NonIntegerException(__FILE__, __LINE__)
		if(n < 0)
			throw new /pif_Arithmetic/NegativeIntegerException(__FILE__, __LINE__)

		var
			// Holds the overflow from block_1 into block_2.
			hold

			var/pif_LongInt/UnsignedDouble/Int

		/*
		 * Computation
		 */

		if(mode & NEW_OBJECT)
			Int = new src.type(src)
		else
			Int = src

		if(n >= BitLength())
			Int.block_1 = 0
			Int.block_2 = 0

		else
			if(n <= 16)
				hold = Int.block_1 >> (16 - n)

				Int.block_1 = (Int.block_1 << n) & 0xFFFF
				Int.block_2 = ((Int.block_2 << n) | hold) & 0xFFFF

			else
				Int.block_2 = (Int.block_1 << (n-16)) & 0xFFFF
				Int.block_1 = 0

		return Int

	BitshiftLeftRotate(n)
		if(!isnum(n) || (round(n) != n))
			throw new /pif_Arithmetic/NonIntegerException(__FILE__, __LINE__)
		if(n < 0)
			throw new /pif_Arithmetic/NegativeIntegerException(__FILE__, __LINE__)

		var
			// Holds the overflow from block_1 into block_2 and from block_2
			// into block_1, respectively.
			hold_1
			hold_2

			var/pif_LongInt/UnsignedDouble/Int

		/*
		 * Computation
		 */

		if(mode & NEW_OBJECT)
			Int = new src.type(src)
		else
			Int = src

		n %= BitLength()

		if(n <= 16)
			hold_1 = Int.block_1 >> (16 - n)
			hold_2 = Int.block_2 >> (16 - n)

			Int.block_1 = ((Int.block_1 << n) | hold_2) & 0xFFFF
			Int.block_2 = ((Int.block_2 << n) | hold_1) & 0xFFFF

		else if(n > 16)
			n = 16 - (n % 16)

			hold_1 = Int.block_1 << (16 - n)
			hold_2 = Int.block_2 << (16 - n)

			Int.block_1 = ((Int.block_1 >> n) | hold_2) & 0xFFFF
			Int.block_2 = ((Int.block_2 >> n) | hold_1) & 0xFFFF

		return Int

	BitshiftRight(n)
		if(!isnum(n) || (round(n) != n))
			throw new /pif_Arithmetic/NonIntegerException(__FILE__, __LINE__)
		if(n < 0)
			throw new /pif_Arithmetic/NegativeIntegerException(__FILE__, __LINE__)

		var
			// Holds the overflow from block_1 into block_2.
			hold

			var/pif_LongInt/UnsignedDouble/Int

		/*
		 * Computation
		 */

		if(mode & NEW_OBJECT)
			Int = new src.type(src)
		else
			Int = src

		if(n >= BitLength())
			Int.block_1 = 0
			Int.block_2 = 0

		else
			if(n <= 16)
				hold = Int.block_2 << (16 - n)

				Int.block_1 = ((Int.block_1 >> n) | hold) & 0xFFFF
				Int.block_2 = (Int.block_2 >> n) & 0xFFFF

			else
				Int.block_1 = (Int.block_2 >> (n-16)) & 0xFFFF
				Int.block_2 = 0

		return Int

	BitshiftRightRotate(n)
		if(!isnum(n) || (round(n) != n))
			throw new /pif_Arithmetic/NonIntegerException(__FILE__, __LINE__)
		if(n < 0)
			throw new /pif_Arithmetic/NegativeIntegerException(__FILE__, __LINE__)

		var
			// Holds the overflow from block_1 into block_2 and from block_2
			// into block_2, respectively.
			hold_1
			hold_2

			var/pif_LongInt/UnsignedDouble/Int

		/*
		 * Computation
		 */

		if(mode & NEW_OBJECT)
			Int = new src.type(src)
		else
			Int = src

		n %= BitLength()

		if(n <= 16)
			hold_1 = Int.block_1 << (16 - n)
			hold_2 = Int.block_2 << (16 - n)

			Int.block_1 = ((Int.block_1 >> n) | hold_2) & 0xFFFF
			Int.block_2 = ((Int.block_2 >> n) | hold_1) & 0xFFFF

		else if(n > 16)
			n = 16 - (n % 16)

			hold_1 = Int.block_1 >> (16 - n)
			hold_2 = Int.block_2 >> (16 - n)

			Int.block_1 = ((Int.block_1 << n) | hold_2) & 0xFFFF
			Int.block_2 = ((Int.block_2 << n) | hold_1) & 0xFFFF

		return Int

	// Bitstring methods.

	Bit(p)
		if(!isnum(p) || (round(p) != p))
			throw new /pif_Arithmetic/NonIntegerException(__FILE__, __LINE__)
		if(p < 0)
			throw new /pif_Arithmetic/NegativeIntegerException(__FILE__, __LINE__)
		if(p > (BitLength() - 1))
			throw new /pif_Arithmetic/OutOfBoundsException(__FILE__, __LINE__)

		if(p < 16)
			return (block_1 >> p) & 0x0001
		else
			return (block_2 >> (32 - p)) & 0x0001

	BitString(P, L)
		// TODO
	BitObject(P, L)
		// TODO

	// Miscellaneous methods.

	FindFirstSet()
		// TODO

	/*
	 * Comparison methods.
	 */

	Compare(...)
		var
			list/Processed = _Process(args)

			b1 = Processed[1]
			b2 = Processed[2]

		. = src.block_2 - b2
		if(. != 0)
			return (. > 0) ? 1 : -1

		. = src.block_1 - b1
		return (. == 0) ? 0 : ( (. > 1) ? 1 : -1)

	EqualTo(...)
		return Compare(arglist(args)) ==  0
	NotEqualTo(...)
		return Compare(arglist(args)) !=  0
	GreaterThan(...)
		return Compare(arglist(args)) ==  1
	GreaterThanOrEqualTo(...)
		return Compare(arglist(args)) != -1
	LessThan(...)
		return Compare(arglist(args)) == -1
	LessThanOrEqualTo(...)
		return Compare(arglist(args)) !=  1

	// Alias methods.

	EQ(...)
		return Compare(arglist(args)) ==  0
	NEQ(...)
		return Compare(arglist(args)) !=  0
	GT(...)
		return Compare(arglist(args)) ==  1
	GEQ(...)
		return Compare(arglist(args)) != -1
	LT(...)
		return Compare(arglist(args)) == -1
	LEQ(...)
		return Compare(arglist(args)) !=  1

	// Miscellaneous comparison methods.

	IsNegative()
		return 0
	IsNonNegative()
		return 1

	IsZero()
		return (block_1 == 0) && (block_2 == 0)
	IsNonZero()
		return !IsZero()

	IsPositive()
		return !IsZero()
	IsNonPositive()
		return IsZero()

	/*
	 * Print methods.
	 */

#ifdef	PIF_LONGINT_PRINT_UNARY

	PrintUnary()
		// Here only as a joke.

		. = ""
		var/pif_LongInt/UnsignedDouble/Int = new src.type(src)
		Int.SetMode(NEW_OBJECT, 0)

		while(Int.IsNonZero())
			. += "1"
			Int.Decrement()

#endif

	PrintBinary()
		var
			b1 = ""
			b2 = ""

		for(var/i = 0, i < 16, i ++)
			b1 = "[(block_1 >> i) & 0x0001]" + b1
			b2 = "[(block_2 >> i) & 0x0001]" + b2

		return b2 + b1

	PrintQuaternary()
		var
			b1 = ""
			b2 = ""

		for(var/i = 0, i < 8, i ++)
			b1 = "[(block_1 >> (2*i)) & 0x0003]" + b1
			b2 = "[(block_2 >> (2*i)) & 0x0003]" + b2

		return b2 + b1

	PrintOctal()
		var
			b1 = ""
			b2 = ""

		for(var/i = 0, i < 5, i ++)
			b1 = "[(block_1 >> (3*i    )) & 0x0007]" + b1
			b2 = "[(block_2 >> (3*i + 2)) & 0x0007]" + b2

		return b2 + "[(((block_2 & 0x003) << 1) | ((block_1 >> 15) & 0x0001))]" + b1

	PrintDecimal()
		var
			pif_LongInt/UnsignedDouble
				Printer = new src.type(src)
				R
			list/QR

		. = ""

		Printer.SetModeFlag(Printer.NEW_OBJECT, 0)
		while(Printer.IsNonZero())
			QR = Printer.Divide(10)
			R = QR[2]

			. = "[R.block_1][.]"

		if(. == "")
			return "0"

	PrintHexadecimal()
		var
			b1 = ""
			b2 = ""

		for(var/i = 0, i < 4, i ++)
			var
				_1 = (block_1 >> (4*i)) & 0x000F
				_2 = (block_2 >> (4*i)) & 0x000F

			// 65 (=55+10) is A in ASCII.
			_1 = (_1 < 10) ? _1 : ascii2text(_1 + 55)
			_2 = (_2 < 10) ? _2 : ascii2text(_2 + 55)

			b1 = "[_1][b1]"
			b2 = "[_2][b2]"

		return b2 + b1

	PrintBase64()
#define	ToBase64(x)	(((x) <= 25) ? ascii2text(65 + (x)) : (((x) <= 51) ? ascii2text(71 + (x)) : (((x) <= 61) ? "[(x)-52]" : (((x) == 62) ? "+" : "/"))))
		var
			b1 = ""
			b2 = ""

		for(var/i = 0, i < 3, i ++)
			b1 = ToBase64((block_1 >> (5*i    )) & 0x001F) + b1
			b2 = ToBase64((block_2 >> (5*i + 4)) & 0x001F) + b2

		return b2 + ToBase64(((block_2 & 0x000F) << 1) | (block_1 >> 15)) + b1
#undef	ToBase64

	// Alias methods.

	Print()		return PrintDecimal()
	PrintBin()	return PrintBinary()
	PrintHex()	return PrintHexadecimal()

	/*
	 * Inspection methods.
	 */

	Length()
		return Length

	BitLength()
		return 16*Length

	Mode()
		return mode

	/*
	 * Mutator methods.
	 */

	Set(...)
		var/list/Processed = _Process(args)

		block_1 = Processed[1]
		block_2 = Processed[2]

		return src

	SetMode(_m)
		// Make sure that FIXED_PRECISION is always on and SIGNED_MODE is
		// always off.

		mode = (_m & ~SIGNED_MODE) | FIXED_PRECISION

		return mode

	SetModeFlag(flag, state)
		if(state)
			mode |= flag
		else
			mode &= ~flag

		// Make sure that FIXED_PRECISION is always on and SIGNED_MODE is
		// always off.

		mode = (mode & ~SIGNED_MODE) | FIXED_PRECISION

		return mode

	/*
	 * "Static" methods.
	 */

	Maximum()
		return new /pif_LongInt/UnsignedDouble(0xFFFF, 0xFFFF)
	Minimum()
		return new /pif_LongInt/UnsignedDouble(0x0000, 0x0000)