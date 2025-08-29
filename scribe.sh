#!/bin/bash
# We exit if any command returns an error
set -e

# ---------- Argument check and usage ----------

# We print the usage if an incorrect number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 progName \"Author Name\" language(go|sh|R|py(thon)|C)"
    echo " Note: Do not use underscores in progName to avoid LaTeX compilation errors."
    exit 1
fi

# Get the input arguments
prog_name=$1
author_name=$2
lang=$3

# If the language uses header files, we have to tangle the header file.
# By default, we assume that this is not required.
tangle_header_file=""

# Should we require header tangling, we do it like this:
th="\$(ORG2NW) \$(NAME).org | \$(PRETANGLE) | notangle -R\$(NAME).h > \$(NAME).h"

# If the language is unsupported, we notify the user and exit.
case "$lang" in
    go|sh|R|py)
        # language recognized and no further actions are required
        ;;
    r)
	# We replace the lowercase "r" with "R" for consistency
	lang="R"
	;;
    python)
	# We replace "python" with "py" to have conventional file extensions
	lang="py"
	;;
    c)
	# C is a language that uses header files. We re-define $tangle_header_file
	tangle_header_file=$th
	;;
    C)
	# We replace the uppercase "C" with "c" for consistency
	lang="c"
	# C is a language that uses header files. We re-define $tangle_header_file
	tangle_header_file=$th
	;;
    *) # default:
	echo "Error: unsupported language '$lang'"
	echo "Supported languages: go, sh, R, py(thon), C"
	exit 1
	;;
esac

# We create the repo's dir
mkdir $prog_name

# ---------- The literate program ----------

# We read the literate program template...
program_content=$(<"templates/$lang/lit_prog.org")

# ...and put the value of $prog_name in the template
program_content="${program_content//\$prog_name/$prog_name}"

# We write the program template
echo "$program_content" > $prog_name/"$prog_name".org


# ---------- Base Makefile ----------

# We read the base makefile template and the language-specific module...
base_makefile=$(<"templates/base.Makefile")
lang_actions=$(<"templates/$lang/lang_actions.Makefile")

# ...we glue it together and put $prog_name, $lang, and $tangle_header_file in the text 
main_makefile_content=$(printf "%s\n\n%s\n" "$base_makefile" "$lang_actions")
main_makefile_content="${main_makefile_content//\$prog_name/$prog_name}"
main_makefile_content="${main_makefile_content//\$lang/$lang}"
main_makefile_content="${main_makefile_content//\$tangle_header_file/$tangle_header_file}"

# We write the base makefile
echo "$main_makefile_content" > $prog_name/Makefile


# ---------- Files to compile the documentation ----------

mkdir $prog_name/doc

# We copy header.tex, intro.tex, and ref.bib templates as is
cp templates/header.tex $prog_name/doc
cp templates/intro.tex $prog_name/doc
cp templates/ref.bib $prog_name/doc

# We read the doc template...
doc_content=$(<"templates/doc.tex")

# ...and put the value of $prog_name and $author_name in the template
doc_content="${doc_content//\$prog_name/$prog_name}"
doc_content="${doc_content//\$author_name/$author_name}"

# We write it to the doc dir
echo "$doc_content" > $prog_name/doc/"$prog_name"Doc.tex

# We read the doc makefile template...
doc_makefile_content=$(<"templates/doc.Makefile")

# ...and put the value of $prog_name in the template
doc_makefile_content="${doc_makefile_content//\$prog_name/$prog_name}"

# We write it to the doc dir
echo "$doc_makefile_content" > $prog_name/doc/Makefile


# ---------- The helper scripts ----------

# We copy the helper scripts as is
cp -r templates/scripts $prog_name


# ---------- Initialize a git repository ----------

cd $prog_name
git init
git add .
git commit -m "initial commit"
git tag -a 0.0 -m "initialized the project"
