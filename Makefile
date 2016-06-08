TARGET = slide.pdf
OUT_FORMAT = beamer
IN_FORMAT = markdown
HEADER = header.tex
META = metadata.yaml
SOURCES = slide.md bibliography.tex

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(META) $(SOURCES) $(HEADER)
	pandoc -H $(HEADER) \
		-f $(IN_FORMAT) \
		-t $(OUT_FORMAT) \
		-s \
		-o $(TARGET) \
		$(META) $(SOURCES)

clean:
	-@rm -f $(TARGET)
