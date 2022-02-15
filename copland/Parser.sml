(* util/Extra.sml
 * util/ByteString.sml
 * util/Misc.sml
 * util/Parsing.sml
 * copland/CoqDefaults.sml
 * copland/Instr.sml
 *)
(* term    ::= '(' term ')'
             | asp
 *           | term '->' term 
 *           | term sp '<' sp term
 *           | term sp '~' sp term
 *           | '@' NUMERAL '[' term ']'
 * sp      ::= '+' | '-'
 * asp     ::= NUMERAL STRING*
 *           | '_' | '!' | '#'
 * NUMERAL ::= [0-9]+
 * STRING  ::= '"' [^"] '"'
 * WS      ::= [ \t\r\n]*
 *)
local
    (* Import definitions *)
    val pure  = Parser.pure
    val bind  = Parser.bind
    val bind_ = Parser.seq

    (* ('a, char) parser -> ('a, char) parser *)
    fun token p = Parser.followedBy p Parser.spaces

    (* (string, char) parser *)
    fun symbol s = token (Parser.string s)

    (* ('a, char) parser -> ('a, char) parser *)
    fun parens p = Parser.between (symbol "(") (symbol ")") p
in
    (* numeralP :: (nat, char) parser *)
    val numeralP = token (
        Parser.bindResult
            (fn numStr =>
                OptionExtra.option
                    (Err "failed to parse an integer")
                    (fn x => Ok (natFromInt x))
                    (Int.fromString (String.implode numStr)))
            (Parser.many1 Parser.digit))

    (* identifierP :: (id, char) parser *)
    val identifierP =
        Parser.map (fn x => Id x) numeralP

    (* stringP :: (string, char) parser *)
    val stringP =
        Parser.map String.implode
            (Parser.between (Parser.char #"\"") (symbol "\"")
                (Parser.many (Parser.notChar #"\"")))

    (* copyP, signP, hashP, aspcP :: (asp, char) parser *)
    val copyP = Parser.return Cpy (symbol "_")
    val signP = Parser.return Sig (symbol "!")
    val hashP = Parser.return Hsh (symbol "#")
    val aspcP = 
        bind identifierP (fn ident =>
        bind (Parser.many stringP) (fn args =>
        pure (Aspc ident args)
        ))

   (* allP, noneP, spP :: (sp, char) parser *)
    val allP = Parser.return ALL (symbol "+")
    val noneP = Parser.return NONE (symbol "-")
    val spP = Parser.choice [allP, noneP]

    (* (sp -> sp -> term -> term -> term, char) parser *)
    val bseqP = Parser.return (fn lsp => fn rsp => fn x => fn y => Bseq (lsp, rsp) x y) (symbol "<")
    val bparP = Parser.return (fn lsp => fn rsp => fn x => fn y => Bpar (lsp, rsp) x y) (symbol "~")

    (* (term -> term -> term, char) parser *)
    val splitOpP = 
        bind spP (fn l =>
        bind (Parser.choice [bseqP, bparP]) (fn splitOp =>
        bind spP (fn r =>
        pure (splitOp l r)
        )))
    val lseqP = Parser.return (fn x => fn y => Lseq x y) (symbol "->")
    val infixOpP = Parser.choice [lseqP, splitOpP]

    (* aspP :: (asp, char) parser *)
    val aspP = Parser.choice [copyP, signP, hashP, aspcP]

    (* aspP :: (term, char) parser *)
    val aspTermP = Parser.map (fn a => Asp a) aspP

    (* (term, char) parser -> (term, char) parser *)
    fun atP subP = 
        bind_ (symbol "@") (
        bind  numeralP (fn pl =>
        bind  (Parser.between (symbol "[") (symbol "]") subP) (fn t =>
        pure (Att pl t)
        )))

    (* (term, char) parser *)
    (* All infix ops have equal precedence and associate rightward *)
    fun termP stream =
        bind (Parser.choice [parens termP, atP termP, aspTermP]) (fn t =>
        Parser.choice [
            bind infixOpP (fn iop =>
            bind termP (fn t' =>
            pure (iop t t')
            )),
            pure t]
        ) stream

    (* string -> (term, string) result *)
    val parseTerm = Parser.parse (
        bind_ Parser.spaces (
        Parser.followedBy termP Parser.eof
        )
    )
end