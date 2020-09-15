/-
Copyright (c) 2020 Johan Commelin. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johan Commelin, Robert Y. Lewis
-/

import ring_theory.witt_vector.witt_polynomial
import field_theory.mv_polynomial
import field_theory.finite
import data.matrix.notation

/-!
# Witt structure polynomials

In this file we prove the main theorem that makes the whole theory of Witt vectors work.
Briefly, consider a polynomial `Φ : mv_polynomial idx ℤ` over the integers,
with polynomials variables indexed by an arbitrary type `idx`.

Then there exists a unique family of polynomials `φ : ℕ → mv_polynomial (idx × ℕ) Φ`
such that for all `n : ℕ` we have (`witt_structure_int_exists_unique`)
```lean
bind₁ φ (witt_polynomial p ℤ n) = bind₁ (λ b, (rename (λ i, (b,i)) (witt_polynomial p ℤ n))) Φ
```
In other words: evaluating the `n`-th Witt polynomial on the family `φ`
is the same as evaluation `Φ` on the (appropriately renamed) `n`-th Witt polynomials.

N.b.: As far as we know, these polynomials do not have a name in the literature,
so we have decided to call them the “Witt structure polynomials”. See `witt_structure_int`.

## Special cases

With the main result of this file in place, we apply it to certain special polynomials.
For example, by taking `Φ = X tt + X ff` resp. `Φ = X tt * X ff`
we obtain families of polynomials `witt_add` resp. `witt_mul`
(with type `ℕ → mv_polynomial (bool × ℕ) ℤ`) that will be used in later files to define the
addition and multiplication on the ring of Witt vectors.

## Outline of the proof

The proof of `witt_structure_int_exists_unique` is rather technical, and takes up most of this file.
We start by proving the analagous version for polynomials with rational coefficients,
instead of integer coefficients.
In this case, the solution is rather easy,
since the Witt polynomials form a faithful change of coordinates
in the polynomial ring `mv_polynomial ℕ ℚ`.

We therefore obtain a family of polynomials `witt_structure_rat Φ`
for every `Φ : mv_polynomial idx ℚ`.
If `Φ` has integer coefficients, then the polynomials `witt_structure_rat Φ n` do so as well.
Proving this claim is the essential core of this file, and culminates in
`map_witt_structure_int`, which proves that upon mapping the coefficients of `witt_structure_int Φ n`
from the integers to the rationals, one obtains `witt_structure_rat Φ n`.
Ultimately, the proof of `map_witt_structure_int` relies on
```lean
dvd_sub_pow_of_dvd_sub {R : Type*} [comm_ring R] {p : ℕ} {a b : R} :
    (p : R) ∣ a - b → ∀ (k : ℕ), (p : R) ^ (k + 1) ∣ a ^ p ^ k - b ^ p ^ k
```

## Main results

* `witt_structure_int Φ`: the family of polynomials `ℕ → mv_polynomial (idx × ℕ) Φ`
  associated with `Φ : mv_polynomial idx ℤ` and satisfying the property explained above.
* `witt_structure_int_prop`: the proof that `witt_structure_int` indeed satisfies the property.

* Five families of polynomials that will be used to define the rings structure
  on the ring of Witt vectors:
  - `witt_vector.witt_zero`
  - `witt_vector.witt_one`
  - `witt_vector.witt_add`
  - `witt_vector.witt_mul`
  - `witt_vector.witt_neg`
  (We also define `witt_vector.witt_sub`, and later we will prove that it describes subtraction,
  which is defined as `λ a b, a + -b`. See `witt_vector.sub_coeff` for this proof.)

-/

open mv_polynomial
open set
open finset (range)
open finsupp (single)

-- This lemma reduces a bundled morphism to a "mere" function,
-- and consequently the simplifier cannot use a lot of powerful simp-lemmas.
-- We disable this locally, and probably it should be disabled globally in mathlib.
local attribute [-simp] coe_eval₂_hom

variables {p : ℕ} {R : Type*} {idx : Type*} [comm_ring R]

open_locale witt
open_locale big_operators

section p_prime

variables (p) [hp : fact p.prime]
include hp

/-- `witt_structure_rat Φ` is a family of polynomials `ℕ → mv_polynomial (idx × ℕ) ℚ`
that are uniquely characterised by the property that
`bind₁ (witt_structure_rat p Φ) (witt_polynomial p ℚ n) = bind₁ (λ b, (rename (λ i, (b,i)) (witt_polynomial p ℚ n))) Φ`.
In other words: evaluating the `n`-th Witt polynomial on the family `witt_structure_rat Φ`
is the same as evaluation `Φ` on the (appropriately renamed) `n`-th Witt polynomials.

See `witt_structure_rat_prop` for this property,
and `witt_structure_rat_exists_unique` for the fact that `witt_structure_rat`
gives the unique family of polynomials with this property.

These polynomials turn out to have integral coefficients,
but it requires some effort to show this.
See `witt_structure_int` for the version with integral coefficients,
and `map_witt_structure_int` for the fact that it is equal to `witt_structure_rat`
when mapped to polynomials over the rationals. -/
noncomputable def witt_structure_rat (Φ : mv_polynomial idx ℚ) (n : ℕ) :
  mv_polynomial (idx × ℕ) ℚ :=
bind₁ (λ k, bind₁ (λ b, rename (λ i, (b,i)) (W_ ℚ k)) Φ) (X_in_terms_of_W p ℚ n)

theorem witt_structure_rat_prop (Φ : mv_polynomial idx ℚ) (n : ℕ) :
  bind₁ (witt_structure_rat p Φ) (W_ ℚ n) =
  bind₁ (λ b, (rename (λ i, (b,i)) (W_ ℚ n))) Φ :=
calc bind₁ (witt_structure_rat p Φ) (W_ ℚ n)
    = bind₁ (λ k, bind₁ (λ b, (rename (prod.mk b)) (W_ ℚ k)) Φ) (bind₁ (X_in_terms_of_W p ℚ) (W_ ℚ n)) :
      by { rw [bind₁_bind₁], apply eval₂_hom_congr (ring_hom.ext_rat _ _) rfl rfl }
... = bind₁ (λ b, (rename (λ i, (b,i)) (W_ ℚ n))) Φ :
      by rw [X_in_terms_of_W_prop₂ p _ n, bind₁_X_right]

theorem witt_structure_rat_exists_unique (Φ : mv_polynomial idx ℚ) :
  ∃! (φ : ℕ → mv_polynomial (idx × ℕ) ℚ),
    ∀ (n : ℕ), bind₁ φ (W_ ℚ n) = bind₁ (λ b, (rename (λ i, (b,i)) (W_ ℚ n))) Φ :=
begin
  refine ⟨witt_structure_rat p Φ, _, _⟩,
  { intro n, apply witt_structure_rat_prop },
  { intros φ H,
    funext n,
    rw show φ n = bind₁ φ (bind₁ (W_ ℚ) (X_in_terms_of_W p ℚ n)),
    { rw [X_in_terms_of_W_prop p, bind₁_X_right] },
    rw [bind₁_bind₁],
    apply eval₂_hom_congr (ring_hom.ext_rat _ _) _ rfl,
    funext k, exact H k },
end

lemma witt_structure_rat_rec_aux (Φ : mv_polynomial idx ℚ) (n : ℕ) :
  (witt_structure_rat p Φ n) * C (p ^ n : ℚ) =
  ((bind₁ (λ b, (rename (λ i, (b, i)) (W_ ℚ n))) Φ)) -
  ∑ i in range n, C (p ^ i : ℚ) * (witt_structure_rat p Φ i) ^ p ^ (n - i) :=
begin
  have := X_in_terms_of_W_aux p ℚ n,
  replace := congr_arg (bind₁ (λ k : ℕ, (bind₁ (λ b, (rename (λ i, (b,i)) (W_ ℚ k)))) Φ)) this,
  rw [alg_hom.map_mul, bind₁_C_right] at this,
  convert this, clear this,
  conv_rhs { simp only [alg_hom.map_sub, bind₁_X_right] },
  rw sub_right_inj,
  simp only [alg_hom.map_sum, alg_hom.map_mul, bind₁_C_right, alg_hom.map_pow],
  refl
end

lemma witt_structure_rat_rec (Φ : mv_polynomial idx ℚ) (n : ℕ) :
  (witt_structure_rat p Φ n) = C (1 / p ^ n : ℚ) *
  (bind₁ (λ b, (rename (λ i, (b, i)) (W_ ℚ n))) Φ -
  ∑ i in range n, C (p ^ i : ℚ) * (witt_structure_rat p Φ i) ^ p ^ (n - i)) :=
begin
  rw [← witt_structure_rat_rec_aux p Φ n, mul_comm, mul_assoc,
      ← C_mul, mul_one_div_cancel, C_1, mul_one],
  exact pow_ne_zero _ (nat.cast_ne_zero.2 $ ne_of_gt (nat.prime.pos ‹_›)),
end

/-- `witt_structure_int Φ` is a family of polynomials `ℕ → mv_polynomial (idx × ℕ) ℚ`
that are uniquely characterised by the property that
`bind₁ (witt_structure_int p Φ) (witt_polynomial p ℚ n) = bind₁ (λ b, (rename (λ i, (b,i)) (witt_polynomial p ℚ n))) Φ`.
In other words: evaluating the `n`-th Witt polynomial on the family `witt_structure_int Φ`
is the same as evaluation `Φ` on the (appropriately renamed) `n`-th Witt polynomials.

See `witt_structure_int_prop` for this property,
and `witt_structure_int_exists_unique` for the fact that `witt_structure_int`
gives the unique family of polynomials with this property. -/
noncomputable def witt_structure_int (Φ : mv_polynomial idx ℤ) (n : ℕ) : mv_polynomial (idx × ℕ) ℤ :=
finsupp.map_range rat.num (rat.coe_int_num 0)
  (witt_structure_rat p (map (int.cast_ring_hom ℚ) Φ) n)

end p_prime

variables {ι : Type*} {σ : Type*}
variables {S : Type*} [comm_ring S]
variables {T : Type*} [comm_ring T]

variable {p}

-- this seems overly specific. I wouldn't mind getting rid of it.
lemma rat_mv_poly_is_integral_iff (p : mv_polynomial ι ℚ) :
  map (int.cast_ring_hom ℚ) (finsupp.map_range rat.num (rat.coe_int_num 0) p) = p ↔
  ∀ m, (coeff m p).denom = 1 :=
begin
  rw mv_polynomial.ext_iff,
  apply forall_congr, intro m,
  rw coeff_map,
  split; intro h,
  { rw [← h], apply rat.coe_int_denom },
  { show (rat.num (coeff m p) : ℚ) = coeff m p,
    lift (coeff m p) to ℤ using h with n hn,
    rw rat.coe_int_num n }
end

section p_prime

variable [hp : fact p.prime]
include hp

lemma sum_induction_steps (Φ : mv_polynomial idx ℤ) (n : ℕ)
  (IH : ∀ m : ℕ, m < n →
    map (int.cast_ring_hom ℚ) (witt_structure_int p Φ m) = witt_structure_rat p (map (int.cast_ring_hom ℚ) Φ) m) :
  map (int.cast_ring_hom ℚ)
    (∑ i in range n, C (p ^ i : ℤ) * (witt_structure_int p Φ i) ^ p ^ (n - i)) =
  ∑ i in range n, C (p ^ i : ℚ) * (witt_structure_rat p (map (int.cast_ring_hom ℚ) Φ) i) ^ p ^ (n - i) :=
begin
  rw [ring_hom.map_sum],
  apply finset.sum_congr rfl,
  intros i hi,
  rw finset.mem_range at hi,
  simp only [IH i hi, ring_hom.map_mul, ring_hom.map_pow, map_C], refl
end

lemma bind₁_rename_expand_witt_polynomial (Φ : mv_polynomial idx ℤ) (n : ℕ)
  (IH : ∀ m : ℕ, m < (n + 1) →
    map (int.cast_ring_hom ℚ) (witt_structure_int p Φ m) = witt_structure_rat p (map (int.cast_ring_hom ℚ) Φ) m) :
  bind₁ (λ b, rename (λ i, (b, i)) (expand p (W_ ℤ n))) Φ =
  bind₁ (λ i, expand p (witt_structure_int p Φ i)) (W_ ℤ n) :=
begin
  apply mv_polynomial.map_injective (int.cast_ring_hom ℚ) int.cast_injective,
  simp only [map_bind₁, map_rename, map_expand, rename_expand, map_witt_polynomial],
  have key := (witt_structure_rat_prop p (map (int.cast_ring_hom ℚ) Φ) n).symm,
  apply_fun expand p at key,
  simp only [expand_bind₁] at key,
  rw key, clear key,
  apply eval₂_hom_congr' rfl _ rfl,
  rintro i hi -,
  rw [witt_polynomial_vars, finset.mem_range] at hi,
  simp only [IH i hi],
end

lemma C_p_pow_dvd_bind₁_rename_witt_polynomial_sub_sum (Φ : mv_polynomial idx ℤ) (n : ℕ)
  (IH : ∀ m : ℕ, m < n →
    map (int.cast_ring_hom ℚ) (witt_structure_int p Φ m) = witt_structure_rat p (map (int.cast_ring_hom ℚ) Φ) m) :
  C ↑(p ^ n) ∣
    (bind₁ (λ (b : idx), rename (λ i, (b, i)) (witt_polynomial p ℤ n)) Φ -
      ∑ i in range n, C (↑p ^ i) * witt_structure_int p Φ i ^ p ^ (n - i)) :=
begin
  cases n,
  { simp only [is_unit_one, int.coe_nat_zero, int.coe_nat_succ, zero_add,
      nat.pow_zero, C_1, is_unit.dvd] },
  rw [nat.succ_eq_add_one, C_dvd_iff_zmod, ring_hom.map_sub, sub_eq_zero, map_bind₁],
  simp only [map_rename, map_witt_polynomial, witt_polynomial_zmod_self],
  -- prepare a useful equation for rewriting
  have key := bind₁_rename_expand_witt_polynomial Φ n IH,
  apply_fun (map (int.cast_ring_hom (zmod (p ^ (n + 1))))) at key,
  conv_lhs at key { simp only [map_bind₁, map_rename, map_expand, map_witt_polynomial] },
  rw key,
  clear key IH,
  -- clean up and massage
  rw [bind₁, aeval_witt_polynomial, ring_hom.map_sum, ring_hom.map_sum, finset.sum_congr rfl],
  intros k hk,
  rw finset.mem_range at hk,
  simp only [← sub_eq_zero, ← ring_hom.map_sub, ← C_dvd_iff_zmod, C_eq_coe_nat, ← mul_sub,
    ← int.nat_cast_eq_coe_nat, ← nat.cast_pow],
  rw show p ^ (n + 1) = p ^ k * p ^ (n - k + 1),
  { rw ← nat.pow_add, congr' 1, omega },
  rw [nat.cast_mul, nat.cast_pow, nat.cast_pow],
  apply mul_dvd_mul_left,
  rw show p ^ (n + 1 - k) = p * p ^ (n - k),
  { rw [mul_comm, ← pow_succ'], congr' 1, omega },
  rw [pow_mul],
  -- the machine!
  apply dvd_sub_pow_of_dvd_sub,
  rw [← C_eq_coe_nat, int.nat_cast_eq_coe_nat, C_dvd_iff_zmod, ring_hom.map_sub,
      sub_eq_zero, map_expand, ring_hom.map_pow, mv_polynomial.expand_zmod],
end

variables (p)

@[simp] lemma map_witt_structure_int (Φ : mv_polynomial idx ℤ) (n : ℕ) :
  map (int.cast_ring_hom ℚ) (witt_structure_int p Φ n) =
    witt_structure_rat p (map (int.cast_ring_hom ℚ) Φ) n :=
begin
  apply nat.strong_induction_on n, clear n,
  intros n IH,
  rw [witt_structure_int, rat_mv_poly_is_integral_iff],
  intro c,
  rw [witt_structure_rat_rec, coeff_C_mul, mul_comm, mul_div_assoc', mul_one],
  simp only [← sum_induction_steps Φ n IH, ← map_witt_polynomial p (int.cast_ring_hom ℚ),
    ← map_rename, ← map_bind₁, ← ring_hom.map_sub, coeff_map],
  rw show (p : ℚ)^n = ((p^n : ℕ) : ℤ), by norm_cast,
  rw [ring_hom.eq_int_cast, rat.denom_div_cast_eq_one_iff],
  swap, { exact_mod_cast pow_ne_zero n hp.ne_zero },
  revert c, rw [← C_dvd_iff_dvd_coeff],
  exact C_p_pow_dvd_bind₁_rename_witt_polynomial_sub_sum Φ n IH,
end

variables (p)

theorem witt_structure_int_prop (Φ : mv_polynomial idx ℤ) (n) :
  bind₁ (witt_structure_int p Φ) (witt_polynomial p ℤ n) =
  bind₁ (λ b, (rename (λ i, (b,i)) (W_ ℤ n))) Φ :=
begin
  apply mv_polynomial.map_injective (int.cast_ring_hom ℚ) int.cast_injective,
  have := witt_structure_rat_prop p (map (int.cast_ring_hom ℚ) Φ) n,
  simpa only [map_bind₁, ← eval₂_hom_map_hom, eval₂_hom_C_left, map_rename,
        map_witt_polynomial, alg_hom.coe_to_ring_hom, map_witt_structure_int],
end

lemma eq_witt_structure_int (Φ : mv_polynomial idx ℤ) (φ : ℕ → mv_polynomial (idx × ℕ) ℤ)
  (h : ∀ n, bind₁ φ (witt_polynomial p ℤ n) = bind₁ (λ b, (rename (λ i, (b,i)) (W_ ℤ n))) Φ) :
  φ = witt_structure_int p Φ :=
begin
  funext k,
    apply mv_polynomial.map_injective (int.cast_ring_hom ℚ) int.cast_injective,
    rw map_witt_structure_int,
    refine congr_fun _ k,
    have := (witt_structure_rat_exists_unique p (map (int.cast_ring_hom ℚ) Φ)),
    apply unique_of_exists_unique this,
    { clear this, intro n,
      specialize h n,
      apply_fun map (int.cast_ring_hom ℚ) at h,
      simpa only [map_bind₁, ← eval₂_hom_map_hom, eval₂_hom_C_left, map_rename,
        map_witt_polynomial, alg_hom.coe_to_ring_hom] using h, },
    { intro n, apply witt_structure_rat_prop }
end

theorem witt_structure_int_exists_unique (Φ : mv_polynomial idx ℤ) :
  ∃! (φ : ℕ → mv_polynomial (idx × ℕ) ℤ),
  ∀ (n : ℕ), bind₁ φ (witt_polynomial p ℤ n) = bind₁ (λ b : idx, (rename (λ i, (b,i)) (W_ ℤ n))) Φ :=
⟨witt_structure_int p Φ, witt_structure_int_prop _ _, eq_witt_structure_int _ _⟩

theorem witt_structure_prop (Φ : mv_polynomial idx ℤ) (n) :
  aeval (λ i, map (int.cast_ring_hom R) (witt_structure_int p Φ i)) (witt_polynomial p ℤ n) =
  aeval (λ b, (rename (λ i, (b,i)) (W n))) Φ :=
begin
  convert congr_arg (map (int.cast_ring_hom R)) (witt_structure_int_prop p Φ n),
  { rw [hom_bind₁],
    exact eval₂_hom_congr (ring_hom.ext_int _ _) rfl rfl, },
  { rw [hom_bind₁],
    apply eval₂_hom_congr (ring_hom.ext_int _ _) _ rfl,
    simp only [map_rename, map_witt_polynomial] }
end

@[simp]
lemma constant_coeff_witt_structure_rat_zero (Φ : mv_polynomial idx ℚ) :
  constant_coeff (witt_structure_rat p Φ 0) = constant_coeff Φ :=
begin
  rw witt_structure_rat,
  simp only [bind₁, map_aeval, X_in_terms_of_W_zero, aeval_X, constant_coeff_witt_polynomial,
    constant_coeff_rename, constant_coeff_comp_algebra_map],
  exact @aeval_zero' _ _ ℚ _ _ (algebra.id _) Φ,
end

lemma constant_coeff_witt_structure_rat (Φ : mv_polynomial idx ℚ) (h : constant_coeff Φ = 0) (n : ℕ) :
  constant_coeff (witt_structure_rat p Φ n) = 0 :=
begin
  rw witt_structure_rat,
  -- we need `eval₂_hom_zero` but it doesn't exist
  have : (eval₂_hom (ring_hom.id ℚ) (λ (_x : idx), 0)) Φ = constant_coeff Φ :=
    @aeval_zero' _ _ ℚ _ _ (algebra.id _) Φ,
  simp only [this, h, bind₁, map_aeval, constant_coeff_witt_polynomial, constant_coeff_rename,
    constant_coeff_comp_algebra_map],
  conv_rhs { rw ← constant_coeff_X_in_terms_of_W p ℚ n },
  exact @aeval_zero' _ _ ℚ _ _ (algebra.id _) _,
end

@[simp]
lemma constant_coeff_witt_structure_int_zero (Φ : mv_polynomial idx ℤ) :
  constant_coeff (witt_structure_int p Φ 0) = constant_coeff Φ :=
begin
  have inj : function.injective (int.cast_ring_hom ℚ),
  { intros m n, exact int.cast_inj.mp, },
  apply inj,
  rw [← constant_coeff_map, map_witt_structure_int,
      constant_coeff_witt_structure_rat_zero, constant_coeff_map],
end

lemma constant_coeff_witt_structure_int (Φ : mv_polynomial idx ℤ) (h : constant_coeff Φ = 0) (n : ℕ) :
  constant_coeff (witt_structure_int p Φ n) = 0 :=
begin
  have inj : function.injective (int.cast_ring_hom ℚ),
  { intros m n, exact int.cast_inj.mp, },
  apply inj,
  rw [← constant_coeff_map, map_witt_structure_int,
      constant_coeff_witt_structure_rat, ring_hom.map_zero],
  rw [constant_coeff_map, h, ring_hom.map_zero],
end

end p_prime

namespace witt_vector
variables (p) [hp : fact p.prime]
include hp

/-- The polynomials used for defining the element `0` of the ring of Witt vectors. -/
noncomputable def witt_zero : ℕ → mv_polynomial (fin 0 × ℕ) ℤ :=
witt_structure_int p 0

/-- The polynomials used for defining the element `1` of the ring of Witt vectors. -/
noncomputable def witt_one : ℕ → mv_polynomial (fin 0 × ℕ) ℤ :=
witt_structure_int p 1

/-- The polynomials used for defining the addition of the ring of Witt vectors. -/
noncomputable def witt_add : ℕ → mv_polynomial (fin 2 × ℕ) ℤ :=
witt_structure_int p (X 0 + X 1)

/-- The polynomials used for describing the subtraction of the ring of Witt vectors.
Note that `a - b` is defined as `a + -b`.
See `witt_vector.sub_coeff` for a proof that subtraction is precisely
given by these polynomials `witt_vector.witt_sub` -/
noncomputable def witt_sub : ℕ → mv_polynomial (fin 2 × ℕ) ℤ :=
witt_structure_int p (X 0 - X 1)

/-- The polynomials used for defining the multiplication of the ring of Witt vectors. -/
noncomputable def witt_mul : ℕ → mv_polynomial (fin 2 × ℕ) ℤ :=
witt_structure_int p (X 0 * X 1)

/-- The polynomials used for defining the negation of the ring of Witt vectors. -/
noncomputable def witt_neg : ℕ → mv_polynomial (fin 1 × ℕ) ℤ :=
witt_structure_int p (-X 0)

section witt_structure_simplifications

@[simp] lemma witt_zero_eq_zero (n : ℕ) : witt_zero p n = 0 :=
begin
  apply mv_polynomial.map_injective (int.cast_ring_hom ℚ) int.cast_injective,
  simp only [witt_zero, witt_structure_rat, bind₁, aeval_zero',
    constant_coeff_X_in_terms_of_W, ring_hom.map_zero,
    alg_hom.map_zero, map_witt_structure_int],
end

@[simp] lemma witt_one_zero_eq_one : witt_one p 0 = 1 :=
begin
  apply mv_polynomial.map_injective (int.cast_ring_hom ℚ) int.cast_injective,
  simp only [witt_one, witt_structure_rat, X_in_terms_of_W_zero, alg_hom.map_one,
    ring_hom.map_one, bind₁_X_right, map_witt_structure_int]
end

@[simp] lemma witt_one_pos_eq_zero (n : ℕ) (hn : 0 < n) : witt_one p n = 0 :=
begin
  apply mv_polynomial.map_injective (int.cast_ring_hom ℚ) int.cast_injective,
  simp only [witt_one, witt_structure_rat, ring_hom.map_zero, alg_hom.map_one,
    ring_hom.map_one, map_witt_structure_int],
  revert hn, apply nat.strong_induction_on n, clear n,
  intros n IH hn,
  rw X_in_terms_of_W_eq,
  simp only [alg_hom.map_mul, alg_hom.map_sub, alg_hom.map_sum, alg_hom.map_pow, bind₁_X_right, bind₁_C_right],
  rw [sub_mul, one_mul],
  rw [finset.sum_eq_single 0],
  { simp only [inv_of_eq_inv, one_mul, inv_pow', nat.sub_zero, ring_hom.map_one, pow_zero],
    simp only [one_pow, one_mul, X_in_terms_of_W_zero, sub_self, bind₁_X_right] },
  { intros i hin hi0,
    rw [finset.mem_range] at hin,
    rw [IH _ hin (nat.pos_of_ne_zero hi0), zero_pow (nat.pow_pos hp.pos _), mul_zero], },
  { rw finset.mem_range, intro, contradiction }
end

@[simp] lemma witt_add_zero : witt_add p 0 = X (0,0) + X (1,0) :=
begin
  apply mv_polynomial.map_injective (int.cast_ring_hom ℚ) int.cast_injective,
  simp only [witt_add, witt_structure_rat, alg_hom.map_add, ring_hom.map_add,
    rename_X, X_in_terms_of_W_zero, map_X,
     witt_polynomial_zero, bind₁_X_right, map_witt_structure_int],
end

@[simp] lemma witt_sub_zero : witt_sub p 0 = X (0,0) - X (1,0) :=
begin
  apply mv_polynomial.map_injective (int.cast_ring_hom ℚ) int.cast_injective,
  simp only [witt_sub, witt_structure_rat, alg_hom.map_sub, ring_hom.map_sub,
    rename_X, X_in_terms_of_W_zero, map_X,
     witt_polynomial_zero, bind₁_X_right, map_witt_structure_int],
end

@[simp] lemma witt_mul_zero : witt_mul p 0 = X (0,0) * X (1,0) :=
begin
  apply mv_polynomial.map_injective (int.cast_ring_hom ℚ) int.cast_injective,
  simp only [witt_mul, witt_structure_rat, rename_X, X_in_terms_of_W_zero, map_X,
    witt_polynomial_zero, ring_hom.map_mul,
    bind₁_X_right, alg_hom.map_mul, map_witt_structure_int]

end

@[simp] lemma witt_neg_zero : witt_neg p 0 = - X (0,0) :=
begin
  apply mv_polynomial.map_injective (int.cast_ring_hom ℚ) int.cast_injective,
  simp only [witt_neg, witt_structure_rat, rename_X, X_in_terms_of_W_zero, map_X,
    witt_polynomial_zero, ring_hom.map_neg,
   alg_hom.map_neg, bind₁_X_right, map_witt_structure_int]
end

@[simp] lemma constant_coeff_witt_add (n : ℕ) :
  constant_coeff (witt_add p n) = 0 :=
begin
  apply constant_coeff_witt_structure_int p _ _ n,
  simp only [add_zero, ring_hom.map_add, constant_coeff_X],
end

@[simp] lemma constant_coeff_witt_sub (n : ℕ) :
  constant_coeff (witt_sub p n) = 0 :=
begin
  apply constant_coeff_witt_structure_int p _ _ n,
  simp only [sub_zero, ring_hom.map_sub, constant_coeff_X],
end

@[simp] lemma constant_coeff_witt_mul (n : ℕ) :
  constant_coeff (witt_mul p n) = 0 :=
begin
  apply constant_coeff_witt_structure_int p _ _ n,
  simp only [mul_zero, ring_hom.map_mul, constant_coeff_X],
end

@[simp] lemma constant_coeff_witt_neg (n : ℕ) :
  constant_coeff (witt_neg p n) = 0 :=
begin
  apply constant_coeff_witt_structure_int p _ _ n,
  simp only [neg_zero, ring_hom.map_neg, constant_coeff_X],
end

end witt_structure_simplifications


section witt_vars
variable (R)

-- we could relax the fintype on `idx`, but then we need to cast from finset to set.
-- for our applications `idx` is always finite.
lemma witt_structure_rat_vars [fintype idx] (Φ : mv_polynomial idx ℚ) (n : ℕ) :
  (witt_structure_rat p Φ n).vars ⊆ finset.univ.product (finset.range (n + 1)) :=
begin
  rw witt_structure_rat,
  intros x hx,
  simp only [finset.mem_product, true_and, finset.mem_univ, finset.mem_range],
  replace hx := bind₁_vars _ _ hx,
  simp only [exists_prop, finset.mem_bind, finset.mem_range] at hx,
  rcases hx with ⟨k, hk, hx⟩,
  replace hk := X_in_terms_of_W_vars_subset p _ hk,
  rw finset.mem_range at hk,
  replace hx := bind₁_vars _ _ hx,
  simp only [exists_prop, finset.mem_bind, finset.mem_range] at hx,
  rcases hx with ⟨i, -, hx⟩,
  replace hx := vars_rename _ _ hx,
  rw [finset.mem_image] at hx,
  rcases hx with ⟨j, hj, rfl⟩,
  rw [witt_polynomial_vars, finset.mem_range] at hj,
  exact lt_of_lt_of_le hj hk,
end

-- we could relax the fintype on `idx`, but then we need to cast from finset to set.
-- for our applications `idx` is always finite.
lemma witt_structure_int_vars [fintype idx] (Φ : mv_polynomial idx ℤ) (n : ℕ) :
  (witt_structure_int p Φ n).vars ⊆ finset.univ.product (finset.range (n + 1)) :=
begin
  rw [← @vars_map_of_injective _ _ _ _ _ _ (int.cast_ring_hom ℚ) (λ m n, (rat.coe_int_inj m n).mp),
      map_witt_structure_int],
  apply witt_structure_rat_vars,
end

lemma witt_add_vars (n : ℕ) :
  (witt_add p n).vars ⊆ finset.univ.product (finset.range (n + 1)) :=
witt_structure_int_vars _ _ _

lemma witt_mul_vars (n : ℕ) :
  (witt_mul p n).vars ⊆ finset.univ.product (finset.range (n + 1)) :=
witt_structure_int_vars _ _ _

lemma witt_neg_vars (n : ℕ) :
  (witt_neg p n).vars ⊆ finset.univ.product (finset.range (n + 1)) :=
witt_structure_int_vars _ _ _

end witt_vars

end witt_vector
