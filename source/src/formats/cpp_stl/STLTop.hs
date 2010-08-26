{-
    BNF Converter: C++ Main file
    Copyright (C) 2004  Author:  Markus Forsberg, Michael Pellauer

    Modified from CPPTop to STLTop 2006 by Aarne Ranta.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
-}

module STLTop (makeSTL) where

import Utils
import CF
import CFtoSTLAbs
import CFtoFlex
import CFtoBisonSTL
import CFtoCVisitSkelSTL
import CFtoSTLPrinter
import CFtoLatex
import System
import GetCF
import Char
import System
import STLUtils

makeSTL :: Bool -> Bool -> Maybe String -> String -> FilePath -> IO ()
makeSTL make linenumbers inPackage name file = do
  (cf, isOK) <- tryReadCF file
  if isOK then do 
    let (hfile, cfile) = cf2CPPAbs linenumbers inPackage name cf
    writeFileRep "Absyn.H" hfile
    writeFileRep "Absyn.C" cfile
    let (flex, env) = cf2flex inPackage name cf
    writeFileRep (name ++ ".l") flex
    putStrLn "   (Tested with flex 2.5.31)"
    let bison = cf2Bison linenumbers inPackage name cf env
    writeFileRep (name ++ ".y") bison
    putStrLn "   (Tested with bison 1.875a)"
    let header = mkHeaderFile inPackage cf (allCats cf) (allEntryPoints cf) env
    writeFileRep "Parser.H" header
    let (skelH, skelC) = cf2CVisitSkel inPackage cf
    writeFileRep "Skeleton.H" skelH
    writeFileRep "Skeleton.C" skelC
    let (prinH, prinC) = cf2CPPPrinter inPackage cf
    writeFileRep "Printer.H" prinH
    writeFileRep "Printer.C" prinC
    writeFileRep "Test.C" (cpptest inPackage cf)
    let latex = cfToLatex name cf
    writeFileRep (name ++ ".tex") latex
    if make then (writeFileRep "Makefile" $ makefile name) else return ()
    putStrLn "Done!"
   else do putStrLn $ "Failed"
	   exitFailure

makefile :: String -> String
makefile name = unlines 
  [
   "CC = g++",
   "CCFLAGS = -g",
   "FLEX = flex",
   "BISON = bison",
   "LATEX = latex",
   "DVIPS = dvips",
   "",
   "all: test" ++ name ++ " " ++ name ++ ".ps",
   "",
   "clean:",
   -- peteg: don't nuke what we generated - move that to the "vclean" target.
   "\trm -f *.o " ++ name ++ ".dvi " ++ name ++ ".aux " ++ name ++ ".log " ++ name ++ ".ps test" ++ name,
   "",
   "distclean:",
   "\t rm -f *.o Absyn.C Absyn.H Test.C Parser.C Parser.H Lexer.C Skeleton.C Skeleton.H Printer.C Printer.H " ++ name ++ ".l " ++ name ++ ".y " ++ name ++ ".tex " ++ name ++ ".dvi " ++ name ++ ".aux " ++ name ++ ".log " ++ name ++ ".ps test" ++ name ++ " Makefile",
   "",
   "test" ++ name ++ ": Absyn.o Lexer.o Parser.o Printer.o Test.o",
   "\t@echo \"Linking test" ++ name ++ "...\"",
   "\t${CC} ${CCFLAGS} *.o -o test" ++ name ++ "",
   "        ",
   "Absyn.o: Absyn.C Absyn.H",
   "\t${CC} ${CCFLAGS} -c Absyn.C",
   "",
   "Lexer.C: " ++ name ++ ".l",
   "\t${FLEX} -oLexer.C " ++ name ++ ".l",
   "",
   "Parser.C: " ++ name ++ ".y",
   "\t${BISON} " ++ name ++ ".y -o Parser.C",
   "",
   "Lexer.o: Lexer.C Parser.H",
   "\t${CC} ${CCFLAGS} -c Lexer.C ",
   "",
   "Parser.o: Parser.C Absyn.H",
   "\t${CC} ${CCFLAGS} -c Parser.C",
   "",
   "Printer.o: Printer.C Printer.H Absyn.H",
   "\t${CC} ${CCFLAGS} -c Printer.C",
   "",
   "Skeleton.o: Skeleton.C Skeleton.H Absyn.H",
   "\t${CC} ${CCFLAGS} -c Skeleton.C",
   "",
   "Test.o: Test.C Parser.H Printer.H Absyn.H",
   "\t${CC} ${CCFLAGS} -c Test.C",
   "",
   "" ++ name ++ ".dvi: " ++ name ++ ".tex",
   "\t${LATEX} " ++ name ++ ".tex",
   "",
   "" ++ name ++ ".ps: " ++ name ++ ".dvi",
   "\t${DVIPS} " ++ name ++ ".dvi -o " ++ name ++ ".ps",
   ""
  ]
  
cpptest :: Maybe String -> CF -> String
cpptest inPackage cf =
  unlines
   [
    "/*** Compiler Front-End Test automatically generated by the BNF Converter ***/",
    "/*                                                                          */",
    "/* This test will parse a file, print the abstract syntax tree, and then    */",
    "/* pretty-print the result.                                                 */",
    "/*                                                                          */",
    "/****************************************************************************/",
    "#include <stdio.h>",
    "#include \"Parser.H\"",
    "#include \"Printer.H\"",
    "#include \"Absyn.H\"",
    "",
    "int main(int argc, char ** argv)",
    "{",
    "  FILE *input;",
    "  if (argc > 1) ",
    "  {",
    "    input = fopen(argv[1], \"r\");",
    "    if (!input)",
    "    {",
    "      fprintf(stderr, \"Error opening input file.\\n\");",
    "      exit(1);",
    "    }",
    "  }",
    "  else input = stdin;",
    "  /* The default entry point is used. For other options see Parser.H */",
    "  " ++ scope ++ def ++ " *parse_tree = " ++ scope ++ "p" ++ def ++ "(input);",
    "  if (parse_tree)",
    "  {",
    "    printf(\"\\nParse Succesful!\\n\");",
    "    printf(\"\\n[Abstract Syntax]\\n\");",
    "    " ++ scope ++ "ShowAbsyn *s = new " ++ scope ++ "ShowAbsyn();",
    "    printf(\"%s\\n\\n\", s->show(parse_tree));",
    "    printf(\"[Linearized Tree]\\n\");",
    "    " ++ scope ++ "PrintAbsyn *p = new " ++ scope ++ "PrintAbsyn();",
    "    printf(\"%s\\n\\n\", p->print(parse_tree));",
    "    return 0;",
    "  }",
    "  return 1;",
    "}",
    ""
   ]
  where
   def = head (allEntryPoints cf)
   scope = nsScope inPackage

mkHeaderFile inPackage cf cats eps env = unlines
 [
  "#ifndef " ++ hdef,
  "#define " ++ hdef,
  "",
  "#include<vector>",
  "#include<string>",
  "",
  nsStart inPackage,
  concatMap mkForwardDec cats,
  "typedef union",
  "{",
  "  int int_;",
  "  char char_;",
  "  double double_;",
  "  char* string_;",
  (concatMap mkVar cats) ++ "} YYSTYPE;",
  "",
  concatMap mkFuncs eps,
  nsEnd inPackage,
  "",
  "#define " ++ nsDefine inPackage "_ERROR_" ++ " 258",
  mkDefines (259 :: Int) env,
  "extern " ++ nsScope inPackage ++ "YYSTYPE " ++ nsString inPackage ++ "yylval;",
  "",
  "#endif"
 ]
 where
  hdef = nsDefine inPackage "PARSER_HEADER_FILE"
  mkForwardDec s | (normCat s == s) = "class " ++ (identCat s) ++ ";\n"
  mkForwardDec _ = ""
  mkVar s | (normCat s == s) = "  " ++ (identCat s) ++"*" +++ (map toLower (identCat s)) ++ "_;\n"
  mkVar _ = ""
  mkDefines n [] = mkString n
  mkDefines n ((_,s):ss) = ("#define " ++ s +++ (show n) ++ "\n") ++ (mkDefines (n+1) ss) -- "nsDefine inPackage s" not needed (see cf2flex::makeSymEnv)
  mkString n =  if isUsedCat cf "String" 
   then ("#define " ++ nsDefine inPackage "_STRING_ " ++ show n ++ "\n") ++ mkChar (n+1)
   else mkChar n
  mkChar n =  if isUsedCat cf "Char" 
   then ("#define " ++ nsDefine inPackage "_CHAR_ " ++ show n ++ "\n") ++ mkInteger (n+1)
   else mkInteger n
  mkInteger n =  if isUsedCat cf "Integer" 
   then ("#define " ++ nsDefine inPackage "_INTEGER_ " ++ show n ++ "\n") ++ mkDouble (n+1)
   else mkDouble n
  mkDouble n =  if isUsedCat cf "Double" 
   then ("#define " ++ nsDefine inPackage "_DOUBLE_ " ++ show n ++ "\n") ++ mkIdent(n+1)
   else mkIdent n
  mkIdent n =  if isUsedCat cf "Ident" 
   then ("#define " ++ nsDefine inPackage "_IDENT_ " ++ show n ++ "\n")
   else ""
  mkFuncs s | (normCat s == s) = (identCat s) ++ "*" +++ "p" ++ (identCat s) ++ "(FILE *inp);\n" ++
                                 (identCat s) ++ "*" +++ "p" ++ (identCat s) ++ "(const char *str);\n"
  mkFuncs _ = ""
