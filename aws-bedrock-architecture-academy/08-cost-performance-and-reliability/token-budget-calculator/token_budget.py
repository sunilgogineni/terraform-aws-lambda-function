"""Token budget and cost calculator for Amazon Bedrock workloads.

Code status: syntax-checked (python -m py_compile) and unit-tested with
unittest (standard library only, no AWS calls) - never deployed.

Prices are inputs, in US dollars per 1,000,000 tokens, as quoted on the
Amazon Bedrock pricing page for one model, Region, routing and tier. Token
counts use the meaning of the Converse `usage` fields: `inputTokens` excludes
cached tokens, so total input = input + cache read + cache write.
"""
from __future__ import annotations

import math
from dataclasses import dataclass

PER_MILLION = 1_000_000


@dataclass(frozen=True)
class Prices:
    """USD per 1M tokens for one model, Region, routing and service tier."""

    input: float
    output: float
    cache_read: float = 0.0
    cache_write: float = 0.0

    def scaled(self, factor: float) -> "Prices":
        """Apply a tier factor such as 0.5 (Flex) or 1.75 (Priority).

        Assumption: the factor applies to every token type. Check the
        provider's footnote on the pricing page for your model.
        """
        return Prices(self.input * factor, self.output * factor,
                      self.cache_read * factor, self.cache_write * factor)


@dataclass(frozen=True)
class Usage:
    """Token counts for one call, or expected counts for an average call."""

    input_tokens: float
    output_tokens: float
    cache_read_tokens: float = 0.0
    cache_write_tokens: float = 0.0

    @classmethod
    def from_converse(cls, usage: dict) -> "Usage":
        """Build from the `usage` object of a Converse or ConverseStream response."""
        return cls(usage.get("inputTokens", 0), usage.get("outputTokens", 0),
                   usage.get("cacheReadInputTokens", 0), usage.get("cacheWriteInputTokens", 0))


def cost(usage: Usage, prices: Prices) -> float:
    """Cost in USD of the given token counts. All four token types are billed."""
    return (usage.input_tokens * prices.input
            + usage.output_tokens * prices.output
            + usage.cache_read_tokens * prices.cache_read
            + usage.cache_write_tokens * prices.cache_write) / PER_MILLION


@dataclass(frozen=True)
class CallProfile:
    """Expected shape of one model call."""

    static_tokens: int        # identical prefix: system prompt, tool definitions
    dynamic_tokens: int       # history, retrieved passages, the question
    output_tokens: int
    cache_hit_ratio: float | None = None  # None means prompt caching is not used

    def expected_usage(self) -> Usage:
        if self.cache_hit_ratio is None:
            return Usage(self.static_tokens + self.dynamic_tokens, self.output_tokens)
        if not 0.0 <= self.cache_hit_ratio <= 1.0:
            raise ValueError("cache_hit_ratio must be between 0 and 1")
        hit = self.cache_hit_ratio
        return Usage(self.dynamic_tokens, self.output_tokens,
                     cache_read_tokens=hit * self.static_tokens,
                     cache_write_tokens=(1 - hit) * self.static_tokens)


def monthly_token_cost(profile: CallProfile, prices: Prices, calls_per_month: float) -> float:
    """Expected monthly token cost for `calls_per_month` calls shaped like `profile`."""
    return cost(profile.expected_usage(), prices) * calls_per_month


def guardrail_text_units(characters: int) -> int:
    """Text units for one guardrail policy: every started 1,000 characters is one unit."""
    return math.ceil(characters / 1000) if characters > 0 else 0


class BudgetExceeded(Exception):
    """Raised when a request would break a per-request cap or a tenant's budget."""


@dataclass(frozen=True)
class RequestLimits:
    """Per-request caps, enforced before the model is called."""

    max_input_tokens: int
    max_output_tokens: int

    def clamp(self, input_tokens: int, requested_max_tokens: int | None = None) -> int:
        """Return the maxTokens value to send; raise if the input is over its cap."""
        if input_tokens > self.max_input_tokens:
            raise BudgetExceeded(f"input of {input_tokens} tokens exceeds the "
                                 f"per-request cap of {self.max_input_tokens}")
        if requested_max_tokens is None:
            return self.max_output_tokens
        return min(requested_max_tokens, self.max_output_tokens)


@dataclass(frozen=True)
class Reservation:
    tenant: str
    amount: float
    max_tokens: int


class TenantBudget:
    """Per-tenant spend budget for one period, with reserve-then-settle accounting.

    reserve() books the worst case before the call: every input token at the
    higher of the input and cache-write rates, plus maxTokens of output. This
    mirrors how Bedrock reserves input plus max_tokens against the
    tokens-per-minute quota. settle() replaces the reservation with the cost
    of the usage that the response reports.
    """

    def __init__(self, prices: Prices, limits: RequestLimits, period_limits: dict[str, float],
                 min_output_tokens: int = 0):
        self.prices = prices
        self.limits = limits
        self.period_limits = dict(period_limits)
        self.min_output_tokens = min_output_tokens
        self.spent = {tenant: 0.0 for tenant in self.period_limits}
        self.reserved = {tenant: 0.0 for tenant in self.period_limits}

    def remaining(self, tenant: str) -> float:
        return self.period_limits[tenant] - self.spent[tenant] - self.reserved[tenant]

    def worst_case(self, input_tokens: int, max_tokens: int) -> float:
        input_rate = max(self.prices.input, self.prices.cache_write)
        return (input_tokens * input_rate + max_tokens * self.prices.output) / PER_MILLION

    def reserve(self, tenant: str, input_tokens: int, requested_max_tokens: int | None = None) -> Reservation:
        """Reserve budget for one call. If min_output_tokens > 0, shrink maxTokens to fit
        the remaining budget instead of rejecting, as long as at least that many fit."""
        if tenant not in self.period_limits:
            raise KeyError(f"unknown tenant {tenant!r}")
        max_tokens = self.limits.clamp(input_tokens, requested_max_tokens)
        if self.worst_case(input_tokens, max_tokens) > self.remaining(tenant) and self.min_output_tokens:
            input_cost = self.worst_case(input_tokens, 0)
            fit = math.floor((self.remaining(tenant) - input_cost) * PER_MILLION / self.prices.output)
            if fit >= self.min_output_tokens:
                max_tokens = min(max_tokens, fit)
        amount = self.worst_case(input_tokens, max_tokens)
        if amount > self.remaining(tenant):
            raise BudgetExceeded(f"tenant {tenant!r}: worst case ${amount:.4f} exceeds "
                                 f"remaining ${self.remaining(tenant):.4f}")
        self.reserved[tenant] += amount
        return Reservation(tenant, amount, max_tokens)

    def settle(self, reservation: Reservation, usage: Usage) -> float:
        """Release the reservation and record the actual cost. Returns the actual cost."""
        actual = cost(usage, self.prices)
        self.reserved[reservation.tenant] -= reservation.amount
        self.spent[reservation.tenant] += actual
        return actual


# Example prices: Moonshot Kimi 3 through Global cross-Region inference and Kimi K2.5
# in-Region (US East), Standard tier, read from https://aws.amazon.com/bedrock/pricing/
# as of 2026-11-15. They are examples only, not recommendations - replace them.
EXAMPLE_LARGE = Prices(input=3.00, output=15.00, cache_read=0.30, cache_write=3.75)
EXAMPLE_SMALL = Prices(input=0.60, output=3.00)


def worked_estimate(actions_per_month: int = 600_000) -> list[tuple[str, float]]:
    """The cumulative optimisation steps of the chapter's worked monthly estimate."""
    steps = [
        ("1. Baseline", CallProfile(3_000, 2_500, 350)),
        ("2. + prompt caching, 90% hits", CallProfile(3_000, 2_500, 350, 0.9)),
        ("3. + 3 better chunks instead of 5", CallProfile(3_000, 1_700, 350, 0.9)),
        ("4. + shorter answers", CallProfile(3_000, 1_700, 250, 0.9)),
    ]
    rows = [(name, monthly_token_cost(p, EXAMPLE_LARGE, actions_per_month)) for name, p in steps]
    small_share = 0.6
    large = monthly_token_cost(steps[-1][1], EXAMPLE_LARGE, actions_per_month * (1 - small_share))
    small = monthly_token_cost(CallProfile(3_000, 1_700, 250), EXAMPLE_SMALL, actions_per_month * small_share)
    rows.append(("5. + route 60% to the smaller model", large + small))
    return rows


if __name__ == "__main__":
    for name, monthly in worked_estimate():
        print(f"{name:38} ${monthly:>10,.2f} per month")

    budget = TenantBudget(EXAMPLE_LARGE, RequestLimits(max_input_tokens=8_000, max_output_tokens=1_000),
                          {"tenant-a": 0.04}, min_output_tokens=200)
    first = budget.reserve("tenant-a", input_tokens=5_000)
    print(f"reserved ${first.amount:.4f} with maxTokens={first.max_tokens}")
    actual = budget.settle(first, Usage.from_converse(
        {"inputTokens": 2_000, "cacheReadInputTokens": 3_000, "outputTokens": 300}))
    print(f"settled at ${actual:.4f}; remaining ${budget.remaining('tenant-a'):.4f}")
    second = budget.reserve("tenant-a", input_tokens=5_000)
    print(f"second call shrunk to maxTokens={second.max_tokens}")
    try:
        budget.reserve("tenant-a", input_tokens=5_000)
    except BudgetExceeded as exc:
        print(f"third call rejected: {exc}")
