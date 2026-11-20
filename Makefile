VENV := .venv
BIN := $(VENV)/bin
ROBOT := $(BIN)/robot --outputdir results

.PHONY: install test smoke llm unit clean

install:
	python3 -m venv $(VENV)
	$(BIN)/pip install --quiet --upgrade pip
	$(BIN)/pip install --quiet -r requirements.txt
	$(BIN)/rfbrowser init chromium

test:
	$(ROBOT) --exclude llm tests

smoke:
	$(ROBOT) --include smoke --exclude llm tests

llm:
	$(ROBOT) --include llm tests

unit:
	$(BIN)/pytest unit -q

clean:
	rm -rf results
