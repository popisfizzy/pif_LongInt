// This file is so that the #undefs for the various preprocessors are handled correctly.

// INCLUDE FIRST.
#include "+Preprocessors.dm"
// INCLUDE FIRST

// MAIN LIBRARY CODE
#include "pif_Arithmetic Protocol.dm"
#include "pif_LongInt.dm"

#include "pif_LongInt Subclasses/Unsigned32.dm"
#include "pif_LongInt Subclasses/Signed32.dm"
// MAIN LIBRARY CODE

// INCLUDE LAST
#include "+Preprocessor undefs.dm"
// INCLUDE LAST
