# Laboratorio 10.1 - Paquetes con APT en Debian

## Objetivo

- Ver de qué repositorios descarga Debian el software.
- Actualizar la lista de paquetes y ver qué hay para actualizar.
- Informarse sobre un paquete antes de instalarlo.
- Instalar un paquete leyendo el resumen antes de confirmar.
- Consultar qué instaló un paquete y de qué paquete viene un archivo.
- Quitarlo con `remove` y con `purge`, y ver la diferencia.

### Punto de partida

Usamos la VM Debian 13 del curso y la cuenta administradora con `sudo`, por ejemplo `cristian`. **Alcanza con tener la VM instalada y el acceso por SSH del [Laboratorio 3](../lab3/lab3.md).** La VM necesita salida a Internet.

El paquete de práctica es `mc` (Midnight Commander), un administrador de archivos para la terminal. Al final lo quitamos, así que la VM queda como estaba.

> [!NOTE]
> Reemplazá `cristian` por tu usuario habitual. Los comandos de SSH usan el reenvío del curso, puerto 2222 del anfitrión hacia SSH de la VM. Las versiones y la cantidad de paquetes para actualizar pueden ser otras en tu VM.

## 0. Preparación

Desde la máquina anfitriona:

```bash
ssh -p 2222 cristian@localhost
```

Comprobá que estás en la VM:

```bash
hostname
```

Tiene que aparecer `lab2-vm` (o el nombre que le hayas dado).

## 1. De dónde vienen los paquetes

Mirá los repositorios configurados, sin los comentarios ni las líneas vacías:

```bash
grep -v '^#' /etc/apt/sources.list | grep -v '^$'
```

Ejemplo de salida:

```text
deb http://deb.debian.org/debian/ trixie main non-free-firmware
deb-src http://deb.debian.org/debian/ trixie main non-free-firmware
deb http://security.debian.org/debian-security trixie-security main non-free-firmware
deb-src http://security.debian.org/debian-security trixie-security main non-free-firmware
deb http://deb.debian.org/debian/ trixie-updates main non-free-firmware
deb-src http://deb.debian.org/debian/ trixie-updates main non-free-firmware
```

Cada línea dice el tipo (`deb` para instalar, `deb-src` para código fuente), el servidor, la versión de Debian (`trixie` es Debian 13) y los componentes. La línea de `trixie-security` es la de las correcciones de seguridad.

> [!TIP]
> Si tu instalación usa el formato nuevo, no vas a ver líneas en `sources.list` y los repositorios van a estar en `/etc/apt/sources.list.d/debian.sources`. Lo leés con `cat /etc/apt/sources.list.d/debian.sources`.

## 2. Actualizar la lista de paquetes

```bash
sudo apt update
```

Ejemplo de salida:

```text
Obj:1 http://security.debian.org/debian-security trixie-security InRelease
Obj:2 http://deb.debian.org/debian trixie InRelease
Obj:3 http://deb.debian.org/debian trixie-updates InRelease
Leyendo lista de paquetes...
Creando árbol de dependencias...
Leyendo la información de estado...
Se pueden actualizar 39 paquetes. Ejecute «apt list --upgradable» para verlos.
```

`apt update` baja la lista de paquetes de cada repositorio. No instala ni actualiza ningún programa. `Obj` indica que esa lista no cambió desde la última vez; `Des` (descargado), que bajó una nueva.

Mirá las primeras líneas de lo que hay para actualizar:

```bash
apt list --upgradable | head -4
```

```text
Listando...
base-files/stable 13.8+deb13u7 amd64 [actualizable desde: 13.8+deb13u6]
bash/stable 5.2.37-2+b10 amd64 [actualizable desde: 5.2.37-2+b9]
bind9-dnsutils/stable-security 1:9.20.29-1~deb13u1 amd64 [actualizable desde: 1:9.20.26-1~deb13u1]
```

Cada línea muestra el paquete, el repositorio de donde viene la versión nueva, la versión nueva y la instalada. Lo que dice `stable-security` es una corrección de seguridad.

> [!NOTE]
> Si aparece `WARNING: apt does not have a stable CLI interface`, es porque la salida de `apt` pasó por una tubería. Es un aviso para quien escribe scripts; podés ignorarlo.

Hoy no actualizamos el sistema para no alargar la práctica. Cuando quieras hacerlo, el comando es `sudo apt upgrade`, siempre después de `sudo apt update`.

## 3. Antes de instalar: informarse

```bash
apt show mc
```

Fijate en estas líneas (salida recortada):

```text
Package: mc
Version: 3:4.8.33-1+deb13u1
Installed-Size: 1.628 kB
Depends: libc6 (>= 2.38), libext2fs2t64 (>= 1.37), libglib2.0-0t64 (>= 2.78.0), libgpm2 (>= 1.20.7), libslang2 (>= 2.2.4), libssh2-1t64 (>= 1.2.8), mc-data (= 3:4.8.33-1+deb13u1)
Recommends: mailcap, perl, sensible-utils, unzip
APT-Sources: http://deb.debian.org/debian trixie/main amd64 Packages
Description: Midnight Commander - a powerful file manager
```

`Depends` son los paquetes que necesita sí o sí, `Recommends` los que APT instala también por omisión, y `APT-Sources` el repositorio de donde se bajaría. Si `apt show` muestra varias pantallas, salís con `q`.

Comprobá que todavía no está instalado:

```bash
dpkg -l mc
```

La última línea empieza con `un`: no instalado.

## 4. Instalar mc

```bash
sudo apt install mc
```

Antes de instalar, APT muestra un resumen. Leelo antes de responder:

```text
Installing:
  mc

Installing dependencies:
  libssh2-1t64  mailcap  mc-data  unzip

Paquetes sugeridos:
  antiword              genisoimage    poedit
  ...

Summary:
  Upgrading: 0, Installing: 5, Removing: 0, Not Upgrading: 39
  Download size: 2.342 kB
  Space needed: 8.993 kB / 16,4 GB available
```

- `Installing`: lo que pediste.
- `Installing dependencies`: lo que APT agrega porque `mc` lo necesita o lo recomienda.
- `Paquetes sugeridos`: solo se mencionan; no se instalan.
- `Summary`: cuántos paquetes instala, actualiza y quita, cuánto descarga y cuánto espacio ocupa.

Los títulos del resumen salen en inglés aunque el resto esté en español. Respondé `S` y `Enter`.

Probalo:

```bash
mc
```

Se abre con dos paneles de archivos. Salís con `F10`.

## 5. Consultar lo que instaló

### 1. Estado del paquete

```bash
dpkg -l mc
```

```text
ii  mc             3:4.8.33-1+deb13u1 amd64        Midnight Commander - a powerful file manager
```

`ii` significa instalado.

### 2. Qué archivos instaló

```bash
dpkg -L mc | head -12
dpkg -L mc | wc -l
```

```text
/.
/etc
/etc/mc
/etc/mc/edit.indent.rc
/etc/mc/filehighlight.ini
/etc/mc/mc.default.keymap
/etc/mc/mc.emacs.keymap
/etc/mc/mc.ext.ini
/etc/mc/mc.menu
/etc/mc/mc.vim.keymap
/etc/mc/mcedit.menu
/etc/mc/sfs.ini
115
```

Las primeras líneas son la configuración en `/etc/mc/`. En total, `mc` instaló 115 archivos y directorios.

### 3. De qué paquete viene un archivo

```bash
command -v mc
dpkg -S "$(command -v mc)"
```

```text
/usr/bin/mc
mc: /usr/bin/mc
```

`command -v` dice dónde está el programa y `dpkg -S` a qué paquete pertenece ese archivo. Sirve para cualquier archivo instalado por un paquete. Probá con otro:

```bash
dpkg -S /usr/bin/ps
```

```text
procps: /usr/bin/ps
```

### 4. De qué repositorio vino

```bash
apt policy mc
```

```text
mc:
  Instalados: 3:4.8.33-1+deb13u1
  Candidato:  3:4.8.33-1+deb13u1
  Tabla de versión:
 *** 3:4.8.33-1+deb13u1 500
        500 http://deb.debian.org/debian trixie/main amd64 Packages
        100 /var/lib/dpkg/status
```

La versión marcada con `***` es la instalada, y la línea de abajo dice de qué repositorio salió.

### 5. El registro de APT

```bash
tail -6 /var/log/apt/history.log
```

```text
Start-Date: 2026-10-02  02:26:55
Commandline: apt install mc
Requested-By: cristian (1000)
Install: mc-data:amd64 (3:4.8.33-1+deb13u1, automatic), libssh2-1t64:amd64 (1.11.1-1+deb13u2, automatic), mailcap:amd64 (3.74, automatic), mc:amd64 (3:4.8.33-1+deb13u1), unzip:amd64 (6.0-29+deb13u1, automatic)
End-Date: 2026-10-02  02:26:58
```

APT anota cada operación: cuándo, con qué comando y qué usuario la pidió. Las dependencias aparecen como `automatic`; `mc`, que lo pediste vos, no.

## 6. Quitar el paquete

### 1. remove

```bash
sudo apt remove mc
```

```text
Los paquetes indicados a continuación se instalaron de forma automática y ya no son necesarios.
  libssh2-1t64  mc-data  unzip
Utilice «sudo apt autoremove» para eliminarlos.

REMOVING:
  mc
```

Respondé `S`. Después mirá el estado y la configuración:

```bash
dpkg -l mc
ls /etc/mc
```

```text
rc  mc             3:4.8.33-1+deb13u1 amd64        Midnight Commander - a powerful file manager
edit.indent.rc
filehighlight.ini
mc.default.keymap
mcedit.menu
mc.emacs.keymap
mc.ext.ini
mc.menu
mc.vim.keymap
sfs.ini
```

`rc` significa que el programa se quitó, pero su configuración quedó. Los archivos de `/etc/mc/` siguen ahí.

### 2. purge

```bash
sudo apt purge mc
```

```text
REMOVING:
  mc*
```

El asterisco indica que también se borra la configuración. Respondé `S` y comprobá:

```bash
dpkg -l mc
ls /etc/mc
```

```text
un  mc             <ninguna>    <ninguna>    (no hay ninguna descripción disponible)
ls: no se puede acceder a '/etc/mc': No existe el fichero o el directorio
```

### 3. autoremove

Las dependencias que entraron con `mc` siguen instaladas. Quitalas:

```bash
sudo apt autoremove
```

```text
REMOVING:
  libssh2-1t64  mc-data  unzip
```

Respondé `S`.

> [!NOTE]
> En nuestra VM, `mailcap` no aparece en la lista porque otro paquete instalado (`w3m`) lo recomienda, y `autoremove` no quita lo que otro paquete recomienda. En tu VM la lista puede variar por lo mismo.

## 7. Verificación final

### 1. Comprobá el estado

```bash
dpkg -l mc mc-data libssh2-1t64 2>&1 | tail -3
```

Las tres líneas tienen que empezar con `un` (no instalado).

### 2. Respondé a partir de lo observado

1. ¿Qué hizo `sudo apt update`? ¿Cambió algún programa?
2. ¿Qué repositorio de tu `sources.list` trae las correcciones de seguridad?
3. ¿Qué paquetes instaló APT además de `mc`? ¿Por qué?
4. ¿Qué comando usaste para saber de qué paquete viene `/usr/bin/ps`?
5. ¿Qué diferencia viste en `dpkg -l` y en `/etc/mc/` después de `remove` y después de `purge`?
6. ¿Dónde quedó registrado quién instaló `mc`?

### 3. Cerrá la sesión

```bash
exit
```

## Resumen del laboratorio

- Los repositorios están en `/etc/apt/sources.list` (o en `sources.list.d/`). `trixie-security` trae las correcciones de seguridad.
- `apt update` actualiza la lista de paquetes; no instala nada. `apt list --upgradable` muestra lo pendiente y `apt upgrade` lo instala.
- `apt show` informa antes de instalar. El resumen de `apt install` se lee antes de confirmar.
- `dpkg -l` dice el estado, `dpkg -L` qué instaló un paquete y `dpkg -S` de qué paquete viene un archivo.
- `remove` deja la configuración (`rc`), `purge` la borra y `autoremove` quita las dependencias que ya no hacen falta.
- `/var/log/apt/history.log` registra cada operación y quién la pidió.

## Enlaces útiles y referencias

- Ayuda en Debian: `man apt`, `man dpkg`, `man sources.list`.
- [Debian Reference, capítulo 2: gestión de paquetes](https://www.debian.org/doc/manuals/debian-reference/ch02.es.html).
- Siguiente práctica: [Laboratorio 10.2 - Paquetes con dnf en Rocky Linux](lab10.2.md).

-----

<p align="center">
<img src="../img/logos.footer.gray.webp">
</p>
