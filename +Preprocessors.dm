// Marks the library as included. This allows for something like
//
//   #ifdef PIF_LONGINT_INLUDED
//
// to optionally include/exclude code based on the presence of the library.

#define PIF_LONGINT_INCLUDED

/*
 * Various macros.
 */

#define	pliFLOOR(X) 			round(X) // This is the largest integer less than X.

// These macros are used to make the behavior of the code in this library cleaner in its
// presentation and clearer in its purpose. The clarity comes from two counts: the first is
// that bit manipulation can often be a bit opaque and hard to follow, while the other is
// that two operations that are conceptually quite distinct (for example, reading the second
// byte from a variable versus reading the buffer from a piece of data) have the same bitwise
// operations.

#define	pliBYTE_ONE(X)			((X) & 0x00FF)			// Extracts the first byte of X.
#define	pliBYTE_TWO(X)			(((X) & 0xFF00) >> 8)	// Extracs the second byte.

#define	pliBYTE_ONE_N(X)		(~(X) & 0x00FF)			// Extracts the bitwise-not of the first byte.
#define	pliBYTE_TWO_N(X)		((~(X) & 0xFF00) >> 8)	// Bitwise not of the second byte.

#define	pliBYTE_ONE_SHIFTED(X)	(((X) & 0x00FF) << 8)	// Shifts byte one of X into byte two.

#define	pliDATA(X)				pliBYTE_ONE(X)			// Gets the data from X.
#define	pliBUFFER(X)			pliBYTE_TWO(X)			// Gets the buffer from X.
#define	pliADDBUFFER(X,Y)		(Y) += pliBUFFER(X)		// Adds the buffer of X to Y.
#define	pliADDDATA(X,Y)			(Y) += pliDATA(X)		// Adds the data of X to Y.

#define	pliDATA_T2(X)			(pliDATA(X) << 1)		// Gets the data from X and multiplies it by 2.
#define	pliBUFFER_T2(X)			(((X) & 0xFF00) >> 7)	// Gets the buffer of X and multiplies it b 2.
#define	pliADDDATA_T2(X,Y)		(Y) += pliDATA_T2(X)	// Add the data (times 2) from X to Y.
#define	pliADDBUFFER_T2(X,Y)	(Y) += pliBUFFER_T2(X)	// Add the buffer (times 2) of X to Y.

#define	pliFLUSH(X) 			(X) &= 0x00FF			// Flush the buffer of X. That is, clear out the
														// data in the buffer.