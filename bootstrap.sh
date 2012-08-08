#!/bin/sh

if [ "x$1" = "xclean" ]; then
	echo Cleaning
	echo DONDOODODNODNODNODNODNO
	make distclean
  rm -f confi
  rm -rf autom4te.cache config.aux m4
	exit
fi


LNAME=libbats

echo "Generating CMakeFiles.txt"

SOURCES=`find . -name '*.cc' | grep -v examples | tr '\n' ' '`
HEADERS=`find . -name '*.hh' | grep -v examples | tr '\n' ' '`
IHEADERS=`find . -name '*.ih' | tr '\n' ' '`
XML=`ls xml/*.xml |  tr '\n' ' '`


#CMakeLists.txt
cat > CMakeLists.txt <<EOF
cmake_minimum_required (VERSION 2.6)
project ($LNAME)

set(CMAKE_MODULE_PATH \${CMAKE_SOURCE_DIR}/cmake/)

INCLUDE(FindPkgConfig)

find_package(Eigen2 REQUIRED)
find_package(LibXml2 REQUIRED)
find_package(SigC++ REQUIRED)
PKG_CHECK_MODULES(GTKMM gtkmm-2.4)
#find_package(GTKmm REQUIRED)

set(LIBBATS_SOURCES ${SOURCES})

include_directories(\${EIGEN2_INCLUDE_DIR} \${LIBXML2_INCLUDE_DIR} \${SigC++_INCLUDE_DIRS} \${GTKMM_INCLUDE_DIRS})

add_library(batsStatic STATIC
\${LIBBATS_SOURCES}
)

add_library(batsDynamic SHARED
\${LIBBATS_SOURCES}
)

set_target_properties(batsStatic PROPERTIES OUTPUT_NAME bats)
set_target_properties(batsDynamic PROPERTIES OUTPUT_NAME bats)

set(CMAKE_CXX_FLAGS "-std=c++0x")

install(TARGETS batsStatic DESTINATION lib)

EOF

exit

#Main Makefile.am
cat > Makefile.am <<EOF
#THIS FILE IS AUTOMATICALLY GENERATED BY bootstrap.sh
# DO NOT EDIT THIS, BUT EDIT THAT
PACKAGE = @PACKAGE@
VERSION = @VERSION@

AUTOMAKE_OPTIONS = subdir-objects

lib_LTLIBRARIES = ${LNAME}.la
nobase_pkginclude_HEADERS = ${HEADERS}
dist_pkgdata_DATA = ${XML}
dist_bin_SCRIPTS = util/createbehavior.pl

#List of source files needed to build the library:
${LNAME}_la_SOURCES = ${SOURCES}

AM_CPPFLAGS = -Wall -O2 -DDATADIR="\$(pkgdatadir)" \$(DEPS_CFLAGS) -I/usr/include/eigen2

doc:
	doxygen
.PHONY: doc
if COND_DOXYGEN
all-local: doc
endif

SUBDIRS = docs . examples

EXTRA_DIST = AUTHORS COPYING INSTALL NEWS README TODO Doxyfile ${IHEADERS}

EOF

# docs Makefile.am
cat > docs/Makefile.am <<EOF
EXTRA_DIST = header.html footer.html doxygen.css mainpage.txt
SUBDIRS = manual
EOF

# manual Makefile.am
cat > docs/manual/Makefile.am <<EOF
#THIS FILE IS AUTOMATICALLY GENERATED BY bootstrap.sh
# DO NOT EDIT THIS, BUT EDIT THAT
if COND_PDFLATEX
%.toc: %.tex
	touch \$@
	pdflatex \$<

%.pdf: %.tex %.toc 
	pdflatex \$<

all-local:
	\$(MAKE) \$(AM_MAKEFLAGS) libbatsmanual.pdf
	
EXTRA_DIST = libbatsmanual.pdf
CLEANFILES = manual.log manual.pdf manual.aux manual.toc manual.bib manual.dvi manual.out
endif
EOF

# examples Makefile.am
cat > examples/Makefile.am <<EOF
SUBDIRS = helloworld
EOF

# helloworld Makefile.am
cat > examples/helloworld/Makefile.am <<EOF
AM_CPPFLAGS = -DBATS_NO_DEBUG -DDATADIR="\$(pkgdatadir)" -I../.. \$(DEPS_CFLAGS) -I/usr/include/eigen2
AM_LDFLAGS = ../../libbats.la \$(DEPS_LIBS)

noinst_PROGRAMS = helloworld
noinst_HEADERS = HelloWorldAgent/helloworldagent.hh HelloWorldAgent/helloworldagent.ih
helloworld_SOURCES = HelloWorldAgent/init.cc HelloWorldAgent/think.cc helloworld.cc
EOF

rm -f config.cache acconfig.h

echo "- libtoolize."    && \
((which libtoolize && libtoolize) || (which glibtoolize && glibtoolize)) && \
echo "- aclocal."		&& \
aclocal	&& \
echo "- autoconf."		&& \
autoconf			&& \
echo "- automake."		&& \
automake --add-missing --copy
