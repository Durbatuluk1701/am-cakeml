type 'a coq_EqClass =
  'a -> 'a -> bool
  (* singleton inductive, whose constructor was Build_EqClass *)

(** val eqb : 'a1 coq_EqClass -> 'a1 -> 'a1 -> bool **)

fun eqb eqClass =
  eqClass

(** val coq_EqClass_impl_DecEq : 'a1 coq_EqClass -> 'a1 -> 'a1 -> sumbool **)

fun coq_EqClass_impl_DecEq h x y =
  let val b = h x y in (case b of
                          True => Coq_left
                        | False => Coq_right) end

(** val nat_EqClass : nat coq_EqClass **)

val nat_EqClass =
  Nat.eqb

(** val eqbPair :
    'a1 coq_EqClass -> 'a2 coq_EqClass -> ('a1, 'a2) prod -> ('a1, 'a2) prod
    -> bool **)

fun eqbPair h h' p1 p2 =
  let val Coq_pair a1 b1 = p1 in
  let val Coq_pair a2 b2 = p2 in
  (case eqb h a1 a2 of
     True => eqb h' b1 b2
   | False => False) end end

(** val pair_EqClass :
    'a1 coq_EqClass -> 'a2 coq_EqClass -> ('a1, 'a2) prod coq_EqClass **)

val pair_EqClass =
  eqbPair
