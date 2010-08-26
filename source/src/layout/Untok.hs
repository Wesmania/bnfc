{-
    BNF Converter: untokenizer
    Copyright (C) 2004  Author: Aarne Ranta

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

module Untok where

import LexAlfa2
import Alex

untok :: [Token] -> String
untok = unto (1,1) where
  unto _  [] = ""
  unto (l0,c0) (t@(PT (Pn _ l c) _) : ts) = 
    let s  = prToken t 
        ns = l - l0
        ls = replicate ns '\n'
        cs = replicate (if ns == 0 then c - c0 else c-1) ' '
    in ls ++ cs ++ s ++ unto (l,c + length s) ts

