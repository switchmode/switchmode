CF=node_modules/.bin/commonform
CFT=node_modules/.bin/cftemplate
SPELL=node_modules/.bin/reviewers-edition-spell
OUTPUT=build
PROJECT_OUTPUT=$(OUTPUT)/projects
GIT_TAG=$(strip $(shell git tag -l --points-at HEAD))
EDITION=$(if $(GIT_TAG),$(GIT_TAG),Development Draft)
ifeq ($(EDITION),development draft)
	SPELLED_EDITION=$(EDITION)
else
	SPELLED_EDITION=$(shell echo "$(EDITION)" | $(SPELL) | sed 's!draft of!draft of the!')
endif

FORMS=$(basename $(wildcard *.cform))
PROJECTS=$(basename $(wildcard projects/*.cform))
DOCX=$(addprefix $(OUTPUT)/,$(addsuffix .docx,$(FORMS) $(PROJECTS)))
PDF=$(addprefix $(OUTPUT)/,$(addsuffix .pdf,$(FORMS) $(PROJECTS)))
MD=$(addprefix $(OUTPUT)/,$(addsuffix .md,$(FORMS) $(PROJECTS)))
JSON=$(addprefix $(OUTPUT)/,$(addsuffix .json,$(FORMS) $(PROJECTS)))

CO_NOTICES=$(basename $(notdir $(wildcard notices/company/*.eml)))
PREFIXED_CO_NOTICES=$(addprefix company-,$(CO_NOTICES))

TR_NOTICES=$(basename $(notdir $(wildcard notices/company/technical-representative/*.eml)))
PREFIXED_TR_NOTICES=$(addprefix tech-rep-,$(TR_NOTICES))

DEV_NOTICES=$(basename $(notdir $(wildcard notices/developer/*.eml)))
PREFIXED_DEV_NOTICES=$(addprefix developer-,$(DEV_NOTICES))

PREFIXED_NOTICES=$(PREFIXED_CO_NOTICES) $(PREFIXED_TR_NOTICES) $(PREFIXED_DEV_NOTICES)

NOTICES=$(addprefix $(OUTPUT)/,$(addprefix notice-,$(PREFIXED_NOTICES)))

TARGETS=$(DOCX) $(PDF) $(MD) $(JSON) $(NOTICES)

all: $(TARGETS)

$(PROJECT_OUTPUT):
	mkdir -p $@

SUMMARY_TITLE=Switchmode Developer Agreement Project Summary

$(PROJECT_OUTPUT)/%.md: projects/%.form blanks.json | $(CF) $(PROJECT_OUTPUT)
	$(CF) render --format markdown --title "$(SUMMARY_TITLE)" --blanks blanks.json < $< > $@

$(PROJECT_OUTPUT)/%.docx: projects/%.cform projects/signatures.json blanks.json | $(CF) $(PROJECT_OUTPUT)
	$(CF) render --format docx --title "$(SUMMARY_TITLE)" --left-align-title --edition "$(SPELLED_EDITION)" --indent-margins --number outline --signatures projects/signatures.json --blanks blanks.json < $< > $@

$(PROJECT_OUTPUT)/%.json: projects/%.cform | $(CF) $(PROJECT_OUTPUT)
	$(CF) render --format native < $< > $@

$(OUTPUT):
	mkdir -p $@

$(OUTPUT)/%.md: %.form %.options blanks.json | $(CF) $(OUTPUT)
	$(CF) render --format markdown $(shell cat $*.options) --blanks blanks.json < $< > $@

$(OUTPUT)/%.docx: %.form %.options %.json blanks.json | $(CF) $(OUTPUT)
	$(CF) render --format docx $(shell cat $*.options) --edition "$(SPELLED_EDITION)" --signatures $*.json --blanks blanks.json < $< > $@

$(OUTPUT)/%.json: %.form | $(CF) $(OUTPUT)
	$(CF) render --format native < $< > $@

%.form: %.cform
ifeq ($(EDITION),Development Draft)
	cat $< | sed "s!PUBLICATION!a development draft of the Switchmode Developer Agreement!" > $@
else
	cat $< | sed "s!PUBLICATION!the $(SPELLED_EDITION) of the Switchmode Developer Agreement!" > $@
endif

$(OUTPUT)/%.pdf: $(OUTPUT)/%.docx
	soffice --headless --convert-to pdf --outdir "$(OUTPUT)" "$<"

$(OUTPUT)/notice-company-%: notices/company/%.eml
	cp $< $@

$(OUTPUT)/notice-tech-rep-%: notices/company/technical-representative/%.eml
	cp $< $@

$(OUTPUT)/notice-developer-%: notices/developer/%.eml
	cp $< $@

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
