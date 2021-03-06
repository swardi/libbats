#!/bin/sh

LNAME=libbats

echo "Generating CMakeFiles.txt"

SOURCES=`find . -name '*.cc' | grep -v examples | grep -v GtkDebugger`
HEADERS=`find . -name '*.hh' | grep -v examples | grep -v configure.hh`
IHEADERS=`find . -name '*.ih' | tr '\n' ' '`
XML=`ls xml/*.xml |  tr '\n' ' '`

#CMakeLists.txt
cat > CMakeLists.txt <<EOF
#
## This file is generated by bootstrap.sh. Edit that file, not this
#

cmake_minimum_required (VERSION 2.6)
project ($LNAME)

set(CMAKE_MODULE_PATH \${CMAKE_SOURCE_DIR}/cmake/)
set(BUILD_SHARED_LIBS ON CACHE BOOL "Choose whether to build a shared library")

INCLUDE(FindPkgConfig)

find_package(Eigen3 REQUIRED)
find_package(LibXml2 REQUIRED)
find_package(SigC++ REQUIRED)
PKG_CHECK_MODULES(GTKMM gtkmm-2.4)
find_package(Doxygen)
find_package(LATEX)

set(CMAKE_CXX_FLAGS "-std=c++0x -Wno-deprecated-register")

#
## libbats
#

set(LIBBATS_SOURCES
${SOURCES}
)

set(LIBBATS_INCLUDE_DIRS \${EIGEN3_INCLUDE_DIR} \${LIBXML2_INCLUDE_DIR} \${SigC++_INCLUDE_DIRS} \${LIBXMLXX_INCLUDE_DIRS})

# Only build GTK debugger if GTKmm was found
if(GTKMM_FOUND)
  list(APPEND LIBBATS_SOURCES
       ./Debugger/GtkDebugger/onDebugText.cc
       ./Debugger/GtkDebugger/run.cc
       ./Debugger/GtkDebugger/onThinkEnd.cc
       ./Debugger/GtkDebugger/drawShapes.cc
       ./Debugger/GtkDebugger/GtkDebugger.cc
       ./Debugger/GtkDebugger/drawBall.cc
       ./Debugger/GtkDebugger/drawCurve.cc
       ./Debugger/GtkDebugger/plot.cc
       ./Debugger/GtkDebugger/drawPlayers.cc
       ./Debugger/GtkDebugger/start.cc
       ./Debugger/GtkDebugger/drawSelf.cc
       ./Debugger/GtkDebugger/init.cc
       ./Debugger/GtkDebugger/drawField.cc
       ./Debugger/GtkDebugger/reDraw.cc
       ./Debugger/GtkDebugger/onDrawingAreaExpose.cc
  )

  list(APPEND LIBBATS_INCLUDE_DIRS \${GTKMM_INCLUDE_DIRS})
else(GTKMM_FOUND)
  message(STATUS "  GtkDebugger will not be built")
endif(GTKMM_FOUND)

include_directories(\${LIBBATS_INCLUDE_DIRS} \${CMAKE_BINARY_DIR})

configure_file (
  "\${CMAKE_SOURCE_DIR}/configure.hh.in"
  "\${CMAKE_BINARY_DIR}/configure.hh"
)

configure_file(xml/conf.xml xml/conf.xml COPYONLY)
configure_file(xml/conf.dtd xml/conf.dtd COPYONLY)
configure_file(xml/nao_mdl.xml xml/nao_mdl.xml COPYONLY)

add_library(bats
\${LIBBATS_SOURCES}
)

#
## HTML documentation with doxygen
#
if(DOXYGEN_FOUND)
  configure_file(\${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile.in \${CMAKE_CURRENT_BINARY_DIR}/Doxyfile @ONLY)
  add_custom_target(doc ALL
                    \${DOXYGEN_EXECUTABLE} \${CMAKE_CURRENT_BINARY_DIR}/Doxyfile
                    WORKING_DIRECTORY \${CMAKE_CURRENT_BINARY_DIR}
                    COMMENT "Generating API documentation with Doxygen" VERBATIM
  )
endif(DOXYGEN_FOUND)

#
## PDF manual
#
if (PDFLATEX_COMPILER)
  SET(PDFLATEX_COMMAND  \${PDFLATEX_COMPILER} -interaction=batchmode -halt-on-error -output-directory \${CMAKE_CURRENT_BINARY_DIR}/docs/manual libbatsmanual.tex)
  add_custom_target(manual ALL
                    mkdir -p \${CMAKE_CURRENT_BINARY_DIR}/docs/manual && \${PDFLATEX_COMMAND} && \${PDFLATEX_COMMAND}
                    WORKING_DIRECTORY \${CMAKE_CURRENT_SOURCE_DIR}/docs/manual
                    COMMENT "Generating manual with pdfLaTeX"
  )
endif(PDFLATEX_COMPILER)

install(TARGETS bats DESTINATION lib)

# Macro used to install headers under correct directory structure
macro(INSTALL_HEADERS_WITH_DIRECTORY DESTINATION HEADER_LIST)
  foreach(HEADER \${\${HEADER_LIST}})
    get_filename_component(FILE \${HEADER} NAME) 
    string(REPLACE \${FILE} "" DIR \${HEADER})
    install(FILES \${HEADER} DESTINATION \${DESTINATION}/\${DIR})
  endforeach(HEADER)
endmacro(INSTALL_HEADERS_WITH_DIRECTORY)

set(LIBBATS_HEADERS ${HEADERS})

install_headers_with_directory(include/libbats "LIBBATS_HEADERS")

install(FILES ${XML} DESTINATION share/libbats/xml/)

add_subdirectory(examples)

EOF

echo "Generating examples/CMakeLists.txt"
cat > examples/CMakeLists.txt <<EOF
#
## This file is generated by bootstrap.sh. Edit that file, not this
#

add_subdirectory(helloworld)
add_subdirectory(dribble)

EOF

echo "Generating examples/helloworld/CMakeLists.txt"
cat > examples/helloworld/CMakeLists.txt <<EOF
#
## This file is generated by bootstrap.sh. Edit that file, not this
#

include_directories(\${CMAKE_SOURCE_DIR})

set(HELLOWORLD_SOURCES
helloworld.cc
HelloWorldAgent/init.cc
HelloWorldAgent/think.cc
)

add_executable(helloworld
\${HELLOWORLD_SOURCES}
)

target_link_libraries(helloworld bats \${LIBXML2_LIBRARIES} \${SigC++_LIBRARIES})

if (GTKMM_FOUND)
  target_link_libraries(helloworld \${GTKMM_LIBRARIES})
endif (GTKMM_FOUND)
EOF

echo "Generating examples/dribble/CMakeLists.txt"
cat > examples/dribble/CMakeLists.txt <<EOF
#
## This file is generated by bootstrap.sh. Edit that file, not this
#

include_directories(\${CMAKE_SOURCE_DIR})

set(DRIBBLE_SOURCES
dribble.cc
DribbleAgent/DribbleAgent.cc
DribbleAgent/init.cc
DribbleAgent/think.cc
DribbleAgent/determineWhereToLook.cc
DribbleAgent/determineWhereToWalk.cc
DribbleAgent/stand.cc
)

add_executable(dribble
\${DRIBBLE_SOURCES}
)


target_link_libraries(dribble bats \${LIBXML2_LIBRARIES} \${SigC++_LIBRARIES})

if (GTKMM_FOUND)
  target_link_libraries(dribble \${GTKMM_LIBRARIES})
endif (GTKMM_FOUND)

configure_file(conf.xml conf.xml COPYONLY)
configure_file(nao_mdl.xml nao_mdl.xml COPYONLY)
configure_file(conf.dtd conf.dtd COPYONLY)

EOF
