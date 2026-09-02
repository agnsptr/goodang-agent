"""Eval metrics — accuracy, business safety, forbidden tool rate."""


def accuracy(passed: int, total: int) -> float:
    return passed / total if total else 1.0
