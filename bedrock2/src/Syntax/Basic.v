Require Import bedrock2.Syntax bedrock2.ToCString.
Require Import coqutil.Datatypes.String.
Require Coq.Strings.String Coq.Numbers.DecimalZ Coq.Numbers.DecimalString.

Definition parameters := {|
  Syntax.varname := String.string;
  Syntax.funname := String.string;
  Syntax.actname := String.string;
|}.

Import bedrock2.Syntax.bopname.
Definition to_c_parameters : ToCString.parameters := {|
  syntax := parameters;
  c_lit w := DecimalString.NilZero.string_of_int (BinInt.Z.to_int w) ++ "ULL";
  c_bop := fun e1 op e2 =>
             match op with
             | add => e1++"+"++e2
             | sub => e1++"-"++e2
             | mul => e1++"*"++e2
             | mulhuu => "sizeof(intptr_t) == 4 ? ((uint64_t)"++e1++"*"++e2++")>>32 : ((__uint128_t)"++e1++"*"++e2++")>>64 /* TODO this has not been tested */"
             | divu => e1++"/"++e2
             | remu => e1++"%"++e2
             | and => e1++"&"++e2
             | or => e1++"|"++e2
             | xor => e1++"^"++e2
             | sru => e1++">>"++e2
             | slu => e1++"<<"++e2
             | srs => "(intptr_t)"++e1++">>"++e2
             | lts => "(intptr_t)"++e1++"<"++"(intptr_t)"++e2
             | ltu => e1++"<"++e2
             | eq => e1++"=="++e2
             end%string;
     c_var := id;
     c_fun := id;
     c_act := ToCString.c_call;

     varname_eqb := String.eqb;
     rename_away_from x xs :=
       let x' := "_" ++ x in
       if List.existsb (String.eqb x') xs
       then "#error rename_away_from '" ++ x ++"' = '" ++ x' ++"'"
       else x'
  |}%string.

Definition c_func := @c_func to_c_parameters.