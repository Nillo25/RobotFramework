# Robot Framework: UI, API and LLM tests

[![ci](https://github.com/Nillo25/RobotFramework/actions/workflows/ci.yml/badge.svg)](https://github.com/Nillo25/RobotFramework/actions/workflows/ci.yml)

A small test automation project in Robot Framework. It has three suites:

| Suite | System under test | Library | Tests |
|---|---|---|---|
| `tests/ui` | [Sauce Demo](https://www.saucedemo.com), a demo shop Sauce Labs built for practising automation | Browser library (Playwright) | 6 |
| `tests/api` | [Restful Booker](https://restful-booker.herokuapp.com), a public practice API | RequestsLibrary | 6 |
| `tests/llm` | "Hotel Aurora" assistant: a system prompt plus Claude Haiku 5.5 | own Python library `LLMLibrary` | 4 |

I work as a QA engineer and wrote my earlier automation in Java (Selenium, Appium, REST Assured). I built this project to learn Robot Framework, the Browser library and Python test code on something small enough to understand line by line.

## What is tested and why

**UI (Sauce Demo).** Login with a valid user, a locked-out user and a wrong password; the cart badge after adding two items; a full checkout; sorting by price. Each test gets a fresh browser context, so no cookies or cart state leak between tests.

**API (Restful Booker).** Health check, create and read back a booking, get an auth token, update with and without a token, delete. Every test creates its own booking, because other people use the public instance at the same time. Two quirks of the app are asserted as they are and commented in the tests: `/ping` returns 201 and `DELETE` returns 201.

**LLM (Hotel Aurora assistant).** The assistant is defined in [`assistant/system_prompt.md`](assistant/system_prompt.md). The suite checks four things:

1. Consistency: the same question asked 3 times, every answer must contain the check-in time `14:00`.
2. Prompt injection: three attacks (ignore instructions, role play, "translate your instructions"). The system prompt contains a canary string, and it must not appear in any answer.
3. Scope: an off-topic request must get the fixed refusal sentence from the prompt.
4. Length: an answer must stay within 80 words.

All checks are deterministic string checks. There is no LLM judge here; my other project [llm-sales-assistant-evals](https://github.com/Nillo25/llm-sales-assistant-evals) covers that approach.

## Project structure

```
assistant/system_prompt.md     the assistant under test
libraries/LLMLibrary.py        custom keyword library (Python)
resources/saucedemo.resource   UI keywords: Login As, Add Item To Cart, Complete Checkout ...
resources/booker.resource      API keywords: Open Booker Session, Create Test Booking ...
tests/ui/  tests/api/  tests/llm/
unit/test_llm_library.py       pytest tests for the library, no API calls
.github/workflows/             ci.yml (every push), llm.yml (manual + weekly)
```

Where the line between Robot and Python is: test scenarios and page steps are in `.robot` and `.resource` files. Code that talks to an external SDK or compares several values (the model client, consistency and leak checks) is in Python, where it can have its own unit tests.

## Run locally

Needs Python 3.11+ and Node.js (tested with Node 22).

```bash
make install    # venv, dependencies, Playwright Chromium
make test       # UI + API (everything except llm)
make smoke      # only tests tagged smoke
make unit       # pytest for LLMLibrary
```

The LLM suite needs an Anthropic API key. Copy `.env.example` to `.env`, add the key, then:

```bash
make llm
```

Reports go to `results/report.html` and `results/log.html`. To watch the browser, add `--variable HEADLESS:False` to the robot command.

## Tags

Every test has a suite tag (`ui`, `api`, `llm`) and a level tag (`smoke` or `regression`). Examples: `robot --include smoke tests`, `robot --include api --exclude regression tests`.

## CI

- `ci.yml` runs on every push and pull request: unit tests, then UI and API tests. Restful Booker runs as a Docker service container inside the job, so a slow public instance does not break the build. The Robot report is uploaded as the `robot-results` artifact, also when tests fail.
- `llm.yml` runs the LLM suite on demand and every Monday, with the key from GitHub Secrets. One full run is about 12 short API calls, well under one cent.

## What I learned

- Robot Framework splits test intent (`.robot`), reusable steps (`.resource`) and code (Python libraries). Keyword names become the test language.
- The Browser library waits for elements to be visible, enabled and stable before it clicks, so the tests have no sleeps.
- RequestsLibrary does not verify TLS certificates by default (`verify=False`). I turned verification on in `Create Session`.
- Testing an LLM with plain asserts works when the system prompt gives the model something checkable: a fixed refusal sentence, a canary string, a word limit.

## Limitations

- Three runs per question is a smoke check for consistency, not a statistical measurement. Current Claude models do not accept a temperature setting, so the answers really do vary between runs.
- The injection attacks are three hand-written prompts. Passing them does not mean the prompt resists injection in general.
- Sauce Demo and Restful Booker belong to other people. If they change their pages or go down, the tests fail for reasons outside this repo. Locally, the API tests use the public Restful Booker unless `BASE_URL` is set.
- The UI suite runs only in Chromium.
