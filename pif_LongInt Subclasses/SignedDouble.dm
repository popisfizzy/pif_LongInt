/*
 * Implementation of an signed double precision (32-bit) integer that uses the
 * pif_Arithmetic protocol. Numbers are stored in two's complement form, and
 * thus have a precision between -2147483648 and 2147483647 (that is, between
 * 0x80000000 and 0x7FFFFFFF).
 */

pif_LongInt/SignedDouble
	parent_type = /pif_LongInt/UnsignedDouble

	Negate()
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

/*

Let D(x,y) -> (q,r) <=> y*q + r = x. Then we have the following where + denotes some positive number
and - denotes some negative number:

	- D(+,+) -> (+,+)
	- D(+,-) -> (-,+)
	- D(-,+) -> (-,-)
	- D(-,-) -> (+,-)

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

  - D( 40, 3) -> ( 13, 1) because  3*( 13) + 1 =  40.
  - D( 40,-3) -> (-13, 1) because -3*(-13) + 1 =  40.
  - D(-40, 3) -> (-13,-1) because  3*(-13) - 1 = -40.
  - D(-40,-3) -> ( 13,-1) because -3*( 13) - 1 = -40.

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
			// If the largest bit is turned on, then Processed[1] is negative and we need to make
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
		 * And now begin constructing the quotient.
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

			if(2)
				Quot._SetBlock(1, D[3] | pliBYTE_ONE_SHIFTED(D[2]) )

			if(3)
				Quot._SetBlock(2, D[2])
				Quot._SetBlock(1, D[4] | pliBYTE_ONE_SHIFTED(D[3]) )

			if(4)
				Quot._SetBlock(2, D[3] | pliBYTE_ONE_SHIFTED(D[2]) )
				Quot._SetBlock(1, D[5] | pliBYTE_ONE_SHIFTED(D[4]) )

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

	Maximum()
		// 2147483647
		return new /pif_LongInt/SignedDouble(0x7FFF, 0xFFFF)
	Minimum()
		// -2147483648
		return new /pif_LongInt/SignedDouble(0x8000, 0x0000)