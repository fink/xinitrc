#! /bin/sh
# vim: set sw=4:
set -e

myfullname="$0"
old_LANG="$LANG"
old_LC_ALL="$LC_ALL"
LANG=C
LC_ALL=C

showhelp() {
    cat << EOF
Syntax:
    $myname [option]... [var=value]... mode [mode-specific options]

Modes:
    build
    install
    clean
    distclean
    fink [-r,--release]

Options:
    -n, --dry-run   display commands without modifying any files
    -q, --quiet	    don't print informational messages
    -d, --debug	    debug $myname
    -h, --help	    show this message

Variables:
    prefix[=/opt/sw]
    destdir[empty]
    srcdir[auto($mydir)]

Examples:
    $myname -q destdir=/opt/sw/src/foobar install
    $myname clean
EOF
    return 0
}

badarg() {
    test "x$1" != x && extra=" $1"
    echo "Bad argument$extra; try $myname -h for more information." >&2
    return 2
}

# Following constructs do not work:
#   go some-command > somewhere
#   go some-command | another-command
#   go some-command && another-command
# Instead use go_r or go_p:
#   go_r somewhere some-command
#   go_p 'another-command' some-command
# Or do manually:
#   $show some-command \&\& another-command
#   $run some-command && $run another-command
go() {
    $show "$@"
    $run "$@"
}

go_r() {
    dst="$1"
    shift
    $show "$@" \> "$dst"
    case "x$run" in
	x:) ;;
	*) $run "$@" > "$dst" ;;
    esac
}

go_p() {
    dst="$1"
    shift
    eval '$show "$@" \| '"$dst"
    $run "$@" | $run eval "$dst"
}

dobuild() {
    go $mkinstalldirscmd "$builddir"
    $show "creating build.sed"
    if [[ -d /opt/X11/etc/X11/xinit ]]; then
        xinitdir="/opt/X11/etc/X11/xinit";
    elif [[ -d /opt/X11/lib/X11/xinit ]]; then
        xinitdir="/opt/X11/lib/X11/xinit";
    else
    	echo "xinit dir for X11 not found. Exiting."
    	exit 1;
    fi
    case "x$run" in
	x:) ;;
	*)
    $run cat > "$builddir/build.sed" << EOF
s|@PREFIX@|$prefix|g
s|@XINITDIR@|$xinitdir|g
s|@X_BINDIR@|/opt/X11/bin|g
EOF
	;;
    esac
    for src in "$srcdir"/sedsrc/*.in; do
	base=`basename "$src" .in`
	go_r "$builddir/$base" /usr/bin/sed -f "$builddir/build.sed" "$src"
    done
}

doinstall() {
    go $mkinstalldirscmd -m 755 "$destdir$bindir"
    go $mkinstalldirscmd -m 755 "$destdir$sbindir"
    go $mkinstalldirscmd -m 755 "$destdir$mydatadir"
    go $mkinstalldirscmd -m 755 "$destdir$mydocdir"
    go $mkinstalldirscmd -m 755 "$destdir$sysconfdir/xinitrc.d"

    $show cd "$builddir"
    cd "$builddir"
    go $installcmd -m 755 xinitrc.sh "$destdir$bindir"
    go $installcmd -m 755 update-sys-xinitrc "$destdir$sbindir"
    go $installcmd -m 644 sys-xinitrc-fink "$destdir$mydatadir"

    $show cd "$firstpwd"
    cd "$firstpwd"
    $show cd "$srcdir/doc"
    cd "$srcdir/doc"
    go $installcmd -m 644 README.txt numbering.txt "$destdir$mydocdir"

    $show cd "../simple"
    cd "../simple"
    go $installcmd -m 755 [0-9][0-9]*.sh "$destdir$sysconfdir/xinitrc.d"
}

doclean() {
    go rm -rf "$builddir" "$pkgname.info" "$pkgname.patch" "$pkgname-"*".tar.gz"
}

dodistclean() {
    doclean
    go_p 'xargs rm -f' find . -name "semantic.cache" -or -name "*~" -or -name "*.bak" -or -name ".*.swp"
}

dofink() {
    version=`cat $srcdir/version`
    case "x$1" in
	x-r|x--release)
	gitver=
	fullver="$version"
	sedargs="-e s/@TARDIST@//g -e s/@PATCHDIST@/#/g"
	;;
	x)
	gitcommit=`/usr/bin/git rev-parse HEAD 2>/dev/null | cut -b 1-8`
	gitver="+git-$gitcommit"
	fullver="$version$gitver"
	sedargs="-e s/@TARDIST@/#/g -e s/@PATCHDIST@//g"
	;;
	*) badarg "$1"; exit ;;
    esac

    files=".gitignore ChangeLog build.sh doc/ $pkgname.info.in sedsrc/ simple/ version"
    sedargs="$sedargs -e s/@FULLVERSION@/$fullver/g"

    workdir="$pkgname-$fullver"
    go rm -rf "$workdir" "$workdir.dummy"
    trap 'go rm -rf "$workdir" "$workdir.dummy"' 0
    go mkdir "$workdir" "$workdir.dummy"
    $show \( cd "$srcdir" \&\& tar cf - $files \) \| \( cd "$workdir" \&\& tar xf - \)
    ( cd "$srcdir" && $run tar cf - $files ) | ( $run cd "$workdir" && $run tar xf - )
    go_p 'xargs rm -r' find "$workdir" -name .git -type d

    case "x$gitcommit" in
	x)
	go tar zcf "$pkgname-$fullver.tar.gz" "$workdir"
	sha256=`$run /usr/bin/shasum -a 256 "$pkgname-$fullver.tar.gz" | cut -f1 -d' '`
	sedargs="$sedargs -e s/@SHA256@/$sha256/g"
	;;
	*)
	set +e
	go_r "$pkgname.patch" diff -Nru "$workdir.dummy" "$workdir"
	set -e
	;;
    esac

    go_r "$pkgname.info" /usr/bin/sed $sedargs "$srcdir/$pkgname.info.in"
}

myname=`basename "$0"`
case "x$myfullname" in
    x*/*) mydir=`echo "$myfullname" | /usr/bin/sed 's|/[^/]*$||'` ;;
    *) mydir=. ;;
esac
pkgname="xinitrc"

destdir=
srcdir="$mydir"
builddir="build"
firstpwd=`pwd`

mkinstalldirscmd="mkdir -p"
installcmd="install"
echocmd="echo"
# more portable way
#echo="printf '%s\n'"

run=
show="$echocmd"

mode=
while test "$#" -gt 0; do
    case "x$1" in
	x-n|x--dry-run) run=: ;;
	x-q|x--quiet) show=: ;;
	x-d|x--debug) set -x ;;
	x-h|x--help) showhelp; exit ;;
	x-*) badarg "$1"; exit ;;
	x*=*) eval "$1" ;;
	x*) mode="$1"; shift; break ;;
    esac
    shift
done

: ${prefix="/opt/sw"}
: ${exec_prefix="${prefix}"}
: ${bindir="${exec_prefix}/bin"}
: ${sbindir="${exec_prefix}/sbin"}
: ${libexecdir="${exec_prefix}/lib"}
: ${datadir="${prefix}/share"}
: ${sysconfdir="${prefix}/etc"}
: ${sharedstatedir="${prefix}/var"}
: ${localstatedir="${prefix}/var"}
: ${libdir="${exec_prefix}/lib"}
: ${includedir="${prefix}/include"}
: ${oldincludedir="/usr/include"}
: ${infodir="${prefix}/share/info"}
: ${mandir="${prefix}/share/man"}
: ${docdir="${prefix}/share/doc"}
: ${mydatadir="${datadir}/$pkgname"}
: ${mydocdir="${docdir}/$pkgname"}

case "x$mode" in
    x|xhelp) showhelp; exit ;;
    xbuild) dobuild "$@" ;;
    xinstall) doinstall "$@" ;;
    xclean) doclean "$@" ;;
    xdistclean) dodistclean "$@" ;;
    xfink) dofink "$@" ;;
    *) badarg "$mode"; exit ;;
esac

