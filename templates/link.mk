include debian/confflags

datadir = $(CURDIR)/debian/$(NAME)-data/usr/share/games/$(NAME)/
libdir = $(CURDIR)/debian/$(NAME)/usr/lib/$(NAME)/

all:
	$(foreach FILE,$(shell ls $(datadir)$(NAME)_Data),\
		ln -s /usr/share/games/$(NAME)/$(NAME)_Data/$(FILE) $(libdir)$(NAME)_Data/$(FILE) ;)
