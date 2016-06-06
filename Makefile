TARGET = slide.pdf
OUT_FORMAT = beamer
IN_FORMAT = markdown
HEADER = header.tex
BIBLIO = bibliography.bib
META = metadata.yaml
SOURCES = slide.md

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(META) $(SOURCES) $(HEADER) $(BIBLIO)
	pandoc -H $(HEADER) \
		-f $(IN_FORMAT) \
		-t $(OUT_FORMAT) \
		--bibliography=$(BIBLIO) \
		-s \
		-o $(TARGET) \
		$(META) $(SOURCES)

clean:
	-@rm -f $(TARGET)
