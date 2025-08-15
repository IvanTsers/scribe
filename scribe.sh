#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 prog_name \"Author Name\""
    exit 1
fi

# Get the input arguments
prog_name=$1
author_name=$2

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

\\\\title{A new program \\\\texttt{$prog_name}}
\\\\author{$author_name}
\\\\date{\\\\input{version.txt}}
\\\\maketitle

\\\\tableofcontents

\\\\section{Introduction}
\\\\input{intro}
\\\\section{Implementation}
\\\\input{$prog_name}

\\\\bibliography{ref}
\\\\end{document}"

doc_makefile_content="NAME = $prog_name

# ---------- Helper scripts ----------
ORG2NW   := bash ../scripts/org2nw
PREWEAVE := awk -f ../scripts/preWeave.awk

# Build the version string
TAG = \$(shell git tag)
VERSION = \$(shell git log --pretty=format:\"%cs, \${TAG}-%h\" -n 1)

all: \$(NAME)Doc.pdf
	echo \$(VERSION) > version.txt
	latex \$(NAME)Doc
	bibtex \$(NAME)Doc
	latex \$(NAME)Doc
	latex \$(NAME)Doc
	dvipdf -dALLOWPSTRANSPARENCY \$(NAME)Doc
\$(NAME)Doc.pdf: \$(NAME)Doc.tex \$(NAME).tex
\$(NAME).tex: ../\$(NAME).org
	\$(ORG2NW) ../\$(NAME).org | \$(PREWEAVE) | noweave -n -x > \$(NAME).tex

clean:
	rm -f \$(NAME).tex *.pdf *.aux *.bbl *.blg *.dvi *.log *.toc version.txt"
	
main_makefile_content="NAME = $prog_name
# ---------- Helper scripts ----------
ORG2NW   := bash scripts/org2nw
PRETANGLE := awk -f scripts/preTangle.awk

all: \$(NAME)
\$(NAME): \$(NAME).go
	go build \$(NAME).go
\$(NAME).go: \$(NAME).org
	\$(ORG2NW) \$(NAME).org | \$(PRETANGLE) | notangle -R\$(NAME).go | gofmt > \$(NAME).go

.PHONY: doc clean

doc:
	make -C doc

clean:
	rm -f \$(NAME) *.go
	make clean -C doc
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

# Create repo and docs folders
mkdir $prog_name
cd $prog_name
mkdir doc
cd doc

# Populate doc with stubs
echo -e "$header_content" > header.tex
echo -e "$intro_content" > intro.tex
echo -e "$ref_content" > ref.bib
echo -e "$doc_content" > "$prog_name"Doc.tex
echo -e "$doc_makefile_content" > Makefile

# Populate the root folder with stubs
cd ..
echo -e "$main_makefile_content" > Makefile
echo -e "$program_content" > "$prog_name".org

# Create and populate the scripts folder
mkdir scripts
cd scripts

content="#!/bin/bash
sed '
s/^#+begin_src *latex/@/
s/^#+begin_export *latex/@/
s/^#+begin_src *[cC] *<</<</
s/^#+begin_src *[cC]++ *<</<</
s/^#+begin_src *[sS][hH] *<</<</
s/^#+begin_src *[aA][wW][kK] *<</<</
s/^#+begin_src *[gG][oO] *<</<</
s/^#+begin_src *[hH][tT][mM][lL] *<</<</
s/^#+begin_src *[pP][yY][tT][hH][oO][nN] *<</<</
s/^#+begin_src *[rR] *<</<</

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
!/^ *!/ && !/begin_src (go|c|c++|r|python|sh|html)/ {
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

# Initialize a git repository
cd ..
git init
git add .
git commit -m "initial commit"
git tag -a 0.0 -m "initialized the project"
