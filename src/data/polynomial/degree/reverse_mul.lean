/-
Copyright (c) 2020 Damiano Testa. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Damiano Testa
-/

import tactic
import data.polynomial.degree.basic
import data.polynomial.degree.trailing_degree

open polynomial finsupp finset

namespace polynomial

variables {R : Type*} [semiring R] {f : polynomial R}

lemma mem_support_C_mul_X_pow {n a : ℕ} {c : R} : a ∈ (C c * X ^ n).support → a = n :=
begin
  intro,
  rw [mem_support_iff_coeff_ne_zero, coeff_C_mul_X c n a] at a_1,
  finish,
end

lemma support_C_mul_X_pow (c : R) (n : ℕ) : (C c * X ^ n).support ⊆ singleton n :=
begin
  intro a,
  rw mem_singleton,
  exact mem_support_C_mul_X_pow,
end

lemma card_support_C_mul_X_pow_le_one {c : R} {n : ℕ} : (C c * X ^ n).support.card ≤ 1 :=
begin
  rw ← card_singleton n,
  apply card_le_of_subset,
  exact support_C_mul_X_pow c n,
end

lemma nat_degree_mem_support_of_nonzero (H : f ≠ 0) : f.nat_degree ∈ f.support :=
(f.3 f.nat_degree).mpr ((not_congr leading_coeff_eq_zero).mpr H)

lemma le_nat_degree_of_mem_supp (a : ℕ) :
  a ∈ f.support → a ≤ nat_degree f:=
begin
  rw mem_support_iff_coeff_ne_zero,
  exact le_nat_degree_of_ne_zero,
end

lemma le_degree_of_mem_supp (a : ℕ) :
  a ∈ f.support → a ≤ nat_degree f :=
begin
  rw mem_support_iff_coeff_ne_zero,
  exact le_nat_degree_of_ne_zero,
end

lemma nonempty_support_iff : f.support.nonempty ↔ f ≠ 0 :=
begin
  split,
    { intro,
      cases a with N Nhip,
      rw mem_support_iff_coeff_ne_zero at Nhip,
      finish, },
    { intro fne,
      apply nonempty_iff_ne_empty.mpr,
      apply ne_empty_of_mem,
      exact mem_support_iff_coeff_ne_zero.mpr ((not_congr leading_coeff_eq_zero).mpr fne), },
end

lemma nat_degree_eq_support_max' (h : f ≠ 0) :
  f.nat_degree = f.support.max' (nonempty_support_iff.mpr h) :=
begin
  apply le_antisymm,
  { apply finset.le_max',
    rw mem_support_iff_coeff_ne_zero,
    exact (not_congr leading_coeff_eq_zero).mpr h, },
  { apply max'_le,
    intros y hy,
    exact le_degree_of_mem_supp y hy, }
end

lemma support_C_mul_X_pow_nonzero {c : R} {n : ℕ} (h : c ≠ 0): (C c * X ^ n).support = singleton n :=
begin
  ext1,
  rw mem_singleton,
  split,
    { exact mem_support_C_mul_X_pow, },
    { intro,
      rwa [mem_support_iff_coeff_ne_zero, ne.def, a_1, coeff_C_mul, coeff_X_pow_self n, mul_one], },
end

lemma nat_degree_C_mul_X_pow_le (a : R) (n : ℕ) : nat_degree (C a * X ^ n) ≤ n :=
begin
  by_cases a0 : a = 0,
    rw [a0, C_0, zero_mul, nat_degree_zero],
    exact nat.zero_le _,


    rw nat_degree_eq_support_max',
      { simp_rw [support_C_mul_X_pow_nonzero a0, max'_singleton n], },
      { intro,
        apply a0,
        rw [← C_inj, C_0],
        apply mul_X_pow_eq_zero a_1, },
end


lemma nat_degree_C_mul_X_pow_nonzero {a : R} (n : ℕ) (ha : a ≠ 0) : nat_degree (C a * X ^ n) = n :=
begin
  rw nat_degree_eq_support_max',
    { simp_rw [support_C_mul_X_pow_nonzero ha, max'_singleton n], },
    { intro,
      apply ha,
      rw [← C_inj, C_0],
      apply mul_X_pow_eq_zero a_1, },
end


@[simp] lemma trailing_coeff_eq_zero : trailing_coeff f = 0 ↔ f = 0 :=
⟨λ h, by_contradiction $ λ hp, mt mem_support_iff.1
  (not_not.2 h) (mem_of_min (trailing_degree_eq_nat_trailing_degree hp)),
λ h, h.symm ▸ leading_coeff_zero⟩

lemma trailing_coeff_nonzero_of_nonzero : f ≠ 0 ↔ trailing_coeff f ≠ 0 :=
begin
  apply not_congr trailing_coeff_eq_zero.symm,
end


lemma nat_trailing_degree_mem_support_of_nonzero : f ≠ 0 → nat_trailing_degree f ∈ f.support :=
begin
  rw mem_support_iff_coeff_ne_zero,
  exact trailing_coeff_nonzero_of_nonzero.mp,
end

lemma nat_trailing_degree_le_of_mem_supp (a : ℕ) :
  a ∈ f.support → nat_trailing_degree f ≤ a:=
begin
  rw mem_support_iff_coeff_ne_zero,
  exact nat_trailing_degree_le_of_ne_zero,
end

lemma nat_degree_eq_support_max'_trailing (h : f ≠ 0) :
  nat_trailing_degree f = f.support.min' (nonempty_support_iff.mpr h) :=
begin
  apply le_antisymm,
  { apply le_min',
    intros y hy,
    exact nat_trailing_degree_le_of_mem_supp y hy },
  { apply finset.min'_le,
    rw mem_support_iff_coeff_ne_zero,
    exact trailing_coeff_nonzero_of_nonzero.mp h, },
end

/-- erase_lead of a polynomial f is the polynomial obtained by
subtracting from f the leading term of f. -/
def erase_lead (f : polynomial R) : polynomial R := ⟨ f.support \ singleton f.nat_degree , λ a : ℕ , ite (a = f.nat_degree) 0 f.coeff a , λ a , begin
  simp only [mem_sdiff, mem_support_iff, ne.def, mem_singleton],
  split_ifs,
    { simp only [not_and, pi.zero_apply, not_not, eq_self_iff_true, not_true, iff_false],
      intros a_1,
      assumption, },
    { split,
        { rw and_imp,
          intros a1 a2,
          assumption, },
        { intros a1,
          exact ⟨ a1 , h ⟩, }, },
end ⟩

lemma erase_lead_support (f : polynomial R) :
 (erase_lead f).support = f.support \ singleton f.nat_degree :=
rfl

@[simp] lemma coeff_remove_nat_degree : (erase_lead f).coeff f.nat_degree = 0 :=
begin
  unfold erase_lead,
  simp only [coeff_mk, if_true, pi.zero_apply, eq_self_iff_true],
end

@[simp] lemma coeff_remove_eq_coeff_of_ne {a : ℕ} (h : a ≠ f.nat_degree) : (erase_lead f).coeff a = f.coeff a :=
begin
  unfold erase_lead,
  rw coeff_mk,
  split_ifs,
    { exfalso,
      solve_by_elim, },
    { refl, },
end

lemma sum_leading_C_mul_X_pow_remove (f : polynomial R) : f = (erase_lead f) + (C f.leading_coeff) * X^f.nat_degree :=
begin
  ext1,
  by_cases nm : n = f.nat_degree,
    { subst nm,
      rw [coeff_add, coeff_C_mul, coeff_X_pow_self, mul_one, coeff_remove_nat_degree, zero_add],
      refl, },
    { simp only [*, coeff_remove_eq_coeff_of_ne nm, coeff_X_pow f.nat_degree n, add_zero, coeff_C_mul, coeff_add, if_false, mul_zero], },
end

lemma erase_lead_nonzero_of_large_support (f0 : 2 ≤ f.support.card) : (erase_lead f).support.nonempty :=
begin
  have fn0 : f ≠ 0,
    { intro,
      subst a,
      rw [polynomial.support_zero, card_empty] at f0,
      exact nat.not_succ_le_zero 1 f0, },
  rw nonempty_iff_ne_empty,
  apply @ne_empty_of_mem _ (nat_trailing_degree f),
  rw [mem_support_iff_coeff_ne_zero, coeff_remove_eq_coeff_of_ne, ← mem_support_iff_coeff_ne_zero],
    { exact nat_trailing_degree_mem_support_of_nonzero fn0, },
    { rw [nat_degree_eq_support_max' fn0, nat_degree_eq_support_max'_trailing fn0],
      exact ne_of_lt (finset.min'_lt_max'_of_card _ f0), },
end

lemma not_mem_of_not_mem_supset {a b : finset ℕ} (h : a ⊆ b) {n : ℕ} : n ∉ b → n ∉ a :=
begin
  apply mt,
  solve_by_elim,
end

/-
@[simp] lemma support_erase_lead_sub : (erase_lead f).support ⊆ range f.nat_degree :=
begin
  unfold erase_lead,
  intros a,
  simp_rw [mem_support_iff_coeff_ne_zero, (finset_sum_coeff (range (nat_degree f)) (λ (b : ℕ), C (coeff f b) * X ^ b) a), coeff_C_mul_X (f.coeff _) _ a],
  finish,
end
-/

@[simp] lemma support_erase_lead_ne : f.nat_degree ∉ (erase_lead f).support :=
begin
  rw [erase_lead_support, mem_sdiff, mem_singleton, eq_self_iff_true, not_true, and_false, not_false_iff],
  trivial,
end

@[simp] lemma ne_nat_degree_of_mem_support_remove {a : ℕ} : a ∈ (erase_lead f).support → ¬ a = f.nat_degree :=
begin
  rw erase_lead_support,
  rw [mem_sdiff, mem_singleton, and_imp, imp_self, forall_true_iff],
  trivial,
end

lemma mem_erase_lead_of_mem_diff {a : ℕ} : a ∈ (f.support \ {f.nat_degree}) ↔ a ∈ (erase_lead f).support :=
begin
  rw erase_lead_support,
end

/-
lemma support_erase_lead : (erase_lead f).support = f.support \ {f.nat_degree} :=
begin

  by_cases f0 : f = 0,
    { rw f0,
      apply (support_eq_empty).mpr,
      refl, },
    { ext,
      split,
        { rw mem_support_iff_coeff_ne_zero,
          by_cases ha : a = f.nat_degree,
            { rw ha,
              intro,
              exfalso,
              exact a_1 coeff_remove_nat_degree, },
            { rw [coeff_remove_eq_coeff_of_ne ha, mem_sdiff, not_mem_singleton],
              intro,
              exact ⟨mem_support_iff_coeff_ne_zero.mpr a_1 , ha ⟩,
            }, },
        { exact mem_erase_lead_of_mem_diff, }, },
end
-/

lemma nat_degree_erase_lead (f0 : 2 ≤ f.support.card) : (erase_lead f).nat_degree < f.nat_degree :=
begin
  rw nat_degree_eq_support_max' (nonempty_support_iff.mp (erase_lead_nonzero_of_large_support f0)),
  apply nat.lt_of_le_and_ne _ (ne_nat_degree_of_mem_support_remove ((erase_lead f).support.max'_mem (nonempty_support_iff.mpr _))),
  simp_rw erase_lead_support f,
  apply max'_le,
  intros y hy,
  apply le_nat_degree_of_ne_zero,
  rw mem_sdiff at hy,
  exact (mem_support_iff_coeff_ne_zero.mp hy.1),
end

lemma support_remove_lt (h : f ≠ 0) : (erase_lead f).support.card < f.support.card :=
begin
  rw erase_lead_support,
  apply card_lt_card,
  split,
    { exact f.support.sdiff_subset {nat_degree f}, },
    { intro,
      rw nat_degree_eq_support_max' h at a,
      have : f.support.max' (nonempty_support_iff.mpr h) ∈ f.support \ {f.support.max' (nonempty_support_iff.mpr h)} := a (max'_mem f.support (nonempty_support_iff.mpr h)),
      simp only [mem_sdiff, eq_self_iff_true, not_true, and_false, mem_singleton] at this,
      cases this, },
end

lemma add_cancel {a b : R} {h : a=0} : a+b=b :=
begin
  rw [h, zero_add],
end

lemma C_mul_X_pow_of_card_support_le_one (h : f.support.card ≤ 1) : f = C f.leading_coeff * X^f.nat_degree :=
begin
  by_cases f0 : f = 0,
  { ext1,
    rw [f0, leading_coeff_zero, C_0, zero_mul], },
  conv
  begin
    congr,
    rw sum_leading_C_mul_X_pow_remove f,
    skip,
  end,
  apply add_cancel,
  rw [← support_eq_empty, ← card_eq_zero],
  apply nat.eq_zero_of_le_zero (nat.lt_succ_iff.mp _),
  convert support_remove_lt f0,
  apply le_antisymm _ h,
  exact card_le_of_subset (singleton_subset_iff.mpr (nat_degree_mem_support_of_nonzero f0)),
end

lemma support_erase_lead_lt (h : f ≠ 0) : (erase_lead f).support.card < f.support.card :=
begin
  apply card_lt_card,
  rw [erase_lead_support, ssubset_iff_of_subset (f.support.sdiff_subset {nat_degree f})],
  use f.nat_degree,
  rw [← mem_sdiff, sdiff_sdiff_self_left, inter_singleton_of_mem, mem_singleton],
  rw mem_support_iff_coeff_ne_zero,
  exact (not_congr leading_coeff_eq_zero).mpr h,
end

lemma erase_lead_monomial {r : R} {n : ℕ} : erase_lead (C r * X^n) = 0 :=
begin
  rw [← support_eq_empty, erase_lead_support, sdiff_eq_empty_iff_subset],
  by_cases r0 : r=0,
    { rw [r0, C_0, zero_mul, polynomial.support_zero],
      exact empty_subset _, },
    { convert support_C_mul_X_pow r n,
      rw nat_degree_C_mul_X_pow_nonzero n r0, },
end

lemma erase_lead_card : f.support.card ≤ 1 → (erase_lead f) = 0 :=
begin
  intro,
  rw [C_mul_X_pow_of_card_support_le_one a, erase_lead_monomial],
end

lemma nat_degree_erase_lead_le : (erase_lead f).nat_degree ≤ f.nat_degree :=
begin
  by_cases su : f.support.card ≤ 1,
    {
      rw [erase_lead_card su, nat_degree_zero],
      exact zero_le f.nat_degree, },
    { apply le_of_lt,
      exact nat_degree_erase_lead (nat.succ_le_iff.mpr (not_le.mp su)), },
end

/-- rev_at is a function of two natural variables (N,i).  If i ≤ N, then rev_at N i returns N-i, otherwise it returns N.  Essentially, this function is only used for i ≤ N. -/
def rev_at (N : ℕ) : ℕ → ℕ := λ i : ℕ , ite (i ≤ N) (N-i) i

@[simp] lemma rev_at_invol {N n : ℕ} : rev_at N (rev_at N n) = n :=
begin
  unfold rev_at,
  split_ifs,
    { exact nat.sub_sub_self h, },
    { exfalso,
      apply h_1,
      exact nat.sub_le N n, },
    { refl, },
end

@[simp] lemma rev_at_small {N n : ℕ} (H : n ≤ N) : rev_at N n = N-n :=
begin
  unfold rev_at,
  split_ifs,
  refl,
end


/-- reflect of a natural number N and a polynomial f, applies the function rev_at to the exponents of the terms appearing in the expansion of f.  In practice, reflect is only used when N is at least as large as the degree of f.  Eventually, it will be used with N exactly equal to the degree of f.  -/
def reflect : ℕ → polynomial R → polynomial R := λ N : ℕ , λ f : polynomial R , ⟨ (rev_at N '' ↑(f.support)).to_finset , λ i : ℕ , f.coeff (rev_at N i) , begin
  simp_rw [set.mem_to_finset, set.mem_image, mem_coe, mem_support_iff],
  intro,
  split,
    { intro a_1,
      rcases a_1 with ⟨ a , ha , rfl⟩,
      rwa rev_at_invol, },
    { intro,
      use (rev_at N a),
      rwa [rev_at_invol, eq_self_iff_true, and_true], },
end ⟩

@[simp] lemma reflect_zero {n : ℕ} : reflect n (0 : polynomial R) = 0 :=
begin
  refl,
end

@[simp] lemma reflect_add {f g : polynomial R} {n : ℕ} : reflect n (f+g) = reflect n f + reflect n g :=
begin
  ext1,
  unfold reflect,
  simp only [coeff_mk, coeff_add],
end

@[simp] lemma reflect_smul (N : ℕ) {r : R} : reflect N (C r * f) = C r * (reflect N f) :=
begin
  ext1,
  unfold reflect,
  simp only [coeff_mk, coeff_C_mul],
end

@[simp] lemma reflect_C_mul_X_pow (N n : ℕ) {c : R} : reflect N (C c * X ^ n) = C c * X ^ (rev_at N n) :=
begin
  ext1,
  unfold reflect,
  rw coeff_mk,
  by_cases h : rev_at N n = n_1,
    { rw [h, coeff_C_mul, coeff_C_mul, coeff_X_pow_self, ← h, rev_at_invol, coeff_X_pow_self], },
    { rw not_mem_support_iff_coeff_zero.mp,
        { symmetry,
          apply not_mem_support_iff_coeff_zero.mp,
          intro,
          apply h,
          exact (mem_support_C_mul_X_pow a).symm, },
        { intro,
          apply h,
          rw ← @rev_at_invol N n_1,
          apply congr_arg _,
          exact (mem_support_C_mul_X_pow a).symm, }, },
end

@[simp] lemma reflect_monomial (N n : ℕ) : reflect N ((X : polynomial R) ^ n) = X ^ (rev_at N n) :=
begin
  rw [← one_mul (X^n), ← one_mul (X^(rev_at N n)), ← C_1, reflect_C_mul_X_pow],
end

/-- The reverse of a polynomial f is the polynomial obtained by "reading f backwards".  Even though this is not the actual definition, reverse f = f (1/X) * X ^ f.nat_degree. -/
def reverse : polynomial R → polynomial R := λ f , reflect f.nat_degree f

lemma nat_degree_add_of_mul_leading_coeff_nonzero (f g: polynomial R) (fg: f.leading_coeff * g.leading_coeff ≠ 0) :
 (f * g).nat_degree = f.nat_degree + g.nat_degree :=
begin
  apply le_antisymm,
    { exact nat_degree_mul_le, },
    { apply le_nat_degree_of_mem_supp,
      rw mem_support_iff_coeff_ne_zero,
      convert fg,
      exact coeff_mul_degree_add_degree f g, },
end

lemma pol_ind_Rhom_prod_on_card (cf cg : ℕ) {rp : ℕ → polynomial R → polynomial R}
 (rp_add  : ∀ f g : polynomial R , ∀ F : ℕ ,
  rp F (f+g) = rp F f + rp F g)
 (rp_smul : ∀ f : polynomial R , ∀ r : R , ∀ F : ℕ ,
  rp F ((C r)*f) = C r * rp F f)
 (rp_mon : ∀ n N : ℕ , n ≤ N →
  rp N (X^n) = X^(N-n)) :
 ∀ N O : ℕ , ∀ f g : polynomial R ,
 f.support.card ≤ cf.succ → g.support.card ≤ cg.succ → f.nat_degree ≤ N → g.nat_degree ≤ O →
 (rp (N + O) (f*g)) = (rp N f) * (rp O g) :=
begin
  have rp_zero : ∀ T : ℕ , rp T (0 : polynomial R) = 0,
    intro,
    rw [← zero_mul (1 : polynomial R), ← C_0, rp_smul (1 : polynomial R) 0 T, C_0, zero_mul, zero_mul],
  induction cf with cf hcf,
  --first induction: base case
    { induction cg with cg hcg,
    -- second induction: base case
      { intros N O f g Cf Cg Nf Og,
        rw [C_mul_X_pow_of_card_support_le_one Cf, C_mul_X_pow_of_card_support_le_one Cg],
        rw [mul_assoc, X_pow_mul, mul_assoc, ← pow_add X],
        repeat {rw rp_smul},
        rw [rp_mon _ _ Nf, rp_mon _ _ Og, rp_mon],
          { rw [mul_assoc, X_pow_mul, mul_assoc, ← pow_add X],
            congr,
            omega, },
          { rw add_comm N O,
            exact add_le_add Og Nf, }, },
    -- second induction: induction step
      { intros N O f g Cf Cg Nf Og,
        by_cases g0 : g = 0,
          { rw [g0, mul_zero, rp_zero, rp_zero, mul_zero], },
          { rw [sum_leading_C_mul_X_pow_remove g, mul_add, rp_add, rp_add, mul_add],
            rw hcg N O f _ Cf _ Nf (le_trans nat_degree_erase_lead_le Og),
            rw hcg N O f _ Cf (le_add_left card_support_C_mul_X_pow_le_one) Nf _,
              { exact (le_trans (nat_degree_C_mul_X_pow_le g.leading_coeff g.nat_degree) Og), },
              { rw ← nat.lt_succ_iff,
                exact gt_of_ge_of_gt Cg (support_erase_lead_lt g0), }, }, }, },
  --first induction: induction step
    { intros N O f g Cf Cg Nf Og,
      by_cases f0 : f=0,
        { rw [f0, zero_mul, rp_zero, rp_zero, zero_mul], },
        { rw [sum_leading_C_mul_X_pow_remove f, add_mul, rp_add, rp_add, add_mul],
          rw hcf N O _ g _ Cg (le_trans nat_degree_erase_lead_le Nf) Og,
          rw hcf N O _ g (le_add_left card_support_C_mul_X_pow_le_one) Cg _ Og,
            { exact (le_trans (nat_degree_C_mul_X_pow_le f.leading_coeff f.nat_degree) Nf), },
            { rw ← nat.lt_succ_iff,
              exact gt_of_ge_of_gt Cf (support_erase_lead_lt f0), }, }, },
end

lemma pol_ind_Rhom_prod {rp : ℕ → polynomial R → polynomial R}
 (rp_add  : ∀ f g : polynomial R , ∀ F : ℕ ,
  rp F (f+g) = rp F f + rp F g)
 (rp_smul : ∀ f : polynomial R , ∀ r : R , ∀ F : ℕ ,
  rp F ((C r)*f) = C r * rp F f)
 (rp_mon : ∀ n N : ℕ , n ≤ N →
  rp N (X^n) = X^(N-n)) :
 ∀ N O : ℕ , ∀ f g : polynomial R ,
 f.nat_degree ≤ N → g.nat_degree ≤ O →
 (rp (N + O) (f*g)) = (rp N f) * (rp O g) :=
begin
  intros N O f g,
  apply pol_ind_Rhom_prod_on_card f.support.card g.support.card rp_add rp_smul rp_mon,
  repeat { exact (support _).card.le_succ, },
end

@[simp] theorem reflect_mul {f g : polynomial R} {F G : ℕ} (Ff : f.nat_degree ≤ F) (Gg : g.nat_degree ≤ G) :
 reflect (F+G) (f*g) = reflect F f * reflect G g :=
begin
  apply pol_ind_Rhom_prod,
    { apply reflect_add, },
    { intros f r F,
      rw reflect_smul, },
    { intros n N Nn,
      rw [reflect_monomial, rev_at_small Nn], },
    repeat { assumption },
end

theorem reverse_mul (f g : polynomial R) {fg : f.leading_coeff*g.leading_coeff ≠ 0} :
 reverse (f*g) = reverse f * reverse g :=
begin
  unfold reverse,
  convert reflect_mul (le_refl _) (le_refl _),
    exact nat_degree_add_of_mul_leading_coeff_nonzero f g fg,
end

end polynomial
