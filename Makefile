CF=node_modules/.bin/commonform
CFT=node_modules/.bin/cftemplate
SPELL=node_modules/.bin/reviewers-edition-spell
OUTPUT=build
PROJECT_OUTPUT=$(OUTPUT)/projects
GIT_TAG=$(strip $(shell git tag -l --points-at HEAD))
EDITION=$(if $(GIT_TAG),$(GIT_TAG),Development Draft)

FORMS=$(basename $(wildcard *.cform))
PROJECTS=$(basename $(wildcard projects/*.cform))
DOCX=$(addprefix $(OUTPUT)/,$(addsuffix .docx,$(FORMS) $(PROJECTS)))
PDF=$(addprefix $(OUTPUT)/,$(addsuffix .pdf,$(FORMS) $(PROJECTS)))
MD=$(addprefix $(OUTPUT)/,$(addsuffix .md,$(FORMS) $(PROJECTS)))
JSON=$(addprefix $(OUTPUT)/,$(addsuffix .json,$(FORMS) $(PROJECTS)))
TARGETS=$(DOCX) $(PDF) $(MD) $(JSON)

all: $(TARGETS)

$(PROJECT_OUTPUT):
	mkdir -p $@

SUMMARY_TITLE=Switchmode Developer Agreement Project Summary

$(PROJECT_OUTPUT)/%.md: projects/%.form blanks.json | $(CF) $(PROJECT_OUTPUT)
	$(CF) render --format markdown --title "$(SUMMARY_TITLE)" --blanks blanks.json < $< > $@

$(PROJECT_OUTPUT)/%.docx: projects/%.cform projects/signatures.json blanks.json | $(CF) $(PROJECT_OUTPUT)
	$(CF) render --format docx --title "$(SUMMARY_TITLE)" --left-align-title --edition "$(EDITION)" --indent-margins --number outline --signatures projects/signatures.json --blanks blanks.json < $< > $@

$(PROJECT_OUTPUT)/%.json: projects/%.cform | $(CF) $(PROJECT_OUTPUT)
	$(CF) render --format native < $< > $@

$(OUTPUT):
	mkdir -p $@

$(OUTPUT)/%.md: %.form %.options blanks.json | $(CF) $(OUTPUT)
	$(CF) render --format markdown $(shell cat $*.options) --blanks blanks.json < $< > $@

$(OUTPUT)/%.docx: %.form %.options %.json blanks.json | $(CF) $(OUTPUT)
	$(CF) render --format docx $(shell cat $*.options) --edition "$(EDITION)" --signatures $*.json --blanks blanks.json < $< > $@

$(OUTPUT)/%.json: %.form | $(CF) $(OUTPUT)
	$(CF) render --format native < $< > $@

%.form: %.cform
ifeq ($(EDITION),Development Draft)
	cat $< | sed "s!PUBLICATION!a development draft of the Switchmode Developer Agreement!" > $@
else
	cat $< | sed "s!PUBLICATION!the $(shell echo "$(EDITION)" | $(SPELL) | sed 's!draft of!draft of the!') of the Switchmode Developer Agreement!" > $@
endif

%.pdf: %.docx
	doc2pdf $<

$(CF):
	npm install

.PHONY: clean docker lint critique

lint: $(JSON) | $(CF)
	for form in $(JSON); do echo $$form; $(CF) lint < $$form; done

critique: $(JSON) | $(CF)
	for form in $(JSON); do echo $$form ; $(CF) critique < $$form; done

clean:
	rm -rf $(OUTPUT)

docker:
	docker build -t switchmode .
	docker run --name switchmode switchmode
	docker cp switchmode:/workdir/$(OUTPUT) .
	docker rm switchmode
