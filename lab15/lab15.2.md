# Laboratorio 15.2 - Actualizaciones automáticas

## Objetivo

- Instalar la herramienta de actualizaciones automáticas y comprobar si quedó activa.
- Ver qué actualizaciones instala y qué temporizador la dispara.
- Probarla sin instalar nada y después ejecutarla de verdad.
- Leer su registro y saber si quedó un reinicio pendiente.

### Punto de partida

Podés hacerlo en la VM Debian 13 del curso o en la VM Rocky Linux 9. No hace falta haber hecho otros laboratorios, tampoco el 15.1.

La VM necesita salida a internet para bajar los paquetes. Este laboratorio instala las actualizaciones pendientes de tu VM: eso no se deshace al final, y está bien que sea así.

> [!NOTE]
> Las fechas, las horas y la lista de paquetes de las salidas van a ser otras en tu VM: dependen de cuánto hace que no la actualizás.

## ¿Con qué distribución lo hacés?

Elegí una y seguí solo esa parte. Si tenés tiempo, hacé las dos y comparalas.

| Distribución | Herramienta | Ir a |
| --- | --- | --- |
| Debian 13 | `unattended-upgrades` | [Parte Debian](#debian-unattended-upgrades) |
| Rocky Linux 9 | `dnf-automatic` | [Parte Rocky](#rocky-linux-dnf-automatic) |

Las dos hacen lo mismo con distinto camino: un temporizador de systemd que baja e instala las actualizaciones. En Debian queda activa al instalarla; en Rocky viene apagada y hay que configurarla.

## Debian: unattended-upgrades

Usamos la VM Debian 13 del curso con la cuenta administradora, por ejemplo `cristian` (reemplazalo por tu usuario), y el acceso por SSH del [Laboratorio 3](../lab3/lab3.md).

### 0. Preparación

Desde la máquina anfitriona:

```bash
ssh -p 2222 cristian@localhost
```

> [!IMPORTANT]
> Si usás una notebook, dejala enchufada. VirtualBox le pasa a la VM el estado de la batería, y los temporizadores de apt, igual que anacron, no corren con la notebook desenchufada.

Actualizá la lista de paquetes:

```bash
sudo apt update
```

### 1. Antes de instalar

Debian ya trae los dos temporizadores de apt:

```bash
systemctl list-timers 'apt*'
```

```text
NEXT                        LEFT LAST                        PASSED UNIT                    ACTIVATES
Fri 2026-10-30 05:54:20 -03   6h Wed 2026-10-28 20:51:08 -03      - apt-daily.timer         apt-daily.service
Fri 2026-10-30 06:45:35 -03   6h Thu 2026-10-29 22:54:15 -03      - apt-daily-upgrade.timer apt-daily-upgrade.service
```

- `apt-daily` baja la lista de paquetes.
- `apt-daily-upgrade` instala.

Que corran no quiere decir que hagan algo. Lo que hacen depende de las opciones `APT::Periodic` de la configuración de apt:

```bash
apt-config dump | grep -i periodic
```

No muestra nada: no hay ninguna opción, así que los temporizadores se disparan y no hacen nada.

`unattended-upgrades` no viene instalado:

```bash
apt-cache policy unattended-upgrades
```

```text
unattended-upgrades:
  Instalados: (ninguno)
  Candidato:  2.12
```

### 2. Instalar unattended-upgrades

```bash
sudo apt install unattended-upgrades
```

Trae siete paquetes: el programa, que está escrito en Python, y bibliotecas que usa. Mirá qué agregó en la configuración de apt:

```bash
ls /etc/apt/apt.conf.d/
cat /etc/apt/apt.conf.d/20auto-upgrades
```

```text
00aptitude  00CDMountPoint  00trustcdrom  01autoremove  20auto-upgrades  20listchanges  50unattended-upgrades  70debconf
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
```

Dejó dos archivos:

- `20auto-upgrades` enciende las dos tareas: bajar la lista todos los días (`Update-Package-Lists "1"`) e instalar todos los días (`Unattended-Upgrade "1"`).
- `50unattended-upgrades` dice qué se instala. Lo vemos en el paso 4 de esta parte.

En Debian 13, instalarlo alcanza: queda activo. Los temporizadores del paso 1 ahora sí van a hacer algo.

### 3. Encenderlo o apagarlo

La pregunta que decide si queda activo se puede volver a hacer:

```bash
sudo dpkg-reconfigure -plow unattended-upgrades
```

```text
Para mantener el sistema seguro es importante instalar las actualizaciones
regularmente. De manera predeterminada, para poder realizar una actualización
tiene que utilizar una herramienta de gestión de paquetes. Como alternativa,
puede elegir que el sistema descargue e instale automáticamente las
actualizaciones importantes.

¿Desea descargar e instalar automáticamente las actualizaciones de la versión estable?
```

- Con **No**, `20auto-upgrades` queda con `"0"` en las dos líneas y deja de actualizar solo. El paquete sigue instalado.
- Con **Sí**, queda con `"1"`.

Elegí **Sí** y comprobá:

```bash
cat /etc/apt/apt.conf.d/20auto-upgrades
```

```text
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
```

`-plow` hace que muestre las preguntas de prioridad baja. Al instalar no la mostró porque es de prioridad baja y tomó la respuesta predeterminada, que es «sí».

### 4. Qué instala

Las fuentes permitidas están al principio de `50unattended-upgrades`. Sin los comentarios:

```bash
grep -v '^\s*//' /etc/apt/apt.conf.d/50unattended-upgrades | grep -v '^\s*$'
```

```text
Unattended-Upgrade::Origins-Pattern {
        "origin=Debian,codename=${distro_codename},label=Debian";
        "origin=Debian,codename=${distro_codename},label=Debian-Security";
        "origin=Debian,codename=${distro_codename}-security,label=Debian-Security";
};
Unattended-Upgrade::Package-Blacklist {
};
```

- `label=Debian-Security`: las correcciones de seguridad.
- `label=Debian`: las actualizaciones de la versión estable, las que llegan con cada versión menor (13.6, 13.7).
- `${distro_codename}` es `trixie`, el nombre de Debian 13. Nunca pasa solo a Debian 14.
- `Package-Blacklist` es una lista de paquetes que no se tocan. Está vacía.

El reinicio automático viene apagado. La línea está comentada con `//`:

```bash
grep -n 'Automatic-Reboot "' /etc/apt/apt.conf.d/50unattended-upgrades
```

```text
116://Unattended-Upgrade::Automatic-Reboot "false";
```

Se deja así: reiniciar un servidor lo decide el administrador.

### 5. Probar sin instalar

`--dry-run` hace todo menos instalar:

```bash
sudo unattended-upgrade --dry-run
```

No muestra nada en la terminal. Lo que hizo queda en su registro:

```bash
sudo grep 'INFO' /var/log/unattended-upgrades/unattended-upgrades.log | tail -n 5
```

```text
2026-10-29 23:56:47,709 INFO Fuentes permitidas: origin=Debian,codename=trixie,label=Debian, origin=Debian,codename=trixie,label=Debian-Security, origin=Debian,codename=trixie-security,label=Debian-Security
2026-10-29 23:57:03,524 INFO Option --dry-run given, *not* performing real actions
2026-10-29 23:57:03,524 INFO Paquetes que se actualizarán: base-files bash bind9-dnsutils bind9-host bind9-libs busybox ca-certificates dhcpcd-base e2fsprogs gzip libasound2-data libasound2t64 libaudit-common libaudit1 libbrotli1 libc-bin libc-l10n libc6 libcap2 libcap2-bin libcom-err2 libexpat1 libext2fs2t64 liblzma5 libpcre2-8-0 libperl5.40 libpng16-16t64 libpython3.13-minimal libpython3.13-stdlib libsqlite3-0 libss2 libssl3t64 linux-image-amd64 locales logsave openssl openssl-provider-legacy perl perl-base perl-modules-5.40 python3.13 python3.13-minimal tzdata xz-utils
2026-10-29 23:57:03,525 INFO Writing dpkg log to /var/log/unattended-upgrades/unattended-upgrades-dpkg.log
2026-10-29 23:57:34,257 INFO Se han instalado todas las actualizaciones
```

`Paquetes que se actualizarán` es lo que instalaría. Entre ellos está `linux-image-amd64`, el kernel. Compará con todo lo que hay para actualizar:

```bash
apt list --upgradable
```

Si en la lista hay algo que no está en `Paquetes que se actualizarán`, es porque viene de otra fuente, por ejemplo `trixie-updates`, que no está entre las permitidas.

> [!TIP]
> Con `sudo unattended-upgrade --dry-run --debug` muestra en la terminal cada decisión. Es mucho texto; sirve para averiguar por qué un paquete no se instaló.

### 6. Ejecutarlo ahora

El temporizador lo ejecuta cerca de las 6 de la mañana. Para no esperar, ejecutalo a mano. Tarda unos minutos:

```bash
sudo unattended-upgrade -v
```

```text
Iniciando guión de actualizaciones desatendidas
Fuentes permitidas: origin=Debian,codename=trixie,label=Debian, origin=Debian,codename=trixie,label=Debian-Security, origin=Debian,codename=trixie-security,label=Debian-Security
...
Packages that were successfully auto-removed: linux-image-6.12.94+deb13-amd64
Packages that are kept back:
```

`-v` muestra lo que va haciendo. En el medio aparecen los paquetes que instala. Al final borra lo que ya no hace falta, como un kernel viejo.

Si no tenía nada para instalar, dice:

```text
No se encontraron paquetes que puedan actualizarse de forma desatendida y no hay pendiente ninguna desinstalación automática
```

El detalle de lo instalado queda en `unattended-upgrades-dpkg.log`, en el mismo directorio:

```bash
sudo ls -l /var/log/unattended-upgrades/
```

```text
-rw-r--r-- 1 root adm   47018 oct 30 00:00 unattended-upgrades-dpkg.log
-rw-r--r-- 1 root root 169889 oct 30 00:01 unattended-upgrades.log
```

### 7. ¿Hay que reiniciar?

Cuando se actualiza el kernel u otra pieza que solo se carga al arrancar, Debian deja un archivo de aviso:

```bash
ls /run/reboot-required
cat /run/reboot-required.pkgs
```

```text
/run/reboot-required
linux-image-6.12.113+deb13-amd64
```

`reboot-required.pkgs` dice qué paquete lo pide. El kernel nuevo está instalado, pero la VM sigue usando el viejo:

```bash
uname -r
```

```text
6.12.105+deb13-amd64
```

Reiniciá la VM, volvé a entrar por SSH y comprobá:

```bash
sudo reboot
```

```bash
uname -r
ls /run/reboot-required
```

```text
6.12.113+deb13-amd64
ls: no se puede acceder a '/run/reboot-required': No existe el fichero o el directorio
```

El aviso desapareció: `/run` se vacía en cada arranque. Si el archivo no existe, no hay reinicio pendiente.

### 8. Limpieza

En un servidor real conviene dejar `unattended-upgrades` activo. Si querés dejar tu VM como estaba, desinstalalo:

```bash
sudo apt purge unattended-upgrades
sudo apt autoremove --purge
ls /etc/apt/apt.conf.d/
```

`purge` borra también `20auto-upgrades` y `50unattended-upgrades`. Los temporizadores de apt siguen, y vuelven a no hacer nada. Las actualizaciones que instalaste quedan.

`autoremove` puede dejar algunas bibliotecas de Python (`python3-gi` y sus `gir1.2-*`) porque otro paquete, `apt-listchanges`, las recomienda. No molestan.

## Rocky Linux: dnf-automatic

Usamos la VM Rocky Linux 9 del curso con la cuenta `usuario` y el acceso por SSH en el puerto 2223.

> **¿No tenés la VM de Rocky?** Descargá `Lab_Rocky.ova` y `Lab_Rocky.ova.sha256` de [linux-files.idep.atepba.org.ar](https://linux-files.idep.atepba.org.ar/) y seguí los pasos 2 a 4 del [Laboratorio 10.2](../lab10/lab10.2.md): comprobar la descarga, importar la VM e iniciarla. La cuenta es `usuario`, con contraseña `linux410`.

### 0. Preparación

Desde la máquina anfitriona:

```bash
ssh -p 2223 usuario@localhost
```

### 1. Antes de instalar

Rocky trae cuatro temporizadores:

```bash
systemctl list-timers
```

```text
NEXT                        LEFT        LAST                        PASSED    UNIT                         ACTIVATES
Fri 2026-10-30 00:38:18 -03 14min left  -                           -         systemd-tmpfiles-clean.timer systemd-tmpfiles-clean.service
Fri 2026-10-30 00:40:13 -03 16min left  -                           -         dnf-makecache.timer          dnf-makecache.service
Sat 2026-10-31 00:00:00 -03 23h left    Fri 2026-10-30 00:00:32 -03 22min ago logrotate.timer              logrotate.service
Sun 2026-11-01 01:00:00 -03 2 days left Wed 2026-10-28 23:30:10 -03 24h ago   raid-check.timer             raid-check.service

4 timers listed.
```

`dnf-makecache` baja la lista de paquetes cada tanto, pero ninguno instala nada. Mirá qué actualizaciones de seguridad hay pendientes:

```bash
sudo dnf check-update --security
```

```text
ca-certificates.noarch             2026.2.92_v9.0.319-90.3.el9_8         baseos
curl.x86_64                        7.76.1-40.el9_8.8                     baseos
expat.x86_64                       2.5.0-6.el9_8.7                       baseos
glibc.x86_64                       2.34-283.el9_8                        baseos
...
```

`--security` muestra solo las que corrigen fallas de seguridad. Sin esa opción, `dnf check-update` muestra todas.

### 2. Instalar dnf-automatic

```bash
sudo dnf install dnf-automatic
```

Es un solo paquete. Mirá cómo viene:

```bash
grep -E '^upgrade_type|^download_updates|^apply_updates' /etc/dnf/automatic.conf
systemctl list-unit-files 'dnf-automatic*.timer'
```

```text
upgrade_type = default
download_updates = yes
apply_updates = no
UNIT FILE                      STATE    PRESET
dnf-automatic-download.timer   disabled disabled
dnf-automatic-install.timer    disabled disabled
dnf-automatic-notifyonly.timer disabled disabled
dnf-automatic.timer            disabled disabled

4 unit files listed.
```

- Todos los temporizadores están `disabled`: instalarlo no alcanza.
- `apply_updates = no`: aunque se encienda, baja las actualizaciones y no las instala.
- `upgrade_type = default`: todas las actualizaciones, no solo las de seguridad.

### 3. Solo seguridad, instalando

Editá el archivo:

```bash
sudo nano /etc/dnf/automatic.conf
```

Cambiá estas dos líneas, que están en la sección `[commands]`:

```ini
upgrade_type = security
apply_updates = yes
```

Encendé el temporizador:

```bash
sudo systemctl enable --now dnf-automatic.timer
systemctl list-timers dnf-automatic.timer
```

```text
NEXT                        LEFT    LAST PASSED UNIT                ACTIVATES
Fri 2026-10-30 06:05:12 -03 6h left -    -      dnf-automatic.timer dnf-automatic.service
```

Corre todos los días cerca de las 6, con hasta una hora de demora al azar.

### 4. Ejecutarlo ahora

Arrancá el servicio sin esperar al temporizador:

```bash
sudo systemctl start --no-block dnf-automatic.service
systemctl is-active dnf-automatic.service
```

```text
activating
```

`--no-block` devuelve el prompt enseguida. Sin esa opción, `systemctl` espera a que termine; si entre las actualizaciones está systemd, la espera se corta con un aviso de D-Bus aunque la actualización sigue bien.

Mientras trabaja dice `activating`. Repetí `systemctl is-active` cada tanto: cuando termina dice `inactive`. Puede tardar varios minutos.

### 5. Leer el registro

Lo que hizo queda en el journal del servicio:

```bash
sudo journalctl -u dnf-automatic --since "15 min ago" | tail -n 6
```

```text
oct 30 00:04:35 localhost.localdomain dnf-automatic[6552]: Instalar    10 Paquetes
oct 30 00:04:35 localhost.localdomain dnf-automatic[6552]: Actualizar  29 Paquetes
oct 30 00:04:35 localhost.localdomain dnf-automatic[6552]: Actualizaciones completadas en 'vie 30 oct 2026 00:04:35'
oct 30 00:04:35 localhost.localdomain systemd[1]: dnf-automatic.service: Deactivated successfully.
oct 30 00:04:35 localhost.localdomain systemd[1]: Finished dnf automatic.
oct 30 00:04:35 localhost.localdomain systemd[1]: dnf-automatic.service: Consumed 1min 43.866s CPU time.
```

`Instalar 10 Paquetes` incluye un kernel nuevo: en Rocky el kernel se instala al lado del anterior, no lo reemplaza.

Si no había nada de seguridad para instalar, dice:

```text
oct 30 00:23:50 localhost.localdomain dnf-automatic[2235]: No es necesaria ninguna actualización de seguridad, pero hay 22 actualizaciones disponibles
```

Las otras 22 no las toca porque elegiste `upgrade_type = security`.

`dnf history` también registra cada transacción, sea a mano o automática:

```bash
sudo dnf history list | head -n 4
```

### 6. ¿Hay que reiniciar?

```bash
sudo dnf needs-restarting -r
```

```text
Core libraries or services have been updated since boot-up:
  * glibc
  * kernel

Reboot is required to fully utilize these updates.
```

Reiniciá con `sudo reboot`, volvé a entrar y repetí el comando:

```text
No core libraries or services have been updated since boot-up.
Reboot should not be necessary.
```

### 7. Limpieza

En un servidor real conviene dejarlo encendido. Si querés dejar tu VM como estaba:

```bash
sudo systemctl disable --now dnf-automatic.timer
sudo dnf remove dnf-automatic
sudo rm /etc/dnf/automatic.conf.rpmsave
```

Como modificaste `automatic.conf`, al desinstalar `dnf` lo guarda como `automatic.conf.rpmsave`. El último comando lo borra. Las actualizaciones que instalaste quedan.

## Preguntas

Debian:

1. En el paso 1 los temporizadores `apt-daily` y `apt-daily-upgrade` estaban activos. ¿Por qué no actualizaban nada?
2. ¿Qué archivo enciende las actualizaciones automáticas, y qué cambia en él si respondés **No** en `dpkg-reconfigure`?
3. Después del paso 6, `apt list --upgradable` todavía puede mostrar algún paquete. ¿Por qué `unattended-upgrades` no lo instaló?
4. ¿Qué indica `/run/reboot-required`, y por qué desaparece al reiniciar?

Rocky:

5. ¿Qué hace `dnf-automatic` si encendés el temporizador pero dejás `apply_updates = no`?
6. Con `upgrade_type = security`, ¿qué pasa con las actualizaciones que no son de seguridad?

Las dos:

7. ¿Por qué no conviene que el sistema se reinicie solo después de actualizar un servidor?

## Resumen del laboratorio

- Las dos distribuciones actualizan solas con un temporizador de systemd que baja e instala.
- Debian: `unattended-upgrades` crea `20auto-upgrades` y queda activo al instalarlo. `50unattended-upgrades` dice qué se instala (seguridad y versión estable). `--dry-run` prueba sin instalar, el registro está en `/var/log/unattended-upgrades/` y `/run/reboot-required` avisa que hay que reiniciar.
- Rocky: `dnf-automatic` viene apagado. Se configura en `/etc/dnf/automatic.conf` (`upgrade_type` y `apply_updates`) y se enciende `dnf-automatic.timer`. El registro está en el journal y `dnf needs-restarting -r` dice si hay que reiniciar.
- En las dos el reinicio automático viene apagado: reiniciar lo decide el administrador.

## Enlaces útiles y referencias

- Ayuda en Debian: `man unattended-upgrade`, `/usr/share/doc/unattended-upgrades/README.md.gz`.
- [Debian Wiki - UnattendedUpgrades](https://wiki.debian.org/UnattendedUpgrades).
- Ayuda en Rocky: `man dnf-automatic`.
- Clase 16: [presentación](https://linux.idepba.com.ar/clase16.html).
- Anterior: [Laboratorio 15.1 - Tareas programadas](./lab15.1.md).

-----

<p align="center">
<img src="../img/logos.footer.gray.webp">
</p>
