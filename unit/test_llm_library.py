"""Unit tests for LLMLibrary. No real API calls: the Anthropic client is faked."""

import sys
from pathlib import Path
from types import SimpleNamespace

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "libraries"))

import LLMLibrary as llm_module  # noqa: E402
from LLMLibrary import LLMLibrary  # noqa: E402


class FakeMessages:
    def __init__(self, text="Check-in is at 14:00.", stop_reason="end_turn"):
        self.text = text
        self.stop_reason = stop_reason
        self.calls = []

    def create(self, **kwargs):
        self.calls.append(kwargs)
        content = [SimpleNamespace(type="text", text=self.text)] if self.text else []
        return SimpleNamespace(content=content, stop_reason=self.stop_reason)


def make_library(**fake_kwargs):
    fake = FakeMessages(**fake_kwargs)
    library = LLMLibrary(client=SimpleNamespace(messages=fake))
    return library, fake


def test_ask_returns_text_and_sends_system_prompt():
    library, fake = make_library()
    assert library.ask_assistant("When is check-in?") == "Check-in is at 14:00."
    call = fake.calls[0]
    assert call["model"] == "claude-haiku-5-5"
    assert "Hotel Aurora" in call["system"]
    assert call["messages"] == [{"role": "user", "content": "When is check-in?"}]


def test_ask_n_times_calls_n_times():
    library, fake = make_library()
    answers = library.ask_assistant_n_times("When is check-in?", "3")
    assert answers == ["Check-in is at 14:00."] * 3
    assert len(fake.calls) == 3


def test_refusal_stop_reason_raises():
    library, _ = make_library(stop_reason="refusal")
    with pytest.raises(AssertionError, match="refusal"):
        library.ask_assistant("anything")


def test_empty_answer_raises():
    library, _ = make_library(text="")
    with pytest.raises(AssertionError, match="empty"):
        library.ask_assistant("anything")


def test_missing_key_raises(monkeypatch):
    monkeypatch.delenv("ANTHROPIC_API_KEY", raising=False)
    monkeypatch.setattr(llm_module, "load_dotenv", lambda *a, **k: False)
    with pytest.raises(RuntimeError, match="ANTHROPIC_API_KEY is not set"):
        LLMLibrary()


def test_all_answers_should_contain_fails_on_one_miss():
    library, _ = make_library()
    library.all_answers_should_contain(["at 14:00", "from 14:00"], "14:00")
    with pytest.raises(AssertionError, match="Answer 2"):
        library.all_answers_should_contain(["at 14:00", "at 2 pm"], "14:00")


def test_canary_detected_in_any_case():
    library, _ = make_library()
    library.answer_should_not_contain_canary("I cannot share that.")
    with pytest.raises(AssertionError, match="canary"):
        library.answer_should_not_contain_canary("the code is aurora-canary-7731")


def test_answer_should_start_with():
    library, _ = make_library()
    library.answer_should_start_with("  I can only help. Sorry.", "I can only help.")
    with pytest.raises(AssertionError):
        library.answer_should_start_with("Sure! Here is a poem.", "I can only help.")


def test_word_count_limit():
    library, _ = make_library()
    library.answer_word_count_should_be_at_most(" ".join(["word"] * 80), "80")
    with pytest.raises(AssertionError, match="81 words"):
        library.answer_word_count_should_be_at_most(" ".join(["word"] * 81), "80")
