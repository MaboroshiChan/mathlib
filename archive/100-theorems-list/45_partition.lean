import ring_theory.power_series
import combinatorics.composition
import data.nat.parity
import data.finset.nat_antidiagonal
import tactic.interval_cases
import tactic.apply_fun

open power_series
noncomputable theory

variables {α : Type*}

lemma eq_mul_inv_iff [field α] {a b c : power_series α} (h : constant_coeff _ c ≠ 0) :
  a = b * c⁻¹ ↔ a * c = b :=
⟨λ k, by simp [k, mul_assoc, power_series.inv_mul _ h],
 λ k, by simp [← k, mul_assoc, power_series.mul_inv _ h]⟩

lemma eq_inv_iff [field α] {a b : power_series α} (h : constant_coeff _ b ≠ 0) : a = b⁻¹ ↔ a * b = 1 :=
by rw [← eq_mul_inv_iff h, one_mul]
lemma power_series.inv_eq_iff [field α] {a b : power_series α} (h : constant_coeff _ b ≠ 0) : b⁻¹ = a ↔ a * b = 1 :=
by rw [eq_comm, eq_inv_iff h]

open finset
open_locale big_operators

lemma count_repeat_ite {α : Type*} [decidable_eq α] (a b : α) (n : ℕ)  :
  multiset.count a (multiset.repeat b n) = if (a = b) then n else 0 :=
begin
  split_ifs,
    cases h,
    rw multiset.count_repeat,
  apply multiset.count_eq_zero_of_not_mem,
  intro,
  apply h,
  apply multiset.eq_of_mem_repeat a_1,
end

open_locale classical
open power_series

noncomputable theory

/-- A partition of `n` is a multiset of positive integers summing to `n`. -/
@[ext, derive decidable_eq] structure partition (n : ℕ) :=
(blocks : multiset ℕ)
(blocks_pos : ∀ {i}, i ∈ blocks → 0 < i)
(blocks_sum : blocks.sum = n)

/-- A composition induces a partition (just convert the list to a multiset). -/
def composition_to_partition (n : ℕ) (c : composition n) : partition n :=
{ blocks := c.blocks,
  blocks_pos := λ i hi, c.blocks_pos hi,
  blocks_sum := by rw [multiset.coe_sum, c.blocks_sum] }

/--
Show there are finitely many partitions by considering the surjection from compositions to
partitions.
-/
instance (n : ℕ) : fintype (partition n) :=
begin
  apply fintype.of_surjective (composition_to_partition n),
  rintro ⟨_, _, _⟩,
  rcases quotient.exists_rep b_blocks with ⟨_, rfl⟩,
  refine ⟨⟨w, λ i hi, b_blocks_pos hi, _⟩, partition.ext _ _ rfl⟩,
  simpa using b_blocks_sum,
end

def partial_odd_gf (n : ℕ) [field α] := ∏ i in range n, (1 - (X : power_series α)^(2*i+1))⁻¹
def partial_distinct_gf (n : ℕ) [comm_semiring α] := ∏ i in range n, (1 + (X : power_series α)^(i+1))

def odd_partition (n : ℕ) := {c : partition n // ∀ i ∈ c.blocks, ¬ nat.even i}
def distinct_partition (n : ℕ) := {c : partition n // multiset.nodup c.blocks}

instance (n : ℕ) : fintype (odd_partition n) :=
subtype.fintype _
instance (n : ℕ) : fintype (distinct_partition n) :=
subtype.fintype _

/--
Functions defined only on `s`, which sum to `n`. In other words, a partition of `n` indexed by `s`.
Every function in here is finitely supported, and the support is a subset of `s`.
This should be thought of as a generalisation of `finset.nat.antidiagonal`, where
`antidiagonal n` is the same thing as `cut s n` if `s` has two elements.
-/
def cut {ι : Type*} (s : finset ι) (n : ℕ) : finset (ι → ℕ) :=
finset.filter (λ f, s.sum f = n) ((s.pi (λ _, range (n+1))).map
  ⟨λ f i, if h : i ∈ s then f i h else 0,
   λ f g h, by { ext i hi, simpa [dif_pos hi] using congr_fun h i }⟩)

def prod_equiv_bool_to {α : Type*} : (bool → α) ≃ α × α :=
{ to_fun := λ f, (f ff, f tt),
  inv_fun := λ x b, bool.cases_on b x.1 x.2,
  left_inv := λ x,
  begin
    ext ⟨_ | _⟩,
    refl,
    refl,
  end,
  right_inv := λ ⟨x₁, x₂⟩, rfl }

lemma mem_cut {ι : Type*} (s : finset ι) (n : ℕ) (f : ι → ℕ) :
  f ∈ cut s n ↔ s.sum f = n ∧ ∀ i ∉ s, f i = 0 :=
begin
  rw [cut, mem_filter, and_comm, and_congr_right],
  intro h,
  rw [mem_map],
  simp only [exists_prop, function.embedding.coe_fn_mk, mem_pi],
  split,
  { rintro ⟨_, _, rfl⟩ _ _,
    simp [dif_neg H] },
  { intro hf,
    refine ⟨λ i hi, f i, λ i hi, _, _⟩,
    { rw [mem_range, nat.lt_succ_iff, ← h],
      apply single_le_sum _ hi,
      simp },
    { ext,
      split_ifs with q,
      { refl },
      { apply (hf _ q).symm } } }
end

def equiv.finset_congr {α β : Type*} (e : α ≃ β) : finset α ≃ finset β :=
{ to_fun := λ s, s.image e,
  inv_fun := λ s, s.image e.symm,
  left_inv := λ s,
  begin
    dsimp,
    rw finset.image_image,
    simp only [equiv.symm_comp_self, image_id],
  end,
  right_inv := λ s,
  begin
    dsimp,
    rw finset.image_image,
    simp only [equiv.self_comp_symm, image_id],
  end }

lemma cut_equiv_antidiag (n : ℕ) :
  equiv.finset_congr prod_equiv_bool_to (cut univ n) = nat.antidiagonal n :=
begin
  ext ⟨x₁, x₂⟩,
  simp only [equiv.finset_congr, equiv.coe_fn_mk, mem_image, ← equiv.eq_symm_apply],
  simp [prod_equiv_bool_to, mem_cut, add_comm],
end

lemma pi_singleton {ι : Type*} (s : finset ι) (i : α) :
  s.pi (λ _, ({i} : finset α)) = {λ _ _, i} :=
begin
  rw eq_singleton_iff_unique_mem,
  split,
    simp,
  intros a ha,
  rw [mem_pi] at ha,
  ext,
  simpa using ha x x_1,
end

/-- There is only one `cut` of 0. -/
@[simp]
lemma cut_zero {ι : Type*} (s : finset ι) :
  cut s 0 = {0} :=
begin
  -- In general it's nice to prove things using `mem_cut` but in this case it's easier to just
  -- use the definition.
  rw [cut, range_one, pi_singleton, map_singleton, function.embedding.coe_fn_mk, filter_singleton,
      if_pos, singleton_inj],
  { ext, split_ifs; refl },
  rw sum_eq_zero_iff,
  intros x hx,
  apply dif_pos hx,
end

@[simp]
lemma cut_empty_succ {ι : Type*} (n : ℕ) :
  cut (∅ : finset ι) (n+1) = ∅ :=
begin
  apply eq_empty_of_forall_not_mem,
  intros x hx,
  rw [mem_cut, sum_empty] at hx,
  cases hx.1,
end

lemma cut_insert {ι : Type*} (n : ℕ) (a : ι) (s : finset ι) (h : a ∉ s) :
  cut (insert a s) n = (nat.antidiagonal n).bind (λ (p : ℕ × ℕ), (cut s p.snd).map ⟨λ f, f + λ t, if t = a then p.fst else 0, add_left_injective _⟩) :=
begin
  ext f,
  rw [mem_cut, mem_bind, sum_insert h],
  split,
  { rintro ⟨rfl, h₁⟩,
    simp only [exists_prop, function.embedding.coe_fn_mk, mem_map, nat.mem_antidiagonal, prod.exists],
    refine ⟨f a, s.sum f, rfl, λ i, if i = a then 0 else f i, _, _⟩,
    { rw [mem_cut],
      refine ⟨_, _⟩,
      { rw [sum_ite],
        have : (filter (λ x, x ≠ a) s) = s,
          apply filter_true_of_mem,
          rintro i hi rfl,
          apply h hi,
        simp [this] },
      { intros i hi,
        split_ifs,
        { refl },
        { apply h₁ ,
          simpa [not_or_distrib, hi] } } },
    { ext,
      by_cases (x = a),
      { subst h, simp },
      { simp [if_neg h] } } },
  { simp only [mem_insert, function.embedding.coe_fn_mk, mem_map, nat.mem_antidiagonal, prod.exists,
               exists_prop, mem_cut, not_or_distrib],
    rintro ⟨p, q, rfl, g, ⟨rfl, hg₂⟩, rfl⟩,
    refine ⟨_, _⟩,
    { simp [sum_add_distrib, if_neg h, hg₂ _ h, add_comm] },
    { rintro i ⟨h₁, h₂⟩,
      simp [if_neg h₁, hg₂ _ h₂] } }
end

lemma coeff_prod_range [comm_semiring α] {ι : Type*} (s : finset ι) (f : ι → power_series α) (n : ℕ) :
  coeff α n (∏ j in s, f j) = ∑ l in cut s n, ∏ i in s, coeff α (l i) (f i) :=
begin
  revert n,
  apply finset.induction_on s,
    rintro ⟨_ | n⟩,
      simp,
    simp [cut_empty_succ, if_neg (nat.succ_ne_zero _)],
  intros a s hi ih n,
  rw [cut_insert _ _ _ hi, prod_insert hi, coeff_mul, sum_bind],
  { apply sum_congr rfl _,
    simp only [prod.forall, sum_map, pi.add_apply, function.embedding.coe_fn_mk, nat.mem_antidiagonal],
    rintro i j rfl,
    simp only [prod_insert hi, if_pos rfl],
    rw ih,
    rw mul_sum,
    apply sum_congr rfl _,
    intros x hx,
    rw mem_cut at hx,
    rw [hx.2 a hi, zero_add],
    congr' 1,
    apply prod_congr rfl,
    intros k hk,
    rw [if_neg, add_zero],
    rintro rfl,
    apply hi hk },
  { simp only [prod.forall, not_and, ne.def, nat.mem_antidiagonal, disjoint_left, mem_map,
               exists_prop, function.embedding.coe_fn_mk, exists_imp_distrib, not_exists],
    rintro p₁ q₁ rfl p₂ q₂ h t p q ⟨hq, rfl⟩ p hp z,
    rw mem_cut at hp hq,
    have := sum_congr (eq.refl s) (λ x _, function.funext_iff.1 z x),
    have : q₂ = q₁,
      simpa [sum_add_distrib, hp.1, hq.1, if_neg hi] using this,
    subst this,
    have : p₂ = p₁,
      simpa using h,
    subst this,
    apply t,
    refl }
end

def indicator_series (α : Type*) [semiring α] (f : set ℕ) : power_series α :=
power_series.mk (λ n, if f n then 1 else 0)

lemma coeff_indicator (f : set ℕ) [semiring α] (n : ℕ) :
  coeff α n (indicator_series _ f) = if f n then 1 else 0 :=
coeff_mk _ _
lemma coeff_indicator_pos (f : set ℕ) [semiring α] (n : ℕ) (h : f n):
  coeff α n (indicator_series _ f) = 1 :=
by rw [coeff_indicator, if_pos h]
lemma coeff_indicator_neg (f : set ℕ) [semiring α] (n : ℕ) (h : ¬f n):
  coeff α n (indicator_series _ f) = 0 :=
by rw [coeff_indicator, if_neg h]
lemma constant_coeff_indicator (f : set ℕ) [semiring α] :
  constant_coeff α (indicator_series _ f) = if f 0 then 1 else 0 :=
by rw [← coeff_zero_eq_constant_coeff_apply, coeff_indicator]

lemma two_series (i : ℕ) [semiring α] :
  (1 + (X : power_series α)^i.succ) = indicator_series α {0, i.succ} :=
begin
  ext,
  simp only [coeff_indicator, coeff_one, add_monoid_hom.map_add, coeff_X_pow,
             ← @set.mem_def _ _ {0, i.succ}, set.mem_insert_iff, set.mem_singleton_iff],
  cases n,
    simp [(nat.succ_ne_zero i).symm],
  simp [nat.succ_ne_zero n],
end

lemma num_series' [field α] (i : ℕ) :
  (1 - (X : power_series α)^(i+1))⁻¹ = indicator_series α (λ k, i + 1 ∣ k) :=
begin
  rw power_series.inv_eq_iff,
  { ext,
    cases n,
    { simp [mul_sub, zero_pow, constant_coeff_indicator] },
    { rw [coeff_one, if_neg (nat.succ_ne_zero n), mul_sub, mul_one, add_monoid_hom.map_sub,
          coeff_indicator],
      simp_rw [coeff_mul, coeff_X_pow, coeff_indicator, boole_mul, sum_ite, filter_filter,
               sum_const_zero, add_zero, sum_const, nsmul_eq_mul, mul_one, sub_eq_iff_eq_add,
               zero_add, filter_congr_decidable],
      symmetry,
      split_ifs,
      { suffices : ((nat.antidiagonal n.succ).filter (λ (a : ℕ × ℕ), i + 1 ∣ a.fst ∧ a.snd = i + 1)).card = 1,
          rw this, norm_cast,
        rw card_eq_one,
        cases h with p hp,
        refine ⟨((i+1) * (p-1), i+1), _⟩,
        ext ⟨a₁, a₂⟩,
        simp only [mem_filter, prod.mk.inj_iff, nat.mem_antidiagonal, mem_singleton],
        split,
        { rintro ⟨_, ⟨a, rfl⟩, rfl⟩,
          refine ⟨_, rfl⟩,
          rw [nat.mul_sub_left_distrib, ← hp, ← a_left, mul_one, nat.add_sub_cancel] },
        { rintro ⟨rfl, rfl⟩,
          cases p,
            rw mul_zero at hp, cases hp,
          rw hp,
          simp [nat.succ_eq_add_one, mul_add] } },
      { suffices : (filter (λ (a : ℕ × ℕ), i + 1 ∣ a.fst ∧ a.snd = i + 1) (nat.antidiagonal n.succ)).card = 0,
          rw this, norm_cast,
        rw card_eq_zero,
        apply eq_empty_of_forall_not_mem,
        simp only [prod.forall, mem_filter, not_and, nat.mem_antidiagonal],
        rintro _ h₁ h₂ ⟨a, rfl⟩ rfl,
        apply h,
        simp [← h₂] } } },
  { simp [zero_pow] },
end

lemma card_eq_of_bijection {β : Type*} {s : finset α} {t : finset β}
  (f : α → β)
  (hf : ∀ a ∈ s, f a ∈ t)
  (hsurj : ∀ b ∈ t, ∃ (a ∈ s), f a = b)
  (hinj : ∀ a₁ a₂ ∈ s, f a₁ = f a₂ → a₁ = a₂) :
s.card = t.card :=
finset.card_congr (λ a _, f a) hf hinj hsurj

lemma sum_multiset_count [decidable_eq α] [add_comm_monoid α] (s : multiset α) :
  s.sum = ∑ m in s.to_finset, s.count m •ℕ m :=
@prod_multiset_count (multiplicative α) _ _ s

lemma auxy (n : ℕ) (a_blocks : multiset ℕ) (s : finset ℕ)
  (a_blocks_sum : a_blocks.sum = n)
  (hp : ∀ (i : ℕ), i ∈ a_blocks → i ∈ s) :
  ∑ (i : ℕ) in s, multiset.count i a_blocks * i = n :=
begin
  rw ← a_blocks_sum,
  rw sum_multiset_count,
  simp_rw nat.nsmul_eq_mul,
  symmetry,
  apply sum_subset_zero_on_sdiff,
  intros i hi,
  apply hp,
  simpa using hi,
  intros,
  rw mem_sdiff at H,
  simp only [multiset.mem_to_finset] at H,
  rw [multiset.count_eq_zero_of_not_mem H.2, zero_mul],
  intros, refl,
end

def mk_odd : ℕ ↪ ℕ := ⟨λ i, 2 * i + 1, λ x y h, by linarith⟩

lemma mem_sum {β : Type*} {f : α → multiset β} (s : finset α) (b : β) :
  b ∈ ∑ x in s, f x ↔ ∃ a ∈ s, b ∈ f a :=
begin
  apply finset.induction_on s,
    simp,
  intros,
  simp only [sum_insert a_1, a_2, multiset.mem_add, exists_prop, mem_insert],
  split,
  rintro (_ | ⟨_, _, _⟩),
    refine ⟨a, or.inl rfl, a_3⟩,
  refine ⟨_, or.inr ‹_›, ‹_›⟩,
  rintro ⟨_, (rfl | _), _⟩,
  left, assumption,
  right,
  refine ⟨a_3_w, ‹_›, ‹_›⟩,
end

lemma sum_sum {β : Type*} [add_comm_monoid β] (f : α → multiset β) (s : finset α) :
  multiset.sum (finset.sum s f) = ∑ x in s, (f x).sum :=
(sum_hom s multiset.sum).symm

lemma partial_gf_prop (α : Type*) [comm_semiring α] (n : ℕ) (s : finset ℕ) (hs : ∀ i ∈ s, 0 < i) (c : ℕ → set ℕ) (hc : ∀ i ∉ s, 0 ∈ c i) :
  (finset.card ((univ : finset (partition n)).filter (λ p, (∀ j, p.blocks.count j ∈ c j) ∧ ∀ j ∈ p.blocks, j ∈ s)) : α) =
  (coeff α n) (∏ (i : ℕ) in s, indicator_series α ((* i) '' c i)) :=
begin
  simp_rw [coeff_prod_range, coeff_indicator, prod_boole, sum_boole],
  congr' 1,
  refine card_eq_of_bijection _ _ _ _,
  { intros p i, apply multiset.count i p.blocks * i },
  { simp only [mem_filter, mem_cut, mem_univ, true_and, exists_prop, and_assoc, and_imp,
               nat.mul_eq_zero, function.embedding.coe_fn_mk, exists_imp_distrib],
    rintro ⟨p, hp₁, hp₂⟩ hp₃ hp₄,
    refine ⟨_, _, _⟩,
    { rw auxy _ _ _ hp₂,
      apply hp₄ },
    { intros i hi,
      left,
      apply multiset.count_eq_zero_of_not_mem,
      apply mt (hp₄ i) hi },
    { intros i hi,
      refine ⟨_, hp₃ i, rfl⟩ } },
  { simp only [mem_filter, mem_cut, mem_univ, exists_prop, true_and, and_assoc],
    rintros f ⟨hf₁, hf₂, hf₃⟩,
    refine ⟨⟨∑ i in s, multiset.repeat i (f i / i), _, _⟩, _, _, _⟩,
    { intros i hi,
      simp only [exists_prop, mem_sum, mem_map, function.embedding.coe_fn_mk] at hi,
      rcases hi with ⟨t, ht, z⟩,
      apply hs,
      rwa multiset.eq_of_mem_repeat z },
    { rw sum_sum,
      simp_rw [multiset.sum_repeat, nat.nsmul_eq_mul],
      have : ∀ i ∈ s, i ∣ f i,
      { intros i hi,
        rcases hf₃ i hi with ⟨w, hw, hw₂⟩,
        rw ← hw₂,
        apply dvd.intro_left _ rfl },
      { rw sum_congr rfl (λ i hi, nat.div_mul_cancel (this i hi)),
        apply hf₁ } },
    { intro i,
      dsimp,
      rw ← sum_hom _ (multiset.count i),
      simp_rw [count_repeat_ite],
      simp only [sum_ite_eq],
      split_ifs,
      { rcases hf₃ i h with ⟨w, hw₁, hw₂⟩,
        rw ← hw₂,
        dsimp,
        rw nat.mul_div_cancel,
        apply hw₁,
        apply hs,
        apply h },
      { apply hc, assumption } },
    { intros i hi,
      dsimp at hi,
      rw mem_sum at hi,
      rcases hi with ⟨_, _, _⟩,
      cases multiset.eq_of_mem_repeat hi_h_h,
      assumption },
    { ext i,
      dsimp,
      rw ← sum_hom _ (multiset.count i),
      simp_rw [count_repeat_ite],
      simp only [sum_ite_eq],
      split_ifs,
      { apply nat.div_mul_cancel,
        rcases hf₃ i h with ⟨w, hw, hw₂⟩,
        apply dvd.intro_left _ hw₂ },
      { rw [zero_mul],
        apply (hf₂ i h).symm } } },
  { intros p₁ p₂ hp₁ hp₂ h,
    apply partition.ext,
    simp only [true_and, mem_univ, mem_filter] at hp₁ hp₂,
    ext i,
    rw function.funext_iff at h,
    specialize h i,
    cases i,
    { rw multiset.count_eq_zero_of_not_mem,
      rw multiset.count_eq_zero_of_not_mem,
      intro a, exact nat.lt_irrefl 0 (hs 0 (hp₂.right 0 a)),
      intro a, exact nat.lt_irrefl 0 (hs 0 (hp₁.right 0 a)) },
    { rwa nat.mul_left_inj at h,
      exact nat.succ_pos i } },
end

lemma partial_odd_gf_prop (n m : ℕ) [field α] :
  (finset.card ((univ : finset (partition n)).filter (λ p, ∀ j ∈ p.blocks, j ∈ (range m).map mk_odd)) : α) =
    coeff α n (partial_odd_gf m) :=
begin
  rw partial_odd_gf,
  convert partial_gf_prop α n ((range m).map mk_odd) _ (λ _, set.univ) (λ _ _, trivial) using 2,
  { congr' 2,
    simp only [true_and, forall_const, set.mem_univ] },
  { rw finset.prod_map,
    simp_rw num_series',
    apply prod_congr rfl,
    intros,
    congr' 1,
    ext k,
    split,
      rintro ⟨p, rfl⟩,
      refine ⟨p, ⟨⟩, _⟩,
      apply mul_comm,
    rintro ⟨_, _, rfl⟩,
    apply dvd.intro_left a_w rfl },
  { intro i,
    rw mem_map,
    rintro ⟨_, _, rfl⟩,
    apply nat.succ_pos },
end

lemma multiset.single_le_sum {a : ℕ} (s : multiset ℕ) :
  a ∈ s → a ≤ s.sum :=
begin
  apply multiset.induction_on s,
    simp,
  rintros b s₁ ih h,
  rw multiset.sum_cons,
  rw multiset.mem_cons at h,
  rcases h with rfl | _,
  exact nat.le.intro rfl,
  apply le_add_left,
  apply ih h,
end

/--  If m is big enough, the partial product's coefficient counts the number of odd partitions -/
theorem odd_gf_prop (n m : ℕ) (h : n < m * 2) [field α] :
  (fintype.card (odd_partition n) : α) = coeff α n (partial_odd_gf m) :=
begin
  erw [fintype.subtype_card, ← partial_odd_gf_prop],
  congr' 2,
  apply filter_congr,
  intros p hp,
  apply ball_congr,
  intros i hi,
  have : i ≤ n,
    simpa [p.blocks_sum] using multiset.single_le_sum _ hi,
  simp only [mk_odd, exists_prop, mem_range, function.embedding.coe_fn_mk, mem_map],
  split,
    intro hi₂,
    have := nat.mod_add_div i 2,
    rw nat.not_even_iff at hi₂,
    rw [hi₂, add_comm] at this,
    refine ⟨i / 2, _, ‹_›⟩,
    rw nat.div_lt_iff_lt_mul,
    apply lt_of_le_of_lt ‹i ≤ n› h,
    norm_num,
  rintro ⟨_, _, rfl⟩,
  apply nat.two_not_dvd_two_mul_add_one,
end


lemma partial_distinct_gf_prop (n m : ℕ) [comm_semiring α] :
  (finset.card ((univ : finset (partition n)).filter (λ p, p.blocks.nodup ∧ ∀ j ∈ p.blocks, j ∈ (range m).map ⟨nat.succ, nat.succ_injective⟩)) : α) =
  coeff α n (partial_distinct_gf m) :=
begin
  rw partial_distinct_gf,
  convert partial_gf_prop α n ((range m).map ⟨nat.succ, nat.succ_injective⟩) _ (λ _, {0, 1}) (λ _ _, or.inl rfl) using 2,
  { congr' 2,
    ext p,
    congr' 2,
    apply propext,
    rw multiset.nodup_iff_count_le_one,
    apply forall_congr,
    intro i,
    rw [set.mem_insert_iff, set.mem_singleton_iff],
    split,
    { intro hi,
      interval_cases (multiset.count i p.blocks),
      left, assumption,
      right, assumption },
    { rintro (h | h);
        rw h,
      norm_num } },
  { rw finset.prod_map,
    apply prod_congr rfl,
    intros,
    rw two_series,
    congr' 1,
    simp [set.image_pair] },
  { simp only [mem_map, function.embedding.coe_fn_mk],
    rintro i ⟨_, _, rfl⟩,
    apply nat.succ_pos }
end

/--  If m is big enough, the partial product's coefficient counts the number of distinct partitions -/
theorem distinct_gf_prop (n m : ℕ) (h : n < m + 1) [comm_semiring α] :
  (fintype.card (distinct_partition n) : α) = coeff α n (partial_distinct_gf m) :=
begin
  erw [fintype.subtype_card, ← partial_distinct_gf_prop],
  congr' 2,
  apply filter_congr,
  intros p hp,
  apply (and_iff_left _).symm,
  intros i hi,
  have : i ≤ n,
    simpa [p.blocks_sum] using multiset.single_le_sum _ hi,
  simp only [mk_odd, exists_prop, mem_range, function.embedding.coe_fn_mk, mem_map],
  refine ⟨i-1, _, _⟩,
  rw nat.sub_lt_right_iff_lt_add,
  apply lt_of_le_of_lt ‹i ≤ n› h,
  apply p.blocks_pos hi,
  apply nat.succ_pred_eq_of_pos,
  apply p.blocks_pos hi,
end

lemma same_gf (n : ℕ) [field α] :
  partial_odd_gf n * (range n).prod (λ i, (1 - (X : power_series α)^(n+i+1))) = partial_distinct_gf n :=
begin
  rw [partial_odd_gf, partial_distinct_gf],
  induction n with n ih,
  { simp },
  let Z : power_series α := ∏ (x : ℕ) in range n, (1 - X^(2*x+1))⁻¹,
  rw [prod_range_succ _ n, prod_range_succ _ n, prod_range_succ _ n, ← ih],
  clear ih,
  erw ← two_mul (n+1),
  have : 1 - (X : power_series α) ^ (2 * (n+1)) = (1 + X^(n+1)) * (1 - X^(n+1)),
    rw [← sq_sub_sq, one_pow, ← pow_mul, mul_comm],
  rw this, clear this,
  rw [mul_assoc, mul_assoc, ← mul_assoc Z, mul_left_comm _ (Z * _), mul_left_comm _ Z,
      ← mul_assoc Z],
  congr' 1,
  have := prod_range_succ' (λ x, 1 - (X : power_series α)^(n.succ + x)) n,
  dsimp at this,
  simp_rw [← add_assoc, add_zero, mul_comm _ (1 - X ^ n.succ)] at this,
  erw [← this],
  rw [prod_range_succ],
  simp_rw [nat.succ_eq_add_one, add_right_comm _ 1, ← two_mul, ← mul_assoc],
  rw [power_series.inv_mul, one_mul],
  simp [zero_pow],
end

lemma coeff_prod_one_add (n : ℕ) [comm_semiring α] (φ ψ : power_series α) (h : ↑n < ψ.order) :
  coeff α n (φ * ψ) = 0 :=
begin
  rw [coeff_mul],
  have : ∑ p in nat.antidiagonal n, (0 : α) = 0,
    rw [sum_const_zero],
  rw ← this,
  apply sum_congr rfl _,
  intros pq hpq,
  apply mul_eq_zero_of_right,
  apply coeff_of_lt_order,
  apply lt_of_le_of_lt _ h,
  rw nat.mem_antidiagonal at hpq,
  norm_cast,
  rw ← hpq,
  apply le_add_left,
  apply le_refl,
end

lemma coeff_prod_one_sub (n : ℕ) [comm_ring α] (φ ψ : power_series α) (h : ↑n < ψ.order) :
  coeff α n (φ * (1 - ψ)) = coeff α n φ :=
by rw [mul_sub, mul_one, add_monoid_hom.map_sub, coeff_prod_one_add _ _ _ h, sub_zero]

lemma same_coeffs (n m : ℕ) (h : m ≤ n) [field α] :
  coeff α m (partial_odd_gf n) = coeff α m (partial_distinct_gf n) :=
begin
  rw ← same_gf,
  set! k := n with h,
  apply_fun range at h,
  rw ← h,
  clear_value k, clear h,
  induction k,
    simp,
  rwa [prod_range_succ, ← mul_assoc, mul_right_comm, coeff_prod_one_sub],
  simp only [enat.coe_one, enat.coe_add, order_X_pow],
  norm_cast,
  rw nat.lt_succ_iff,
  apply le_add_right,
  assumption,
end

theorem freek (n : ℕ) : fintype.card (odd_partition n) = fintype.card (distinct_partition n) :=
begin
  -- We need the counts to live in some field (which contains ℕ), so let's just use ℚ
  suffices : (fintype.card (odd_partition n) : ℚ) = fintype.card (distinct_partition n),
    norm_cast at this, assumption,
  rw distinct_gf_prop _ (n+1),
  rw odd_gf_prop _ (n+1),
  apply same_coeffs,
  linarith,
  linarith,
  linarith,
end
