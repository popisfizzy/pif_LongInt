#define	DEBUG

pif_LongInt/proc/SetRand(max_bit = null)
	Set(0)

	if(isnull(max_bit))
		max_bit = BitLength()

	var/b = 0
	while(max_bit > 0)
		b ++

		var/n = 0
		for(var/i = 0, i < 16, i ++)
			n |= (1 << i) * rand(0, 1)

			max_bit --
			if(max_bit <= 0)
				break

		_SetBlock(b, n)

mob
	Login()
		..()

		var/pif_LongInt/SignedDouble
			U = new(0xFFFF, -10)
			V = new(3)

			W

		U.SetModeFlag(U.NEW_OBJECT, 1)

		W = U.Quotient(V)

		world << "<tt>Quotient\[[U.Print()], [V.Print()]] == [W.Print()]</tt>"

	verb/Foo()
		var/pif_LongInt
			SignedDouble
				U = new
				V = new

				W

		U.SetModeFlag(U.NEW_OBJECT, 1)
		V.SetModeFlag(V.NEW_OBJECT, 0)

		for(var/i = 1, i <= 500, i ++)
			U.SetRand( rand(1, 32) )
			V.SetRand( rand(1, 32) )

			if(V.IsZero())
				V.Set(1)

			if(rand(0,1) == 0)
				U = U.Negate()
			if(rand(0,1) == 0)
				V.Negate()

			W = U.Quotient(V)

			world << "<tt>IntegerPart\[[U.Print()] / [V.Print()]] == [W.Print()]</tt>"