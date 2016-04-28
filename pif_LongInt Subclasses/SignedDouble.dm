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

	Maximum()
		// 2147483647
		return new /pif_LongInt/SignedDouble(0x7FFF, 0xFFFF)
	Minimum()
		// -2147483648
		return new /pif_LongInt/SignedDouble(0x8000, 0x0000)