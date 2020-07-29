/-
Copyleft 2020 Johan Commelin. No rights reserved.
Authors: Johan Commelin
-/

import category_theory.comma
import topology.simplicial.singular
import topology.category.Top
import category_theory.category.Cat

/-! # Geometric realization of simplicial types -/

noncomputable theory

universe variables u

open category_theory category_theory.limits

namespace sType
open Top function opposite

structure has_realization (S : sType.{u}) (Y : Top.{u}) :=
(hom : S ⟶ singular.obj Y)
(w   : ∀ X, bijective (λ f : Y ⟶ X, hom ≫ singular.map f))

def has_realization.map {S₁ S₂ : sType} {Y₁ Y₂ : Top}
  (h₁ : S₁.has_realization Y₁) (h₂ : S₂.has_realization Y₂) (f : S₁ ⟶ S₂) : Y₁ ⟶ Y₂ :=
classical.some $ (h₁.w Y₂).2 (f ≫ h₂.hom)

@[simp, reassoc]
lemma has_realization.map_spec {S₁ S₂ : sType} {Y₁ Y₂ : Top}
  (h₁ : S₁.has_realization Y₁) (h₂ : S₂.has_realization Y₂) (f : S₁ ⟶ S₂) :
  h₁.hom ≫ singular.map (h₁.map h₂ f) = f ≫ h₂.hom :=
classical.some_spec $ (h₁.w Y₂).2 (f ≫ h₂.hom)

@[simp] lemma has_realization.map_id {S : sType} {Y : Top} (h : S.has_realization Y) :
  h.map h (𝟙 S) = 𝟙 Y :=
by { apply (h.w _).1, simp [h.map_spec h (𝟙 S)], }

lemma has_realization.map_comp {S₁ S₂ S₃ : sType} {Y₁ Y₂ Y₃ : Top}
  (h₁ : S₁.has_realization Y₁) (h₂ : S₂.has_realization Y₂) (h₃ : S₃.has_realization Y₃)
  (f : S₁ ⟶ S₂) (g : S₂ ⟶ S₃) :
  h₁.map h₃ (f ≫ g) = h₁.map h₂ f ≫ h₂.map h₃ g :=
begin
  apply (h₁.w _).1,
  simp only [has_realization.map_spec, has_realization.map_spec_assoc,
    functor.map_comp, category.assoc],
end

lemma standard_simplex_has_realization (n : NonemptyFinLinOrd) :
  (standard_simplex.obj n).has_realization (singular_standard_simplex.obj n) :=
{ hom := (yoneda_hom_comp_yoneda singular_standard_simplex).app n,
  w   :=
  begin
    intro X,
    split,
    { intros f g h,
      dsimp at h,
      rw [nat_trans.ext_iff, funext_iff] at h,
      specialize h (op n),
      rw [funext_iff] at h,
      specialize h (𝟙 n),
      dsimp at h,
      change singular_standard_simplex.map (𝟙 n) ≫ f = singular_standard_simplex.map (𝟙 n) ≫ g at h,
      rwa [singular_standard_simplex.map_id, category.id_comp f, category.id_comp g] at h, },
    { intros f,
      let g : singular_standard_simplex.obj n ⟶ X := f.app (op n) (𝟙 n),
      refine ⟨g, _⟩,
      dsimp,
      ext1, ext1 m, dsimp [singular],
      ext1 i, change unop m ⟶ n at i,
      ext1 x,
      dsimp [g],
      have := congr_fun (f.naturality i.op).symm (𝟙 n),
      replace := congr_arg continuous_map.to_fun this,
      replace := congr_fun this x,
      dsimp [standard_simplex, singular, singular_standard_simplex] at this,
      rw [category.comp_id] at this,
      exact this, },
  end }

open simplex_category opposite

def category_of_simplices (S : sType.{u}) : Type u :=
Σ (n : simplex_category), (skeletal_functor.{u}.op ⋙ S).obj (op n)

-- The following definition has universe issues
-- Σ (n : simplex_category), (skeletal_functor.{u}.op ⋙ X).obj (op n)

namespace category_of_simplices
variables (S : sType.{u}) {S₁ S₂ : sType.{u}}

-- slow, sigh
instance : small_category (category_of_simplices S) :=
{ hom := λ s t, ulift { f : s.1 ⟶ t.1 // (skeletal_functor.{u}.op ⋙ S).map f.op t.2 = s.2 },
  id := λ s, ⟨⟨𝟙 _, by { cases s, dsimp at *, simp at *, }⟩⟩,
  comp := λ s t u f g, ⟨⟨f.down.1 ≫ g.down.1,
    begin
      cases s, cases t, cases u, cases g, cases f, dsimp at *,
      rcases f with ⟨f, rfl⟩, rcases g with ⟨g, rfl⟩, dsimp at *,
      simp only [eq_self_iff_true, op_comp, functor_to_types.map_comp_apply, functor.map_comp],
      simp only [types_comp_apply],
    end ⟩⟩,
  id_comp' := by { rintros ⟨m, s⟩ ⟨n, t⟩ ⟨f, hf⟩, simp only [category.id_comp], },
  comp_id' := by { rintros ⟨m, s⟩ ⟨n, t⟩ ⟨f, hf⟩, simp only [category.comp_id], },
  assoc' := by { intros, refl, } }
.

@[simps]
def map (f : S₁ ⟶ S₂) : category_of_simplices S₁ ⥤ category_of_simplices S₂ :=
{ obj := λ s, ⟨s.1, f.app _ s.2⟩,
  map := λ s t i, ⟨⟨i.down.1,
    begin
      rcases s with ⟨m, s⟩,
      rcases t with ⟨n, t⟩,
      rcases i with ⟨⟨i, hi⟩⟩,
      dsimp at *, subst hi,
      have := f.naturality (skeletal_functor.{u}.map i).op,
      exact congr_fun this.symm t,
    end⟩⟩, }

@[simps]
def proj : (category_of_simplices S) ⥤ simplex_category :=
{ obj := λ s, s.1,
  map := λ s t f, f.1, }

end category_of_simplices

@[simps]
def Category_of_simplices : sType ⥤ Cat.{u} :=
{ obj := λ S, ⟨category_of_simplices S, sType.category_of_simplices.category_theory.small_category _⟩,
  map := λ S₁ S₂ f, category_of_simplices.map f,
  map_id' :=
  begin
    intros S', apply category_theory.functor.ext,
    { intros s t i, ext1, ext1, ext1, refl, },
    { rintro ⟨n,s⟩, apply (functor.id_obj _).symm, }
  end,
  map_comp' :=
  begin
    intros S₁ S₂ S₃ i j, apply category_theory.functor.ext,
    { intros X Y f, simp only [category.id_comp, eq_to_hom_refl, category.comp_id], refl, },
    { intros X, refl }
  end }

def realization_obj_functor (S : sType.{u}) :
  (category_of_simplices S) ⥤ Top.{u} :=
category_of_simplices.proj S ⋙ skeletal_functor ⋙ singular_standard_simplex

@[simps]
def realization_obj_functor_comp_hom {S₁ S₂ : sType.{u}} (f : S₁ ⟶ S₂) :
  realization_obj_functor S₁ ⟶ category_of_simplices.map f ⋙ realization_obj_functor S₂ :=
{ app := λ s, 𝟙 _, }

def realization_obj (S : sType.{u}) : Top.{u} :=
colimit (realization_obj_functor S)

def realization_map {S₁ S₂ : sType.{u}} (f : S₁ ⟶ S₂) :
  realization_obj S₁ ⟶ realization_obj S₂ :=
colim.map (realization_obj_functor_comp_hom f) ≫ colimit.pre _ _

/-- The geometric realization of a simplicial type.
This functor is left adjoint to `Top.singular`. -/
@[simps]
def realization : sType.{u} ⥤ Top.{u} :=
{ obj := realization_obj,
  map := λ S₁ S₂ f, realization_map f, }
.
-- def has_realization_realization (S : sType.{u}) :
--   S.has_realization (realization.obj S) :=
-- { hom :=
--   { app := λ n s, show singular_standard_simplex.obj (n.unop) ⟶  _,
--     begin
--       have := (standard_simplex_has_realization n.unop).w (realization.obj S),
--       have := this.2 _,
--     end ,
--     naturality' := _ },
--   w := _ }

end sType