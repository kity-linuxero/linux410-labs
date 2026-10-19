# Laboratorio 13.1 - Logs del sistema

## Objetivo

- Buscar en el journal por tiempo, por arranque, por prioridad, por servicio y por texto.
- Dejar mensajes propios en el log con `logger`.
- Investigar un intento de acceso por SSH: quién, desde dónde, cuándo, cuántas veces y si alguien entró.
- Instalar rsyslog y encontrar los mismos mensajes en los archivos de `/var/log`.
- Encontrar en el log por qué falla un servicio de respaldo y corregirlo.

### Punto de partida

Usamos la VM Debian 13 del curso con la cuenta administradora, por ejemplo `cristian`, y el acceso por SSH del [Laboratorio 3](../lab3/lab3.md). No hace falta haber hecho otros laboratorios: lo que se necesita se arma acá y se borra al final.

> [!NOTE]
> Reemplazá `cristian` por tu usuario. Las horas, los números de proceso (`[2670]`) y los puertos de las salidas van a ser otros en tu VM.

## 0. Preparación

Desde la máquina anfitriona:

```bash
ssh -p 2222 cristian@localhost
```

## 1. El journal

### 1. ¿Dónde guarda?

```bash
ls -d /var/log/journal
sudo journalctl --disk-usage
```

```text
/var/log/journal
Archived and active journals take up 184.4M in the file system.
```

El directorio existe, así que el journal está en disco y se conserva al reiniciar. Mirá qué hay en `/var/log`:

```bash
ls /var/log
```

```text
alternatives.log
alternatives.log.1
apt
btmp
btmp.1
dpkg.log
dpkg.log.1
installer
journal
lastlog
private
README
runit
unattended-upgrades
wtmp
wtmp.db
```

No están `syslog` ni `auth.log`: Debian 13 no trae rsyslog. Todo está en el journal. Lo instalamos en el paso 4.

### 2. Sin sudo y con sudo

```bash
journalctl -n 3
```

```text
Hint: You are currently not seeing messages from other users and the system.
      Users in groups 'adm', 'systemd-journal' can see all messages.
      Pass -q to turn off this notice.
oct 18 22:08:37 lab2-vm sudo[1007]: cristian : PWD=/home/cristian ; USER=root ; COMMAND=/usr/bin/journalctl --disk-usage
...
```

Sin `sudo` solo ves tus propios mensajes. De acá en adelante usamos `sudo journalctl`.

### 3. Por prioridad

```bash
sudo journalctl -b -p err
```

```text
oct 18 21:50:34 lab2-vm systemd-ssh-generator[224]: Failed to query local AF_VSOCK CID: Cannot assign requested address
oct 18 21:50:34 lab2-vm (sd-exec-[216]: /usr/lib/systemd/system-generators/systemd-ssh-generator failed with exit status 1.
oct 18 21:50:35 lab2-vm kernel: vmwgfx 0000:00:02.0: [drm] *ERROR* vmwgfx seems to be running on an unsupported hypervisor.
oct 18 21:50:35 lab2-vm kernel: vmwgfx 0000:00:02.0: [drm] *ERROR* This configuration is likely broken.
oct 18 21:50:35 lab2-vm kernel: vmwgfx 0000:00:02.0: [drm] *ERROR* Please switch to a supported graphics device to avoid problems.
```

`-b` es el arranque actual y `-p err` deja los errores y lo más grave. Estos aparecen en cada arranque de la VM y no indican ninguna falla: son avisos de VirtualBox. Conviene conocerlos para no confundirlos con un problema real. Salimos con `q`.

### 4. El kernel y el arranque anterior

```bash
sudo journalctl -k -n 3
sudo journalctl -b -1 -n 3
```

```text
oct 18 21:50:36 lab2-vm kernel: Loaded X.509 cert 'wens: 61c038651aabdcf94bd0ac7ff06c7248db18c600'
oct 18 21:50:36 lab2-vm kernel: 8021q: adding VLAN 0 to HW filter on device enp0s3
oct 18 21:50:36 lab2-vm kernel: e1000: enp0s3 NIC Link is Up 1000 Mbps Full Duplex, Flow Control: RX
oct 18 18:22:50 lab2-vm systemd-shutdown[1]: Sending SIGTERM to remaining processes...
oct 18 18:22:50 lab2-vm systemd-journald[243]: Received SIGTERM from PID 1 (systemd-shutdow).
oct 18 18:22:50 lab2-vm systemd-journald[243]: Journal stopped
```

- `-k` muestra solo los mensajes del kernel: la placa de red quedó conectada.
- `-b -1` es el encendido anterior. Las últimas líneas son las del apagado: la VM se apagó en orden. Si la hubieras cerrado de golpe desde VirtualBox, el log terminaría en cualquier mensaje, sin estas líneas.

### 5. Por tiempo

```bash
sudo journalctl --since "10 min ago"
```

Muestra lo que pasó en los últimos diez minutos. También se puede dar una hora: `--since "21:50"`, o un rango con `--until`.

## 2. Escribir en el log con logger

```bash
logger -t lab13 "Empieza el laboratorio 13.1"
logger -t lab13 -p user.err "Prueba de un error"
journalctl -t lab13
```

```text
oct 18 22:08:45 lab2-vm lab13[1037]: Empieza el laboratorio 13.1
oct 18 22:08:45 lab2-vm lab13[1038]: Prueba de un error
```

`-t lab13` pone la etiqueta y `journalctl -t` filtra por ella. Como los mensajes son tuyos, los ves sin `sudo`. El segundo tiene prioridad `err`:

```bash
sudo journalctl -p err -t lab13
```

```text
oct 18 22:08:45 lab2-vm lab13[1038]: Prueba de un error
```

## 3. Incidente A: intentos de acceso por SSH

### 1. Provocar los intentos

Abrí **otra terminal en la máquina anfitriona**, sin cerrar la sesión SSH. Intentá entrar con una cuenta que no existe:

```bash
ssh -p 2222 invitado@localhost
```

Escribí cualquier contraseña. SSH pide tres veces y después corta:

```text
invitado@localhost's password:
Permission denied, please try again.
invitado@localhost's password:
Permission denied, please try again.
invitado@localhost's password:
invitado@localhost: Permission denied (publickey,password).
```

Repetilo una vez más con `invitado`. Después probá con `root`, que sí existe, también con contraseñas equivocadas:

```bash
ssh -p 2222 root@localhost
```

En la VM del curso, root tiene la contraseña bloqueada desde el Laboratorio 2, así que no entra con ninguna. Es la cuenta que más prueban los robots en internet, porque existe en todos los sistemas.

En Windows, los mismos comandos funcionan en PowerShell.

### 2. Investigar

Volvé a la sesión de `cristian`. Buscá los fallos de los últimos minutos:

```bash
sudo journalctl -u ssh --since "15 min ago" --grep "Failed password"
```

```text
oct 18 23:38:24 lab2-vm sshd-session[2670]: Failed password for invalid user invitado from 10.0.2.2 port 58390 ssh2
oct 18 23:38:27 lab2-vm sshd-session[2670]: Failed password for invalid user invitado from 10.0.2.2 port 58390 ssh2
oct 18 23:38:28 lab2-vm sshd-session[2670]: Failed password for invalid user invitado from 10.0.2.2 port 58390 ssh2
oct 18 23:38:31 lab2-vm sshd-session[2672]: Failed password for invalid user invitado from 10.0.2.2 port 60732 ssh2
oct 18 23:38:33 lab2-vm sshd-session[2672]: Failed password for invalid user invitado from 10.0.2.2 port 60732 ssh2
oct 18 23:38:35 lab2-vm sshd-session[2672]: Failed password for invalid user invitado from 10.0.2.2 port 60732 ssh2
oct 18 23:38:37 lab2-vm sshd-session[2674]: Failed password for root from 10.0.2.2 port 40338 ssh2
oct 18 23:38:40 lab2-vm sshd-session[2674]: Failed password for root from 10.0.2.2 port 40338 ssh2
oct 18 23:38:42 lab2-vm sshd-session[2674]: Failed password for root from 10.0.2.2 port 40338 ssh2
```

Para contarlos, sumá `wc -l`, que vimos en la clase 6:

```bash
sudo journalctl -u ssh --since "15 min ago" --grep "Failed password" | wc -l
```

```text
9
```

Cada conexión tiene su número de proceso (`[2670]`, `[2672]`, `[2674]`) y su puerto de origen: fueron tres conexiones con tres intentos cada una.

`invalid user` quiere decir que la cuenta no existe. Para ver cuántas veces probaron cuentas inexistentes:

```bash
sudo journalctl -u ssh --since "15 min ago" --grep "Invalid user"
```

```text
oct 18 23:38:23 lab2-vm sshd-session[2670]: Invalid user invitado from 10.0.2.2 port 58390
oct 18 23:38:29 lab2-vm sshd-session[2672]: Invalid user invitado from 10.0.2.2 port 60732
```

Para saber si alguien llegó a entrar, buscá `Accepted`:

```bash
sudo journalctl -u ssh --since "15 min ago" --grep "Accepted"
```

```text
oct 18 23:38:42 lab2-vm sshd-session[2679]: Accepted publickey for cristian from 10.0.2.2 port 40344 ssh2: ED25519 SHA256:1FLXkLVegS5rb/XoAIN5uRHJgAw/DVWFQblwXIJ2XcQ
```

Solo aparecen tus propias entradas como `cristian`. Si entrás con contraseña y no con clave, vas a ver `Accepted password for cristian`.

> [!NOTE]
> `10.0.2.2` es la dirección con la que VirtualBox presenta a la máquina anfitriona dentro de la red NAT. Todo lo que llega por el reenvío del puerto 2222 tiene ese origen.

### 3. El nombre de la unidad o servicio

Probá con `sshd`, que es como se llama el servicio en muchas distribuciones:

```bash
sudo journalctl -u sshd --since "15 min ago"
```

```text
-- No entries --
```

En Debian la unidad es `ssh`. `sshd` es un alias que acepta `systemctl`, pero `journalctl` no. Si `journalctl -u` no muestra nada, lo primero es confirmar el nombre con `systemctl status`.



## 4. Instalar rsyslog

```bash
sudo apt install rsyslog
```

Al terminar, rsyslog queda habilitado y en marcha. Mirá los archivos nuevos:

```bash
systemctl is-active rsyslog
ls -l /var/log/syslog /var/log/auth.log /var/log/kern.log
```

```text
active
-rw-r----- 1 root adm   100 oct 18 22:10 /var/log/auth.log
-rw-r----- 1 root adm 57475 oct 18 22:10 /var/log/kern.log
-rw-r----- 1 root adm 58080 oct 18 22:10 /var/log/syslog
```

Son de `root` y del grupo `adm`, sin permiso para los demás. `auth.log` es casi vacío: rsyslog copia desde que se instala, y los intentos del paso 3 quedaron solo en el journal.

Escribí un mensaje y buscalo en `syslog`:

```bash
logger -t lab13 "Hola desde logger"
sudo tail -n 2 /var/log/syslog
```

```text
2026-10-18T22:10:24.409911-03:00 lab2-vm kernel: e1000: enp0s3 NIC Link is Up 1000 Mbps Full Duplex, Flow Control: RX
2026-10-18T22:10:24.935484-03:00 lab2-vm lab13: Hola desde logger
```

La fecha viene completa, con la zona horaria (`-03:00`).

### 1. Un intento más

Desde la terminal del anfitrión, intentá entrar una vez más como `invitado` con cualquier contraseña. Después buscalo en `auth.log`:

```bash
sudo grep "Failed password" /var/log/auth.log
```

```text
2026-10-18T22:10:27.330658-03:00 lab2-vm sshd-session[1277]: Failed password for invalid user invitado from 10.0.2.2 port 59158 ssh2
2026-10-18T22:10:28.245741-03:00 lab2-vm sudo: cristian : PWD=/home/cristian ; USER=root ; COMMAND=/usr/bin/grep 'Failed password' /var/log/auth.log
```

Hay dos resultados, aunque hiciste un solo intento. La segunda línea la escribió `sudo`: registra en `auth.log` cada comando que ejecuta, con el texto completo. Como el comando contiene `Failed password`, `grep` se encuentra a sí mismo. Si contás con `grep -c`, el número da mal.

Para quedarte solo con lo que escribió SSH, filtrá primero por programa:

```bash
sudo cat /var/log/auth.log | grep sshd-session | grep "Failed password"
```

```text
2026-10-18T22:10:27.330658-03:00 lab2-vm sshd-session[1277]: Failed password for invalid user invitado from 10.0.2.2 port 59158 ssh2
```

Con `journalctl -u ssh` esto no pasa, porque filtra por servicio.

### 2. syslog no tiene los accesos

```bash
sudo grep -c "Failed password" /var/log/syslog
```

```text
0
```

`syslog` recibe todo menos la autenticación, que va aparte a `auth.log`. Eso está seteado en las reglas de rsyslog en `/etc/rsyslog.conf`.


## 5. Incidente B: un backup que falla

> Vamos a simular un error en un servicio. Para eso crearemos un servicio que hace un bkp de `etc` en una ruta, luego llenaremos la ruta e intentaremos correr el bkp para que falle por falta de espacio.

### 1. Un lugar chico para los respaldos

Para provocar un disco lleno sin tocar los discos de la VM, armamos un sistema de archivos chico en memoria. `tmpfs` guarda los archivos en la RAM, como `/run`; con `size=20M` le ponemos un límite de 20 MB. Al reiniciar desaparece.

```bash
sudo mkdir /srv/respaldos
sudo mount -t tmpfs -o size=20M tmpfs /srv/respaldos
df -h /srv/respaldos
```

```text
S.ficheros     Tamaño Usados  Disp Uso% Montado en
tmpfs             20M      0   20M   0% /srv/respaldos
```

### 2. El servicio de respaldo

Creamos un servicio que comprime `/etc` en `/srv/respaldos`. Es un servicio de una sola ejecución (`Type=oneshot`): corre, termina y queda inactivo.

```bash
sudo tee /etc/systemd/system/respaldo-etc.service > /dev/null << "EOF"
[Unit]
Description=Copia de /etc a /srv/respaldos

[Service]
Type=oneshot
ExecStart=/usr/bin/tar -czf /srv/respaldos/etc.tar.gz /etc
EOF
sudo systemctl daemon-reload
```

`tee` con `sudo` escribe el archivo como root, y `<< "EOF"` le pasa todo el texto hasta la línea `EOF`. `daemon-reload` hace que systemd lea la unidad nueva.

Probalo:

```bash
sudo systemctl start respaldo-etc
ls -lh /srv/respaldos
sudo journalctl -u respaldo-etc
```

```text
total 452K
-rw-r--r-- 1 root root 451K oct 18 23:39 etc.tar.gz
oct 18 23:39:20 lab2-vm systemd[1]: Starting respaldo-etc.service - Copia de /etc a /srv/respaldos...
oct 18 23:39:20 lab2-vm tar[2753]: /usr/bin/tar: Eliminando la `/' inicial de los nombres
oct 18 23:39:20 lab2-vm systemd[1]: respaldo-etc.service: Deactivated successfully.
oct 18 23:39:20 lab2-vm systemd[1]: Finished respaldo-etc.service - Copia de /etc a /srv/respaldos.
```

La copia se hizo. El aviso de `tar` sobre la `/` inicial es normal: guarda las rutas como `etc/...`.

### 3. Llenar el disco

Borrá la copia y llená `/srv/respaldos` con un archivo de ceros. `dd` escribe hasta que no entra más:

```bash
sudo rm /srv/respaldos/etc.tar.gz
sudo dd if=/dev/zero of=/srv/respaldos/relleno.bin bs=1M status=none
df -h /srv/respaldos
```

```text
dd: error al escribir en '/srv/respaldos/relleno.bin': No queda espacio en el dispositivo
S.ficheros     Tamaño Usados  Disp Uso% Montado en
tmpfs             20M    20M     0 100% /srv/respaldos
```

El error de `dd` es lo esperado.

### 4. El respaldo falla

```bash
sudo systemctl start respaldo-etc
```

```text
Job for respaldo-etc.service failed because the control process exited with error code.
See "systemctl status respaldo-etc.service" and "journalctl -xeu respaldo-etc.service" for details.
```

Imaginá que no sabés que el disco está lleno. Seguí el orden de la clase 10:

```bash
systemctl status respaldo-etc
```

```text
× respaldo-etc.service - Copia de /etc a /srv/respaldos
     Loaded: loaded (/etc/systemd/system/respaldo-etc.service; static)
     Active: failed (Result: exit-code) since Sun 2026-10-18 23:39:20 -03; 7ms ago
 Invocation: 3958845f16af4af783964f6fab5020ad
    Process: 2771 ExecStart=/usr/bin/tar -czf /srv/respaldos/etc.tar.gz /etc (code=exited, status=2)
   Main PID: 2771 (code=exited, status=2)
   Mem peak: 1.7M
        CPU: 30ms
```

`status` dice que falló sin decir por qué. Eso hay que buscarlo en el log:

```bash
sudo journalctl -u respaldo-etc -n 8
```

```text
oct 18 23:39:20 lab2-vm tar[2771]: /usr/bin/tar: Eliminando la `/' inicial de los nombres
oct 18 23:39:20 lab2-vm tar[2773]: gzip: stdout: No space left on device
oct 18 23:39:20 lab2-vm tar[2771]: /usr/bin/tar: /srv/respaldos/etc.tar.gz: No se puede efectuar write: Tubería rota
oct 18 23:39:20 lab2-vm tar[2771]: /usr/bin/tar: Child returned status 1
oct 18 23:39:20 lab2-vm tar[2771]: /usr/bin/tar: Error is not recoverable: exiting now
oct 18 23:39:20 lab2-vm systemd[1]: respaldo-etc.service: Main process exited, code=exited, status=2/INVALIDARGUMENT
oct 18 23:39:20 lab2-vm systemd[1]: respaldo-etc.service: Failed with result 'exit-code'.
oct 18 23:39:20 lab2-vm systemd[1]: Failed to start respaldo-etc.service - Copia de /etc a /srv/respaldos.
```

Leelo de abajo hacia arriba: la última línea dice que falló, y subiendo aparece la causa, `No space left on device`. Los mensajes mezclan inglés y castellano porque cada programa tiene su propia traducción, o no tiene.

Probá filtrar por prioridad:

```bash
sudo journalctl -u respaldo-etc -p err
```

```text
oct 18 23:39:20 lab2-vm systemd[1]: Failed to start respaldo-etc.service - Copia de /etc a /srv/respaldos.
```

Solo queda la línea de systemd. Las de `tar` y `gzip` tienen otra prioridad. Para diagnosticar un servicio conviene leer todas sus líneas, sin filtrar por prioridad.

`systemctl --failed` lista todo lo que quedó en falla:

```bash
systemctl --failed
```

```text
  UNIT                 LOAD   ACTIVE SUB    DESCRIPTION
● respaldo-etc.service loaded failed failed Copia de /etc a /srv/respaldos
```

### 5. Encontrar qué ocupa el disco y corregir

Con `du`, de la clase 12:

```bash
sudo du -sh /srv/respaldos/*
```

```text
0	/srv/respaldos/etc.tar.gz
20M	/srv/respaldos/relleno.bin
```

`relleno.bin` ocupa todo. `etc.tar.gz` quedó vacío por el intento fallido. Borrá el relleno y volvé a correr el respaldo:

```bash
sudo rm /srv/respaldos/relleno.bin
sudo systemctl start respaldo-etc
ls -lh /srv/respaldos/etc.tar.gz
systemctl --failed
```

```text
-rw-r--r-- 1 root root 451K oct 18 23:39 /srv/respaldos/etc.tar.gz
  UNIT LOAD ACTIVE SUB DESCRIPTION

0 loaded units listed.
```

La copia volvió a tener su tamaño y no queda nada en falla.

## 6. Opcional: rotar los logs

Mirá qué haría logrotate con los archivos de rsyslog, sin cambiar nada:

```bash
sudo logrotate -d /etc/logrotate.d/rsyslog
```

Avisa que está en modo de prueba y, para cada archivo, dice si hace falta rotarlo. Como rsyslog se instaló hace un rato, contesta que no (`log does not need rotating`). Forzá una rotación con `-f` y mirá los archivos:

```bash
sudo logrotate -f /etc/logrotate.d/rsyslog
ls /var/log/syslog*
```

```text
/var/log/syslog
/var/log/syslog.1
```

El `syslog` anterior pasó a `syslog.1` y empezó uno nuevo. Escribí un mensaje, rotá otra vez y leé el comprimido:

```bash
logger -t lab13 "Después de rotar"
sudo logrotate -f /etc/logrotate.d/rsyslog
ls /var/log/syslog*
```

```text
/var/log/syslog
/var/log/syslog.1
/var/log/syslog.2.gz
```

El `.1` no se comprime enseguida (`delaycompress`); recién pasa a `.2.gz` en la rotación siguiente. Los `.gz` se leen con `zcat` o `zless`, de la clase 6:

```bash
sudo zcat /var/log/syslog.2.gz | tail -n 3
```

## 7. Limpieza

Borrá el servicio de prueba y desmontá `/srv/respaldos`. Lo que había adentro estaba en memoria y se pierde al desmontar:

```bash
sudo rm /etc/systemd/system/respaldo-etc.service
sudo systemctl daemon-reload
sudo umount /srv/respaldos
sudo rmdir /srv/respaldos
```

rsyslog puede quedar instalado. El [Laboratorio 13.2](lab13.2.md) lo usa, y si no está lo instala.

## Preguntas

1. En el paso 3, ¿qué diferencia hay entre `Failed password for invalid user invitado` y `Failed password for root`? ¿Por qué los robots prueban siempre con `root`?
2. ¿Por qué los intentos del paso 3 no aparecen en `/var/log/auth.log`?
3. Si tuvieras que buscar los intentos fallidos con `journalctl -p warning`, ¿los encontrarías? ¿Por qué?
4. En el incidente B, ¿qué línea del log te dio la causa? ¿Por qué no alcanzaba con `systemctl status`?
5. ¿Por qué `sudo grep "Failed password" /var/log/auth.log` encuentra una línea de más?

## Resumen del laboratorio

- `journalctl` filtra por arranque (`-b`, `-b -1`), prioridad (`-p`), núcleo (`-k`), tiempo (`--since`), servicio (`-u`), etiqueta (`-t`) y texto (`--grep`). Sin `sudo` muestra solo los mensajes propios.
- En Debian la unidad de SSH es `ssh`; `journalctl -u sshd` no encuentra nada.
- `logger -t` deja mensajes propios en el log.
- Un intento de acceso se reconstruye con `Failed password`, `Invalid user` y `Accepted`: cuenta, origen, hora y cantidad.
- rsyslog copia el log a texto desde que se instala: `syslog` para todo menos los accesos, `auth.log` para los accesos. `sudo` registra sus comandos en `auth.log`.
- Ante un servicio que falla, la causa está en las líneas de antes del `Failed to start`.

## Enlaces útiles y referencias

- Ayuda en Debian: `man journalctl`, `man logger`, `man rsyslog.conf`, `man logrotate`.
- Clase 14: [presentación](https://linux.idepba.com.ar/clase14.html).
- Siguiente: [Laboratorio 13.2 - Logs en otro equipo](lab13.2.md).

-----

<p align="center">
<img src="../img/logos.footer.gray.webp">
</p>
