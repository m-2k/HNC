
module SPL.Interpretator (SPL.Interpretator.P (..), step, get_code_of_expr) where

import SPL.Parser
import SPL.Compiler
import SPL.Check3
import SPL.Top
--import Debug.Trace

import Data.Map as M hiding (map, filter)

data P = P ([Char], [Char]) | N ([Char], [Char])

step str =
	case parse str of
		SPL.Parser.P _ i p ->
			case compile p of
				SPL.Compiler.P c ->
					case check0 c of
						SPL.Check3.P (ur, a)|M.null ur -> SPL.Interpretator.P (show a, show $ eval0 c)
						SPL.Check3.P (u2, a) -> error ("check0 returned saved vars: "++show u2++"\n"++show str)
						SPL.Check3.N e -> SPL.Interpretator.N $ ("type error: " ++ e, show c)
				SPL.Compiler.N ->
					SPL.Interpretator.N ("compile error", "")
		SPL.Parser.N i ->
			SPL.Interpretator.N ("  "++(take i $ repeat ' ')++"^ parser error", "")

get_code_of_expr str =
	case parse str of
		SPL.Parser.P _ i p ->
			case compile p of
				SPL.Compiler.P c -> SPL.Interpretator.P (show c, "")
				SPL.Compiler.N -> SPL.Interpretator.N ("compile error", "")
		SPL.Parser.N i ->
			SPL.Interpretator.N ("  "++(take i $ repeat ' ')++"^ parser error", "")

{-comp2 str = 
	case parse str of
	Parser.P i p ->
		case compile p of
		Compiler.P c -> show c
		Compiler.N -> "compile error"
	Parser.N i -> "parser error"
