Require Import bedrock2.Syntax bedrock2.Syntax.Basic.
Require Import bedrock2.NotationsCustomEntry coqutil.Z.HexNotation.
Require Import bedrock2.FE310CSemantics. (* TODO for andres: [literal] shouldn't need this *)

Import Syntax BinInt String List.ListNotations.
Local Existing Instance Syntax.Basic.parameters.
Local Open Scope string_scope. Local Open Scope Z_scope. Local Open Scope list_scope.
Local Coercion literal (z : Z) : expr := expr.literal z.
Local Coercion var (x : String.string) : expr := expr.var x.

Definition lightbulb := 
    let packet : varname := "packet" in
    let len : varname := "len" in
    let ethertype : varname := "ethertype" in
    let protocol : varname := "protocol" in
    let port : varname := "port" in
    let mmio_val : varname := "mmio_val" in
    let command : varname := "command" in
    let MMIOREAD : varname := "MMIOREAD" in
    let MMIOWRITE : varname := "MMIOWRITE" in
    let r : varname := "r" in

  ("lightbulb", ((packet::len::nil), (r::nil), bedrock_func_body:(

    ethertype = ((load1(packet + constr:(12)) << constr:(8)) | (load1(packet + constr:(13))));
    require (constr:(1536 - 1) < ethertype) else { r = (constr:(-1)) };

    protocol = (load1(packet + constr:(23)));
    require (protocol == constr:(Ox"11")) else { r = (constr:(-1)) };

    command = (load1(packet + constr:(42))); (* TODO: MMIOWRITE one bit only *)

    io! mmio_val = MMIOREAD(constr:(Ox"10012008"));
    output! MMIOWRITE(constr:(Ox"10012008"), mmio_val | constr:(1) << constr:(23));

    io! mmio_val = MMIOREAD(constr:(Ox"1001200c"));
    output! MMIOWRITE(constr:(Ox"1001200c"), mmio_val | command << constr:(23));

    r = (constr:(0))
  ))).


From coqutil Require Import Word.Interface Map.Interface.
From coqutil.Tactics Require Import letexists eabstract.
From bedrock2 Require Import FE310CSemantics Semantics WeakestPrecondition ProgramLogic Array Scalars.
From bedrock2.Map Require Import Separation SeparationLogic.

Local Existing Instance bedrock2.FE310CSemantics.parameters.
Local Infix "*" := sep.
Local Infix "*" := sep : type_scope.
Instance spec_of_lightbulb : spec_of "lightbulb" := fun functions => 
  forall p_addr packet len R m t,
    (array scalar8 (word.of_Z 1) p_addr packet * R) m ->
    42 < Z.of_nat (List.length packet) ->
    (* ^ TODO from andres: when code is changed to check length, this precondition can be removed *)
    WeakestPrecondition.call functions "lightbulb" t m [p_addr; len]
      (fun t' m' rets => exists v, rets = [v]).

Ltac seplog_use_array_load1 H i :=
  let iNat := eval cbv in (Z.to_nat i) in
  let H0 := fresh in pose proof H as H0;
  unshelve SeparationLogic.seprewrite_in @array_index_nat_inbounds H0;
    [exact iNat|exact (word.of_Z 0)|Lia.lia|];
  change ((word.unsigned (word.of_Z 1) * Z.of_nat iNat)%Z) with i in *.

(* bsearch.v has examples to deal with arrays *)
Lemma lightbulb_ok : program_logic_goal_for_function! lightbulb.
Proof.
  repeat straightline.

  seplog_use_array_load1 H 12.
  seplog_use_array_load1 H 13.
  seplog_use_array_load1 H 23.
  seplog_use_array_load1 H 42.
  repeat straightline.

  (* if for early out *)
  letexists; split; repeat straightline; split; [|repeat straightline; eauto].
  repeat straightline.

  (* if for early out *)
  letexists; split; repeat straightline; split; [|repeat straightline; eauto].
  repeat straightline.

  (* the 1st MMIOREAD *)
  { hnf.
    letexists. split. { 
       left. split. { exact eq_refl. } { split. { exact eq_refl. }
       intros. { letexists. split. { subst l1. exact eq_refl. } 
    repeat straightline.

  { hnf. letexists. split. { 
       right. split. { exact eq_refl. } { letexists. split. { subst args0. exact eq_refl. }
       intros. { letexists. split. { subst l1. exact eq_refl. } 

    repeat straightline.

  { hnf. letexists. split. { 
       left. split. { exact eq_refl. } { split. { exact eq_refl. }
       intros. { letexists. split. { subst l1. exact eq_refl. } 
    repeat straightline.

  { hnf. letexists. split. { 
       right. split. { exact eq_refl. } { letexists. split. { subst args0. exact eq_refl. }
       intros. { letexists. split. { subst l1. exact eq_refl. } 
  (* TODO for andres: accumulate trace in context instead of goal *)
    repeat straightline.
    eauto. } } }
  cbv. eauto. 
  (* TODO: reorder subgoals in ext_spec -- address range checks should be earlier *)
} } } }
  cbv. eauto. } } } }
  cbv. eauto. } } } }
  cbv. eauto. } 
Qed.

Compute c_func lightbulb.