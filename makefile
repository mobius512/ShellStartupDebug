# $Id$
PATH_TO_LUA	:= /vol/local/bin
VERSION_SRC	:= src/Version.lua
VERSION_LIB	:= $(subst .lua,,$(VERSION_SRC))
prefix		:= /usr/local
package		:= shell_startup
version		:= $(shell lua -l $(VERSION_LIB) -e "print(Version.name())" | awk '{print $$1}')
PKG		:= $(prefix)/$(package)/$(package)
LIBEXEC		:= $(prefix)/$(package)/$(version)/libexec
INIT		:= $(prefix)/$(package)/$(version)/init

DIRLIST		:= $(LIBEXEC) $(INIT)

SHELL_INIT	:= bash.in csh.in ksh.in tcsh.in zsh.in sh.in
SHELL_INIT	:= $(patsubst %, setup/%, $(SHELL_INIT))

MAIN_DIR	:= Makefile.in configure

lua_code	:= $(wildcard src/*.lua) src/COPYRIGHT 
VDATE		:= $(shell date +'%F %H:%M')

REQUIRED_PKGS	:= BeautifulTbl ColumnTable hash Optiks Optiks_Option strict \
                 fileOps string_split serialize pairsByKeys string_trim

LIBEXEC_CMDS    := $(patsubst %, src/%, DBG_INDENT_cmd.in ECHO_cmd.in)
INIT_FILES      := $(patsubst %, src/%, shell_startup.in)


.PHONY: test

all:
	@echo done

install: $(DIRLIST) startup libexec libexec_cmds rc_files
	$(RM) $(PKG)
	ln -s $(version) $(PKG)

echo:
	@echo Version: $(version)
echo_version:
	@echo $(version)


$(DIRLIST) :
	mkdir -p $@


__install_me: $(INSTALL_LIST)
	for i in $^; do                                           \
	  fn=`basename $$i .in`;                                  \
	  fn="$$fn$(EXT)";                                        \
          sed -e 's|@PREFIX@|/usr/local|g'                          \
	      -e 's|@path_to_lua@|$(PATH_TO_LUA)|g'               \
              -e 's|@PKG@|$(PKG)|g'         < $$i > $$fn;         \
          chmod +x $$fn;                                          \
          mv $$fn      $(DESTDIR)$(INSTALL_DIR);                  \
        done

startup: $(SHELL_INIT)
	$(MAKE) INSTALL_LIST="$^" INSTALL_DIR=$(INIT) __install_me


libexec_cmds: $(LIBEXEC_CMDS)
	$(MAKE) INSTALL_LIST="$^" INSTALL_DIR=$(LIBEXEC) __install_me

rc_files: $(INIT_FILES)
	$(MAKE) INSTALL_LIST="$^" INSTALL_DIR=$(LIBEXEC) EXT=".rc" __install_me

libexec:  $(lua_code)
	cp $^ $(LIBEXEC)

makefile: Makefile.in config.status
	./config.status

config.status:
	./configure

dist:  
	$(MAKE) DistD=DIST _dist

_dist: _distMkDir _distMainDir _distSrc _distSetup _distReqPkg _distTar

_distMkDir:
	$(RM) -r $(DistD)
	mkdir $(DistD)

_distSrc:
	mkdir $(DistD)/src
	cp $(lua_code) $(LIBEXEC_CMDS) $(INIT_FILES) $(DistD)/src

_distSetup:
	mkdir $(DistD)/setup
	cp $(SHELL_INIT) $(DistD)/setup

_distMainDir:
	cp $(MAIN_DIR) $(DistD)

_distReqPkg:
	cp `findLuaPkgs $(REQUIRED_PKGS)` $(DistD)/src

_distMF:
	mkdir $(DistD)/mf
	cp -r mf $(DistD)/mf
	find $(DistD)/mf -name .svn | xargs rm -rf 

_distTar:
	echo "shell_startup"-$(version) > .fname;                	   \
	$(RM) -r `cat .fname` `cat .fname`.tar*;         		   \
	mv ${DistD} `cat .fname`;                            		   \
	tar chf `cat .fname`.tar `cat .fname`;           		   \
	gzip `cat .fname`.tar;                           		   \
	rm -rf `cat .fname` .fname; 


test:
	cd rt; unset TMFuncPATH; tm .

tags:
	find . \( -regex '.*~$$\|.*/\.svn$$\|.*/\.svn/' -prune \)  \
               -o -type f > file_list.1
	sed -e 's|.*/.svn.*||g'                                    \
            -e 's|.*/rt/.*/t1/.*||g'                               \
            -e 's|./TAGS||g'                                       \
            -e 's|./configure$$||g'                                \
            -e 's|./config.log$$||g'                               \
            -e 's|./testreports/.*||g'                             \
            -e 's|./config.status$$||g'                            \
            -e 's|.*\~$$||g'                                       \
            -e 's|./file_list.*||g'                                \
            -e '/^\s*$$/d'                                         \
	       < file_list.1 > file_list.2
	etags `cat file_list.2`
	$(RM) file_list.*



clean:
	$(RM) config.log

clobber: clean

distclean: clobber
	$(RM) makefile config.status

svntag:
        ifneq ($(TAG),)
	  $(RM)                                           	   $(VERSION_SRC);   \
	  echo "module('Version')"                              >  $(VERSION_SRC);   \
	  echo 'function name() return "'$(TAG) $(VDATE)'" end' >> $(VERSION_SRC);   \
	  svn ci -m'moving to TAG_VERSION $(TAG)'         	   $(VERSION_SRC);   \
          SVN=`svn info | grep "Repository Root" | sed -e 's/Repository Root: //'`;  \
	  svn cp -m'moving to TAG_VERSION $(TAG)' $$SVN/trunk $$SVN/tags/$(TAG)
        else
	  @echo "To svn tag do: make svntag TAG=?"
        endif
