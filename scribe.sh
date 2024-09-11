#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 repo_name prog_name"
    exit 1
fi

# Get the input arguments
repo_name=$1
prog_name=$2

# Define the content with the argument included
header_content="\\\\usepackage{graphics,color,eurosym,latexsym}
\\\\usepackage{algorithm}
\\\\usepackage[noend]{algorithmic}
\\\\usepackage{times}
\\\\usepackage[utf8]{inputenc}
\\\\usepackage[T1]{fontenc}
\\\\usepackage{pst-all}
\\\\usepackage{verbatim}
\\\\usepackage{noweb}
\\\\usepackage{psfrag}
\\\\usepackage{inconsolata}
\\\\usepackage[straightquotes]{newtxtt}
\\\\bibliographystyle{plain}"

intro_content="A placeholder for an introdiction~\\\\cite{aut:txt}."

ref_content="@Article{aut:txt,
  author = 	 {Author, A. and Author, B.},
  title = 	 {Text},
  journal =  {Folio},
  year = 	 3000,
  volume =   1,
  pages  =   {1--100}}"

doc_content="\\\\documentclass[a4paper]{article}
\\\\input{header}
\\\\begin{document}
\\\\pagestyle{noweb}

\\\\title{A new program}
\\\\author{Ivan Tsers}
\\\\date{\\\\input{date.txt}, \\\\input{version.txt}}
\\\\maketitle

\\\\tableofcontents

\\\\section{Introduction}
\\\\input{intro}
\\\\section{A program}
\\\\input{$prog_name}
\\\\section{Testing}
\\\\input{"$prog_name"_test}

\\\\bibliography{ref}
\\\\end{document}"

doc_makefile_content="NAME = $prog_name
date = \$(shell git log | grep -m 1 Date | sed -r 's/Date: +[A-Z][a-z]+ ([A-Z][a-z]+) ([0-9]+) [^ ]+ ([0-9]+) .+/\2_\1_\3/')
version = \$(shell git describe)
all: \$(NAME)Doc.pdf
	echo \$(date) | tr '_' ' ' > date.txt
	echo \$(version) | tr '-' ' ' | awk '{printf \"%s\", \$\$1; if (\$\$2) printf \"-%s\", \$\$2; printf "\n"}' > version.txt
	latex \$(NAME)Doc
	bibtex \$(NAME)Doc
	latex \$(NAME)Doc
	latex \$(NAME)Doc
	dvipdf -dALLOWPSTRANSPARENCY \$(NAME)Doc
\$(NAME)Doc.pdf: \$(NAME)Doc.tex \$(NAME).tex \$(NAME)_test.tex
\$(NAME).tex: ../\$(NAME).org
	bash ../scripts/org2nw ../\$(NAME).org       | awk -f ../scripts/preWeave.awk | noweave -n -x > \$(NAME).tex
\$(NAME)_test.tex: ../\$(NAME)_test.org
	bash ../scripts/org2nw ../\$(NAME)_test.org  | awk -f ../scripts/preWeave.awk | noweave -n -x | sed 's/_test/\\\\\\_test/' > \$(NAME)_test.tex
clean:
	rm -f \$(NAME).tex \$(NAME)_test.tex *.pdf *.aux *.bbl *.blg *.dvi *.log *.toc date.txt version.txt"
	
main_makefile_content="EXE = $prog_name
all: \$(EXE)
\$(EXE): \$(EXE).go
	go build \$(EXE).go
\$(EXE).go: \$(EXE).org
	awk -f scripts/preTangle.awk \$(EXE).org | bash scripts/org2nw | notangle -R\$(EXE).go | gofmt > \$(EXE).go
test: \$(EXE)_test.go \$(EXE)
	go test -v
\$(EXE)_test.go: \$(EXE)_test.org
	awk -f scripts/preTangle.awk \$(EXE)_test.org | bash scripts/org2nw | notangle -R\$(EXE)_test.go | gofmt > \$(EXE)_test.go

.PHONY: doc clean init

doc:
	make -C doc

clean:
	rm -f \$(EXE) *.go
	make clean -C doc
	
init:
	go mod init \$(EXE)
	go mod tidy
"

program_content="#+begin_export latex
The package \\\\texttt{$prog_name} has hooks for imports and functions.
#+end_export
#+begin_src go <<$prog_name.go>>=
  package $prog_name
  import (
	  //<<Imports>>
  )
  //<<Functions>>
#+end_src
#+begin_export latex
The function \\\\texttt{hello} prints \"hello\"...
#+end_export
#+begin_src go <<Functions>>=
  func hello() {
	  fmt.Println(\"Hello\")
  }
#+end_src
#+begin_export latex
We import \\\\texttt{fmt}.
#+end_export
#+begin_src go <<Imports>>=
  \"fmt\"
#+end_src
"

test_content="#+begin_export latex
We import the \\\\texttt{testing} package and add hooks for further
imports and functions.
#+end_export
#+begin_src go <<"$prog_name"_test.go>>=
  package "$prog_name"
  import (
	  \"testing\"
	  //<<Testing imports>>
  )
  //<<Testing functions>>
#+end_src
#+begin_export latex
The first testing function just says \"hello\"...
#+end_export
#+begin_src go <<Testing functions>>=
  func TestHello(t *testing.T) {
	  fmt.Println(\"Hello\")
  }
#+end_src
#+begin_export latex
We import \\\\texttt{fmt}.
#+end_export
#+begin_src go <<Testing imports>>=
  \"fmt\"
#+end_src
"

# Create repo and docs folders
mkdir $repo_name
cd $repo_name
mkdir doc
cd doc

# Populate doc with stubs
echo -e "$header_content" > header.tex
echo -e "$intro_content" > intro.tex
echo -e "$ref_content" > ref.bib
echo -e "$doc_content" > "$prog_name"Doc.tex
echo -e "$doc_makefile_content" > Makefile

# Populate the root folder with stubs
cd ../
echo -e "$main_makefile_content" > Makefile
echo -e "$program_content" > "$prog_name".org
echo -e "$test_content" > "$prog_name"_test.org
# Create and populate the scripts folder
mkdir scripts
cd scripts

content="#!/bin/bash
sed '
s/^#+begin_src *latex/@/
s/^#+begin_export *latex/@/
s/^#+begin_src *[cC] *<</<</
s/^#+begin_src *[sS][hH] *<</<</
s/^#+begin_src *[aA][wW][kK] *<</<</
s/^#+begin_src *[gG][oO] *<</<</
s/^#+begin_src *[hH][tT][mM][lL] *<</<</
s/\\/\\/ *<</<</
/^#+end/d
/^\\*/d
s/^  //
' \$@"
echo -e "$content" > org2nw

content="/^ *!/ {
  sub(/^ *!/, \"\", \$0)
  s = s \" \" \$0
}
/begin_src go/ {
  if(s) {
    gsub(/\\\\\\[^{]+{/, \"\", s)
    gsub(/}/, \"\", s)
    gsub(/\\$/, \"\", s)
    printf \"%s\\\n//%s\\\n\", \$0, s
    s = \"\"
  } else 
    print
}
!/^ *!/ && !/begin_src go/ {
  print
}"
echo -e "$content" > preTangle.awk

content="/^ *!/ {
  l = \$0
  sub(/^ *!/, \"\", l)
  printf \"\\\\\\\\textbf{%s}\\\n\", l
}
!/^ *!/ {
  print
}"
echo -e "$content" > preWeave.awk
