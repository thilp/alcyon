HTML=Axiom.html		\
     Hermes.html	\
     Memory.html

all: doc
	@echo "Documentation of \`Core' generated."

doc: clean $(HTML)
	firefox $(HTML) \
	  || chromium-browser $(HTML) \
	  || google-chrome $(HTML) \
	  || opera $(HTML) &

%.html: %.pm
	pod2html $< > $@

clean:
	find . -name "*.tmp" -delete

distclean: clean
	find . -name "*.html" -delete
