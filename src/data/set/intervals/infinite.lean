/-
Copyright (c) 2020 Reid Barton. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Reid Barton
-/
import data.set.finite

/-!
# Infinitude of intervals

Bounded intervals in dense orders are infinite, as are unbounded intervals
in orders that are unbounded on the appropriate side.
-/

namespace set

variables {α : Type*} [preorder α]

section bounded

variables [densely_ordered α]

lemma Ioo.infinite {a b : α} (h : a < b) : infinite (Ioo a b) :=
begin
  obtain ⟨c, hc₁, hc₂⟩ : ∃ c : α, a < c ∧ c < b := dense h,
  rintro (f : finite (Ioo a b)),
  letI := f.fintype,
  have : well_founded (@has_lt.lt (Ioo a b) _) :=
    fintype.well_founded_of_trans_of_irrefl _,
  obtain ⟨m, -, hm⟩ : ∃ (m : Ioo a b) _,
    ∀ d ∈ univ, ¬ d < m := this.has_min univ ⟨⟨c, hc₁, hc₂⟩, trivial⟩,
  obtain ⟨z, hz₁, hz₂⟩ : ∃ (z : α), a < z ∧ z < m := dense m.2.1,
  refine hm ⟨z, hz₁, lt_trans hz₂ m.2.2⟩ trivial hz₂
end

lemma Ico.infinite {a b : α} (h : a < b) : infinite (Ico a b) :=
infinite_mono Ioo_subset_Ico_self (Ioo.infinite h)

lemma Ioc.infinite {a b : α} (h : a < b) : infinite (Ioc a b) :=
infinite_mono Ioo_subset_Ioc_self (Ioo.infinite h)

lemma Icc.infinite {a b : α} (h : a < b) : infinite (Icc a b) :=
infinite_mono Ioo_subset_Icc_self (Ioo.infinite h)

end bounded

section unbounded_below

variables [no_bot_order α]

lemma Iio.infinite {b : α} : infinite (Iio b) :=
begin
  obtain ⟨c, hc⟩ : ∃ c : α, c < b := no_bot _,
  rintro (f : finite (Iio b)),
  letI := f.fintype,
  have : well_founded (@has_lt.lt (Iio b) _) :=
    fintype.well_founded_of_trans_of_irrefl _,
  obtain ⟨m, -, hm⟩ : ∃ (m : Iio b) _,
    ∀ d ∈ univ, ¬ d < m := this.has_min univ ⟨⟨c, hc⟩, trivial⟩,
  obtain ⟨z, hz⟩ : ∃ (z : α), z < m := no_bot _,
  refine hm ⟨z, lt_trans hz m.2⟩ trivial hz
end

lemma Iic.infinite {b : α} : infinite (Iic b) :=
infinite_mono Iio_subset_Iic_self Iio.infinite

end unbounded_below

section unbounded_above

variables [no_top_order α]

lemma Ioi.infinite {a : α} : infinite (Ioi a) :=
by apply @Iio.infinite (order_dual α)

lemma Ici.infinite {a : α} : infinite (Ici a) :=
infinite_mono Ioi_subset_Ici_self Ioi.infinite

end unbounded_above

end set
