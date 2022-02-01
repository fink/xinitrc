The xinitrc package is a mechanism to run programs when X11 is launched.
The design follows:

* /opt/sw/bin/xinitrc.sh is the core component. It prepairs some variables
and sources /etc/xinitrc.d/*.

* /opt/sw/sbin/update-xinitrc replaces the system-wide xinitrc.

* First the system-wide xinitrc tests if /opt/sw/etc/xinitrc-override
exists. If it exists then it is sourced from the system-wide
xinitrc. Otherwise /opt/sw/bin/xinitrc.sh is sourced. If xinitrc.sh is
also missing then the system-wide xinitrc mimics the traditional
xinitrc.

* The "xinitrc" package has many customization knobs. For instance,
/opt/sw/etc/xinitrc-first-hook and /opt/sw/etc/xinitrc-last-hook are
sourced from /opt/sw/bin/xinitrc.sh to allow administrators to run some
programs or set environment variables.

Sample xinitrc.d script "50kinput2.sh" follows:
: ${xinitrc_kinput2_enable=YES}
case "x$xinitrc_kinput2_enable" in
    x[Yy][Ee][Ss])
    if test -x /opt/sw/bin/kinput2; then
	/opt/sw/bin/kinput2 -canna -xim &
    fi
    ;;
esac


LEGAL:

You can use or modify or redistribute or do anything to this program
as if it were in public domain, although Japan's laws do not admit
to disclaim one's copyright.

Author: AIDA Shinra <shinra@j10n.org>
