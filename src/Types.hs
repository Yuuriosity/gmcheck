module Types where

{-| Resource type. In GML it's actually just a number, but here we want to differ. -}
data Resource
    = RSprite
    | RBackground
    | RSound
    | RObject
    | RRoom
    -- TODO: paths, etc.
    deriving (Eq, Show)

{-| Value type. -}
data Type
    = TVoid -- ^ Should be used only as a return type
    | TReal | TString
    | TArray Type | TArray2 Type
    | TId Resource -- ^ Resource descriptor
    | TUnknown [Type] -- ^ Unknown type with possibilities, if any
    deriving (Eq, Show)

tBool, tInstance, tSprite, tObject, tRoom, tUnknown :: Type
tBool = TReal
tInstance = TReal
tSprite = TId RSprite
tObject = TId RObject
tRoom = TId RRoom
tUnknown = TUnknown []

{-| Function or script signature. -}
data Signature = Sig [Type] Type --TODO: variadic and optional arguments
    deriving (Eq, Show)