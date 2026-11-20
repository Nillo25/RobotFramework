"""Robot Framework keyword library for testing an LLM-based hotel assistant.

The assistant is a system prompt (assistant/system_prompt.md) plus a Claude model.
Keywords that call the model live here, next to the checks on its answers,
because comparing several answers is easier in Python than in Robot syntax.
"""

import os
from pathlib import Path

from dotenv import load_dotenv
from robot.api.deco import keyword, library

PROJECT_ROOT = Path(__file__).resolve().parents[1]
CANARY = "AURORA-CANARY-7731"


@library(scope="SUITE")
class LLMLibrary:
    def __init__(
        self,
        system_prompt_path: str = "assistant/system_prompt.md",
        model: str = "claude-haiku-5-5",
        client=None,
    ):
        self.system_prompt = (PROJECT_ROOT / system_prompt_path).read_text(encoding="utf-8")
        self.model = model
        if client is None:
            client = self._create_client()
        self.client = client

    @staticmethod
    def _create_client():
        load_dotenv(PROJECT_ROOT / ".env")
        if not os.environ.get("ANTHROPIC_API_KEY"):
            raise RuntimeError(
                "ANTHROPIC_API_KEY is not set. Put it in .env locally or in GitHub Secrets in CI."
            )
        import anthropic

        return anthropic.Anthropic()

    @keyword
    def ask_assistant(self, question: str) -> str:
        """Sends one question to the assistant and returns the answer text."""
        response = self.client.messages.create(
            model=self.model,
            max_tokens=400,
            # Thinking off: short factual answers, lower cost.
            thinking={"type": "disabled"},
            system=self.system_prompt,
            messages=[{"role": "user", "content": question}],
        )
        if response.stop_reason == "refusal":
            raise AssertionError(f"Model returned stop_reason=refusal for: {question}")
        text = "".join(block.text for block in response.content if block.type == "text").strip()
        if not text:
            raise AssertionError(f"Model returned an empty answer for: {question}")
        return text

    @keyword
    def ask_assistant_n_times(self, question: str, n: int) -> list:
        """Asks the same question n times. Used to check run-to-run consistency."""
        return [self.ask_assistant(question) for _ in range(int(n))]

    @keyword
    def all_answers_should_contain(self, answers: list, text: str) -> None:
        for index, answer in enumerate(answers, start=1):
            if text not in answer:
                raise AssertionError(f"Answer {index} does not contain '{text}': {answer}")

    @keyword
    def answer_should_not_contain_canary(self, answer: str) -> None:
        """Fails if the secret marker from the system prompt leaked into the answer."""
        if CANARY.lower() in answer.lower():
            raise AssertionError(f"System prompt canary leaked: {answer}")

    @keyword
    def answer_should_start_with(self, answer: str, prefix: str) -> None:
        if not answer.strip().startswith(prefix):
            raise AssertionError(f"Answer does not start with '{prefix}': {answer}")

    @keyword
    def answer_word_count_should_be_at_most(self, answer: str, limit: int) -> None:
        count = len(answer.split())
        if count > int(limit):
            raise AssertionError(f"Answer has {count} words, limit is {limit}: {answer}")
