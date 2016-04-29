#ifdef	DEBUG

mob
	var
		const/TEST_DIFFICULTY = 50000

		test_class = /pif_LongInt/UnsignedDouble

	verb
		AddTest()
			var
				pif_LongInt
					A = new test_class
					B = new test_class

			for(var/i = 1, i <= TEST_DIFFICULTY, i ++)
				A.Set( rand(0, 0xFFFF), rand(0, 0xFFFF) )
				B.Set( rand(0, 0xFFFF), rand(0, 0xFFFF) )

				A.Add(B)

			world << "Done."

		SubtractTest()
			var
				pif_LongInt
					A = new test_class
					B = new test_class

			for(var/i = 1, i <= TEST_DIFFICULTY, i ++)
				A.Set( rand(0, 0xFFFF), rand(0, 0xFFFF) )
				B.Set( rand(0, 0xFFFF), rand(0, 0xFFFF) )

				A.Subtract(B)

			world << "Done."

		MultiplyTest()
			var
				pif_LongInt
					A = new test_class
					B = new test_class

			for(var/i = 1, i <= TEST_DIFFICULTY, i ++)
				A.Set( rand(0, 0xFFFF), rand(0, 0xFFFF) )
				B.Set( rand(0, 0xFFFF), rand(0, 0xFFFF) )

				A.Multiply(B)

			world << "Done."

		QuotientTest()
			var
				pif_LongInt
					A = new test_class
					B = new test_class

			for(var/i = 1, i <= TEST_DIFFICULTY, i ++)
				A.Set( rand(0, 0xFFFF), rand(0, 0xFFFF) )
				B.Set( rand(0, 0xFFFF), rand(0, 0xFFFF) )

				A.Quotient(B)

			world << "Done."

		RemainderTest()
			var
				pif_LongInt
					A = new test_class
					B = new test_class

			for(var/i = 1, i <= TEST_DIFFICULTY, i ++)
				A.Set( rand(0, 0xFFFF), rand(0, 0xFFFF) )
				B.Set( rand(0, 0xFFFF), rand(0, 0xFFFF) )

				A.Remainder(B)

			world << "Done."

		DivideTest()
			var
				pif_LongInt
					A = new test_class
					B = new test_class

			for(var/i = 1, i <= TEST_DIFFICULTY, i ++)
				A.Set( rand(0, 0xFFFF), rand(0, 0xFFFF) )
				B.Set( rand(0, 0xFFFF), rand(0, 0xFFFF) )

				A.Divide(B)

			world << "Done."

		SquareTest()
			var
				pif_LongInt
					A = new test_class

			for(var/i = 1, i <= TEST_DIFFICULTY, i ++)
				A.Set( rand(0, 0xFFFF), rand(0, 0xFFFF) )
				A.Square()

			world << "Done."

		PowerTest()
			var
				pif_LongInt
					A = new test_class

			for(var/i = 1, i <= TEST_DIFFICULTY, i ++)
				A.Set( rand(0, 0x00FF) ) // FF**4 = FC05FC01, so it is guaranteed to not overflow.
				A.Power(4)

			world << "Done."

		BitwiseAndTest()
			var
				pif_LongInt
					A = new test_class
					B = new test_class

			for(var/i = 1, i <= TEST_DIFFICULTY, i ++)
				A.Set( rand(0, 0xFFFF), rand(0, 0xFFFF) )
				B.Set( rand(0, 0xFFFF), rand(0, 0xFFFF) )

				A.BitwiseAnd(B)

			world << "Done."

		BitwiseOrTest()
			var
				pif_LongInt
					A = new test_class
					B = new test_class

			for(var/i = 1, i <= TEST_DIFFICULTY, i ++)
				A.Set( rand(0, 0xFFFF), rand(0, 0xFFFF) )
				B.Set( rand(0, 0xFFFF), rand(0, 0xFFFF) )

				A.BitwiseOr(B)

			world << "Done."

		BitwiseXorTest()
			var
				pif_LongInt
					A = new test_class
					B = new test_class

			for(var/i = 1, i <= TEST_DIFFICULTY, i ++)
				A.Set( rand(0, 0xFFFF), rand(0, 0xFFFF) )
				B.Set( rand(0, 0xFFFF), rand(0, 0xFFFF) )

				A.BitwiseXor(B)

			world << "Done."

		BitwiseNotTest()
			var
				pif_LongInt
					A = new test_class

			for(var/i = 1, i <= TEST_DIFFICULTY, i ++)
				A.Set( rand(0, 0x00FF) ) // FF**4 = FC05FC01, so it is guaranteed to not overflow.
				A.BitwiseNot()

			world << "Done."

		BitshiftLeftTest()
			var
				pif_LongInt
					A = new test_class

			for(var/i = 1, i <= TEST_DIFFICULTY, i ++)
				A.Set( rand(0, 0x00FF) ) // FF**4 = FC05FC01, so it is guaranteed to not overflow.
				A.BitshiftLeft(8)

			world << "Done."

		BitshiftRightTest()
			var
				pif_LongInt
					A = new test_class

			for(var/i = 1, i <= TEST_DIFFICULTY, i ++)
				A.Set( rand(0, 0x00FF) ) // FF**4 = FC05FC01, so it is guaranteed to not overflow.
				A.BitshiftRight(8)

			world << "Done."

		BitshiftLeftRotateTest()
			var
				pif_LongInt
					A = new test_class

			for(var/i = 1, i <= TEST_DIFFICULTY, i ++)
				A.Set( rand(0, 0x00FF) ) // FF**4 = FC05FC01, so it is guaranteed to not overflow.
				A.BitshiftLeftRotate(8)

			world << "Done."

		BitshiftRightRotateTest()
			var
				pif_LongInt
					A = new test_class

			for(var/i = 1, i <= TEST_DIFFICULTY, i ++)
				A.Set( rand(0, 0x00FF) ) // FF**4 = FC05FC01, so it is guaranteed to not overflow.
				A.BitshiftRightRotate(8)

			world << "Done."

#endif	DEBUG