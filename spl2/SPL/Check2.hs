
module SPL.Check2 (P (..), check0, res) where

import Data.Map as M hiding (filter)

import SPL.Types
import SPL.Code hiding (res)
import SPL.Top
--import Debug.Trace

data P = P (Map [Char] T, T) | N [Char]
	deriving Show


get_r (P (ur, r)) = r
get_rl l = Prelude.map get_r l

union a b =
	M.unionWith (\a b ->
		case Check2.compare a b of
			(_, _, True) -> a -- b ?
			(_, _, False) -> error "union"
	) a b

ch [] [] et ul uv =
	N "too many parameters for"
ch (r:[]) [] et ul uv =
--	trace ("cmpRet: "++show r++" |"++show ul++" |"++show uv) $
--	P (uv, setm (setm r ul) uv)
	P (uv, setm r ul)
ch r [] et ul uv =
--	trace ("cmpERROR") $
	P (uv, setm (TT r) ul)
ch (r:rs) (p1:ps) et ul uv =
	case check p1 et of
		P (rm, r_p1) ->
			case Check2.compare (setm r ul) r_p1 of
				(l2, r2, True) ->
--					trace ("cmp: "++show (setm r ul)++","++show r_p1++
--					"\n  "++show l2++"|"++show r2) $
					ch rs ps et
						(Check2.union l2 ul)
--						(M.map (\x -> setm (setm x r2) uv) $ Check2.union rm $ Check2.union r2 uv)
						(M.map (\x -> setm x (Check2.union r2 $ Check2.union rm uv)) $ Check2.union r2 $ Check2.union rm uv)
				(l2, r2, False) ->
--					trace (show r++show (get_r p1)++"|"++show ul)$
					N ("expected "++show (setm r ul)++", actual "++show r_p1++"|="++show p1)
--					N ("expected "++show r++", actual "++show r_p1)
		N e -> N e

check::C -> Map [Char] T -> P
check (CNum n) et = P (M.empty, T "num")
check (CBool n) et = P (M.empty, T "boolean")
check (CStr n) et = P (M.empty, T "string")
check (CVal n) et =
	case M.lookup n et of
		Just a -> P (M.empty, a)
		Nothing -> N $ (++) "check cannot find " $ show n

check (CL a (K [])) et =
	check a et

check (CL a (K p)) et =
	case check a et of
		P (rm0, TT r) ->
			case ch r p et M.empty M.empty of
				P (rm, r) ->
					P (Check2.union rm0 rm, r)
				N e -> N (e++" for "++show a)
--		P (rm, TU n) ->
--			P (putp [n] [TT ((get_rl p_ok)++[TU ('_':n)])] rm, TU ('_':n))
		P (_, TT []) ->
			N ("too many parameters for "++show a)
		P (ur, TU n) ->
			P (putp [n] [TT (get_rl p_ok++[TU ('_':n)])] M.empty, TU ('_':n)) -- ?
		N e -> N e
	where
		p_ok = Prelude.map (\x -> check x et) p

check (CL a (S [])) et =
	check a et

check (CL a (S (p:ps))) et =
	case check (CL a (S ps)) (putp [p] [TU p_n] et) of
		P (ur, r) ->
			case M.lookup (p_n) ur of
				Just v ->
					let w = case (v, r) of
						(a, TT b) -> TT (a:b)
						(a, b) -> TT [a, b]
					in
					P (ur, w)
				Nothing ->
					let w = case r of
						TT b -> TT ((TU p_n):b)
						b -> TT [TU p_n, b]
					in
					P (ur, w) -- rm ?
		o -> o
	where p_n = ""++p

check (CL a L) et =
	case check a et of
		P (ur, r) ->
			P (ur, TT [TL, r])
		o -> o
	
check (CL a R) et =
	case check a (putp ["_f"] [TU "_f"] et) of
		P (ur, r) -> check a (putp ["_f"] [r] et)
		o -> o

check o et =
	error ("check o: "++show o)

putp (v:vs) (c:cs) et = putp vs cs (M.insert v c et)
putp [] [] et = et
putp o1 o2 et = error ("Check2.putp: "++show o1++", "++show o2)

compare (T a) (T b)|a == b = (M.empty, M.empty, True)
compare (TD a l1) (TD b l2)|a == b = foldr (\(u1l,u1r,r1) (u2l,u2r,r2) -> (M.union u1l u2l, M.union u1r u2r, r1 && r2)) (M.empty, M.empty, True) $ zipWith Check2.compare l1 l2
--compare (TT l1) (TT l2) = foldr (\(u1l,u1r,r1) (u2l,u2r,r2) -> (M.union u1l u2l, M.union u1r u2r, r1 && r2)) (M.empty, M.empty, True) $ zipWith Check2.compare l1 l2
-- error: TT [T "num",TU "_l"]/TT [TU "_",TU "z",T "num"]
compare (TT []) (TT []) =
	(M.empty, M.empty, True)
compare (TT [TU a]) b@(TT l)|1 < length l =
	(M.singleton a b, M.empty, True)
compare (TT (l1:l1s)) (TT (l2:l2s)) =
	(M.union l ll, M.union r rr, b && bb)
	where
		(l, r, b) = Check2.compare l1 l2
		(ll, rr, bb) = Check2.compare (TT l1s) (TT l2s)
compare a (TV n) = (M.empty, M.singleton n a, True)
compare (TU a) (TU b) = (M.empty, M.empty, True)
compare (TU n) b = (M.singleton n b, M.empty, True)
compare a (TU n) = (M.empty, M.singleton n a, True) -- correct ?
compare TL TL = (M.empty, M.empty, True) -- return lazy?
--compare t1 t2 = error $ (show t1)++"/"++(show t2)
compare t1 t2 = (M.empty, M.empty, False)

setu (TD n tt) u = TD n (Prelude.map (\t -> setu t u) tt)
setu (TT tt) u = TT (Prelude.map (\t -> setu t u) tt)
setu (TU n) (t2:t2s) = t2
setu o (t2:t2s) = o
setu o [] = o

setml2 l u = Prelude.map (\(P (rm, r)) -> P (rm, setm r u)) l
setml l u = Prelude.map (\x -> setm x u) l
setm (TD n tt) u = TD n (Prelude.map (\t -> setm t u) tt)
setm (TT tt) u = TT (Prelude.map (\t -> setm t u) tt)
setm (TU n) u =
	case M.lookup n u of
		Just a -> a
		Nothing -> TU n
setm o u = o

check0 o =
--	trace ("check0: "++show o) $
	check o Top.get_types

res = Check2.compare (TD "list" [TT [T "num",T "num"]]) (TD "list" [TT [T "num",T "num"]])


