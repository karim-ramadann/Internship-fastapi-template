"""Conftest for services tests - no database required."""

import pytest


# Override the db fixture for this folder - don't connect to database
@pytest.fixture(scope="session", autouse=True)
def db() -> None:
    """No-op database fixture for services tests."""
    yield None
