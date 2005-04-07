# $Id: 20dispconf.sh,v 1.1.1.1 2005/04/07 12:31:27 aida_s Exp $
: ${xinitrc_dispconf_xrdb_enable=YES}
: ${xinitrc_dispconf_sysresources="$xinitrc_xconfdir/xinit/.Xresources"}
: ${xinitrc_dispconf_userresources="$HOME/.Xresources"}
: ${xinitrc_dispconf_xmodmap_enable=YES}
: ${xinitrc_dispconf_sysmodmap="$xinitrc_xconfdir/xinit/.Xmodmap"}
: ${xinitrc_dispconf_usermodmap="$HOME/.Xmodmap"}

case "x$xinitrc_dispconf_xrdb_enable" in
    x[Yy][Ee][Ss])
    if test -f "$xinitrc_dispconf_sysresources"; then
	xrdb -merge "$xinitrc_dispconf_sysresources"
    fi
    if test -f "$xinitrc_dispconf_userresources"; then
	xrdb -merge "$xinitrc_dispconf_userresources"
    fi
    ;;
esac

case "x$xinitrc_dispconf_xmodmap_enable" in
    x[Yy][Ee][Ss])
    if test -f "$xinitrc_dispconf_sysmodmap"; then
	xmodmap "$xinitrc_dispconf_sysmodmap"
    fi
    if test -f "$xinitrc_dispconf_usermodmap"; then
	xmodmap "$xinitrc_dispconf_usermodmap"
    fi
    ;;
esac
