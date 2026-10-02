# Laboratorio 10.2 - Paquetes con dnf en Rocky Linux

## Objetivo

- Descargar una máquina virtual ya preparada y comprobar que el archivo llegó sano.
- Importarla en VirtualBox y conectarse por SSH.
- Ver los repositorios de Rocky Linux y comparar `dnf` con lo que hicimos con `apt`.
- Instalar un paquete, consultarlo con `rpm` y quitarlo.

### Punto de partida

Usamos VirtualBox 7.2 en la máquina anfitriona. Esta vez no instalamos el sistema: descargamos una VM de Rocky Linux 9 lista para usar, en formato OVA (un único archivo con la configuración y el disco de la VM).

| Dato | Valor |
| --- | --- |
| Sistema | Rocky Linux 9 (familia Red Hat) |
| Usuario | `usuario` |
| Contraseña | `linux410` |
| Permisos | `usuario` puede usar `sudo` |
| Acceso SSH | puerto 2223 del anfitrión |
| Memoria | 1024 MB |

Necesitás unos 6 GB libres en la anfitriona: 2,7 GB para el archivo descargado y otro tanto para el disco de la VM importada. Al terminar de importar, el archivo `.ova` se puede borrar.

> [!NOTE]
> La VM de Debian usa el puerto 2222 y la de Rocky el 2223, así que pueden estar encendidas a la vez. Si tu anfitriona tiene poca memoria, apagá la de Debian antes de iniciar la de Rocky.

## 1. Descargar la VM

Entrá a [linux-files.idep.atepba.org.ar](https://linux-files.idep.atepba.org.ar/) y descargá los dos archivos en la misma carpeta:

| Archivo | Qué es |
| --- | --- |
| `Lab_Rocky.ova` | La máquina virtual (unos 2,7 GB) |
| `Lab_Rocky.ova.sha256` | La suma SHA256 que tiene que dar el archivo |



## 2. Comprobar la descarga

La suma SHA256 es como una huella del archivo: si cambia un solo byte, cambia la suma. Si la que calculás coincide con la publicada, el archivo llegó completo y sin alteraciones.

### En Linux

En la carpeta donde están los dos archivos:

```bash
sha256sum -c Lab_Rocky.ova.sha256
```

Tarda unos segundos. Si todo está bien:

```text
Lab_Rocky.ova: La suma coincide
```

Si el archivo está incompleto o dañado:

```text
Lab_Rocky.ova: La suma no coincide
sha256sum: WARNING: 1 computed checksum did NOT match
```

En ese caso, borralo y volvé a descargarlo. Si tu sistema está en inglés, los mensajes son `OK` y `FAILED`.

### En Windows

Abrí PowerShell en la carpeta de descarga (en el Explorador, clic derecho sobre la carpeta → **Abrir en Terminal**) y calculá la suma:

```powershell
Get-FileHash .\Lab_Rocky.ova -Algorithm SHA256
```

Muestra algo así:

```text
Algorithm       Hash                                                                   Path
---------       ----                                                                   ----
SHA256          403EC68E5DCC30EED9075BD53988A548883E9C30DF5E8CFEE93FA642B4B22FC7       C:\Users\...\Lab_Rocky.ova
```

Compará ese valor con el contenido del archivo `.sha256`:

```powershell
Get-Content .\Lab_Rocky.ova.sha256
```

```text
403ec68e5dcc30eed9075bd53988a548883e9c30df5e8cfee93fa642b4b22fc7  Lab_Rocky.ova
```

Windows muestra la suma en mayúsculas y el archivo la tiene en minúsculas: es el mismo número. Para no comparar a ojo, PowerShell puede hacerlo por vos:

```powershell
(Get-FileHash .\Lab_Rocky.ova -Algorithm SHA256).Hash -eq (Get-Content .\Lab_Rocky.ova.sha256).Split(' ')[0]
```

Tiene que responder `True`. Si responde `False`, volvé a descargar el archivo.

> [!TIP]
> En el símbolo del sistema (`cmd`) también se puede usar `certutil -hashfile Lab_Rocky.ova SHA256`.

> [!NOTE]
> La suma comprueba que el archivo llegó igual a como se publicó. No dice quién lo publicó: para eso los repositorios usan firmas, como vimos en la clase.

## 3. Importar la VM en VirtualBox

1. Abrí VirtualBox y andá a **Archivo → Importar servicio virtualizado...** (o `Ctrl+I`).
2. En **Archivo**, elegí `Lab_Rocky.ova` y pasá a la pantalla siguiente.
3. Revisá la configuración que trae: nombre `Lab_Rocky`, 1 CPU y 1024 MB de memoria. No hace falta cambiar nada.
4. En **Política de dirección MAC**, elegí **Generar nuevas direcciones MAC para todos los adaptadores de red**. Así tu VM no comparte la dirección de red con la de otra persona.
5. En **Carpeta base de máquina** queda la carpeta de VirtualBox. Cambiala solo si querés guardarla en otro disco.
6. Presioná **Terminar** y esperá a que termine la importación. Tarda unos minutos.

Al final aparece `Lab_Rocky` en la lista de máquinas.

> [!NOTE]
> La VM ya trae configurado el reenvío de puertos: el puerto 2223 de la anfitriona va al 22 de la VM. Lo podés ver en **Configuración → Red → Adaptador 1 → Avanzado → Reenvío de puertos**.

## 4. Iniciar la VM y conectarse

Seleccioná `Lab_Rocky` y presioná **Iniciar**. Se abre una ventana con la consola de la VM; esperá a que aparezca el pedido de usuario (`localhost login:`). No hace falta iniciar sesión ahí: nos conectamos por SSH.

> [!TIP]
> Con la flecha junto a **Iniciar** se puede elegir el inicio sin interfaz (*headless*): la VM arranca sin abrir la ventana. Para apagarla después, usá `sudo poweroff` desde SSH.

Desde una terminal de la anfitriona:

```bash
ssh -p 2223 usuario@localhost
```

La primera vez, SSH pregunta si confiás en la clave del servidor. Escribí `yes`. Después, la contraseña: `linux410`.

Comprobá dónde estás:

```bash
cat /etc/os-release | head -4
id
```

```text
NAME="Rocky Linux"
VERSION="9.8 (Blue Onyx)"
RELEASE_TYPE="stable"
ID="rocky"
uid=1000(usuario) gid=1000(usuario) grupos=1000(usuario),10(wheel) contexto=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
```

`usuario` está en el grupo `wheel`, que en la familia Red Hat es el grupo que puede usar `sudo`. En Debian es el grupo `sudo`.

## 5. Los repositorios de Rocky

```bash
sudo dnf repolist
```

```text
id del repositorio                   nombre del repositorio
appstream                            Rocky Linux 9 - AppStream
baseos                               Rocky Linux 9 - BaseOS
extras                               Rocky Linux 9 - Extras
```

Los repositorios están en archivos `.repo` dentro de `/etc/yum.repos.d/`, que cumple la función de `/etc/apt/sources.list.d/` en Debian. El archivo `rocky.repo` empieza con comentarios; mirá solo el bloque del repositorio `baseos`:

```bash
grep -A8 '^\[baseos\]' /etc/yum.repos.d/rocky.repo
```

```text
[baseos]
name=Rocky Linux $releasever - BaseOS
mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=BaseOS-$releasever$rltype
#baseurl=http://dl.rockylinux.org/$contentdir/$releasever/BaseOS/$basearch/os/
gpgcheck=1
enabled=1
countme=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9
```

- `enabled=1`: el repositorio está activo.
- `gpgcheck=1` y `gpgkey=`: los paquetes se verifican con la clave de Rocky, como `Signed-By` en Debian.
- `metadata_expire=6h`: `dnf` actualiza la lista de paquetes solo cuando tiene más de 6 horas.

> [!IMPORTANT]
> Usá `sudo` también en las consultas de `dnf`. Sin `sudo`, `dnf` arma una caché aparte para tu usuario y vuelve a bajar todas las listas de paquetes, que tarda bastante.

## 6. ¿Hay actualizaciones?

```bash
sudo dnf check-update
```

La primera vez baja las listas de los tres repositorios (unos 60 MB) y tarda unos segundos:

```text
Rocky Linux 9 - BaseOS                           16 MB/s |  35 MB     00:02
Rocky Linux 9 - AppStream                       8.3 MB/s |  26 MB     00:03
Rocky Linux 9 - Extras                           13 kB/s |  17 kB     00:01
Última comprobación de caducidad de metadatos hecha hace 0:00:01, el vie 02 oct 2026 02:40:01.
```

Después muestra lo que hay para actualizar. Si no aparece ningún paquete, como en este ejemplo, está todo al día. En Rocky no hay un paso como `apt update`: `dnf` baja las listas cuando hace falta. Por eso `sudo dnf upgrade` (o `sudo dnf update`, que es lo mismo) hace en un solo comando lo que en Debian es `apt update` y `apt upgrade`.

Hoy no actualizamos el sistema para no alargar la práctica.

## 7. Instalar un paquete

Vamos a usar `tree`, que ya conocés de Debian.

```bash
sudo dnf info tree
```

Salida recortada:

```text
Paquetes disponibles
Nombre       : tree
Versión      : 1.8.0
Lanzamiento  : 10.el9
Arquitectura : x86_64
Tamaño       : 55 k
Repositorio  : baseos
Resumen      : File system tree viewer
```

`Paquetes disponibles` quiere decir que está en un repositorio, pero no instalado. Es el equivalente de `apt show`.

Instalalo:

```bash
sudo dnf install tree
```

Antes de instalar, `dnf` muestra una tabla y un resumen:

```text
Dependencias resueltas.
================================================================================
 Paquete        Arquitectura     Versión                 Repositorio       Tam.
================================================================================
Instalando:
 tree           x86_64           1.8.0-10.el9            baseos            55 k

Resumen de la transacción
================================================================================
Instalar  1 Paquete

Tamaño total de la descarga: 55 k
Tamaño instalado: 113 k
¿Está de acuerdo [s/N]?:
```

Fijate en la pregunta: en `dnf` la respuesta por omisión es **no** (`[s/N]`). Si presionás `Enter` sin escribir nada, responde `Operación abortada.` y no instala. Escribí `s` y `Enter`.

La primera vez que instalás algo, `dnf` pide además aceptar la clave con la que Rocky firma sus paquetes:

```text
Importando llave GPG 0x350D275D:
 ID usuario: "Rocky Enterprise Software Foundation - Release key 2022 <releng@rockylinux.org>"
 Huella    : 21CB 256A E16F C54C 6E65 2949 702D 426D 350D 275D
 Desde     : /etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-9
¿Está de acuerdo [s/N]?:
```

Es la clave que nombra el `gpgkey=` del archivo `.repo`, y viene con el sistema. Respondé `s`. Al terminar:

```text
Instalado:
  tree-1.8.0-10.el9.x86_64

¡Listo!
```

Probalo:

```bash
tree -L 1 /etc/yum.repos.d
```

```text
/etc/yum.repos.d
├── rocky-addons.repo
├── rocky-devel.repo
├── rocky-extras.repo
├── rocky.repo
└── rocky-security.repo

0 directories, 5 files
```

## 8. Consultar con rpm

`rpm` cumple el papel de `dpkg`: consulta lo instalado.

```bash
rpm -q tree
rpm -ql tree
rpm -qf /usr/bin/tree
rpm -qf /usr/bin/ps
```

```text
tree-1.8.0-10.el9.x86_64
/usr/bin/tree
/usr/lib/.build-id
/usr/lib/.build-id/d0
/usr/lib/.build-id/d0/a010245f25272aff8e82aa32809790125b7f0b
/usr/share/doc/tree
/usr/share/doc/tree/README
/usr/share/licenses/tree
/usr/share/licenses/tree/LICENSE
/usr/share/man/man1/tree.1.gz
tree-1.8.0-10.el9.x86_64
procps-ng-3.3.17-14.el9.x86_64
```

La primera línea es `rpm -q`: el paquete está instalado y esa es su versión. Después viene la lista de `rpm -ql`, y las dos últimas son las respuestas de `rpm -qf`: `/usr/bin/ps` viene de `procps-ng`, el mismo programa que en Debian está en el paquete `procps`.

| En Debian | En Rocky | Para qué |
| --- | --- | --- |
| `dpkg -l tree` | `rpm -q tree` | ¿Está instalado? |
| `dpkg -L tree` | `rpm -ql tree` | ¿Qué archivos instaló? |
| `dpkg -S /usr/bin/ps` | `rpm -qf /usr/bin/ps` | ¿De qué paquete viene este archivo? |

## 9. Quitar el paquete

```bash
sudo dnf remove tree
```

```text
Eliminando:
 tree           x86_64           1.8.0-10.el9           @baseos           113 k

Resumen de la transacción
================================================================================
Eliminar  1 Paquete

Espacio liberado: 113 k
¿Está de acuerdo [s/N]?:
```

El `@baseos` indica de qué repositorio vino lo que está instalado. Respondé `s`. Comprobá:

```bash
rpm -q tree
```

```text
el paquete tree no está instalado
```

`dnf` no tiene `purge`: si hubieras modificado un archivo de configuración del paquete, quedaría guardado con la extensión `.rpmsave`. Tampoco hace falta `autoremove`: `dnf remove` quita en el mismo paso las dependencias que ya no se usan.

## 10. Verificación final

### 1. Comprobá el estado

```bash
rpm -q tree
sudo dnf repolist
```

`tree` no tiene que estar instalado y los repositorios tienen que ser los tres del comienzo.

### 2. Respondé a partir de lo observado

1. ¿Para qué sirve el archivo `.sha256`? ¿Qué pasaría si la suma no coincidiera?
2. ¿Qué cambia al elegir **Generar nuevas direcciones MAC** en la importación?
3. ¿En qué directorio están los repositorios en Rocky y en Debian?
4. ¿Por qué en Rocky no hace falta un paso como `apt update`?
5. ¿Qué pasa si en la pregunta de `dnf install` presionás `Enter` sin escribir nada?
6. ¿Qué comando de Rocky equivale a `dpkg -S`?

### 3. Cerrá la sesión y apagá la VM

```bash
sudo poweroff
```

La conexión SSH se corta sola. Conservá la VM: la vamos a usar más adelante.

## Resumen del laboratorio

- Una OVA trae una VM completa. Antes de importarla, se comprueba la descarga con su suma SHA256: `sha256sum -c` en Linux, `Get-FileHash` en Windows.
- Al importar, conviene generar direcciones MAC nuevas.
- En Rocky, los repositorios están en `/etc/yum.repos.d/*.repo` y cada uno declara su clave con `gpgkey`.
- `dnf` actualiza solo las listas de paquetes: `dnf upgrade` equivale a `apt update` más `apt upgrade`.
- `dnf install` y `dnf remove` instalan y quitan; `rpm -q`, `rpm -ql` y `rpm -qf` consultan, como `dpkg -l`, `-L` y `-S`.
- En `dnf` la respuesta por omisión es no.

## Enlaces útiles y referencias

- Ayuda en Rocky: `man dnf`, `man rpm`, `man yum.conf`.
- [Documentación de Rocky Linux](https://docs.rockylinux.org/).
- [Manual de VirtualBox: primeros pasos, con importación y exportación de VM](https://www.virtualbox.org/manual/ch01.html).
- Práctica anterior: [Laboratorio 10.1 - Paquetes con APT en Debian](lab10.1.md).

-----

<p align="center">
<img src="../img/logos.footer.gray.webp">
</p>
