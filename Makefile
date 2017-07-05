CF=node_modules/.bin/commonform
OUTPUT=build

FORMS=$(basename $(wildcard *.cform))
DOCX=$(addprefix $(OUTPUT)/,$(addsuffix .docx,$(FORMS)))
PDF=$(addprefix $(OUTPUT)/,$(addsuffix .pdf,$(FORMS)))
MD=$(addprefix $(OUTPUT)/,$(addsuffix .md,$(FORMS)))
JSON=$(addprefix $(OUTPUT)/,$(addsuffix .json,$(FORMS)))
TARGETS=$(DOCX) $(PDF) $(MD) $(JSON)

all: $(TARGETS)

$(OUTPUT):
	mkdir -p $@

$(OUTPUT)/%.md: %.cform %.options blanks.json | $(CF) $(OUTPUT)
	$(CF) render --format markdown $(shell cat $*.options) --blanks blanks.json < $< > $@

$(OUTPUT)/%.docx: %.cform %.options %.json blanks.json | $(CF) $(OUTPUT)
	$(CF) render --format docx $(shell cat $*.options) --signatures $*.json --blanks blanks.json < $< > $@

$(OUTPUT)/%.json: %.cform | $(CF) $(OUTPUT)
	$(CF) render --format native < $< > $@

%.pdf: %.docx
	doc2pdf $<

$(CF):
	npm install

.PHONY: clean docker

clean:
	rm -rf $(OUTPUT)

docker:
	docker build -t switchmode .
	docker run --name switchmode switchmode
	docker cp switchmode:/workdir/$(OUTPUT) .
	docker rm switchmode
