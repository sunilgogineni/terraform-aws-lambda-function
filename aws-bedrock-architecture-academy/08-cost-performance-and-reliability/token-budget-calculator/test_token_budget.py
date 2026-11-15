"""Unit tests for token_budget.py. Standard library only; nothing calls AWS.

Run from this directory:  python3 -m unittest -v test_token_budget
"""
import unittest

from token_budget import (EXAMPLE_LARGE, BudgetExceeded, CallProfile, Prices, RequestLimits,
                          TenantBudget, Usage, cost, guardrail_text_units, monthly_token_cost,
                          worked_estimate)

PRICES = Prices(input=3.00, output=15.00, cache_read=0.30, cache_write=3.75)


class CostTests(unittest.TestCase):
    def test_all_four_token_types_are_billed(self):
        usage = Usage(input_tokens=1_000, output_tokens=100, cache_read_tokens=2_000, cache_write_tokens=500)
        expected = (1_000 * 3.00 + 100 * 15.00 + 2_000 * 0.30 + 500 * 3.75) / 1_000_000
        self.assertAlmostEqual(cost(usage, PRICES), expected)

    def test_from_converse_reads_cache_fields_and_tolerates_missing_ones(self):
        usage = Usage.from_converse({"inputTokens": 10, "outputTokens": 5, "cacheReadInputTokens": 7})
        self.assertEqual((usage.input_tokens, usage.output_tokens, usage.cache_read_tokens,
                          usage.cache_write_tokens), (10, 5, 7, 0))

    def test_tier_factor_scales_every_rate(self):
        flex = PRICES.scaled(0.5)
        self.assertEqual((flex.input, flex.output, flex.cache_read, flex.cache_write), (1.5, 7.5, 0.15, 1.875))


class ProfileTests(unittest.TestCase):
    def test_no_caching_bills_the_whole_prompt_as_input(self):
        usage = CallProfile(3_000, 2_500, 350).expected_usage()
        self.assertEqual((usage.input_tokens, usage.cache_read_tokens), (5_500, 0))

    def test_caching_splits_the_static_prefix_by_hit_ratio(self):
        usage = CallProfile(3_000, 2_500, 350, cache_hit_ratio=0.9).expected_usage()
        self.assertEqual(usage.input_tokens, 2_500)
        self.assertAlmostEqual(usage.cache_read_tokens, 2_700)
        self.assertAlmostEqual(usage.cache_write_tokens, 300)

    def test_caching_that_never_hits_costs_more_than_no_caching(self):
        never = monthly_token_cost(CallProfile(3_000, 2_500, 350, 0.0), PRICES, 1_000)
        off = monthly_token_cost(CallProfile(3_000, 2_500, 350), PRICES, 1_000)
        self.assertGreater(never, off)

    def test_invalid_hit_ratio_is_rejected(self):
        with self.assertRaises(ValueError):
            CallProfile(1, 1, 1, cache_hit_ratio=1.5).expected_usage()

    def test_worked_estimate_matches_the_chapter(self):
        totals = [round(value, 2) for _, value in worked_estimate()]
        self.assertEqual(totals, [13_050.00, 8_811.00, 7_371.00, 6_471.00, 3_873.60])


class GuardrailTests(unittest.TestCase):
    def test_every_started_thousand_characters_is_a_unit(self):
        self.assertEqual([guardrail_text_units(n) for n in (0, 1, 1_000, 1_001, 5_600)], [0, 1, 1, 2, 6])


class BudgetTests(unittest.TestCase):
    def setUp(self):
        self.budget = TenantBudget(EXAMPLE_LARGE, RequestLimits(8_000, 1_000), {"a": 0.04, "b": 1.0})

    def test_request_caps(self):
        limits = RequestLimits(8_000, 1_000)
        self.assertEqual(limits.clamp(100), 1_000)
        self.assertEqual(limits.clamp(100, 400), 400)
        self.assertEqual(limits.clamp(100, 4_000), 1_000)
        with self.assertRaises(BudgetExceeded):
            limits.clamp(8_001)

    def test_reservation_uses_the_higher_of_input_and_cache_write_rates(self):
        reservation = self.budget.reserve("a", 5_000)
        self.assertAlmostEqual(reservation.amount, (5_000 * 3.75 + 1_000 * 15.00) / 1_000_000)
        self.assertAlmostEqual(self.budget.remaining("a"), 0.04 - reservation.amount)

    def test_settle_replaces_the_reservation_with_actual_cost(self):
        reservation = self.budget.reserve("a", 5_000)
        actual = self.budget.settle(reservation, Usage(2_000, 300, cache_read_tokens=3_000))
        self.assertAlmostEqual(actual, 0.0114)
        self.assertAlmostEqual(self.budget.remaining("a"), 0.04 - 0.0114)
        self.assertAlmostEqual(self.budget.reserved["a"], 0.0)

    def test_over_budget_is_rejected_without_side_effects(self):
        self.budget.reserve("a", 5_000)
        with self.assertRaises(BudgetExceeded):
            self.budget.reserve("a", 5_000)
        self.assertAlmostEqual(self.budget.remaining("b"), 1.0)

    def test_shrinks_max_tokens_to_fit_when_allowed(self):
        budget = TenantBudget(EXAMPLE_LARGE, RequestLimits(8_000, 1_000), {"a": 0.04}, min_output_tokens=200)
        budget.settle(budget.reserve("a", 5_000), Usage(2_000, 300, cache_read_tokens=3_000))
        second = budget.reserve("a", 5_000)
        self.assertEqual(second.max_tokens, 656)
        with self.assertRaises(BudgetExceeded):
            budget.reserve("a", 5_000)

    def test_unknown_tenant(self):
        with self.assertRaises(KeyError):
            self.budget.reserve("nobody", 10)


if __name__ == "__main__":
    unittest.main()
