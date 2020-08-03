/-
Copyright (c) 2020 Adam Topaz. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Adam Topaz.
-/

import ring_theory.algebra
import linear_algebra

/-!
# Tensor Algebras

Given a commutative semiring `R`, and an `R`-module `M`, we construct the tensor algebra of `M`.
This is the free `R`-algebra generated (`R`-linearly) by the module `M`.

## Notation

1. `tensor_algebra R M` is the tensor algebra itself. It is endowed with an R-algebra structure.
2. `tensor_algebra.ι R M` is the canonical R-linear map `M → tensor_algebra R M`.
3. Given a linear map `f : M → A` to an R-algebra `A`, `lift R M f` is the lift of `f` to an
  `R`-algebra morphism `tensor_algebra R M → A`.

## Theorems

1. `ι_comp_lift` states that the composition `(lift R M f) ∘ (ι R M)` is identical to `f`.
2. `lift_unique` states that whenever an R-algebra morphism `g : tensor_algebra R M → A` is
  given whose composition with `ι R M` is `f`, then one has `g = lift R M f`.
3. `hom_ext` is a variant of `lift_unique` in the form of an extensionality theorem.
4. `lift_comp_ι` is a combination of `ι_comp_lift` and `lift_unique`. It states that the lift
  of the composition of an algebra morphism with `ι` is the algebra morphism itself.

## Implementation details

As noted above, the tensor algebra of `M` is constructed as the free `R`-algebra generated by `M`.
This is done as a quotient of an inductive type by an inductively defined relation.
Explicltly, the construction involves three steps:
1. We construct an inductive type `tensor_algebra.pre R M`, the terms of which should be thought
  of as representatives for the elements of `tensor_algebra R M`.
  It is the free type with maps from `R` and `M`, and with two binary operations `add` and `mul`.
2. We construct an inductive relation `tensor_algebra.rel R M` on `tensor_algebra.pre R M`.
  This is the smallest relation for which the quotient is an `R`-algebra where addition resp.
  multiplication are induced by `add` resp. `mul` from 1, and for which the map from `R` is the
  structure map for the algebra while the map from `M` is `R`-linear.
3. The tensor algebra `tensor_algebra R M` is the quotient of `tensor_algebra.pre R M` by
  the relation `tensor_algebra.rel R M`.
-/

variables (R : Type*) [comm_semiring R]
variables (M : Type*) [add_comm_group M] [semimodule R M]

namespace tensor_algebra

/--
This inductive type is used to express representatives of the tensor algebra.
-/
inductive pre
| of : M → pre
| of_scalar : R → pre
| add : pre → pre → pre
| mul : pre → pre → pre

namespace pre

instance : inhabited (pre R M) := ⟨of_scalar 0⟩

-- Note: These instances are only used to simplify the notation.
/-- Coercion from `M` to `pre R M`. Note: Used for notation only. -/
def has_coe_module : has_coe M (pre R M) := ⟨of⟩
/-- Coercion from `R` to `pre R M`. Note: Used for notation only. -/
def has_coe_semiring : has_coe R (pre R M) := ⟨of_scalar⟩
/-- Multiplication in `pre R M` defined as `pre.mul`. Note: Used for notation only. -/
def has_mul : has_mul (pre R M) := ⟨mul⟩
/-- Addition in `pre R M` defined as `pre.add`. Note: Used for notation only. -/
def has_add : has_add (pre R M) := ⟨add⟩
/-- Zero in `pre R M` defined as the image of `0` from `R`. Note: Used for notation only. -/
def has_zero : has_zero (pre R M) := ⟨of_scalar 0⟩
/-- One in `pre R M` defined as the image of `1` from `R`. Note: Used for notation only. -/
def has_one : has_one (pre R M) := ⟨of_scalar 1⟩
/--
Scalar multiplication defined as multiplication by the image of elements from `R`.
Note: Used for notation only.
-/
def has_scalar : has_scalar R (pre R M) := ⟨λ r m, mul (of_scalar r) m⟩

end pre

local attribute [instance]
  pre.has_coe_module pre.has_coe_semiring pre.has_mul pre.has_add pre.has_zero
  pre.has_one pre.has_scalar

/--
Given a linear map from `M` to an `R`-algebra `A`, `lift_fun` provides a lift of `f` to a function
from `pre R M` to `A`. This is mainly used in the construction of `tensor_algebra.lift`.
-/
def lift_fun {A : Type*} [semiring A] [algebra R A] (f : M →ₗ[R] A) : pre R M → A :=
  λ t, pre.rec_on t f (algebra_map _ _) (λ _ _, (+)) (λ _ _, (*))

/--
An inductively defined relation on `pre R M` used to force the initial algebra structure on
the associated quotient.
-/
inductive rel : (pre R M) → (pre R M) → Prop
-- force `of` to be linear
| add_lin {a b : M} : rel ↑(a+b) (↑a + ↑b)
| smul_lin {r : R} {a : M} : rel ↑(r • a) (↑r * ↑a)
-- force `of_scalar` to be a central semiring morphism
| add_scalar {r s : R} : rel ↑(r + s) (↑r + ↑s)
| mul_scalar {r s : R} : rel ↑(r * s) (↑r * ↑s)
| central_scalar {r : R} {a : pre R M} : rel (r * a) (a * r)
-- commutative additive semigroup
| add_assoc {a b c : pre R M} : rel (a + b + c) (a + (b + c))
| add_comm {a b : pre R M} : rel (a + b) (b + a)
| zero_add {a : pre R M} : rel (0 + a) a
-- multiplicative monoid
| mul_assoc {a b c : pre R M} : rel (a * b * c) (a * (b * c))
| one_mul {a : pre R M} : rel (1 * a) a
| mul_one {a : pre R M} : rel (a * 1) a
-- distributivity
| left_distrib {a b c : pre R M} : rel (a * (b + c)) (a * b + a * c)
| right_distrib {a b c : pre R M} : rel ((a + b) * c) (a * c + b * c)
-- other relations needed for semiring
| zero_mul {a : pre R M} : rel (0 * a) 0
| mul_zero {a : pre R M} : rel (a * 0) 0
-- compatibility
| add_compat_left {a b c : pre R M} : rel a b → rel (a + c) (b + c)
| add_compat_right {a b c : pre R M} : rel a b → rel (c + a) (c + b)
| mul_compat_left {a b c : pre R M} : rel a b → rel (a * c) (b * c)
| mul_compat_right {a b c : pre R M} : rel a b → rel (c * a) (c * b)

end tensor_algebra

/--
The tensor algebra of the module `M` over the commutative semiring `R`.
-/
def tensor_algebra := quot (tensor_algebra.rel R M)

namespace tensor_algebra

local attribute [instance]
  pre.has_coe_module pre.has_coe_semiring pre.has_mul pre.has_add pre.has_zero
  pre.has_one pre.has_scalar

instance : semiring (tensor_algebra R M) :=
{ add := quot.map₂ (+) (λ _ _ _, rel.add_compat_right) (λ _ _ _, rel.add_compat_left),
  add_assoc := by { rintros ⟨⟩ ⟨⟩ ⟨⟩, exact quot.sound rel.add_assoc },
  zero := quot.mk _ 0,
  zero_add := by { rintro ⟨⟩, exact quot.sound rel.zero_add },
  add_zero := begin
    rintros ⟨⟩,
    change quot.mk _ _ = _,
    rw [quot.sound rel.add_comm, quot.sound rel.zero_add],
  end,
  add_comm := by { rintros ⟨⟩ ⟨⟩, exact quot.sound rel.add_comm },
  mul := quot.map₂ (*) (λ _ _ _, rel.mul_compat_right) (λ _ _ _, rel.mul_compat_left),
  mul_assoc := by { rintros ⟨⟩ ⟨⟩ ⟨⟩, exact quot.sound rel.mul_assoc },
  one := quot.mk _ 1,
  one_mul := by { rintros ⟨⟩, exact quot.sound rel.one_mul },
  mul_one := by { rintros ⟨⟩, exact quot.sound rel.mul_one },
  left_distrib := by { rintros ⟨⟩ ⟨⟩ ⟨⟩, exact quot.sound rel.left_distrib },
  right_distrib := by { rintros ⟨⟩ ⟨⟩ ⟨⟩, exact quot.sound rel.right_distrib },
  zero_mul := by { rintros ⟨⟩, exact quot.sound rel.zero_mul },
  mul_zero := by { rintros ⟨⟩, exact quot.sound rel.mul_zero } }

instance : inhabited (tensor_algebra R M) := ⟨0⟩

instance : has_scalar R (tensor_algebra R M) :=
{ smul := λ r a, quot.lift_on a (λ x, quot.mk _ $ ↑r * x) $
  λ a b h, quot.sound (rel.mul_compat_right h) }

instance : algebra R (tensor_algebra R M) :=
{ to_fun := λ r, quot.mk _ r,
  map_one' := rfl,
  map_mul' := λ _ _, quot.sound rel.mul_scalar,
  map_zero' := rfl,
  map_add' := λ _ _, quot.sound rel.add_scalar,
  commutes' := λ _, by { rintros ⟨⟩, exact quot.sound rel.central_scalar },
  smul_def' := λ _ _, rfl }

/--
The canonical linear map `M →ₗ[R] tensor_algebra R M`.
-/
def ι : M →ₗ[R] (tensor_algebra R M) :=
{ to_fun := λ m, quot.mk _ m,
  map_add' := λ x y, quot.sound rel.add_lin,
  map_smul' := λ r x, quot.sound rel.smul_lin }

/--
Given a linear map `f : M → A` where `A` is an `R`-algebra, `lift R M f` is the unique lift
of `f` to a morphism of `R`-algebras `tensor_algebra R M → A`.
-/
def lift {A : Type*} [semiring A] [algebra R A] (f : M →ₗ[R] A) : tensor_algebra R M →ₐ[R] A :=
{ to_fun := λ a, quot.lift_on a (lift_fun _ _ f) $ λ a b h,
  begin
    induction h,
    { change f _ = f _ + f _,
      simp, },
    { change f _ = (algebra_map _ _ _) * f _,
      rw linear_map.map_smul,
      exact algebra.smul_def h_r (f h_a) },
    { exact (algebra_map R A).map_add h_r h_s, },
    { exact (algebra_map R A).map_mul h_r h_s },
    { apply algebra.commutes },
    { change _ + _ + _ = _ + (_ + _),
      rw add_assoc },
    { change _ + _ = _ + _,
      rw add_comm, },
    { change (algebra_map _ _ _) + lift_fun R M f _ = lift_fun R M f _,
      simp, },
    { change _ * _ * _ = _ * (_ * _),
      rw mul_assoc },
    { change (algebra_map _ _ _) * lift_fun R M f _ = lift_fun R M f _,
      simp, },
    { change lift_fun R M f _ * (algebra_map _ _ _) = lift_fun R M f _,
      simp, },
    { change _ * (_ + _) = _ * _ + _ * _,
      rw left_distrib, },
    { change (_ + _) * _ = _ * _ + _ * _,
      rw right_distrib, },
    { change (algebra_map _ _ _) * _ = algebra_map _ _ _,
      simp },
    { change _ * (algebra_map _ _ _) = algebra_map _ _ _,
      simp },
    repeat { change lift_fun R M f _ + lift_fun R M f _ = _,
      rw h_ih,
      refl, },
    repeat { change lift_fun R M f _ * lift_fun R M f _ = _,
      rw h_ih,
      refl, },
  end,
  map_one' := by { change algebra_map _ _ _ = _, simp },
  map_mul' := by { rintros ⟨⟩ ⟨⟩, refl },
  map_zero' := by { change algebra_map _ _ _ = _, simp },
  map_add' := by { rintros ⟨⟩ ⟨⟩, refl },
  commutes' := by tauto }

variables {R M}

@[simp]
theorem ι_comp_lift {A : Type*} [semiring A] [algebra R A] (f : M →ₗ[R] A) :
  (lift R M f).to_linear_map.comp (ι R M) = f := by {ext, refl}

@[simp]
theorem ι_comp_lift' {A : Type*} [semiring A] [algebra R A] (f : M →ₗ[R] A) (m : M) :
  (lift R M f) (ι R M m) = f m := rfl

@[simp]
theorem lift_unique {A : Type*} [semiring A] [algebra R A] (f : M →ₗ[R] A)
  (g : tensor_algebra R M →ₐ[R] A) : g.to_linear_map.comp (ι R M) = f ↔ g = lift R M f :=
begin
  refine ⟨λ hyp, _, λ hyp, by rw [hyp, ι_comp_lift]⟩,
  ext,
  rcases x,
  induction x,
  { change (g.to_linear_map.comp (ι R M)) _ = _,
    rw hyp,
    refl },
  { exact alg_hom.commutes g x },
  { change g (quot.mk _ _ + quot.mk _ _) = _,
    rw [alg_hom.map_add, x_ih_a, x_ih_a_1],
    refl },
  { change g (quot.mk _ _ * quot.mk _ _) = _,
    rw [alg_hom.map_mul, x_ih_a, x_ih_a_1],
    refl },
end

@[simp]
theorem lift_comp_ι {A : Type*} [semiring A] [algebra R A] (g : tensor_algebra R M →ₐ[R] A) :
  lift R M (g.to_linear_map.comp (ι R M)) = g := by {symmetry, rw ←lift_unique}

theorem hom_ext {A : Type*} [semiring A] [algebra R A] {f g : tensor_algebra R M →ₐ[R] A} :
  f.to_linear_map.comp (ι R M) = g.to_linear_map.comp (ι R M) → f = g :=
begin
  intro hyp,
  let h := g.to_linear_map.comp (ι R M),
  have : g = lift R M h, by rw ←lift_unique,
  rw [this, ←lift_unique, hyp],
end

end tensor_algebra
